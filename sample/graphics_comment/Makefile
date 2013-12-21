.PHONY: all update rebase

TEXTARGETS := graphics_comment.pdf

CMP := cmp -s
CP := cp
CONVERT := convert

$(TEXTARGETS):

all: $(TEXTARGETS)

include tex.mk

clean: tex-clean

distclean: rebase clean tex-distclean
	$(RM) graphics_*.pdf
