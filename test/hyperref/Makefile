TEXTARGETS := hyperref.pdf

CMP := cmp -s
DIFF := diff
PATCH := patch

.PHONY: all update rebase clean distclean

all:
	@$(MAKE) -s hyperref_1.pdf
	@$(ECHO) '--------------------'
	@$(MAKE) -s hyperref_2.pdf

hyperref_1.pdf: rebase
	@$(ECHO) '---------- $@: $^ ----------'
	@$(MAKE) -s hyperref.pdf
	@$(CP) -v hyperref.pdf $@

hyperref_2.pdf: update
	@$(ECHO) '---------- $@: $^ ----------'
	@$(MAKE) -s hyperref.pdf
	@$(CP) -v hyperref.pdf $@

update: hyperref.tex.6th.patch
	@$(PATCH) <$<

hyperref.tex.6th.patch:
	@$(MAKE) -s rebase
	@$(DIFF) -u hyperref.tex hyperref.tex.6th >$@ || exit 0

rebase:
	$(CMP) hyperref.tex.5th hyperref.tex || $(CP) -v hyperref.tex.5th hyperref.tex

include latex.mk

clean: tex-clean

distclean: rebase tex-distclean
	$(RM) *.patch
	$(RM) hyperref_*.pdf
