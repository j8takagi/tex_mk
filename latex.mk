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

.PHONY: tex-clean tex-distclean

# シェルコマンド
CAT := cat
CMP := cmp -s
CP := cp
ECHO := echo
GREP := grep
SED := sed

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

# ファイル名から拡張子を除いた部分
FILEBASE = $(basename $<)
# .texファイル
TEXFILE = $(addsuffix .tex,$(FILEBASE))
# .auxファイル
AUXFILE = $(addsuffix .aux,$(FILEBASE))
# .prev_auxファイル。.auxファイルのコピー
PREV_AUXFILE = $(addsuffix .prev_aux,$(FILEBASE))
# .dviファイル
DVIFILE = $(addsuffix .dvi,$(FILEBASE))
# .dファイル
DFILE = $(addsuffix .d,$(FILEBASE))
# .logファイル
LOGFILE = $(addsuffix .log,$(FILEBASE))
# .idxファイル
IDXFILE = $(addsuffix .idx,$(FILEBASE))
# .prev_idxファイル。.idxファイルのコピー
PREV_IDXFILE = $(addsuffix .prev_idx,$(FILEBASE))
# .indファイル
INDFILE = $(addsuffix .ind,$(FILEBASE))
# .bblファイル
BBLFILE = $(addsuffix .bbl,$(FILEBASE))

#LaTeXオプション
LATEXFLAG ?=
DVIPDFMXFLAG ?=
EXTRACTBBFLAGS ?=
BIBTEXFLAG ?=
MENDEXFLAG ?=

# LaTeX処理（コンパイル）
COMPILE.tex = $(LATEX) -interaction=batchmode $(LATEXFLAG) $(TEXFILE) || $(CAT) $(LOGFILE)

# 相互参照未定義の警告
WARN_UNDEFREF := 'There were undefined references\.'

# 読み込むべき中間ファイルがないことの警告
WARN_NOFILE = 'No file $(FILEBASE)\.[a-zA-Z0-9]*\.'

# ログファイルに警告がある場合、LaTeX処理を最大4回繰り返す
COMPILES.tex = \
  if test -s $(INDFILE); then \
    $(ECHO) "---------- for index ----------"; \
    $(COMPILE.tex); \
  fi; \
  for f in 1st 2nd 3rd final; do \
    if test -s $@ -a -s $(LOGFILE); then \
      $(GREP) -e $(WARN_UNDEFREF) -e $(WARN_NOFILE) $(LOGFILE) || exit 0; \
    fi; \
    $(ECHO) "---------- $$f try ----------"; \
    $(COMPILE.tex); \
  done

# \includegraphics命令で読み込まれるグラフィックファイル
ingraphics = $(strip $(shell \
  $(SED) -n -e '/^%/!s/\\includegraphics\(\[[^]]*\]\)\{0,1\}\({[^}]*}\)/&\n/gp' $< $(intex) | \
  $(SED) -e 's/.*{\([^}]*\)}.*/\1/'))

# \include、\input命令で読み込まれるtexファイル
intex = $(addsuffix .tex,$(basename $(strip $(shell \
  $(SED) -n -e '/^%/!s/\\\(include\|input\)\(\[[^]]*\]\)\{0,1\}{[^}]*}/&\n/gp' $< | \
  $(SED) -e 's/.*{\([^}]*\)}.*/\1/'))))

# \makeindex命令
makeindex = $(SED) -n -e '/^%/!s/\\makeindex/&/p' $<

# \bibliography命令で読み込まれる文献データベースファイル
bibdb = $(addsuffix .bib,$(basename $(strip $(shell \
  $(SED) -n -e '/^%/!s/\\bibliography\(\[[^]]*\]\)\{0,1\}{\([^}]*\)}/&\n/gp' $< $(intex) | \
  $(SED) -e 's/.*{\([^}]*\)}.*/\1/' | \
  $(SED) -e 's/,/ /g'))))

# 依存関係を.dファイルに書き出す
%.d: %.tex
	@$(ECHO) '$@ is created by scanning $^.'
  # texファイルの依存関係
	@($(ECHO) '$(AUXFILE) $(DFILE): $<'; \
      $(ECHO); \
      $(ECHO) '$(DVIFILE): $(AUXFILE)') >$@
  # 画像ファイルの依存関係
	$(if $(ingraphics),@( \
      $(ECHO); \
      $(ECHO) '# IncludeGraphic Files - .pdf, .jpeg/.jpg, .png with .xbb'; \
      $(ECHO) '$(DVIFILE) $(AUXFILE): $(ingraphics)'; \
      $(ECHO); \
      $(ECHO) '$(DVIFILE) $(AUXFILE): $(addsuffix .xbb,$(basename $(ingraphics)))') >>$@)
  # Include/Inputファイルの依存関係
	$(if $(intex),@( \
      $(ECHO); \
      $(ECHO) '# Include / Input Files - .tex'; \
      $(ECHO) '$(DVIFILE) $(AUXFILE): $(intex)') >>$@)
  # 索引作成用ファイルの依存関係
	$(if $(makeindex),@( \
      $(ECHO); \
      $(ECHO) '# Index Files: .aux -> idx -> .ind -> .dvi'; \
      $(ECHO) '$(IDXFILE): $<'; \
      $(ECHO); \
      $(ECHO) '$(PREV_IDXFILE): $(IDXFILE)'; \
      $(ECHO); \
      $(ECHO) '$(INDFILE): $(PREV_IDXFILE)'; \
      $(ECHO); \
      $(ECHO) '$(DVIFILE): $(INDFILE)') >>$@)
  # 文献処理用ファイルの依存関係
	$(if $(bibdb),@( \
      $(ECHO); \
      $(ECHO) '# Bibliography Files - .bbl, .bib'; \
      $(ECHO) '$(PREV_AUXFILE): $(AUXFILE)'; \
      $(ECHO); \
      $(ECHO) '$(DVIFILE): $(BBLFILE)'; \
      $(ECHO); \
      $(ECHO) '$(BBLFILE): $(bibdb)') >>$@)

# 変数TARGETSで指定されたターゲットファイルに対応する
# .dファイルをインクルードし、依存関係を取得する
# ターゲットに %clean、%.xbb、%.d が含まれている場合は除く
ifeq (,$(filter %clean %.xbb %.d,$(MAKECMDGOALS)))
  -include $(addsuffix .d,$(basename $(TARGETS)))
endif

# dviファイル作成
%.dvi: %.tex
	$(COMPILES.tex)

# auxファイル作成
%.aux: %.tex
	$(COMPILE.tex)

%.prev_aux: %.aux
	-$(CMP) $@ $< || $(CP) $< $@

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
	$(COMPILE.tex)

%.prev_idx: %.idx
	-$(CMP) $@ $< || $(CP) $< $@

%.ind: %.prev_idx
	$(MENDEX) $(MENDEXFLAG) $(IDXFILE)

# 文献処理用ファイル作成
%.bbl: %.prev_aux
	$(BIBTEX) $(BIBTEXFLAG) $(AUXFILE)

# tex-cleanターゲット
tex-clean:
	$(RM) $(addprefix *,$(TEX_INT) $(IND_INT) $(BIB_INT) .d .prev_aux .prev_idx)
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
