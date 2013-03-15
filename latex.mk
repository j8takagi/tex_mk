.PHONY: clean-tex distclean-tex

# シェルコマンド
ECHO := echo
GREP := grep
SED := sed

# LaTeXコマンド
BIBTEX := pbibtex
DVIPDFMX := dvipdfmx
EXTRACTBB := extractbb
LATEX := platex
MENDEX := mendex

#LaTeXオプション
BIBTEXFLAG ?=
DVIPDFMXFLAG ?=
EXTRACTBBFLAGS ?=
LATEXFLAG ?=
MENDEXFLAG ?=

# LaTeXで処理
COMPILE.tex = $(LATEX) -interaction=batchmode $(LATEXFLAG) $(addsuffix .tex,$(basename $<))

# logファイルに未定義参照の警告があるか確認
REFWARN := 'LaTeX Warning: There were undefined references.'

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
	@($(ECHO) '$(subst .tex,.dvi,$<) $(subst .tex,.aux,$<) $(subst .tex,.d,$<): $<' >$@)
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

# dviファイル作成
%.dvi: %.aux
  # logファイルに未定義参照の警告がある場合、LaTeXで処理
	while $(GREP) -F $(REFWARN) $(addsuffix .log,$(basename $<)); do $(COMPILE.tex); done

# 文献処理用ファイル作成
# BiBTeXで文献処理するときに使用される
%.bbl: %.aux
	$(BIBTEX) $(BIBTEXFLAG) $(addsuffix .aux,$(basename $<))

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

%.ind: %.idx
	$(MENDEX) $(MENDEXFLAG) $<

# PDFファイル作成
%.pdf: %.dvi
	$(DVIPDFMX) $(DVIPDFMXFLAG) $<

# tex-cleanターゲット
tex-clean:
	$(RM) *.aux *.bbl *.blg *.d *.idx *.ilg *.ind *.lof *.log *.lot *.out *.toc *.xbb

# tex-distcleanターゲット
tex-distclean: tex-clean
	$(RM) $(addsuffix .dvi,$(basename $(TARGETS))) $(addsuffix .pdf,$(basename $(TARGETS)))
