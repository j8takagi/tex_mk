.PHONY: all bib-update bib-rebase body-update rebase clean distclean

CAT := cat
CMP := cmp -s
SED := sed

TEXTARGETS := bibtex.pdf

all: $(TEXTARGETS)

include latex.mk

rebase: bib-rebase body-rebase

bib-update: bib-rebase
	$(CAT) jpnbook_add.bib >>jpnbook.bib

bib-rebase:
	$(CMP) jpnbook.bib.base jpnbook.bib || $(CP) jpnbook.bib.base jpnbook.bib

body-update: body-rebase
	$(SED) -i s/bibtexのテスト。/bibtexのテスト。本文だけ変更。/ bibtex.tex

body-rebase:
	$(CMP) bibtex.tex.base bibtex.tex || $(CP) bibtex.tex.base bibtex.tex

clean: tex-clean

distclean: rebase tex-distclean
