.PHONY: all bib-update bib-rebase body-update rebase clean distclean

CAT := cat
CMP := cmp -s
SED := sed

TEXTARGETS := bibtex.pdf

all:
	@$(MAKE) -s bibtex_1.pdf
	@$(ECHO) '--------------------'
	@$(MAKE) -s bibtex_2.pdf
	@$(ECHO) '--------------------'
	@$(MAKE) -s bibtex_3.pdf
	@$(ECHO) '--------------------'
	@$(MAKE) -s bibtex_4.pdf
	@$(ECHO) '--------------------'
	@$(MAKE) -s bibtex_5.pdf

bibtex_1.pdf: rebase
	$(ECHO) '---------- $@: $^ ----------'
	@$(MAKE) -s bibtex.pdf
	$(CP) -v bibtex.pdf $@

bibtex_2.pdf: body-update
	$(ECHO) '---------- $@: $^ ----------'
	@$(MAKE) -s bibtex.pdf
	$(CP) -v bibtex.pdf $@

bibtex_3.pdf: rebase bibtex.pdf bib-update
	$(ECHO) '---------- $@: $^ ----------'
	@$(MAKE) -s bibtex.pdf
	$(CP) -v bibtex.pdf $@

bibtex_4.pdf: body-update bib-update
	$(ECHO) '---------- $@: $^ ----------'
	@$(MAKE) -s bibtex.pdf
	$(CP) -v bibtex.pdf $@

bibtex_5.pdf: rebase bibtex.pdf body-update bib-update
	$(ECHO) '---------- $@: $^ ----------'
	@$(MAKE) -s bibtex.pdf
	$(CP) -v bibtex.pdf $@

include latex.mk

rebase: bib-rebase body-rebase

bib-update: bib-rebase
	$(CAT) jpnbook_add.bib >>jpnbook.bib

bib-rebase:
	$(CMP) jpnbook.bib.base jpnbook.bib || $(CP) -v jpnbook.bib.base jpnbook.bib

body-update: body-rebase
	$(SED) -i -e 's/本文変更なし。/本文を変更。/' bibtex.tex

body-rebase:
	$(CMP) bibtex.tex.base bibtex.tex || $(CP) -v bibtex.tex.base bibtex.tex

clean: tex-clean

distclean: rebase tex-distclean
	$(RM) bibtex_*.pdf
