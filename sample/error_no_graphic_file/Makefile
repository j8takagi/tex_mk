.PHONY: all clean distclean

TEXTARGETS := error_no_graphic_file.pdf

all:
	$(MAKE) -s error_no_graphic_file.pdf && exit 1 || exit 0

include latex.mk

clean: tex-clean

distclean: clean tex-distclean
