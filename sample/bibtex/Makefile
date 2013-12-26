.PHONY: all bib-update bib-rebase body-update body-rebase rebase clean distclean

CAT := cat
CMP := cmp -s
DIFF := diff
PATCH := patch
SED := sed

TEXTARGETS := bibtex.pdf

all: $(TEXTARGETS)

include tex.mk

update: tex-update bib-update

rebase: tex-rebase bib-rebase

bib-rebase:
	@($(CMP) ref.bib.base ref.bib || $(CP) ref.bib.base ref.bib)

tex-rebase:
	@($(CMP) bibtex.tex.base bibtex.tex || $(CP) bibtex.tex.base bibtex.tex)

ref.bib.update.patch: bib-rebase
	@$(DIFF) -u ref.bib ref.bib.update >$@ || exit 0

bib-update: ref.bib.update.patch
	$(PATCH) <$<

bibtex.tex.update.patch: tex-rebase
	@$(DIFF) -u bibtex.tex bibtex.tex.update >$@ || exit 0

tex-update: bibtex.tex.update.patch
	@$(PATCH) <$<

clean: tex-clean

distclean: rebase clean tex-distclean
	$(RM) *.patch
	$(RM) bibtex*.pdf
