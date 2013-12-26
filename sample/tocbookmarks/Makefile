TEXTARGETS := tocbookmarks.pdf

CMP := cmp -s
DIFF := diff
PATCH := patch

.PHONY: all rebase body-update toc-update clean distclean

all: $(TEXTARGETS)

rebase:
	@$(CMP) base.tex tocbookmarks.tex || $(CP) base.tex tocbookmarks.tex

body-update.patch: rebase
	@$(DIFF) -u tocbookmarks.tex body-update.tex >$@ || exit 0

body-update: body-update.patch
	$(PATCH) tocbookmarks.tex $<

toc-update.patch: rebase
	@$(DIFF) -u tocbookmarks.tex toc-update.tex >$@ || exit 0

toc-update: toc-update.patch
	$(PATCH) tocbookmarks.tex $<

include tex.mk

clean: rebase tex-clean

distclean: clean tex-distclean
	$(RM) *.patch
	$(RM) tocbookmarks*.pdf
