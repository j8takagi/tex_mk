TEXTARGETS := toc.pdf

CMP := cmp -s
DIFF := diff
PATCH := patch

.PHONY: all update rebase clean distclean

$(TEXTARGETS):

all:
	@$(MAKE) -s toc_1.pdf
	@$(ECHO) '--------------------'
	@$(MAKE) -s toc_2.pdf

toc_1.pdf: rebase
	@$(ECHO) '---------- $@: $^ ----------'
	@$(MAKE) -s toc.pdf
	@$(CP) -v toc.pdf $@

toc_2.pdf: update
	@$(ECHO) '---------- $@: $^ ----------'
	@$(MAKE) -s toc.pdf
	@$(CP) -v toc.pdf $@

update: toc.tex.6th.patch
	@$(PATCH) <$<

toc.tex.6th.patch:
	@$(MAKE) -s rebase
	@$(DIFF) -u toc.tex toc.tex.6th >$@ || exit 0

rebase:
	$(CMP) toc.tex.5th toc.tex || $(CP) -v toc.tex.5th toc.tex

include latex.mk

clean: tex-clean

distclean: rebase tex-distclean
	$(RM) *.patch
	$(RM) toc_*.pdf
