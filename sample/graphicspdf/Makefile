.PHONY: all pdf-rebase pdf-update clean distclean

TEXTARGETS := graphicspdf.pdf

CMP := cmp -s
CP := cp
CONVERT := convert
ECHO := echo

all: $(TEXTARGETS)

pdf-rebase:
	$(CMP) tiger.pdf.base tiger.pdf || $(CP) tiger.pdf.base tiger.pdf

pdf-update: pdf-rebase
	$(CONVERT) Panthera_tigris_tigris.jpg tiger.pdf && $(ECHO) "tiger.pdf is updated."

include tex.mk

clean: tex-clean

distclean: pdf-rebase clean tex-distclean
	$(RM) graphics_pdf_*.pdf
