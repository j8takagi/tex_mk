# latex.mk
# LaTeX処理（コンパイル）を行う
#
# == 使い方 ==
# 1. texソースファイルと同じディレクトリーに本ファイル（latex.mk）をコピーする
# 2. Makefileに変数TEXTARGETS と「include latex.mk」を記述する
# 3. texソースファイルと同じディレクトリーで、make コマンドを実行する
#
# == 機能 ==
# - 読み込むべき中間ファイルがないことや相互参照未定義の警告がある場合、LaTeX処理を最大4回繰り返す
# - \includegraphics命令がTeXファイルに含まれる場合、グラフィックファイルを挿入
#   -- 挿入されたグラフィックファイルが更新されたときは、処理を開始
#   -- 挿入されたグラフィックファイルがないときは、処理を中止
#   -- 挿入されたグラフィックファイルに対するバウンディング情報ファイル（.xbb）を作成
# - \include、\input命令がTeXファイルに含まれる場合、TeXファイルを挿入
#   -- 挿入されたTeXファイルが更新されたときは、処理を開始
#   -- 挿入されたTeXファイルがないときは、処理を中止
# - \makeindex命令が含まれる場合、mendexで索引を作成
# - \bibliography命令が含まれる場合、BiBTeXで文献一覧を作成
#
# == 擬似ターゲット ==
# - tex-clean: TeX中間ファイル（auxなど）を削除。ターゲットに.dviが含まれていないときは.dviファイルを削除
# - xbb-clean: バウンディング情報ファイル（.xbb）を削除
# - tex-distclean: TeX中間ファイル、バウンディング情報ファイル、ターゲットファイル（PDF、.dvi）を削除
#
# === Makefile -- sample ===
# TEXTARGETS := report.tex
#
# all: $(TEXTARGETS)
#
# include latex.mk

ifdef DEBUG
  SHELL := /bin/sh -x
endif

.PHONY: tex-warning tex-xbb tex-clean tex-distclean

# シェルコマンド
CAT := cat
CMP := cmp -s
CP := cp
ECHO := /bin/echo
GREP := grep
SED := sed
SEQ := seq

# LaTeXコマンド
LATEX := platex
DVIPDFMX := dvipdfmx
EXTRACTBB := extractbb
BIBTEX := pbibtex
MENDEX := mendex
KPSEWHICH := kpsewhich

#LaTeXオプション
LATEXFLAG ?=
DVIPDFMXFLAG ?=
EXTRACTBBFLAGS ?=
BIBTEXFLAG ?=
MENDEXFLAG ?=

tex-warning:
	@$(ECHO) "check current directory, or set TEXTARGET in Makefile."

# ファイル名から拡張子を除いた部分
BASE = $(basename $<)

# .aux、.fls以外のTeX中間ファイルの拡張子
#   .glo: 用語集。\glossaryがあれば生成
#   .lof: 図リスト。\listoffiguresがあれば生成
#   .lot: 表リスト。\listoftablesがあれば生成
#   .out: PDFブックマーク。hyperrefパッケージをbookmarksオプションtrue（初期値）で呼び出せば生成
#   .toc: 目次。\tableofcontentsがあれば生成
TEX_INT := .glo .lof .lot .out .toc
# 索引中間ファイルの拡張子
#   .idx: \makeindexがあれば生成
#   .ind: idxから作成
IND_INT := .idx .ind
# BiBTeX中間ファイルの拡張子
#   .bbl: auxから作成
BIB_INT := .bbl .blg
#   .log: ログ
#   .ilg: 索引ログ
#   .blg: BiBTeXログ
LOG := .log .ilg .blg

ALL_INTERFILES = $(addprefix *,.aux $(TEX_INT) $(IND_INT) $(BIB_INT) $(LOG) .fls .d .*_prev)

# make完了後、中間ファイルを残す
.SECONDARY: $(wildcard ALL_INTERFILES)

# ファイル名から拡張子を除いた部分
BASE = $(basename $<)

# .flsファイルから、INPUTファイルを取得。ただし、$TEXMFDISTのファイルを除く
# 取得は、1回のmake実行につき1回だけ行われる
INPUTFILES = $(INPUTFILESre)

INPUTFILESre = $(eval INPUTFILES := \
  $(sort $(filter-out $(BASE).tex $(BASE).aux, $(shell \
    $(SED) -n -e 's/^INPUT \(.\{1,\}\)/\1/p' $(BASE).fls | \
    $(GREP) -v `$(KPSEWHICH) -expand-var '$$TEXMFROOT'` \
  ))))

# .flsファイルから、OUTPUTファイルを取得。ただし、$TEXMFDISTのファイルを除く
# 取得は、1回のmake実行につき1回だけ行われる
OUTPUTFILES =  $(OUTFILESre)

OUTFILESre = $(eval OUTPUTFILES := \
  $(sort $(filter-out $(BASE).aux $(BASE).dvi $(BASE).log,$(shell \
    $(SED) -n -e 's/^OUTPUT \(.\{1,\}\)/\1/p' $(BASE).fls | \
    $(GREP) -v `$(KPSEWHICH) -expand-var '$$TEXMFROOT'` \
  ))))

# $(BASE).texで読み込まれる中間ファイルを$(BASE).flsから取得する
# .idxは、.indへ置換
INTERFILES = \
  $(sort $(subst .idx,.ind, \
    $(filter $(addprefix $(BASE),$(TEX_INT) $(IND_INT) $(BIB_INT)),$(INPUTFILES) $(OUTPUTFILES)) \
  ))

INTERFILES_PREV = $(addsuffix _prev,$(INTERFILES))

# TeXファイル - .tex
TEXFILES = $(filter %.tex,$(INPUTFILES))

# 対応する画像ファイルの拡張子
GRAPHICSEXT := .pdf .eps .jpg .jpeg .png .bmp

# $(BASE).texで読み込まれる画像ファイルを取得する
GRAPHICFILES = $(GRAPHICFILESre)

GRAPHICFILESre = $(eval GRAPHICFILES := \
  $(sort \
    $(shell \
      $(SED) -e '/^\s*%/d' -e 's/\([^\]\)\s*%.*/\1/g' $(BASE).tex $(TEXFILES) | \
      $(SED) -e '/\\begin{verbatim}/,/\\end{verbatim}/d' | \
      $(SED) -e 's/\\verb|[^|]*|//g' | \
      $(SED) -e 's/}/}%/g' | $(SED) -e 'y/}%/}\n/' | \
      $(SED) -n -e 's/.*\\includegraphics\(\[[^]]*\]\)\{0,1\}{\([^}]*\)}$$/\2/pg' \
    ) \
    $(filter $(addprefix %,$(GRAPHICSEXT)),$(INPUTFILES)) \
  ))

# そのほかの読み込みファイル
OTHERFILES = \
  $(sort $(filter-out %.aux $(INTERFILES) $(TEXFILES) $(GRAPHICFILES),$(INPUTFILES)))

# \bibliography命令で読み込まれる文献データベースファイルをTeXファイルから検索する
BIBDB = $(BIBDBre)

BIBDBre = $(eval BIBDB := \
  $(addsuffix .bib,$(basename $(sort $(shell \
      $(SED) -e '/^\s*%/d' -e 's/\([^\]\)\s*%.*/\1/g' $(BASE).tex $(TEXFILES) | \
      $(SED) -e '/\\begin{verbatim}/,/\\end{verbatim}/d' | \
      $(SED) -e 's/}/}%/g' | $(SED) -e 'y/}%/}\n/' | \
      $(SED) -n -e 's/.*\\bibliography\(\[[^]]*\]\)\{0,1\}{\([^}]*\)}$$/\2/pg' | \
      $(SED) -e 's/,/ /g' \
   )))))

# LaTeX処理（コンパイル）
LATEXCMD = $(LATEX) -interaction=batchmode $(LATEXFLAG) $(BASE).tex
COMPILE.tex = $(ECHO) $(LATEXCMD); $(LATEXCMD) >/dev/null 2>&1 || ($(SED) -n -e '/^!/,/^$$/p' $(BASE).log; exit 1)

# 相互参照未定義の警告
WARN_UNDEFREF := 'There were undefined references\.'

# LaTeX処理
# ログファイルに警告がある場合は警告がなくなるまで、最大CNTで指定された回数分、処理を実行する
CNT := 3
COMPILES.tex = \
  @(for i in `$(SEQ) 1 $(CNT)`; do \
      if test -s $@ -a -s $(BASE).log; then \
        $(GREP) -e $(WARN_UNDEFREF) $(BASE).log || exit 0; \
      else \
        $(ECHO) '$@ and/or $(BASE).log does not exist.'; \
      fi; \
      $(COMPILE.tex); \
    done)

# DVI -> PDF
# 出力結果は.logファイルへ出力
DVIPDFCMD = $(DVIPDFMX) $(DVIPDFMXFLAG) $(BASE).dvi
COMPILE.dvi = \
  $(ECHO) $(DVIPDFCMD); $(DVIPDFCMD) >>$(BASE).log 2>&1 || \
  ($(SED) -n -e '/^Output written on toc_hyperref.dvi/,$$p' $(BASE).log; exit 1)

# 索引中間ファイル（.ind）作成
MENDEXCMD = $(MENDEX) $(MENDEXFLAG) $(BASE).idx
COMPILE.idx = $(ECHO) $(MENDEXCMD); $(MENDEXCMD) >/dev/null 2>&1 || ($(CAT) $(BASE).ilg; exit 1)

# 文献リスト中間ファイル（.bbl）作成
BIBTEXCMD = $(BIBTEX) $(BIBTEXFLAG) $(BASE).aux
COMPILE.bib = $(ECHO) $(BIBTEXCMD); $(BIBTEXCMD) >/dev/null 2>&1 || ($(CAT) $(BASE).blg; exit 1)

# ターゲットファイルと必須ファイルを比較し、内容が異なる場合はターゲットファイルの内容を必須ファイルに置き換える
CMPPREV = $(CMP) $@ $< || $(CP) -p -v $< $@

# $(BASE).flsファイルの作成
FLSCMD = $(LATEX) -interaction=nonstopmode -recorder $(BASE).tex
CREATE.fls = \
  $(FLSCMD) 1>/dev/null 2>&1; \
  test -e $(BASE).fls && $(ECHO) '$(BASE).fls is created.'; \
  $(RM) $(addprefix $(BASE),.aux .dvi .log $(TEX_INT) $(IND_INT) $(BIB_INT))

# 依存関係を.dファイルに書き出す
%.d: %.fls
	@$(ECHO) '$@ is created by scanning $(BASE).tex and $(BASE).fls.'
    # .dファイルの依存関係
	@$(ECHO) '$(BASE).d: $(BASE).tex $(BASE).fls' >$@
    # \includeまたは\input命令で読み込まれるTeXファイルの依存関係
	$(if $(TEXFILES),@( \
      $(ECHO); \
      $(ECHO) '# Files called from \include or \input - .tex'; \
      $(ECHO) '$(BASE).aux: $(TEXFILES)'; \
    ) >>$@)
    # そのほかのファイル（TEXMFROOT以外にあるスタイルファイルなど）の依存関係
	$(if $(OTHERFILES),@( \
      $(ECHO); \
      $(ECHO) '# Other files'; \
      $(ECHO) '$(BASE).aux: $(OTHERFILES)'; \
    ) >>$@)
    # 画像ファイルの依存関係
	$(if $(GRAPHICFILES),@( \
      $(ECHO); \
      $(ECHO) '# IncludeGraphic Files - .pdf, .eps, .jpeg/.jpg, .png'; \
      $(ECHO) '#           .xbb Files - .pdf, .jpeg/.jpg, .png'; \
      $(ECHO) '$(BASE).aux: $(GRAPHICFILES)'; \
      $(if $(filter-out %.eps,$(GRAPHICFILES)), \
        $(ECHO); \
        $(ECHO) '$(BASE).aux: $(addsuffix .xbb,$(basename $(filter-out %.eps,$(GRAPHICFILES))))'; \
      ) \
    ) >>$@)
    # 文献処理用ファイルの依存関係
	$(if $(BIBDB),@( \
        $(ECHO); \
        $(ECHO) '# Bibliography files: .aux, BIBDB -> .bbl -> .div'; \
        $(ECHO) '$(BASE).bbl: $(BIBDB) $(BASE).tex'; \
      ) >>$@)
    # 中間ファイルの依存関係
	$(if $(sort $(INTERFILES) $(BIBDB)),@( \
      $(ECHO); \
      $(ECHO) '# LaTeX Intermediate Files'; \
      $(ECHO) '$(BASE).dvi:: $(sort $(INTERFILES_PREV) $(if $(BIBDB),$(BASE).bbl_prev))'; \
      $(ECHO) '	@$$(COMPILE.tex)'; \
      $(ECHO); \
      $(ECHO) '$(BASE).dvi:: $(BASE).aux'; \
      $(ECHO) '	@$$(COMPILES.tex)'; \
    ) >>$@)

# 変数TEXTARGETSで指定されたターゲットファイルに対応する
# .dファイルをインクルードし、依存関係を取得する
# ターゲット末尾に clean、.xbb、.tex、.d が含まれている場合は除く
ifeq (,$(filter %clean %.xbb %.tex %.d %.fls %.fls_prev,$(MAKECMDGOALS)))
  -include $(addsuffix .d,$(basename $(TEXTARGETS)))
endif

# auxファイル作成
%.aux: %.tex
	@$(COMPILE.tex)

%.dvi: %.aux
	@$(COMPILES.tex)

%.dvi: %.tex
	@$(COMPILE.tex)
	@$(COMPILES.tex)

# PDFファイル作成
%.pdf: %.dvi
	@$(COMPILE.dvi)

# バウンディング情報ファイル作成
# pdf、jpeg/jpg、pngファイルに対応
extractbb:
	$(MAKE) -s $(addsuffix .xbb,$(basename $(wildcard $(addprefix *,.pdf .jpg .jpeg .png))))

%.xbb: %.pdf
	$(EXTRACTBB) $(EXTRACTBBFLAGS) $<

%.xbb: %.jpeg
	$(EXTRACTBB) $(EXTRACTBBFLAGS) $<

%.xbb: %.jpg
	$(EXTRACTBB) $(EXTRACTBBFLAGS) $<

%.xbb: %.png
	$(EXTRACTBB) $(EXTRACTBBFLAGS) $<

# ファイル一覧作成
%.fls: %.tex
	@-$(CREATE.fls)

%.fls_prev: %.fls
	@$(CMPPREV)

# 目次中間ファイル作成
%.toc: %.tex
	@$(MAKE) -s $(BASE).aux

%.toc_prev: %.toc
	@$(CMPPREV)

# 図リスト中間ファイル作成
%.lof: %.tex
	@$(MAKE) -s $(BASE).aux

%.lof_prev: %.lof
	@$(CMPPREV)

# 表リスト中間ファイル作成
%.lot: %.tex
	@$(MAKE) -s $(BASE).aux

%.lot_prev: %.lot
	@$(CMPPREV)

# 索引中間ファイル作成
%.idx: %.tex
	@$(MAKE) -s $(BASE).aux

%.idx_prev: %.idx
	@$(CMPPREV)

%.ind: %.idx_prev
	@$(COMPILE.idx)

%.ind_prev: %.ind
	@$(CMPPREV)

# BiBTeX中間ファイル作成
%.bbl: %.tex
	@$(MAKE) -s $(BASE).aux
	@$(COMPILE.bib)

%.bbl_prev: %.bbl
	@$(CMPPREV)

# hyperref中間ファイル作成
%.out: %.tex
	@$(MAKE) -s $(BASE).aux

%.out_prev: %.out
	@$(CMPPREV)

# tex-cleanターゲット
tex-clean:
	$(RM) $(ALL_INTERFILES)
ifeq (,$(filter %.dvi,$(TEXTARGETS)))
	$(RM) *.dvi
endif

# xbb-cleanターゲット
xbb-clean:
	$(RM) *.xbb

# tex-distcleanターゲット
tex-distclean: tex-clean xbb-clean
ifneq (,$(filter %.dvi,$(TEXTARGETS)))
	$(RM) *.dvi
endif
	$(RM) $(TEXTARGETS)
