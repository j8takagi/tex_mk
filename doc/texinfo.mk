# texinfo.mk
# Copyright 2013, j8takagi.
# texinfo.mk is licensed under the MIT license.

# DEBUGSH変数が設定されている場合は、デバッグ用にシェルコマンドの詳細が表示される
# 例: DEBUGSH=1 make
ifdef DEBUGSH
  SHELL := /bin/sh -x
endif

.PHONY: texinfo-texint-clean texinfo-clean texinfo-distclean

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

# Texinfo command option flags
# MAKEINFO_FLAGS :=
TEXI2DVI_FLAGS := -q --texinfo=@afourpaper --tidy

#General commands
CP := cp
INSTALL-INFO := install-info
MKDIR := mkdir
TEST := test

######################################################################
# 拡張子
######################################################################
TEXINFOINTEXT := .aux .cp .cps .fn .ky .log .pg .pgs .tmp .toc .tp .vr

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

# DVI -> PDF
# なお、ソース -> DVI はGNU Make標準で設定されている
%.pdf: %.dvi
	$(DVIPDFMX) $(DVIPDFMXFLAGS) $<

# ソース -> テキストファイル
%.txt: %.texi
	$(MAKEINFO) $(MAKEINFO_FLAGS) --no-headers --disable-encoding -o $@ $<

# ソース -> Docbook（XML）
%.xml: %.texi
	@$(MAKEINFO) $(MAKEINFO_FLAGS) --docbook -o $@ $<

######################################################################
# ターゲット
######################################################################
# 警告
texinfo-warn:
	@$(ECHO) "Check current directory, or target of Makefile." >&2; exit 2

texinfo-texint-clean:
	$(RM) $(addprefix *,$(TEXINFOINTEXT))

texinfo-clean: texinfo-texint-clean

texinfo-distclean: texinfo-clean
	$(RM) -r *_html *.info *.html *.pdf *.dvi *.txt *.t2d
