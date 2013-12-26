.PHONY: all eps-update eps-rebase

TEXTARGETS := graphicseps.pdf

CMP := cmp -s
CP := cp
CONVERT := convert

all: $(TEXTARGETS)

eps-rebase:
	@($(CMP) tiger.eps.base tiger.eps || $(CP) tiger.eps.base tiger.eps)

eps-update:
	@$(CONVERT) Panthera_tigris_tigris.jpg tiger.eps

include tex.mk

clean: tex-clean

distclean: eps-rebase clean tex-distclean
	$(RM) graphicseps*.pdf
