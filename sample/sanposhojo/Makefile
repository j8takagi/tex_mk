TEXMAIN := q1 q1_ans
TEXTARGETS := $(addsuffix .pdf,$(TEXMAIN))

.PHONY: all

all: $(TEXTARGETS)

include latex.mk
include eukleides.mk

clean: tex-clean eukleides-clean

distclean: tex-distclean eukleides-distclean
