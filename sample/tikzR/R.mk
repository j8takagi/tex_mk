.PHONY: R-clean R-distclean

CAT := cat
ECHO := /bin/echo
EPSTOPDF := epstopdf
R := R
SED := sed

RFLAG = --slave --vanilla

# read.table文で読み込まれるファイル
tablefiles = $(strip $(shell $(SED) -n -e 's/.*read\.table."\(.*\)".*;/\1/gp' $<))

# source文で読み込まれるファイル
sourcefiles = $(strip $(shell $(SED) -n -e 's/.*source."\(.*\)".*;/\1/gp' $<))

# used by R postscript device.
# For details, type '?postscriptFonts' in R.
psfamily ?= Japan1

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

%.eps.R: %.R
	@$(ECHO) 'postscript(file="$(subst .R,.eps,$<)",family="$(psfamily)", onefile=F, horizontal=F)' >$@
	@$(CAT) $< >>$@
	@$(ECHO) 'invisible(dev.off())' >>$@

%.eps: %.eps.R
	$(R) $(RFLAG) <$<

# %.pdf: %.eps
# 	$(EPSTOPDF) $<

%.pdf.R: %.R
	@$(ECHO) 'pdf("$(subst .R,.pdf,$<)", family="Japan1")' >$@
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

# install.packages("RSvgDevice")
%.svg.R: %.R
	@$(ECHO) 'library("RSvgDevice")' >$@
	@$(ECHO) 'devSVG("$(subst .R,.svg,$<)")' >>$@
	@$(CAT) $< >>$@
	@$(ECHO) 'invisible(dev.off())' >>$@

%.tikz.R: %.R
	@$(ECHO) 'library("tikzDevice")' >$@
	@$(ECHO) 'tikz("$(subst .R,.tex,$<)")' >>$@
	@$(CAT) $< >>$@
	@$(ECHO) 'invisible(dev.off())' >>$@

%.pdf: %.pdf.R
	$(R) $(RFLAG) <$<

%.png: %.png.R
	$(R) $(RFLAG) <$<

%.jpeg: %.jpeg.R
	$(R) $(RFLAG) <$<

%.svg: %.svg.R
	$(R) $(RFLAG) <$<

%.tex: %.tikz.R
	$(R) $(RFLAG) <$< 2>$(subst .R,.log,$<)

R-clean:
	$(RM) *.pdf.R *.png.R *.jpeg.R *.svg.R *.eps.R *.tikz.R *.d

R-distclean: R-clean
	$(RM) $(subst .R,.pdf,$(wildcard *.R)) $(subst .R,.png,$(wildcard *.R))  $(subst .R,.jpeg,$(wildcard *.R)) $(subst .R,.svg,$(wildcard *.R)) $(subst .R,.eps,$(wildcard *.R))  $(subst .R,.tex,$(wildcard *.R))
