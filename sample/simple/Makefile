TEXTARGETS := simple.pdf

CMP := cmp -s
SED := sed

.PHONY: all update rebase clean distclean

$(TEXTARGETS):

all:
	@$(MAKE) -s simple_1.pdf
	@$(ECHO) '--------------------'
	@$(MAKE) -s simple_2.pdf

simple_1.pdf: rebase
	@$(ECHO) '---------- $@: $^ ----------'
	@$(MAKE) -s simple.pdf
	@$(CP) -v simple.pdf $@

simple_2.pdf: update
	@$(ECHO) '---------- $@: $^ ----------'
	@$(MAKE) -s simple.pdf
	@$(CP) -v simple.pdf $@

update:
	$(SED) -i.bak -e 's/，/、/g' -e 's/．/。/g' simple.tex

rebase:
	$(CMP) simple.tex.base simple.tex || $(CP) -v simple.tex.base simple.tex

include latex.mk

clean: rebase tex-clean
	$(RM) *.bak

distclean: clean tex-distclean
	$(RM) simple_*.pdf
