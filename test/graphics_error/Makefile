.PHONY: all update clean distclean

TEXTARGETS := graphics.pdf

all:
	$(MAKE) -s graphics.pdf && exit 1 || exit 0

include latex.mk

clean: tex-clean

distclean: clean tex-distclean
