TEXMAIN := q1 q1_ans
TEXTARGETS := $(addsuffix .pdf,$(TEXMAIN))

.PHONY: all

all: $(TEXTARGETS)

include tex.mk
include eukleides.mk

clean: tex-clean eukleides-clean

distclean: tex-distclean eukleides-distclean
