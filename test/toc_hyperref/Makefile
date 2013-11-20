TEXTARGETS := toc_hyperref.pdf

.PHONY: all update rebase clean distclean

all: $(TEXTARGETS)

update: toc_hyperref.tex
	$(CP) toc_hyperref.tex.6th toc_hyperref.tex

rebase:
	$(CP) toc_hyperref.tex.5th toc_hyperref.tex

toc_hyperref.tex: toc_hyperref.tex.5th
	$(CP) $< $@

include latex.mk

clean: tex-clean

distclean: tex-distclean
