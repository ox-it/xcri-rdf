XCRI-CAP to RDF stylesheets
===========================

These stylesheets convert XCRI-CAP 1.2 into RDF/XML using appropriate
vocabularies.

You will probably want to extend and override parts of the main stylesheet
(``xcri2rdf.xsl``) in order to model locally-important concepts and provide
identifiers for your courses, presentations, and so forth.


Using
-----

Make sure you have an XSLT 2.0 processor installed (we'll assume `saxon
<http://saxon.sourceforge.net/>`_).

Then, simply::

    $ saxon your-xcri-feed.xml xcri2rdf.xsl > your-xcri-feed.rdf


Overriding
----------

The ``daisy2rdf.xsl`` stylesheet should give you some clues. Note the ``<xsl:import />`` line, and how we have overriden the ``rdf-about`` template to check some special case before deferring to the implementation in ``xcri2rdf.xsl`` using ``<xsl:apply-imports />``.


Feedback
--------

Feedback is very welcome to `COURSEDATASTAGE1@JISCMAIL.AC.UK
<mailto:COURSEDATASTAGE1@JISCMAIL.AC.UK>_`.
