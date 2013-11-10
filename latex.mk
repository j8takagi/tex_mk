# latex.mk
# LaTeX処理（コンパイル）を行う
#
# == 使い方 ==
# 1. texソースファイルと同じディレクトリーに本ファイル（latex.mk）をコピーする
# 2. Makefileに変数TARGETS と「include latex.mk」を記述する
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
# TARGETS := report.tex
#
# all: $(TARGETS)
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
#   .aux: 相互参照用
#   .fls: tex -recorderで生成されるファイルリスト
#   .lof: 図リスト（\tableoffigures）用
#   .lot: 表リスト（\tableoftables）用
#   .out: hyperrefパッケージ用
#   .toc: 目次（\tableofcontents）用
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

# \makeindex命令
makeindex = $(shell $(SED) -n -e '/^.*[^\]\{0,1\}%.*\\makeindex/!s/\\makeindex/&/p' $<)

# \bibliography命令で読み込まれる文献データベースファイル
bibdb = $(addsuffix .bib,$(basename $(strip $(shell \
  $(SED) -n -e '/^.*[^\]\{0,1\}%.*\\bibliography/!s/\\bibliography\(\[[^]]*\]\)\{0,1\}{\([^}]*\)}/&\n/gp' $< $(intex) | \
  $(SED) -e 's/.*{\([^}]*\)}.*/\1/' | \
  $(SED) -e 's/,/ /g'))))

# ファイル名から拡張子を除いた部分
BASE = $(basename $<)
# .texファイル
TEXFILE = $(addsuffix .tex,$(BASE))
# .auxファイル
AUXFILE = $(addsuffix .aux,$(BASE))
# .prev_auxファイル
PREV_AUXFILE = $(addsuffix .prev_aux,$(BASE))
# .dviファイル
DVIFILE = $(addsuffix .dvi,$(BASE))
# .dファイル
DFILE = $(addsuffix .d,$(BASE))
# .logファイル
LOGFILE = $(addsuffix .log,$(BASE))
# .idxファイル
IDXFILE = $(addsuffix .idx,$(BASE))
# .prev_idxファイル。.idxファイルのコピー
PREV_IDXFILE = $(addsuffix .prev_idx,$(BASE))
# .indファイル
INDFILE = $(addsuffix .ind,$(BASE))
# .prev_indファイル。.indファイルのコピー
PREV_INDFILE = $(addsuffix .prev_ind,$(BASE))
# .ilgファイル
ILGFILE = $(addsuffix .ilg,$(BASE))
# .bblファイル
BBLFILE = $(addsuffix .bbl,$(BASE))
# .prev_bblファイル。.bblファイルのコピー
PREV_BBLFILE = $(addsuffix .prev_bbl,$(BASE))
# .bblファイル
BLGFILE = $(addsuffix .blg,$(BASE))

#LaTeXオプション
LATEXFLAG ?=
DVIPDFMXFLAG ?=
EXTRACTBBFLAGS ?=
BIBTEXFLAG ?=
MENDEXFLAG ?=

# LaTeX処理（コンパイル）
LATEXCMD = $(LATEX) -interaction=batchmode $(LATEXFLAG) $(TEXFILE)
COMPILE.tex = $(ECHO) $(LATEXCMD); $(LATEXCMD) >/dev/null 2>&1 || ($(CAT) $(LOGFILE); exit 1)

# 索引（.indファイル）作成
MENDEXCMD = $(MENDEX) $(MENDEXFLAG) $(IDXFILE)
COMPILE.idx = $(ECHO) $(MENDEXCMD); $(MENDEXCMD) >/dev/null 2>&1 || ($(CAT) $(ILGFILE); exit 1)

# 文献リスト（.bblファイル）作成
BIBTEXCMD = $(BIBTEX) $(BIBTEXFLAG) $(AUXFILE)
COMPILE.bbl = $(ECHO) $(BIBTEXCMD); $(BIBTEXCMD) >/dev/null 2>&1 || ($(CAT) $(BLGFILE); exit 1)

# 相互参照未定義の警告
WARN_UNDEFREF := 'There were undefined references\.'
# 読み込むべき中間ファイルがないことの警告
WARN_NOFILE = 'No file $(BASE)\.[a-zA-Z0-9]*\.'

# LaTeX処理
# 索引ファイルがある場合、1回処理する
# ログファイルに警告がある場合、警告がなくなるまで最大4回処理する
COMPILES.tex = \
  @(for f in 1st 2nd 3rd final; do \
      if test -s $@ -a -s $(LOGFILE); then \
        $(GREP) -e $(WARN_UNDEFREF) -e $(WARN_NOFILE) $(LOGFILE) || exit 0; \
      fi; \
      $(COMPILE.tex); \
    done)

# *.*ファイルと *.prev_*ファイルを比較し、*.*ファイルが更新されている場合はその内容を*.prev_* にコピーする
CMPPREV = $(CMP) $@ $< && $(ECHO) '$< is up to date.'|| $(CP) -v $< $@

# \include、\input命令で読み込まれるtexファイル
intex = $(addsuffix .tex,$(basename $(strip $(shell \
  $(SED) -n -e '/^.*[^\]\{0,1\}%.*\\\(include\|input\)/!s/\\\(include\|input\)\(\[[^]]*\]\)\{0,1\}{[^}]*}/&\n/gp' $< | \
  $(SED) -e 's/.*{\([^}]*\)}.*/\1/'))))

# \includegraphics命令で読み込まれるグラフィックファイル
ingraphics = $(strip $(shell \
  $(SED) -n -e '/^.*[^\]\{0,1\}%.*\\includegraphics/!s/\\includegraphics\(\[[^]]*\]\)\{0,1\}\({[^}]*}\)/&\n/gp' $< $(intex) | \
  $(SED) -e 's/.*{\([^}]*\)}.*/\1/'))

# 依存関係を.dファイルに書き出す
%.d: %.tex
	@$(ECHO) '$@ is created by scanning $^.'
# TeX、.aux、.dvi、.dファイルの依存関係
	@($(ECHO) '$(AUXFILE) $(DFILE): $(TEXFILE)'; \
      $(ECHO); \
      $(ECHO) '$(PREV_AUXFILE): $(AUXFILE)'; \
      $(ECHO); \
      $(ECHO) '$(DVIFILE): $(PREV_AUXFILE)' $(if $(makeindex),'$(PREV_INDFILE)') $(if $(bibdb),'$(PREV_BBLFILE)'); \
    ) >$@
	$(if $(strip $(makeindex) $(bibdb)),@( \
      $(ECHO) '	@$$(COMPILE.tex)'; \
      $(ECHO) '	@$$(COMPILES.tex)'; \
    ) >>$@)
# 画像ファイルの依存関係
	$(if $(ingraphics),@( \
        $(ECHO); \
        $(ECHO) '# IncludeGraphic Files - .pdf, .jpeg/.jpg, .png with .xbb'; \
        $(ECHO) '$(AUXFILE): $(ingraphics)'; \
        $(ECHO); \
        $(ECHO) '$(AUXFILE): $(addsuffix .xbb,$(basename $(filter-out %.eps,$(ingraphics))))'; \
    ) >>$@)
# \includeまたは\input命令で読み込まれるTeXファイルの依存関係
	$(if $(intex),@( \
        $(ECHO); \
        $(ECHO) '# Files called from \include or \input - .tex'; \
        $(ECHO) '$(AUXFILE): $(intex)'; \
    ) >>$@)
# 索引作成用ファイルの依存関係: .aux -> idx -> .ind -> .dvi
	$(if $(makeindex),@( \
        $(ECHO); \
        $(ECHO) '# Index files: .tex -> .idx -> .ind -> .dvi'; \
        $(ECHO) '$(IDXFILE): $(TEXFILE)'; \
        $(ECHO); \
        $(ECHO) '$(PREV_IDXFILE): $(IDXFILE)'; \
        $(ECHO); \
        $(ECHO) '$(INDFILE): $(PREV_IDXFILE)'; \
        $(ECHO); \
        $(ECHO) '$(PREV_INDFILE): $(INDFILE)'; \
    ) >>$@)
  # 文献処理用ファイルの依存関係
	$(if $(bibdb),@( \
        $(ECHO); \
        $(ECHO) '# Bibliography files: .aux, BIBDB -> .bbl -> .div'; \
        $(ECHO) '$(BBLFILE): $(bibdb) $(AUXFILE)'; \
        $(ECHO); \
        $(ECHO) '$(PREV_BBLFILE): $(BBLFILE)'; \
    ) >>$@)

# 変数TARGETSで指定されたターゲットファイルに対応する
# .dファイルをインクルードし、依存関係を取得する
# ターゲットに %clean、%.xbb、%.d が含まれている場合は除く
ifeq (,$(filter %clean %.xbb %.d,$(MAKECMDGOALS)))
  -include $(addsuffix .d,$(basename $(TARGETS)))
endif

# auxファイル作成
%.aux: %.tex
	@$(COMPILE.tex)

# prev_auxファイル作成
%.prev_aux: %.aux
	@$(CMPPREV)

# dviファイル作成
%.dvi: %.prev_aux
	$(COMPILES.tex)

# PDFファイル作成
%.pdf: %.dvi
	$(DVIPDFMX) $(DVIPDFMXFLAG) $<

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

# 索引ファイル作成
%.idx: %.tex
	@$(COMPILE.tex)

%.prev_idx: %.idx
	@$(CMPPREV)

%.ind: %.prev_idx
	@$(COMPILE.idx)

%.prev_ind: %.ind
	@$(CMPPREV)

# 文献処理用ファイル作成
%.bbl: %.prev_aux
	@$(COMPILE.bbl)

%.prev_bbl: %.bbl
	@$(CMPPREV)

# tex-cleanターゲット
tex-clean:
	$(RM) $(addprefix *,$(TEX_INT) $(IND_INT) $(BIB_INT) .d .prev_aux .prev_idx .prev_ind .prev_bbl)
ifeq (,$(filter %.dvi,$(TARGETS)))
	$(RM) *.dvi
endif

# xbb-cleanターゲット
xbb-clean:
	$(RM) *.xbb

# tex-distcleanターゲット
tex-distclean: tex-clean xbb-clean
ifneq (,$(filter %.dvi,$(TARGETS)))
	$(RM) *.dvi
endif
	$(RM) $(TARGETS)
