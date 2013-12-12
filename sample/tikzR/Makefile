TEXTARGETS := tikzR.pdf

all: $(TEXTARGETS)

include R.mk

include latex.mk

LATEX :=uplatex

clean: tex-clean R-clean

distclean: clean tex-distclean R-distclean
