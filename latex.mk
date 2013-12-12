# latex.mk
# Copyright 2013, j8takagi.
# latex.mk is licensed under the MIT license.

######################################################################
# 使用するシェルコマンドの定義
######################################################################

# シェルコマンド
CAT := cat
CMP := cmp -s
CP := cp
ECHO := /bin/echo
GREP := grep
MKDIR := mkdir
SED := sed
SEQ := seq
TR := tr

# LaTeXコマンド
LATEX := platex
DVIPDFMX := dvipdfmx
EXTRACTBB := extractbb
BIBTEX := pbibtex
MENDEX := mendex
KPSEWHICH := kpsewhich

# LaTeXオプション
LATEXFLAG ?=
DVIPDFMXFLAG ?=
EXTRACTBBFLAGS ?=
BIBTEXFLAG ?=
MENDEXFLAG ?=

# シェルコマンドをデバッグするときは、DEBUGSH変数を設定してmakeを実行する
# 例: DEBUGSH=1 make
ifdef DEBUGSH
  SHELL := /bin/sh -x
endif

######################################################################
# 拡張子
######################################################################

# .aux、.fls以外のLaTeX中間ファイルの拡張子
#   .bbl: 文献リスト。作成方法はパターンルールで定義
#   .glo: 用語集。\glossaryがあればTeX処理で生成
#   .idx: 索引。\makeindexがあればTeX処理で生成
#   .ind: 索引。作成方法はパターンルールで定義
#   .lof: 図リスト。\listoffiguresがあればTeX処理で生成
#   .lot: 表リスト。\listoftablesがあればTeX処理で生成
#   .out: PDFブックマーク。hyperrefパッケージをbookmarksオプションtrue（初期値）で呼び出していれば、TeX処理で生成
#   .toc: 目次。\tableofcontentsがあればTeX処理で生成
LATEXINTEXT := .bbl .glo .idx .ind .lof .lot .out .toc

# ログファイルの拡張子
#   .log: TeXログ
#   .ilg: 索引ログ
#   .blg: BiBTeXログ
LOGEXT := .log .ilg .blg

# すべてのTeX中間ファイルの拡張子
ALLINTEXT := .aux .dvi $(LATEXINTEXT) $(LOGEXT) .fls .d .*_prev

# 画像ファイルの拡張子
GRAPHICSEXT := .pdf .eps .jpg .jpeg .png .bmp

# make完了後、中間ファイルを残す
.SECONDARY: $(foreach t,$(TEXTARGETS),$(addprefix $(basename $t),$(ALLINTEXT)))

# ファイル名から拡張子を除いた部分
BASE = $(basename $<)

######################################################################
# .dファイルの生成と読み込み
# .dファイルには、LaTeX処理での依存関係が記述される
######################################################################

# .flsファイルから、INPUTファイルを取得。ただし、$TEXMFROOTのファイルを除く
# 取得は、1回のmake実行につき1回だけ行われる
INPUTFILES = $(INPUTFILESre)

INPUTFILESre = $(eval INPUTFILES := \
  $(sort $(filter-out $(BASE).tex $(BASE).aux, $(shell \
    $(SED) -n -e 's/^INPUT \(.\{1,\}\)/\1/p' $(BASE).fls | \
    $(GREP) -v `$(KPSEWHICH) -expand-var '$$TEXMFROOT'` \
  ))))

# .flsファイルから、OUTPUTファイルを取得。ただし、$TEXMFROOTのファイルを除く
# 取得は、1回のmake実行につき1回だけ行われる
OUTPUTFILES =  $(OUTFILESre)

OUTFILESre = $(eval OUTPUTFILES := \
  $(sort $(filter-out $(BASE).aux $(BASE).dvi $(BASE).log, \
    $(shell \
      $(SED) -n -e 's/^OUTPUT \(.\{1,\}\)/\1/p' $(BASE).fls | \
      $(GREP) -v `$(KPSEWHICH) -expand-var '$$TEXMFROOT'` \
  ))))

# 引数で指定されたファイルから、LaTeXコマンドを取得する
# 用例: $(call latexsrc_cmd,files)
define latexsrc_cmd
  $(shell $(SED) -e '/^\s*%/d' -e 's/\([^\]\)\s*%.*/\1/g' $1 | \
      $(SED) -e '/\\begin{verbatim}/,/\\end{verbatim}/d' -e 's/\\verb|[^|]*|//g' | \
      $(SED) -e 's/}/}%/g' | $(SED) -e 'y/}%/}\n/' | \
      $(SED) -n -e 's/.*\\\([a-zA-Z]*\(\[[^]]*\]\)\{0,1\}{\([^}]*\)}\)$$/\1/p' \
  )
endef

# \includeや\inputで読み込まれるTeXファイルを.flsから取得する
TEXFILESFLS = $(filter %.tex,$(INPUTFILES))

# \includeや\inputで読み込まれるTeXファイルをソースから取得する
TEXFILES = $(TEXFILESre)

TEXFILESre = $(eval TEXFILES := \
  $(sort $(addsuffix .tex,$(basename \
    $(shell $(SED) -e '/^\s*%/d' -e 's/\([^\]\)\s*%.*/\1/g' $(BASE).tex $(TEXFILESFLS) | \
      $(SED) -e '/\\begin{verbatim}/,/\\end{verbatim}/d' -e 's/\\verb|[^|]*|//g' | \
      $(SED) -e 's/}/}%/g' | $(SED) -e 'y/}%/}\n/' | \
      $(SED) -n -e 's/.*\\input{\([^}]*\)}$$/\1/p' -e 's/.*\\include{\([^}]*\)}$$/\1/p' \
  )))))


# 引数filelistで指定されたファイルリストから、実在するものを取得する
# 用例: $(call valid_files,filelist)
valid_files = $(foreach f,$1,$(shell if test -s $f; then $(ECHO) $f; fi))

# LaTeXコマンド（\\<英字>[ ]{ }）を、コメント、verbatim環境、verb| | 以外の部分から取得する
# 取得は、1回のmake実行につき1回だけ行われる
LATEXSRCCMD = $(LATEXSRCCMDre)

LATEXSRCCMDre = $(eval LATEXSRCCMD := \
    $(shell $(SED) -e '/^\s*%/d' -e 's/\([^\]\)\s*%.*/\1/g' $(BASE).tex $(call valid_files,$(TEXFILES)) | \
      $(SED) -e '/\\begin{verbatim}/,/\\end{verbatim}/d' -e 's/\\verb|[^|]*|//g' | \
      $(SED) -e 's/}/}%/g' | $(SED) -e 'y/}%/}\n/' | \
      $(SED) -n -e 's/.*\\\([a-zA-Z]*\(\[[^]]*\]\)\{0,1\}{\([^}]*\)}\)$$/\1/p' \
  ))

# LaTeXコマンドから、ブレース{}で囲まれた引数を取得する
# 用例: $(call latexsrccmd_bracearg,cmd)
define latexsrccmd_bracearg
  $(strip $(shell \
    $(ECHO) '$(LATEXSRCCMD)' | \
      $(SED) -e 'y/} /}\n/' | \
      $(SED) -n -e '/$1[\[{]/p' | \
      $(SED) -e 's/$1\(\[[^]]*\]\)\{0,1\}{\([^}]*\)}$$/\2/' \
  ))
endef

# $(BASE).texで読み込まれる中間ファイルを.flsから取得する
# .idxは、.indへ置換
LATEXINTFILES = \
  $(sort $(subst .idx,.ind, \
    $(filter $(addprefix $(BASE),$(LATEXINTEXT)),$(INPUTFILES) $(OUTPUTFILES)) \
  ))

LATEXINTFILES_PREV = $(addsuffix _prev,$(LATEXINTFILES))

# \includegraphicsで読み込まれる画像ファイルを$(BASE).texと$(TEXFILES)、および.flsファイルから取得する
# 取得は、1回のmake実行につき1回だけ行われる
GRAPHICFILES = $(GRAPHICFILESre)

GRAPHICFILESre = $(eval GRAPHICFILES := \
  $(sort \
    $(call latexsrccmd_bracearg,includegraphics) \
    $(filter $(addprefix %,$(GRAPHICSEXT)),$(INPUTFILES)) \
  ))

# .flsから取得した、そのほかの読み込みファイル（.styなど）
OTHERFILES = $(sort $(filter-out %.aux $(LATEXINTFILES) $(TEXFILES) $(GRAPHICFILES),$(INPUTFILES)))

# \bibliography命令で読み込まれる文献データベースファイルをTeXファイルから検索する
# 取得は、1回のmake実行につき1回だけ行われる
BIBDB = $(BIBDBre)

BIBDBre = $(eval BIBDB := \
  $(addsuffix .bib,$(basename \
    $(shell $(ECHO) $(call latexsrccmd_bracearg,bibliography) | $(TR) ',' ' ') \
  )))

# .dファイルの依存関係
dfiledep = '$(BASE).d: $(strip $(BASE).tex $(BASE).fls $(TEXFILES))'

# TeXファイルの依存関係
texfilesdep = \
  '\n' \
  '\# Files called from \include or \input - .tex\n' \
  '$(BASE).aux: $(TEXFILES)'

# LaTeX中間ファイルの依存関係
latexintfilesdep = \
  '\n' \
  '\# LaTeX Intermediate Files\n' \
  '\#\n' \
  '\# $$(COMPILE.tex) := $(LATEXCMD)\n' \
  '\# $$(COMPILES.tex) := $(subst $(EXITWARN),exit 1,$(subst $(EXITNOTFOUND),exit 0,$(subst $(COMPILE.tex),$(LATEXCMD),$(COMPILES.tex))))\n' \
  '\#\n' \
  '$(BASE).dvi:: $(sort $(LATEXINTFILES_PREV) $(if $(BIBDB),$(BASE).bbl_prev))\n' \
  '\t@$$(COMPILE.tex)\n' \
  '\n' \
  '$(BASE).dvi:: $(BASE).aux\n' \
  '\t@$$(COMPILES.tex)'

# 画像ファイルの依存関係
graphicfilesdep = \
  '\n' \
  '\# Files called from \includegraphics - $(GRAPHICSEXT)\n' \
  '$(BASE).aux: $(GRAPHICFILES)'

# .xbbファイルの依存関係
xbbfilesdep = \
  '\n' \
  '\# .xbb files with: $(filter-out .eps,$(GRAPHICSEXT))\n' \
  '$(BASE).aux: $(addsuffix .xbb,$(basename $(filter-out %.eps,$(GRAPHICFILES))))'

# 文献リスト作成用ファイルの依存関係
bibdbdep = \
  '\n' \
  '\# Bibliography files: .aux, BIBDB -> .bbl -> .div\n' \
  '$(BASE).bbl: $(BIBDB) $(BASE).tex'

# そのほかのファイル（TeXシステム以外のクラスファイル・スタイルファイルなど）の依存関係
otherfilesdep = \
  '\n' \
  '\# Other files\n' \
  '$(BASE).aux: $(OTHERFILES)'

# putsdep: 依存関係を出力する
# 用例: $(call putsdep,text)
define putsdep
  $(ECHO) -e $1 | $(SED) -e 's/^ \{1,\}//'
endef

# 依存関係を.dファイルに書き出す
%.d: %.fls
    # Makefile変数の展開
	@$(ECHO) ' $(TEXFILESFLS) $(TEXFILES) $(LATEXSRCCMD) $(LATEXINTFILES) $(GRAPHICFILES) $(BIBDB)' >/dev/null
	@$(ECHO) -e 'Makefiles variable\n  TEXFILES=$(TEXFILES)\n  LATEXINTFILES=$(LATEXINTFILES)\n  GRAPHICFILES=$(GRAPHICFILES)\n  BIBDB=$(BIBDB)'
    # .dファイルの依存関係
	@$(call putsdep,$(dfiledep)) >$@
    # TeXファイルの依存関係
	$(if $(TEXFILES),@$(call putsdep,$(texfilesdep)) >>$@)
    # 中間ファイルの依存関係
	$(if $(strip $(LATEXINTFILES) $(BIBDB)), @$(call putsdep,$(latexintfilesdep)) >>$@)
    # 画像ファイルの依存関係
	$(if $(GRAPHICFILES),@$(call putsdep,$(graphicfilesdep)) >>$@)
    # バウンディング情報ファイルの依存関係
	$(if $(filter-out %.eps,$(GRAPHICFILES)),@$(call putsdep,$(xbbfilesdep)) >>$@)
    # 文献リストファイルの依存関係
	$(if $(BIBDB),@$(call putsdep,$(bibdbdep)) >>$@)
    # そのほかのファイル（TEXMFROOT以外にあるスタイルファイルなど）の依存関係
	$(if $(OTHERFILES),@$(call putsdep,$(otherfilesdep)) >>$@)
	@$(ECHO) '$@ is generated by scanning $(strip $(BASE).tex $(TEXFILES)) and $(BASE).fls.'

# 変数TEXTARGETSで指定されたターゲットファイルに対応する
# .dファイルをインクルードし、依存関係を取得する
# ターゲット末尾に clean、.xbb、.tex、.d が含まれている場合は除く
ifeq (,$(filter %clean %xbb %.tex %.d %.fls %.fls_prev,$(MAKECMDGOALS)))
  -include $(addsuffix .d,$(basename $(TEXTARGETS)))
endif

######################################################################
# dviおよびPDFファイルを生成するパターンルール
# TeX -> dvi -> PDF
######################################################################

# LaTeX処理（コンパイル）
LATEXCMD = $(LATEX) -interaction=batchmode $(LATEXFLAG) $(BASE).tex

# エラー発生時、ログのエラー部分を行頭に「<TeXファイル名>:<行番号>:」を付けて表示する
COMPILE.tex = \
  $(ECHO) $(LATEXCMD); $(LATEXCMD) >/dev/null 2>&1 || \
  ( \
    $(SED) -n -e '/^!/,/^$$/p' $(BASE).log | \
      $(SED) -e 's/.*\s*l\.\([0-9]*\)\s*.*/$(BASE).tex:\1: &/' 1>&2; \
    exit 1)

# 相互参照未定義の警告
WARN_UNDEFREF := There were undefined references.

# LaTeX処理
# ログファイルに警告がある場合は警告がなくなるまで、最大LIMで指定された回数分、処理を実行する
LIM := 3
LIMMSG := $(LATEX) is run $(LIM) times, but there are still undefined references.

EXITNOTFOUND = \
  if test $$? -eq 1; then \
    exit 0; \
  else \
    exit $$?; \
  fi

EXITWARN = \
  $(ECHO) "$(LIMMSG)" 1>&2; \
  $(SED) -n -e "/^LaTeX Warning:/,/^$$/p" $(BASE).log | \
    $(SED) -e "s/.*\s*line \([0-9]*\)\s*.*/$(BASE).tex:\1: &/" 1>&2; \
  exit 1

COMPILES.tex = \
  for i in `$(SEQ) 0 $(LIM)`; do \
    if test $$i -lt $(LIM); then \
      $(GREP) -F "$(WARN_UNDEFREF)" $(BASE).log || $(EXITNOTFOUND) && $(COMPILE.tex); \
    else \
      $(EXITWARN); \
    fi; \
  done;

# DVI -> PDF
# 出力時のログは.logファイルへ追加出力
DVIPDFCMD = $(DVIPDFMX) $(DVIPDFMXFLAG) $(BASE).dvi
COMPILE.dvi = \
  $(ECHO) $(DVIPDFCMD); $(DVIPDFCMD) >>$(BASE).log 2>&1 || \
    ($(SED) -n -e '/^Output written on toc_hyperref.dvi/,$$p' $(BASE).log; exit 1)

# TeX -> aux
%.aux: %.tex
	@$(COMPILE.tex)

# aux -> dvi
%.dvi: %.aux
	@$(COMPILES.tex)

# tex -> dvi
%.dvi: %.tex
	@$(COMPILE.tex)
	@$(COMPILES.tex)

# dvi -> PDF
%.pdf: %.dvi
	@$(COMPILE.dvi)

######################################################################
# ファイルリストファイル（.fls）作成
######################################################################

# .flsファイル作成用の一時ディレクトリー
FLSDIR := .fls.temp

# $(BASE).flsファイルの作成
FLSCMD = $(LATEX) -interaction=nonstopmode -recorder -output-directory=$(FLSDIR) $(BASE).tex

GENERETE.fls = \
  if test ! -e $(FLSDIR); then \
    $(MKDIR) $(FLSDIR); \
  fi; \
  $(FLSCMD) 1>/dev/null 2>&1; \
  $(SED) -e 's|$(FLSDIR)/||g' $(FLSDIR)/$(BASE).fls >$(BASE).fls; \
  if test -e $(BASE).fls; then \
    $(ECHO) '$(BASE).fls is generated.'; \
    $(RM) -r $(FLSDIR); \
  else \
    $(ECHO) '$(BASE).fls is not generated.' 1>&2; \
    exit 1; \
  fi

%.fls: %.tex
	@-$(GENERETE.fls)

######################################################################
# LaTeX中間ファイルを生成するパターンルール
######################################################################

# ターゲットファイルと必須ファイルを比較し、
# 内容が異なる場合はターゲットファイルの内容を必須ファイルに置き換える
CMPPREV = $(CMP) $< $@ && $(ECHO) '$@ is up to date.' || $(CP) -p -v $< $@

# 図リスト
%.lof: %.tex
	@$(MAKE) -s $(BASE).aux

%.lof_prev: %.lof
	@$(CMPPREV)

# 表リスト
%.lot: %.tex
	@$(MAKE) -s $(BASE).aux

%.lot_prev: %.lot
	@$(CMPPREV)

# PDFブックマーク
%.out: %.tex
	@$(MAKE) -s $(BASE).aux

%.out_prev: %.out
	@$(CMPPREV)

# 目次
%.toc: %.tex
	@$(MAKE) -s $(BASE).aux

%.toc_prev: %.toc
	@$(CMPPREV)

######################################################################
# 索引用中間ファイルを生成するパターンルール
######################################################################

# 索引用中間ファイル作成コマンド
MENDEXCMD = $(MENDEX) $(MENDEXFLAG) $(BASE).idx

COMPILE.idx = $(ECHO) $(MENDEXCMD); $(MENDEXCMD) >/dev/null 2>&1 || ($(CAT) $(BASE).ilg 1>&2; exit 1)

# .tex -> .idx
%.idx: %.tex
	@$(MAKE) -s $(BASE).aux

%.idx_prev: %.idx
	@$(CMPPREV)

# .idx -> .ind
%.ind: %.idx_prev
	@$(COMPILE.idx)

%.ind_prev: %.ind
	@$(CMPPREV)

######################################################################
# 文献リスト用中間ファイルを生成するパターンルール
######################################################################
# 文献リスト用中間ファイル作成コマンド
BIBTEXCMD = $(BIBTEX) $(BIBTEXFLAG) $(BASE).aux

COMPILE.bib = $(ECHO) $(BIBTEXCMD); $(BIBTEXCMD) >/dev/null 2>&1 || ($(CAT) $(BASE).blg 1>&2; exit 1)

# TeX -> .aux -> .bib
%.bbl: %.tex
	@$(MAKE) -s $(BASE).aux
	@$(COMPILE.bib)

%.bbl_prev: %.bbl
	@$(CMPPREV)

######################################################################
# バウンディング情報ファイルを生成するパターンルール
######################################################################
%.xbb: %.pdf
	$(EXTRACTBB) $(EXTRACTBBFLAGS) $<

%.xbb: %.jpeg
	$(EXTRACTBB) $(EXTRACTBBFLAGS) $<

%.xbb: %.jpg
	$(EXTRACTBB) $(EXTRACTBBFLAGS) $<

%.xbb: %.png
	$(EXTRACTBB) $(EXTRACTBBFLAGS) $<

%.xbb: %.bmp
	$(EXTRACTBB) $(EXTRACTBBFLAGS) $<

######################################################################
# ターゲット
######################################################################

# 警告
tex-warn:
	@($(ECHO) "check current directory, or set TEXTARGET in Makefile." 1>&2)

# すべての画像ファイルに対してextractbbを実行
tex-xbb:
	$(MAKE) -s $(addsuffix .xbb,$(basename $(wildcard $(addprefix *,$(GRAPHICSEXT)))))

# 中間ファイルの削除
tex-clean:
	$(RM) $(addprefix *,$(ALLINTEXT))
	$(RM) -r $(FLSDIR)
ifeq (,$(filter %.dvi,$(TEXTARGETS)))
	$(RM) *.dvi
endif

# .xbbファイルの削除
tex-xbb-clean:
	$(RM) *.xbb

# 生成されたすべてのファイルの削除
tex-distclean: tex-clean tex-xbb-clean
ifneq (,$(filter %.dvi,$(TEXTARGETS)))
	$(RM) *.dvi
endif
	$(RM) $(TEXTARGETS)
