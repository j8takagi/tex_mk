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
.PHONY: warning tex-clean tex-distclean

# シェルコマンド
CAT := cat
CMP := cmp -s
CP := cp
ECHO := echo
GREP := grep
SED := sed

warning:
	@$(ECHO) "check current directory, or set TARGET in Makefile."

# LaTeXコマンド
LATEX := platex
DVIPDFMX := dvipdfmx
EXTRACTBB := extractbb
BIBTEX := pbibtex
MENDEX := mendex

# TeX中間ファイルの拡張子
#   .aux: 相互参照
#   .fls: tex -recorderで生成されるファイルリスト
#   .lof: 図リスト（\tableoffigures）
#   .lot: 表リスト（\tableoftables）
#   .out: hyperrefパッケージ
#   .toc: 目次（\tableofcontents）
#   .log: ログ
TEX_INT := .aux .fls .lof .lot .out .toc .log
# 索引中間ファイルの拡張子
#   .idx: auxから作成
#   .ind: idxから作成
#   .ilg: 索引ログ
IND_INT := .idx .ind .ilg
# BiBTeX中間ファイルの拡張子
#   .bbl: auxから作成
#   .blg: BiBTeXログ
BIB_INT := .bbl .blg

.SECONDARY: $(wildcard $(addsuffix $(TEX_INT) $(IND_INT) $(BIB_INT) .d,*))

# \tableofcontents命令をTeXファイルから検索する
toc = $(shell $(SED) -n -e '/^.*[^\]\{0,1\}%.*\\tableofcontents/!s/.*\(\\tableofcontents\).*/\1/p' $<)

# \listoffigures命令をTeXファイルから検索する
lof = $(shell $(SED) -n -e '/^.*[^\]\{0,1\}%.*\\listoffigures/!s/.*\(\\listoffigures\).*/\1/p' $<)

# \listoftables命令をTeXファイルから検索する
lot = $(shell $(SED) -n -e '/^.*[^\]\{0,1\}%.*\\listoftables/!s/.*\(\\listoftables\).*/\1/p' $<)

# \makeindex命令をTeXファイルから検索する
makeindex = $(shell $(SED) -n -e '/^.*[^\]\{0,1\}%.*\\makeindex/!s/.*\(\\makeindex\).*/\1/p' $<)

# \bibliography命令で読み込まれる文献データベースファイルをTeXファイルから検索する
bibdb = $(addsuffix .bib,$(basename $(strip $(shell \
  $(SED) -n -e '/^.*[^\]\{0,1\}%.*\\bibliography/!s/\\bibliography\(\[[^]]*\]\)\{0,1\}{\([^}]*\)}/&\n/p' $< $(intex) | \
  $(SED) -e 's/.*{\([^}]*\)}.*/\1/' | \
  $(SED) -e 's/,/ /g'))))

# hyperrefパッケージ読み込みをTeXファイルから検索する
hyperref = $(shell $(SED) -n -e '/^.*[^\]\{0,1\}%.*\\usepackage\(\[[^]]*\]\)\{0,1\}{hyperref}/!s/.*\(\\usepackage\)\(\[[^]]*\]\)\{0,1\}\({hyperref}\).*/\1\3/p' $<)

# ファイル名から拡張子を除いた部分
BASE = $(basename $<)

# .texファイル
TEXFILE = $(addsuffix .tex,$(BASE))

# .auxファイル
AUXFILE = $(addsuffix .aux,$(BASE))
# .aux_prevファイル
AUXFILE_PREV = $(addsuffix .aux_prev,$(BASE))

# .dviファイル
DVIFILE = $(addsuffix .dvi,$(BASE))

# .dファイル
DFILE = $(addsuffix .d,$(BASE))

# .logファイル
LOGFILE = $(addsuffix .log,$(BASE))

# .tocファイル
TOCFILE = $(addsuffix .toc,$(BASE))
# .toc_prevファイル。.tocファイルのコピー
TOCFILE_PREV = $(addsuffix .toc_prev,$(BASE))

# .lofファイル
LOFFILE = $(addsuffix .lof,$(BASE))
# .lof_prevファイル。.lofファイルのコピー
LOFFILE_PREV = $(addsuffix .lof_prev,$(BASE))

# .lotファイル
LOTFILE = $(addsuffix .lot,$(BASE))
# .lot_prevファイル。.lotファイルのコピー
LOTFILE_PREV = $(addsuffix .lot_prev,$(BASE))

# .idxファイル
IDXFILE = $(addsuffix .idx,$(BASE))
# .idx_prevファイル。.idxファイルのコピー
IDXFILE_PREV = $(addsuffix .idx_prev,$(BASE))

# .indファイル
INDFILE = $(addsuffix .ind,$(BASE))
# .ind_prevファイル。.indファイルのコピー
INDFILE_PREV = $(addsuffix .ind_prev,$(BASE))

# .ilgファイル
ILGFILE = $(addsuffix .ilg,$(BASE))

# .bblファイル
BBLFILE = $(addsuffix .bbl,$(BASE))
# .bbl_prevファイル。.bblファイルのコピー
BBLFILE_PREV = $(addsuffix .bbl_prev,$(BASE))

# .blgファイル
BLGFILE = $(addsuffix .blg,$(BASE))

# .outファイル
OUTFILE = $(addsuffix .out,$(BASE))
# .out_prevファイル。.outファイルのコピー
OUTFILE_PREV = $(addsuffix .out_prev,$(BASE))

INTERFILES = $(strip \
                $(if $(toc),$(TOCFILE)) \
                $(if $(lof),$(LOFFILE)) \
                $(if $(lot),$(LOTFILE)) \
                $(if $(makeindex),$(INDFILE)) \
                $(if $(bibdb),$(BBLFILE)) \
                $(if $(hyperref),$(OUTFILE)) \
              )

INTERFILES_PREV = $(addsuffix _prev,$(INTERFILES))

#LaTeXオプション
LATEXFLAG ?=
DVIPDFMXFLAG ?=
EXTRACTBBFLAGS ?=
BIBTEXFLAG ?=
MENDEXFLAG ?=

# LaTeX処理（コンパイル）
LATEXCMD = $(LATEX) -interaction=batchmode $(LATEXFLAG) $(TEXFILE)
COMPILE.tex = $(ECHO) $(LATEXCMD); $(LATEXCMD) >/dev/null 2>&1 || ($(CAT) $(LOGFILE); exit 1)

# DVI -> PDF
DVIPDFCMD = $(DVIPDFMX) $(DVIPDFMXFLAG) $(DVIFILE)
COMPILE.dvi = $(ECHO) $(DVIPDFCMD); $(DVIPDFCMD) 2>&1 | $(CAT) >>$(LOGFILE) || $(CAT)

# 索引中間ファイル（.ind）作成
MENDEXCMD = $(MENDEX) $(MENDEXFLAG) $(IDXFILE)
COMPILE.idx = $(ECHO) $(MENDEXCMD); $(MENDEXCMD) >/dev/null 2>&1 || ($(CAT) $(ILGFILE); exit 1)

# 文献リスト中間ファイル（.bbl）作成
BIBTEXCMD = $(BIBTEX) $(BIBTEXFLAG) $(AUXFILE)
COMPILE.bib = $(ECHO) $(BIBTEXCMD); $(BIBTEXCMD) >/dev/null 2>&1 || ($(CAT) $(BLGFILE); exit 1)

# 相互参照未定義の警告
WARN_UNDEFREF := 'There were undefined references\.'
# 読み込むべき中間ファイルがないことの警告
WARN_NOFILE = 'No file $(BASE)\.[a-zA-Z0-9]*\.'

# LaTeX処理
# ログファイルに警告がある場合、警告がなくなるまで最大4回処理する
COMPILES.tex = \
  @(for f in 1st 2nd 3rd final; do \
      if test -s $@ -a -s $(LOGFILE); then \
        $(GREP) -e $(WARN_UNDEFREF) $(LOGFILE) || exit 0; \
      fi; \
      $(COMPILE.tex); \
    done)

# ターゲットファイルと必須ファイルを比較し、内容が異なる場合はターゲットファイルの内容を必須ファイルに置き換える
CMPPREV = $(CMP) $@ $< || $(CP) -v -p $< $@

# \include、\input命令で読み込まれるtexファイル
intex = $(addsuffix .tex,$(basename $(strip $(shell \
  $(SED) -n -e '/^.*[^\]\{0,1\}%.*\\\(include\|input\)/!s/\\\(include\|input\)\(\[[^]]*\]\)\{0,1\}{[^}]*}/&\n/p' $< | \
  $(SED) -e 's/.*{\([^}]*\)}.*/\1/'))))

# \includegraphics命令で読み込まれるグラフィックファイル
ingraphics = $(strip $(shell \
  $(SED) -n -e '/^.*[^\]\{0,1\}%.*\\includegraphics/!s/\\includegraphics\(\[[^]]*\]\)\{0,1\}\({[^}]*}\)/&\n/p' $< $(intex) | \
  $(SED) -e 's/.*{\([^}]*\)}.*/\1/'))

# 依存関係を.dファイルに書き出す
%.d: %.tex
	@$(ECHO) '$@ is created by scanning $^.'
# TeX、.aux、.dvi、.dファイルの依存関係
	@$(ECHO) '$(DFILE): $(TEXFILE)' >$@
	$(if $(INTERFILES),@( \
        $(ECHO); \
        $(ECHO) '$(DVIFILE):: $(INTERFILES_PREV)'; \
        $(ECHO) '	@$$(COMPILE.tex)'; \
        $(ECHO); \
        $(ECHO) '$(DVIFILE):: $(AUXFILE)'; \
        $(ECHO) '	@$$(COMPILES.tex)'; \
    )  >>$@)
# 画像ファイルの依存関係
	$(if $(ingraphics),@( \
        $(ECHO); \
        $(ECHO) '# IncludeGraphic Files - .pdf, .jpeg/.jpg, .png with .xbb'; \
        $(ECHO) '$(AUXFILE) $(INTERFILES): $(ingraphics)'; \
        $(ECHO); \
        $(ECHO) '$(strip $(AUXFILE) $(INTERFILES)): $(addsuffix .xbb,$(basename $(filter-out %.eps,$(ingraphics))))'; \
    ) >>$@)
# \includeまたは\input命令で読み込まれるTeXファイルの依存関係
	$(if $(intex),@( \
        $(ECHO); \
        $(ECHO) '# Files called from \include or \input - .tex'; \
        $(ECHO) '$(strip $(AUXFILE) $(INTERFILES)): $(intex)'; \
    ) >>$@)
# 文献処理用ファイルの依存関係
	$(if $(bibdb),@( \
        $(ECHO); \
        $(ECHO) '# Bibliography files: .aux, BIBDB -> .bbl -> .div'; \
        $(ECHO) '$(BBLFILE): $(bibdb) $(TEXFILE)'; \
        $(ECHO); \
        $(ECHO) '$(BBLFILE_PREV): $(BBLFILE)'; \
    ) >>$@)

# 変数TEXTARGETSで指定されたターゲットファイルに対応する
# .dファイルをインクルードし、依存関係を取得する
# ターゲットに %clean、%.xbb、%.d が含まれている場合は除く
ifeq (,$(filter %clean %.xbb %.tex %.d,$(MAKECMDGOALS)))
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

# aux_prevファイル作成
%.aux_prev: %.aux
	@$(CMPPREV)

# PDFファイル作成
%.pdf: %.dvi
	@$(COMPILE.dvi)

# バウンディング情報ファイル作成
# pdf、jpeg/jpg、pngファイルに対応
%.xbb: %.pdf
	$(EXTRACTBB) $(EXTRACTBBFLAGS) $<

%.xbb: %.jpeg
	$(EXTRACTBB) $(EXTRACTBBFLAGS) $<

%.xbb: %.jpg
	$(EXTRACTBB) $(EXTRACTBBFLAGS) $<

%.xbb: %.png
	$(EXTRACTBB) $(EXTRACTBBFLAGS) $<

# 目次中間ファイル作成
%.toc: %.tex
	@$(MAKE) -s $(AUXFILE)

%.toc_prev: %.toc
	@$(CMPPREV)

# 図リスト中間ファイル作成
%.lof: %.tex
	@$(MAKE) -s $(AUXFILE)

%.lof_prev: %.lof
	@$(CMPPREV)

# 表リスト中間ファイル作成
%.lot: %.tex
	@$(MAKE) -s $(AUXFILE)

%.lot_prev: %.lot
	@$(CMPPREV)

# 索引中間ファイル作成
%.idx: %.tex
	@$(MAKE) -s $(AUXFILE)

%.idx_prev: %.idx
	@$(CMPPREV)

%.ind: %.idx_prev
	@$(COMPILE.idx)

%.ind_prev: %.ind
	@$(CMPPREV)

# BiBTeX中間ファイル作成
%.bbl: %.tex
	@$(MAKE) -s $(AUXFILE)
	@$(COMPILE.bib)

%.bbl_prev: %.bbl
	@$(CMPPREV)

# hyperref中間ファイル作成
%.out: %.tex
	@$(MAKE) -s $(AUXFILE)

%.out_prev: %.out
	@$(CMPPREV)

# tex-cleanターゲット
tex-clean:
	$(RM) $(addprefix *, \
      $(TEX_INT) $(IND_INT) $(BIB_INT) .d \
      .aux_prev .toc_prev .lof_prev .lot_prev \
      .idx_prev .ind_prev .bbl_prev .out_prev \
    )
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
