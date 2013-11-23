TEXTARGETS := toc_hyperref.pdf

.PHONY: all toc-update body-update rebase clean distclean

all: $(TEXTARGETS)

toc-update:
	$(CP) toc_hyperref.tex.6th toc_hyperref.tex

body-update:
	$(CP) toc_hyperref.tex.5th_add toc_hyperref.tex

rebase:
	$(CP) toc_hyperref.tex.5th toc_hyperref.tex

include latex.mk

clean: tex-clean

distclean: tex-distclean rebase
