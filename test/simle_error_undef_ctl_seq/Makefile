TEXTARGETS := simple.pdf

CMP := cmp -s
SED := sed

.PHONY: all clean distclean

all: $(TEXTARGETS)

include latex.mk

clean: tex-clean

distclean: clean tex-distclean
