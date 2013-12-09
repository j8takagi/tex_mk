.PHONY: test clean

test:
	$(MAKE) -sC test check

clean:
	$(MAKE) -sC test clean
