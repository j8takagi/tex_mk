TEXMAINFILES := *.tex

TEXTARGETS := $(subst .tex,.pdf,$(wildcard $(TEXMAINFILES)))

all: $(TEXTARGETS)

include latex.mk

clean: tex-clean

distclean: clean tex-distclean
