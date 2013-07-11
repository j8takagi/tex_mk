.PHONY: clean-tex distclean-tex

# シェルコマンド
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

#LaTeXオプション
interaction ?= batchmode
LATEXFLAG ?=
DVIPDFMXFLAG ?=
EXTRACTBBFLAGS ?=
BIBTEXFLAG ?=
MENDEXFLAG ?=

# LaTeX処理（コンパイル）
COMPILE.tex = $(LATEX) -interaction=$(interaction) $(LATEXFLAG) $(addsuffix .tex,$(basename $<))

# 相互参照の警告
WARN_REF := 'Label(s) may have changed. Rerun to get cross-references right.'

# 相互参照未定義の警告。2回目以降の処理で出る場合は、参照エラー
WARN_UNDEFREF := 'There were undefined references.'

# auxやtocなどのファイルがない警告
WARN_NOFILE := 'No file'

# LaTeX処理の最大回数
MAX_CNT := 10

# logファイルに相互参照または目次ファイルなしの警告がある場合、LaTeX処理を繰り返す
# 2回目以降の処理で相互参照未定義の警告がある場合と、
# 繰り返しの回数がMAX_CNTになった場合は、警告を表示してエラー終了
COMPILES.tex = \
  cnt=0; \
  while $(GREP) -F -e $(WARN_REF) -e $(WARN_NOFILE) $(addsuffix .log,$(basename $<)); do \
    if test $$cnt -ge $(MAX_CNT); then \
      $(ECHO) "LaTeX compile is over $$cnt times, but warnings exist."; \
      exit 1; \
    fi; \
    $(COMPILE.tex); \
    if test $$cnt -eq 1 && $(GREP) -F $(WARN_UNDEFREF) $(addsuffix .log,$(basename $<)); then \
      exit 1; \
    fi; \
    cnt=`expr $$cnt + 1`; \
  done

# \includeコマンドで読み込まれるtexファイル
intex = $(addsuffix .tex,$(basename $(strip $(shell \
  $(SED) -n -e 's/\\\(include\|input\)\(\[[^]]*\]\)\{0,1\}{[^}]*}/&\n/gp' $<  | \
  $(SED) -e 's/.*{\([^}]*\)}.*/\1/'))))

# \includegraphicsコマンドで読み込まれるグラフィックファイル
ingraphics = $(strip $(shell \
  $(SED) -n -e 's/\\includegraphics\(\[[^]]*\]\)\{0,1\}\({[^}]*}\)/&\n/gp' $< $(intex) | \
  $(SED) -e 's/.*{\([^}]*\)}.*/\1/'))

# \bibliographyコマンドで読み込まれる文献データベースファイル
bibdb = $(addsuffix .bib,$(basename $(strip $(shell \
  $(SED) -n -e 's/\\bibliography\(\[[^]]*\]\)\{0,1\}{\([^}]*\)}/&\n/gp' $< $(intex) | \
  $(SED) -e 's/.*{\([^}]*\)}.*/\1/' | \
  $(SED) -e 's/,/ /g'))))

# texファイルに索引作成の指定があるか確認
MAKEINDEX := '\makeindex'
GREP-makeindex = $(GREP) -F $(MAKEINDEX) $<

# 依存関係を自動生成し、dファイルに格納
%.d: %.tex
	@$(ECHO) '$@ is created by scanning $^.'
  # texファイルの依存関係
	@(($(ECHO) '$(subst .tex,.dvi,$<) $(subst .tex,.aux,$<) $(subst .tex,.d,$<): $<'; \
       $(ECHO); \
       $(ECHO) '$(subst .tex,.prev_aux,$<):') >$@)
  # Include/Inputファイルの依存関係
	$(if $(intex),@( \
      $(ECHO); \
      $(ECHO) '# Include/Input Files - tex'; \
      $(ECHO) '$(subst .tex,.dvi,$<) $(subst .tex,.aux,$<): $(intex)') >>$@)
  # 画像ファイルの依存関係
	$(if $(ingraphics),@( \
      $(ECHO); \
      $(ECHO) '# IncludeGraphic Files - pdf, jpeg/jpg, png & xbb'; \
      $(ECHO) '$(subst .tex,.dvi,$<) $(subst .tex,.aux,$<): $(ingraphics)'; \
      $(ECHO); \
      $(ECHO) '$(subst .tex,.dvi,$<) $(subst .tex,.aux,$<): $(addsuffix .xbb,$(basename $(ingraphics)))') >>$@)
  # 文献処理用ファイルの依存関係
	$(if $(bibdb),@( \
       $(ECHO); \
       $(ECHO) '# Bibliography Files - bbl & bib'; \
       $(ECHO) '$(subst .tex,.dvi,$<): $(subst .tex,.bbl,$<)'; \
       $(ECHO); \
       $(ECHO) '$(subst .tex,.bbl,$<): $(bibdb)') >>$@)
  # 索引作成用ファイルの依存関係
	$(if $(strip $(shell $(GREP-makeindex))),@( \
       $(ECHO); \
       $(ECHO) '# MakeIndex Files - ind'; \
       $(ECHO) '$(subst .tex,.idx,$<):'; \
       $(ECHO); \
       $(ECHO) '$(subst .tex,.ind,$<):'; \
       $(ECHO); \
       $(ECHO) '$(subst .tex,.dvi,$<): $(subst .tex,.ind,$<)') >>$@)

# 変数TARGETSで指定されたターゲットファイルに対応するdファイルをインクルード
# .dファイルからヘッダファイルの依存関係を取得する
# ターゲットに clean が含まれている場合は除く
ifeq (,$(filter %clean,$(MAKECMDGOALS)))
  -include $(addsuffix .d,$(basename $(TARGETS)))
endif

# 相互参照ファイル作成。dviファイルも同時に作成される
%.aux: %.tex
	$(COMPILE.tex)

%.prev_aux: %.aux
	-$(CMP) $@ $< || $(CP) $< $@

# dviファイル作成
%.dvi: %.aux
	$(COMPILES.tex)

# 文献処理用ファイル作成
# BiBTeXで文献処理するときに使用される
%.bbl: %.prev_aux
	$(BIBTEX) $(BIBTEXFLAG) $(subst .prev_aux,aux,$<)

# バウンディング情報ファイル作成
# dvipdfmxで図を挿入するときに使用される
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
# 索引を作成するときに使用される
%.idx: %.aux
	$(COMPILE.tex)

%.prev_idx: %.idx
	-$(CMP) $@ $< || $(CP) $< $@

%.ind: %.prev_idx
	$(MENDEX) $(MENDEXFLAG) $(subst .prev_idx,.idx,$<)

# PDFファイル作成
%.pdf: %.dvi
	$(DVIPDFMX) $(DVIPDFMXFLAG) $<

# tex-cleanターゲット
tex-clean:
	$(RM) *.aux *.bbl *.blg *.idx *.ilg *.ind *.lof *.lot *.out *.toc *.xbb *.log *.d

# tex-distcleanターゲット
tex-distclean: tex-clean
	$(RM) $(addsuffix .dvi,$(basename $(TARGETS))) $(addsuffix .pdf,$(basename $(TARGETS)))
