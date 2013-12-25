# texinfo.mk
# Copyright 2013, j8takagi.
# texinfo.mk is licensed under the MIT license.

# TEXITARGETS変数が設定されていない場合は、エラー終了
ifndef TEXITARGETS
  $(error "TEXITARGETS is not set.")
else
  $(foreach \
    f, $(TEXITARGETS), \
    $(if $(wildcard $(basename $f).texi),,$(error "$(basename $f).texi needed by $f is not exist.")) \
  )
endif

# DEBUGSH変数が設定されている場合は、デバッグ用にシェルコマンドの詳細が表示される
# 例: DEBUGSH=1 make
ifdef DEBUGSH
  SHELL := /bin/sh -x
endif

.PHONY: texi-texint-clean texi-clean texi-distclean

######################################################################
# シェルコマンドの定義
######################################################################
# TeX commands
DVIPDFMX := dvipdfmx
TEX := ptex

# TeX command option flags
DVIPDFMX_FLAGS :=

# Texinfo commands
# MAKEINFO := makeinfo    # set default in GNU Make
TEXI2DVI := TEX=$(TEX) texi2dvi
INSTALL-INFO := install-info

# Texinfo command option flags
# MAKEINFO_FLAGS :=
TEXI2DVI_FLAGS := -q --texinfo=@afourpaper

#General commands
CP := cp
MKDIR := mkdir
TEST := test
SED := sed
ECHO := echo
CONVERT := convert

# DVI -> PDF
DVIPDFCMD = $(DVIPDFMX) $(DVIPDFMXFLAG) $(basename $<).dvi

# ログを.logファイルへ追加出力
COMPILE.dvi = \
  $(ECHO) $(DVIPDFCMD); $(DVIPDFCMD) >>$(basename $<).log 2>&1 || \
    ( \
      $(SED) -n -e '/^Output written on $(BASE)\.dvi/,$$p' $(basename $<).log; \
      exit 1 \
    )

######################################################################
# 拡張子
######################################################################
TEXIINTEXT := .aux .cp .cps .fn .ky .log .pg .pgs .tmp .toc .tp .vr .t2d

TEXIOUTEXT := .info .dvi .html _html .txt .xml

######################################################################
# .dファイルの生成と読み込み
# .dファイルには、.texiファイルの依存関係が記述される
######################################################################
CONDITIONAL := docbook html info plaintext tex xml

getincludefiles = \
  $(SED) -e "s/@c .*$$//" -e "s/@comment .*$$//" $< | \
    $(SED) -e "s/@verb{\[^}\]*}//g" | \
    $(SED) -e "/^@verbatim /,/^@end verbatim$$/d" | \
    $(SED) -n -e "s/^@include \(.*\)$$/\1/p"

incadd = `if test -e $${incadd}; then sed -n -e 's/^\([a-z]*\.txt\)/\1/p' $${incadd}; fi`

# 引数rootfileで指定した.texiファイルから@includeで指定されたファイルを再帰的に取得する
# 用例: $(call incfiles,rootfile)
define incfiles
incadd="$1"; while test -n "$${incadd}"; do incfiles="$${incfiles} $${incadd}"; incadd="$(incadd)"; done; echo $${incfiles}
endef

INCLUDEFILES = $(INCLUDEFILESre)

INCLUDEFILESre = $(eval INCLUDEFILES := \
    $(call $incfiles,$<) \
  )

INCLUDEVERBATIMFILES = $(INCLUDEVERBATIMFILESre)

INCLUDEVERBATIMFILESre = $(eval INCLUDEVERBATIMFILES := \
  $(sort $(shell \
    $(SED) -e "s/@c .*$$//" -e "s/@comment .*$$//" $< $(INCLUDEFILES) | \
      $(SED) -e "s/@verb{\[^}\]*}//g" | \
      $(SED) -e "/^@verbatim /,/^@end verbatim$$/d" | \
      $(SED) -n -e "s/^@verbatiminclude \(.*\)$$/\1/p" \
  )))

# .texiファイルから@imageで指定された画像を取得する
# ただし、引数outputで指定された出力先が条件文で除外している部分は除く
# 用例: $(call images,output)
define images
$(sort $(shell \
  $(SED) -e 's/@c .*$$//' -e 's/@comment .*$$//' $< $(INCLUDEFILES) | \
    $(SED) $(foreach c,$(filter-out $1,$(CONDITIONAL)) not$1,-e '/@if$c/,/@end if$c/d') | \
    $(SED) -e 's/@verb{\[^}\]*}//g' | \
    $(SED) -e '/@verbatim/,/@end verbatim/d' | \
    $(SED) -e 's/}/}%/g; y/}%/}\n/' | \
    $(SED) -n -e 's/\(.*[^@]\)\{0,1\}@image{\([^},]*\)[^}]*}$$/\2/p' \
))
endef

# 出力されるファイル群
OUTFILES = $(addprefix $(basename $<),$(TEXIOUTEXT))

# 出力されるファイル群で、グラフィックを挿入できるもの
OUTGFILES = $(filter-out %.tex %.info,$(OUTFILES))

# 指定されたファイルベース名（ファイル名から拡張子を除いた部分）と拡張子のファイルから
# 実在するファイル名のリストを取得する
#
# 用例: $(call imgexist,filebase,ext)
define imgexist
$(strip $(wildcard $(addprefix $1,$2)))
endef

#
TEXIMGEXT := .eps

TEXIMGFILES = $(TEXIMGFILESre)

TEXIMGFILESre = $(eval TEXIMGFILES := \
  $(addsuffix $(TEXIMGEXT),$(basename $(call images,html))))

#
HTMLIMGEXT := .png .jpg .jpeg .gif

HTMLIMGFILES = $(HTMLIMGFILESre)

HTMLIMGFILESre = $(eval HTMLIMGFILES := \
  $(strip $(foreach f,$(call images,html), \
    $(if $(filter $(basename $f),$f),$(firstword $(call imgexist,$f,$(HTMLIMGEXT)),$f)) \
  )))

#
DBIMGEXT := .eps .gif .jpeg .jpg .pdf .png .svg .txt

DBIMGFILES = $(DBIMGFILESre)

DBIMGFILESre = $(eval DBIMGFILES := \
  $(strip $(foreach f,$(call images,docbook), \
    $(call imgexist,$f,$(DBIMGEXT))) \
  ))

#
INFOIMGEXT := .txt .png .jpg

INFOIMGFILES = $(IMGFILESre)

IMGFILESre = $(eval IMGFILES := \
  $(strip $(foreach f,$(call images,info), \
    $(firstword $(call imgexist,$f,$(INFOIMGEXT))) \
  )))

# .dファイルを作成するパターンルール
%.d: %.texi
    # Makefile変数の展開
    # 遅延展開される変数の展開。実際の表示はしない
	@$(foreach f, INCLUDEFILES INCLUDEVERBATIMFILES, $(ECHO) '$f=$($f)' >/dev/null;)
    # .dファイルに書き込まれる変数をコマンドラインへ出力
	@$(if $(strip $(INCLUDEFILES) $(INCLUDEVERBATIMFILES) $(IMG)), \
      $(ECHO) 'Makefile variables'; \
      $(foreach f, INCLUDEFILES INCLUDEVERBATIMFILES IMG, $(if $($f),$(ECHO) '  $f=$($f)'; )) \
    )
    # ターゲットファイル（.dファイル）を作成し、自身の依存関係を出力
	@$(ECHO) '$(OUTFILES) $@: $<' >$@
	@$(ECHO) >>$@
	@$(ECHO) '$(filter %.html %_html,$(OUTFILES)): $(CSS)' >>$@
    # @includeで挿入したファイルがある場合、依存関係をターゲットファイルへ出力
	@$(if $(INCLUDEFILES),($(ECHO); $(ECHO) '$(OUTFILES): $(INCLUDEFILES)') >>$@)
    # @includeverbatimで挿入したファイルがある場合、依存関係をターゲットファイルへ出力
	@$(if $(INCLUDEVERBATIMFILES),($(ECHO); $(ECHO) '$(OUTFILES): $(INCLUDEVERBATIMFILES)') >>$@)
    # @imageで挿入した画像ファイル
    # 遅延展開される変数の展開。実際の表示はしない
	@$(foreach f, TEXIMGFILES HTMLIMGFILES DBIMGFILES INFOIMGFILES, $(ECHO) '$f=$($f)' >/dev/null;)
	@$(if $(TEXIMGFILES),( \
      $(ECHO); \
      $(ECHO) '# TeX (DVI output) reads the file .eps'; \
      $(ECHO) '$(filter %.dvi,$(OUTFILES)): $(TEXIMGFILES)'; \
     ) >>$@)
	@$(if $(HTMLIMGFILES),( \
      $(ECHO); \
      $(ECHO) '# For HTML, makeinfo outputs a reference to  $(HTMLIMGEXT) (in that order).'; \
      $(ECHO) '# If none of those exist, it gives an error, and outputs a reference to filename.jpg anyway.'; \
      $(ECHO) '$(filter %.html %_html,$(OUTFILES)): $(HTMLIMGFILES)'; \
     ) >>$@)
	@$(if $(DBIMGFILES),( \
      $(ECHO); \
      $(ECHO) '# For Docbook, makeinfo outputs references to $(DBIMGEXT) for every file found.'; \
      $(ECHO) '# Also, filename.txt is included verbatim, if present. (The subsequent Docbook processor is supposed to choose the appropriate one.)'; \
      $(ECHO) '$(filter %.xml,$(OUTFILES)): $(DBIMGFILES)'; \
     ) >>$@)
	@$(if $(INFOIMGFILES),( \
      $(ECHO); \
      $(ECHO) '# For Info, makeinfo includes, or include a reference to $(INFOIMGEXT).'; \
      $(ECHO) '$(filter %.info,$(OUTFILES)): $(INFOIMGFILES)'; \
     ) >>$@)
    # ターゲットファイルが作成されたことをコマンドラインへ出力
	@$(ECHO) '$@ is generated by scanning $(strip $< $(INCLUDEFILES)).'

# .dファイルをインクルードし、依存関係を取得する
# ターゲット末尾に cleanが含まれている場合は除く
ifeq (,$(filter %clean %.d,$(MAKECMDGOALS)))
  -include $(addsuffix .d,$(sort $(basename $(TEXITARGETS))))
endif

######################################################################
# 各種形式のドキュメントを生成するパターンルール
######################################################################
# ソース -> Info
%.info: %.texi
	$(MAKEINFO) $(MAKEINFO_FLAGS) -o $@ $<

# ソース -> HTML（1ファイル）
%.html: %.texi
	$(MAKEINFO) $(MAKEINFO_FLAGS) -o $@ --no-split --html --css-include=$(CSS) $<

# ソース -> HTML（複数ファイル）
# 「<texiファイル名の拡張子以外の部分>_html」ディレクトリーに格納
%_html: %.texi
	if $(TEST) ! -e $@; then $(MKDIR) $@; fi
	$(CP) $(CSS) $@/
	$(MAKEINFO) $(MAKEINFO_FLAGS) -o $@ --html --css-ref=$(CSS) $<

# ソース -> DVI
# GNU Make標準で設定されている。次のコマンドで確認。
#  make -p | sed -n '/%\.dvi: %\.texinfo/,/^$/p'

# DVI -> PDF
%.pdf: %.dvi
	@$(COMPILE.dvi)

# ソース -> テキストファイル
%.txt: %.texi
	$(MAKEINFO) $(MAKEINFO_FLAGS) --no-headers --disable-encoding -o $@ $<

# ソース -> Docbook（XML）
%.xml: %.texi
	@$(MAKEINFO) $(MAKEINFO_FLAGS) --docbook -o $@ $<

# .pngの作成
%.jpg: %.pdf
	$(CONVERT) $< $@

######################################################################
# ターゲット
######################################################################
# 警告
texi-warn:
	@$(ECHO) "Check current directory, or target of Makefile." >&2; exit 2

texi-texint-clean:
	$(RM) $(addprefix *,$(TEXIINTEXT))

texi-clean: texi-texint-clean
	$(RM) *.d

texi-distclean: texi-clean
	$(RM) -r $(wildcard $(foreach f,$(sort $(basename $(TEXITARGETS))),$(addprefix $f,$(TEXIOUTEXT) .pdf)))
