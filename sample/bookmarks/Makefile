TEXTARGETS := bookmarks.pdf

CMP := cmp -s
DIFF := diff
PATCH := patch

.PHONY: all rebase body-update toc-update clean distclean

all: $(TEXTARGETS)

rebase:
	@$(CMP) base.tex bookmarks.tex || $(CP) base.tex bookmarks.tex

body-update.patch: rebase
	@$(DIFF) -u bookmarks.tex body-update.tex >$@ || exit 0

body-update: body-update.patch
	@$(PATCH) bookmarks.tex $<

toc-update.patch: rebase
	@$(DIFF) -u bookmarks.tex toc-update.tex >$@ || exit 0

toc-update: toc-update.patch
	@$(PATCH) bookmarks.tex $<

include tex.mk

clean: rebase tex-clean

distclean: clean tex-distclean
	$(RM) *.patch
	$(RM) bookmarks*.pdf
