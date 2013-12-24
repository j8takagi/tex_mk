MKDIR := mkdir
CP := cp
CD := cd
ECHO := echo
ZIP := zip

XSLTPROC := xsltproc
DOCBOOK.XSL := /usr/share/xml/docbook/stylesheet/docbook-xsl/epub/docbook.xsl

TEMPDIR = $@.tempdir

%.epub: %.xml
	if test ! -e $(TEMPDIR); then $(MKDIR) $(TEMPDIR); fi
	$(ECHO) "application/epub+zip" > $(TEMPDIR)/mimetype
	$(CP) $< $(TEMPDIR)/
	$(CD) $(TEMPDIR) && $(XSLTPROC) $(DOCBOOK.XSL) $<
	$(CD) $(TEMPDIR) && $(ZIP) -0Xq $@ mimetype && $(ZIP) -Xr9D $@ *
	$(CP) $(TEMPDIR)/$@ ./

db2epub-clean:
	$(RM) -r *.tempdir

db2epub-distclean: db2epub-clean
	$(RM) *.epub
