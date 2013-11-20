TEXTARGETS := makeindex.pdf

.PHONY: all index-update rebase index-rebase tex-update tex-rebase clean distclean

SED := sed
CMP := cmp -s

all: $(TEXTARGETS)

index-update:
	$(SED) -i.bak -e 's/楽譜の/楽譜\\index{がくふ@楽譜}の/' makeindex.tex

index-rebase:
	$(CMP) makeindex.tex.base makeindex.tex || $(CP) makeindex.tex.base makeindex.tex

rebase: index-rebase

include latex.mk

clean: tex-clean

distclean: clean tex-distclean
