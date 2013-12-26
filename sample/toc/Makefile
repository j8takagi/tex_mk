TEXTARGETS := toc.pdf

CMP := cmp -s
DIFF := diff
PATCH := patch

.PHONY: all rebase body-update toc-update clean distclean

all: $(TEXTARGETS)

rebase:
	@$(CMP) base.tex toc.tex || $(CP) base.tex toc.tex

body-update.patch: rebase
	@$(DIFF) -u toc.tex body-update.tex >$@ || exit 0

body-update: body-update.patch
	@$(PATCH) toc.tex $<

toc-update.patch: rebase
	@$(DIFF) -u toc.tex toc-update.tex >$@ || exit 0

toc-update: toc-update.patch
	@$(PATCH) toc.tex $<

include tex.mk

clean: tex-clean

distclean: rebase clean tex-distclean
	$(RM) *.patch
	$(RM) toc*.pdf
