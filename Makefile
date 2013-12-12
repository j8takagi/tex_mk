.PHONY: test clean

check:
	$(MAKE) -sC test check

clean:
	$(MAKE) -sC test clean
	$(MAKE) -sC sample clean

distclean: clean
	$(MAKE) -sC sample distclean
