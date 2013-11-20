EUKLEIDES = eukleides
EPSTOPDF = epstopdf
# ImageMagick
CONVERT = convert

%.eps: %.euk
	$(EUKLEIDES) $<

%.pdf: %.eps
	$(EPSTOPDF) $<

%.png: %.eps
	$(CONVERT) $< $@

%.jpeg: %.eps
	$(CONVERT) $< $@

eukleides-clean:
	$(RM) $(subst .euk,.png,*.eps)

eukleides-distclean:
	$(RM) $(subst .euk,.pdf,*.euk) $(subst .euk,.png,*.euk) $(subst .euk,.jpeg,*.euk)
