TEXTARGETS := error_no_end_seq.pdf

CMP := cmp -s
SED := sed

.PHONY: all clean distclean

all:
	$(MAKE) -s $(TEXTARGETS) && exit 1 || exit 0

include latex.mk

clean: tex-clean

distclean: tex-distclean
