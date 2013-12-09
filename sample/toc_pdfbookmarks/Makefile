TEXTARGETS := toc_pdfbookmarks.pdf

CMP := cmp -s
DIFF := diff
PATCH := patch

.PHONY: all add update rebase clean distclean

$(TEXTARGETS):

all:
	@$(MAKE) -s toc_pdfbookmarks_1.pdf
	@$(ECHO) '--------------------'
	@$(MAKE) -s toc_pdfbookmarks_2.pdf
	@$(ECHO) '--------------------'
	@$(MAKE) -s toc_pdfbookmarks_3.pdf

toc_pdfbookmarks_1.pdf: rebase
	@$(ECHO) '---------- $@: $^ ----------'
	@$(MAKE) -s toc_pdfbookmarks.pdf
	@$(CP) -v toc_pdfbookmarks.pdf $@

toc_pdfbookmarks_2.pdf: add
	@$(ECHO) '---------- $@: $^ ----------'
	@$(MAKE) -s toc_pdfbookmarks.pdf
	@$(CP) -v toc_pdfbookmarks.pdf $@

toc_pdfbookmarks_3.pdf: update
	@$(ECHO) '---------- $@: $^ ----------'
	@$(MAKE) -s toc_pdfbookmarks.pdf
	@$(CP) -v toc_pdfbookmarks.pdf $@

add: toc_pdfbookmarks.tex.5th_add.patch
	@$(PATCH) <$<

update: toc_pdfbookmarks.tex.6th.patch
	@$(PATCH) <$<

toc_pdfbookmarks.tex.5th_add.patch: rebase
	@$(DIFF) -u toc_pdfbookmarks.tex toc_pdfbookmarks.tex.5th_add >$@ || exit 0

toc_pdfbookmarks.tex.6th.patch: rebase
	@$(DIFF) -u toc_pdfbookmarks.tex toc_pdfbookmarks.tex.6th >$@ || exit 0

rebase:
	$(CMP) toc_pdfbookmarks.tex.5th toc_pdfbookmarks.tex || $(CP) -v toc_pdfbookmarks.tex.5th toc_pdfbookmarks.tex

include latex.mk

clean: tex-clean

distclean: rebase tex-distclean
	$(RM) *.patch
	$(RM) toc_pdfbookmarks_*.pdf
