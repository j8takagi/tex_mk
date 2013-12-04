.PHONY: all update rebase

TEXTARGETS := graphics_comment.pdf

CMP := cmp -s
CP := cp
CONVERT := convert

$(TEXTARGETS):

all: $(TEXTARGETS)

include latex.mk

clean: tex-clean

distclean: rebase clean tex-distclean
	$(RM) graphics_*.pdf
