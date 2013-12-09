TEXTARGETS := pdfbookmarks.pdf

CMP := cmp -s
DIFF := diff
PATCH := patch

.PHONY: all update rebase clean distclean

$(TEXTARGETS):

all:
	@$(MAKE) -s pdfbookmarks_1.pdf
	@$(ECHO) '--------------------'
	@$(MAKE) -s pdfbookmarks_2.pdf

pdfbookmarks_1.pdf: rebase
	@$(ECHO) '---------- $@: $^ ----------'
	@$(MAKE) -s pdfbookmarks.pdf
	@$(CP) -v pdfbookmarks.pdf $@

pdfbookmarks_2.pdf: update
	@$(ECHO) '---------- $@: $^ ----------'
	@$(MAKE) -s pdfbookmarks.pdf
	@$(CP) -v pdfbookmarks.pdf $@

update: pdfbookmarks.tex.6th.patch
	@$(PATCH) <$<

pdfbookmarks.tex.6th.patch:
	@$(MAKE) -s rebase
	@$(DIFF) -u pdfbookmarks.tex pdfbookmarks.tex.6th >$@ || exit 0

rebase:
	$(CMP) pdfbookmarks.tex.5th pdfbookmarks.tex || $(CP) -v pdfbookmarks.tex.5th pdfbookmarks.tex

include latex.mk

clean: tex-clean

distclean: rebase tex-distclean
	$(RM) *.patch
	$(RM) pdfbookmarks_*.pdf
