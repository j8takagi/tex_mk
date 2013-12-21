TEXTARGETS := tikzR.pdf

all: $(TEXTARGETS)

include R.mk

include tex.mk

TEX := uplatex

clean: tex-clean R-clean

distclean: clean tex-distclean R-distclean
