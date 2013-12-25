.PHONY: all check clean distclean

ECHO := echo

all:
	@$(ECHO) "Usage -- make check; make clean; make distclean" >&2


check:
	$(MAKE) -sC test check

clean:
	$(MAKE) -sC test clean
	$(MAKE) -sC sample clean
	$(MAKE) -sC doc clean

distclean: clean
	$(MAKE) -sC sample distclean
	$(MAKE) -sC doc distclean
