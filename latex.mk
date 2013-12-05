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
# - tex-xbb-clean: バウンディング情報ファイル（.xbb）を削除
# - tex-distclean: TeX中間ファイル、バウンディング情報ファイル、ターゲットファイル（PDF、.dvi）を削除
#
# === Makefile -- sample ===
# TEXTARGETS := report.tex
#
# all: $(TEXTARGETS)
#
# include latex.mk

# シェルスクリプトをデバッグするときは、DEBUGSH変数を設定してmakeを実行する
# 例: DEBUGSH=1 make
ifdef DEBUGSH
  SHELL := /bin/sh -x
endif

.PHONY: tex-warn tex-xbb tex-clean tex-distclean

# シェルコマンド
CAT := cat
CMP := cmp -s
CP := cp
ECHO := /bin/echo
GREP := grep
MKDIR := mkdir
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

# .aux、.fls以外のTeX中間ファイルの拡張子
#   .bbl: 文献リスト。作成方法はパターンルールで定義
#   .glo: 用語集。\glossaryがあればTeX処理で生成
#   .idx: 索引。\makeindexがあればTeX処理で生成
#   .ind: 索引。作成方法はパターンルールで定義
#   .lof: 図リスト。\listoffiguresがあればTeX処理で生成
#   .lot: 表リスト。\listoftablesがあればTeX処理で生成
#   .out: PDFブックマーク。hyperrefパッケージをbookmarksオプションtrue（初期値）で呼び出していれば、TeX処理で生成
#   .toc: 目次。\tableofcontentsがあればTeX処理で生成
LATEXINTEXT := .bbl .glo .idx .ind .lof .lot .out .toc

# ログファイル
#   .log: TeXログ
#   .ilg: 索引ログ
#   .blg: BiBTeXログ
LOGEXT := .log .ilg .blg

ALLINTEXT := .aux .dvi $(LATEXINTEXT) $(LOGEXT) .fls .d .*_prev

# make完了後、中間ファイルを残す
.SECONDARY: $(foreach t,$(TEXTARGETS),$(addprefix $(basename $t),$(ALLINTEXT)))

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
LATEXINTFILES = \
  $(sort $(subst .idx,.ind, \
    $(filter $(addprefix $(BASE),$(LATEXINTEXT)),$(INPUTFILES) $(OUTPUTFILES)) \
  ))

LATEXINTFILES_PREV = $(addsuffix _prev,$(LATEXINTFILES))

# 分割され、\includeや\inputで読み込まれるTeXファイル - .tex
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
OTHERFILES = $(sort $(filter-out %.aux $(LATEXINTFILES) $(TEXFILES) $(GRAPHICFILES),$(INPUTFILES)))

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

# ターゲットファイルと必須ファイルを比較し、内容が異なる場合はターゲットファイルの内容を必須ファイルに置き換える
CMPPREV = $(CMP) $@ $< && $(ECHO) '$@ is up to date.' || $(CP) -p -v $< $@

######################################################################
# .dファイルの生成と読み込み
# .dファイルには、LaTeX処理での依存関係が記述される
######################################################################

# .flsファイル作成用の一時ディレクトリー
FLSDIR := .fls.temp

# $(BASE).flsファイルの作成
FLSCMD = $(LATEX) -interaction=nonstopmode -recorder -output-directory=$(FLSDIR) $(BASE).tex

GENERETE.fls = \
  test ! -e $(FLSDIR) && $(MKDIR) $(FLSDIR); \
  $(FLSCMD) 1>/dev/null 2>&1; \
  $(SED) -e 's|$(FLSDIR)/||g' $(FLSDIR)/$(BASE).fls >$(BASE).fls; \
  test -e $(BASE).fls && \
    ($(ECHO) '$(BASE).fls is generated.'; $(RM) -r $(FLSDIR)) || \
    ($(ECHO) '$(BASE).fls is not generated.' 1>&2; exit 1)

# 依存関係を.dファイルに書き出す
%.d: %.fls
    # 変数の展開
	@$(ECHO) "extract LATEXINTFILES:$(LATEXINTFILES) TEXFILES:$(TEXFILES) GRAPHICFILES:$(GRAPHICFILES) BIBDB:$(BIBDB)"
    # .dファイルの依存関係
	@$(ECHO) '$(BASE).d: $(BASE).tex $(BASE).fls' >$@
    # 中間ファイルの依存関係
	$(if $(sort $(LATEXINTFILES) $(BIBDB)),@( \
      $(ECHO); \
      $(ECHO) '# LaTeX Intermediate Files'; \
      $(ECHO) '$(BASE).dvi:: $(sort $(LATEXINTFILES_PREV) $(if $(BIBDB),$(BASE).bbl_prev))'; \
      $(ECHO) '	@$$(COMPILE.tex)'; \
      $(ECHO); \
      $(ECHO) '$(BASE).dvi:: $(BASE).aux'; \
      $(ECHO) '	@$$(COMPILES.tex)'; \
    ) >>$@)
    # \includeまたは\input命令で読み込まれるTeXファイルの依存関係
	$(if $(TEXFILES),@( \
      $(ECHO); \
      $(ECHO) '# Files called from \include or \input - .tex'; \
      $(ECHO) '$(BASE).aux: $(TEXFILES)'; \
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
    # そのほかのファイル（TEXMFROOT以外にあるスタイルファイルなど）の依存関係
	$(if $(OTHERFILES),@( \
      $(ECHO); \
      $(ECHO) '# Other files'; \
      $(ECHO) '$(BASE).aux: $(OTHERFILES)'; \
    ) >>$@)
	@$(ECHO) '$@ is generated by scanning $(BASE).tex and $(BASE).fls.'

# 変数TEXTARGETSで指定されたターゲットファイルに対応する
# .dファイルをインクルードし、依存関係を取得する
# ターゲット末尾に clean、.xbb、.tex、.d が含まれている場合は除く
ifeq (,$(filter %clean %.xbb %.tex %.d %.fls %.fls_prev,$(MAKECMDGOALS)))
  -include $(addsuffix .d,$(basename $(TEXTARGETS)))
endif

######################################################################
# dviおよびPDFファイルを生成するパターンルール
# TeX -> dvi -> PDF
######################################################################

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

%.fls: %.tex
	@-$(GENERETE.fls)

######################################################################
# LaTeX中間ファイルを生成するパターンルール
######################################################################

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

COMPILE.idx = $(ECHO) $(MENDEXCMD); $(MENDEXCMD) >/dev/null 2>&1 || ($(CAT) $(BASE).ilg; exit 1)

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

COMPILE.bib = $(ECHO) $(BIBTEXCMD); $(BIBTEXCMD) >/dev/null 2>&1 || ($(CAT) $(BASE).blg; exit 1)

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
	@$(ECHO) "check current directory, or set TEXTARGET in Makefile."

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
