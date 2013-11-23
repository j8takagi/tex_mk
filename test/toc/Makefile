TEXTARGETS := toc.pdf

.PHONY: all toc-update rebase clean distclean

all: $(TEXTARGETS)

toc-update:
	$(CP) toc.tex.6th toc.tex

body-update:
	$(CP) toc.tex.5th_add toc.tex

rebase:
	$(CP) toc.tex.5th toc.tex

include latex.mk

clean: tex-clean

distclean: tex-distclean rebase
