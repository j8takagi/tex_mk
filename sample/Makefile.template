TEXTARGETS := $(subst .tex,.pdf,$(wildcard *.tex))

all: $(TEXTARGETS)

include latex.mk

clean: tex-clean

distclean: clean tex-distclean
