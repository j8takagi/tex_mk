CAT := cat
ECHO := echo
SED := sed

R := R

RFLAG = --slave --vanilla

GRAPHICEXT := .pdf .png .jpeg .jpg .svg .eps .tex

.PHONY: R-clean R-distclean

.SECONDARY: $(foreach e,$(GRAPHICEXT),$(basename $(wildcard *.R))$e.R)

# read.table文で読み込まれるファイル
tablefiles = $(strip $(shell $(SED) -n -e 's/.*read\.table."\(.*\)".*;/\1/gp' $<))

# source文で読み込まれるファイル
sourcefiles = $(strip $(shell $(SED) -n -e 's/.*source."\(.*\)".*;/\1/gp' $<))

# 依存関係を自動生成し、dファイルに格納
%.d: %.R
	@$(ECHO) '$@ is created by scanning $^.'
  # 画像ファイルとRファイルの依存関係
	@($(ECHO) '$(subst .R,.eps,$<) $(subst .R,.png,$<) $(subst .R,.jpeg,$<): $<' >$@)
  # テーブルファイルの依存関係
	$(if $(tablefiles),@( \
      $(ECHO); \
      $(ECHO) '# Table Files'; \
      $(ECHO) '$(subst .R,.eps,$<) $(subst .R,.png,$<) $(subst .R,.jpeg,$<): $(tablefiles)') >>$@)
  # ソースファイルの依存関係
	$(if $(sourcefiles),@( \
      $(ECHO); \
      $(ECHO) '# Source Files'; \
      $(ECHO) '$(subst .R,.eps,$<) $(subst .R,.png,$<) $(subst .R,.jpeg,$<): $(sourcefiles)') >>$@)

# ターゲットがclean で終わるもの以外の場合、
# RTARGETSで指定されたファイルに対応するdファイルをインクルードし、
# ヘッダファイルの依存関係を取得する
ifeq (,$(filter %clean %d,$(MAKECMDGOALS)))
  -include $(addsuffix .d,$(basename $(RTARGETS)))
endif

# used by R postscript/PDF device.
# For details, type '?postscriptFonts' or '?postscriptFonts' in R.
psfamily := Japan1
pdffamily := Japan1

%.eps.R: %.R
	@$(ECHO) 'postscript(file="$(subst .R,.eps,$<)",family="$(psfamily)", onefile=F, horizontal=F)' >$@
	@$(CAT) $< >>$@
	@$(ECHO) 'invisible(dev.off())' >>$@

%.pdf.R: %.R
	@$(ECHO) 'pdf("$(subst .R,.pdf,$<)", family="$(pdffamily)")' >$@
	@$(CAT) $< >>$@
	@$(ECHO) 'invisible(dev.off())' >>$@

%.png.R: %.R
	@$(ECHO) 'png("$(subst .R,.png,$<)")' >$@
	@$(CAT) $< >>$@
	@$(ECHO) 'invisible(dev.off())' >>$@

%.jpeg.R: %.R
	@$(ECHO) 'jpeg("$(subst .R,.jpeg,$<)")' >$@
	@$(CAT) $< >>$@
	@$(ECHO) 'invisible(dev.off())' >>$@

# required: install.packages("RSvgDevice")
%.svg.R: %.R
	@$(ECHO) 'library("RSvgDevice")' >$@
	@$(ECHO) 'devSVG("$(subst .R,.svg,$<)")' >>$@
	@$(CAT) $< >>$@
	@$(ECHO) 'invisible(dev.off())' >>$@

# reqiured: install.packages("tikzDevice", repos="http://R-Forge.R-project.org", type="source")
%.tex.R: %.R
	@$(ECHO) 'library("tikzDevice")' >$@
	@$(ECHO) 'tikz("$(subst .R,.tex,$<)")' >>$@
	@$(CAT) $< >>$@
	@$(ECHO) 'invisible(dev.off())' >>$@

%.eps: %.eps.R
	$(R) $(RFLAG) <$<

%.pdf: %.pdf.R
	$(R) $(RFLAG) <$<

%.png: %.png.R
	$(R) $(RFLAG) <$<

%.jpeg: %.jpeg.R
	$(R) $(RFLAG) <$<

%.svg: %.svg.R
	$(R) $(RFLAG) <$<

%.tex: %.tex.R
	$(R) $(RFLAG) <$<

R-clean:
	$(RM) $(foreach e,$(GRAPHICEXT),*$e.R)

R-distclean: R-clean
	$(RM) $(wildcard $(foreach f, $(wildcard *.R), $(addprefix $(basename $f),$(GRAPHICEXT))))
