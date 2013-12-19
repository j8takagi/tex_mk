TEXMAIN := *
TEXTARGETS := $(subst .tex,.pdf,$(wildcard $(TEXMAIN).tex))

all: $(TEXTARGETS)

include latex.mk

clean: tex-clean

distclean: clean tex-distclean
