.PHONY: all bib-update bib-rebase tex-update rebase clean distclean

CAT := cat
CMP := cmp -s
SED := sed

TEXTARGETS := bibtex.pdf

all: $(TEXTARGETS)

include latex.mk

rebase: bib-rebase tex-rebase

bib-update: bib-rebase
	$(CAT) jpnbook_add.bib >>jpnbook.bib

bib-rebase:
	$(CMP) jpnbook.bib.base jpnbook.bib || $(CP) jpnbook.bib.base jpnbook.bib

tex-update: tex-rebase
	$(SED) -i s/bibtexのテスト。/bibtexのテスト。本文だけ変更。/ bibtex.tex

tex-rebase:
	$(CMP) bibtex.tex.base bibtex.tex || $(CP) bibtex.tex.base bibtex.tex

clean: tex-clean

distclean: rebase tex-distclean
