.PHONY: all update rebase

TEXTARGETS := graphics_pdf.pdf

CMP := cmp -s
CP := cp
CONVERT := convert

$(TEXTARGETS):

all:
	@$(MAKE) -s graphics_pdf_1.pdf
	@$(ECHO) '--------------------'
	@$(MAKE) -s graphics_pdf_2.pdf

graphics_pdf_1.pdf: rebase
	@$(ECHO) '---------- $@: $^ ----------'
	@$(MAKE) -s graphics_pdf.pdf
	$(CP) -v graphics_pdf.pdf $@

graphics_pdf_2.pdf: update
	@$(ECHO) '---------- $@: $^ ----------'
	@$(MAKE) -s graphics_pdf.pdf
	$(CP) -v graphics_pdf.pdf $@

rebase:
	$(CMP) tiger.pdf.base tiger.pdf || $(CP) -v tiger.pdf.base tiger.pdf

update:
	$(CONVERT) Panthera_tigris_tigris.jpg tiger.pdf

include latex.mk

clean: tex-clean

distclean: rebase clean tex-distclean
	$(RM) graphics_pdf_*.pdf
