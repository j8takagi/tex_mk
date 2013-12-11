.PHONY: all update rebase

TEXTARGETS := graphics_eps.pdf

CMP := cmp -s
CP := cp
CONVERT := convert

$(TEXTARGETS):

all:
	@$(MAKE) -s graphics_eps_1.pdf
	@$(ECHO) '--------------------'
	@$(MAKE) -s graphics_eps_2.pdf

graphics_eps_1.pdf: rebase
	@$(ECHO) '---------- $@: $^ ----------'
	@$(MAKE) -s graphics_eps.pdf
	@$(CP) -v graphics_eps.pdf $@

graphics_eps_2.pdf: update
	@$(ECHO) '---------- $@: $^ ----------'
	@$(MAKE) -s graphics_eps.pdf
	@$(CP) -v graphics_eps.pdf $@

rebase:
	@($(CMP) tiger.eps.base tiger.eps || $(CP) tiger.eps.base tiger.eps)

update:
	@$(CONVERT) Panthera_tigris_tigris.jpg tiger.eps

include latex.mk

clean: tex-clean

distclean: rebase clean tex-distclean
	$(RM) graphics_eps_*.pdf
