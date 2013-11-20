TEXTARGETS := hyperref.pdf

.PHONY: all update rebase clean distclean

all: $(TEXTARGETS)

update:
	$(CP) hyperref.tex.6th hyperref.tex

rebase:
	$(CP) hyperref.tex.5th hyperref.tex

include latex.mk

clean: tex-clean

distclean: tex-distclean
