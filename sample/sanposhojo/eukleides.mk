EUKLEIDES = eukleides
EPSTOPDF = epstopdf
# ImageMagick
CONVERT = convert

eukfiles = $(wildcard *.euk)

%.eps: %.euk
	$(EUKLEIDES) $<

%.pdf: %.eps
	$(EPSTOPDF) $<

%.png: %.eps
	$(CONVERT) $< $@

%.jpeg: %.eps
	$(CONVERT) $< $@

%.jpg: %.eps
	$(CONVERT) $< $@

eukleides-clean:
	$(if $(eukfiles),$(RM) $(subst .euk,.eps,$(eukfiles)))

eukleides-distclean: eukleides-clean
	$(if $(eukfiles), $(RM) $(subst .euk,.pdf,$(eukfiles)) $(subst .euk,.png,$(eukfiles)) $(subst .euk,.jpeg,$(eukfiles)) $(subst .euk,.jpg,$(eukfiles)))
