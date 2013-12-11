.PHONY: all bib-update bib-rebase body-update body-rebase rebase clean distclean

CAT := cat
CMP := cmp -s
DIFF := diff
PATCH := patch
SED := sed

TEXTARGETS := bibtex.pdf

$(TEXTARGETS):

all:
	@$(MAKE) -s bibtex_1.pdf
	@$(ECHO)
	@$(MAKE) -s bibtex_2.pdf

bibtex_1.pdf: rebase
	@$(ECHO) '---------- $@: $^ ----------'
	@$(MAKE) -s bibtex.pdf
	@$(CP) -v bibtex.pdf $@

bibtex_2.pdf: update
	@$(ECHO) '---------- $@: $^ ----------'
	@$(MAKE) -s bibtex.pdf
	@$(CP) -v bibtex.pdf $@

include latex.mk

update: body-update bib-update

rebase: body-rebase bib-rebase

bib-update: bib-rebase
	$(CAT) ref_add.bib >>ref.bib

bib-rebase:
	@($(CMP) ref.bib.base ref.bib || $(CP) ref.bib.base ref.bib)

body-update: bibtex.tex.2nd.patch
	@$(PATCH) <$<

bibtex.tex.2nd.patch: rebase
	@$(DIFF) -u bibtex.tex bibtex.tex.2nd >$@ || exit 0

body-rebase:
	@($(CMP) bibtex.tex.base bibtex.tex || $(CP) bibtex.tex.base bibtex.tex)

clean: tex-clean

distclean: rebase clean tex-distclean
	$(RM) *.patch
	$(RM) bibtex_*.pdf
