TEXTARGETS := toc_hyperref.pdf

CMP := cmp -s
DIFF := diff
PATCH := patch

.PHONY: all update rebase clean distclean

all:
	@$(MAKE) -s toc_hyperref_1.pdf
	@$(ECHO) '--------------------'
	@$(MAKE) -s toc_hyperref_2.pdf

toc_hyperref_1.pdf: rebase
	@$(ECHO) '---------- $@: $^ ----------'
	@$(MAKE) -s toc_hyperref.pdf
	@$(CP) -v toc_hyperref.pdf $@

toc_hyperref_2.pdf: update
	@$(ECHO) '---------- $@: $^ ----------'
	@$(MAKE) -s toc_hyperref.pdf
	@$(CP) -v toc_hyperref.pdf $@

update: toc_hyperref.tex.6th.patch
	@$(PATCH) <$<

toc_hyperref.tex.6th.patch:
	@$(MAKE) -s rebase
	@$(DIFF) -u toc_hyperref.tex toc_hyperref.tex.6th >$@ || exit 0

rebase:
	$(CMP) toc_hyperref.tex.5th toc_hyperref.tex || $(CP) -v toc_hyperref.tex.5th toc_hyperref.tex

include latex.mk

clean: tex-clean

distclean: rebase tex-distclean
	$(RM) *.patch
	$(RM) toc_hyperref_*.pdf
