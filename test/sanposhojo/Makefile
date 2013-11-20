TEXTARGETS = q1.pdf q1_ans.pdf

.PHONY: all

all: $(TEXTARGETS)

include latex.mk eukleides.mk

distclean: tex-distclean  eukleides-distclean

clean: tex-clean eukleides-clean
