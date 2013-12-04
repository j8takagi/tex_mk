TEXTARGETS := simple.pdf

CMP := cmp -s
SED := sed

.PHONY: all update rebase clean distclean

all:
	$(MAKE) -s $(TEXTARGETS) && exit 1 || exit 0

include latex.mk

clean: tex-clean

distclean: tex-distclean
