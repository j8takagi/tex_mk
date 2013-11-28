.PHONY: all update rebase

TEXTARGETS := graphics_pdf.pdf

CMP := cmp -s
CP := cp
CONVERT := convert

$(TEXTARGETS):

all: graphics_pdf.pdf

include latex.mk

clean: tex-clean

distclean: rebase clean tex-distclean
	$(RM) graphics_pdf_*.pdf
