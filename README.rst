XCRI-CAP to RDF and back again
==============================

This repository contains XSL stylesheets to convert XCRI-CAP 1.2 XML into RDF,
a Python script to turn such RDF back into XML, and SKOS concept schemes for a
few relevant controlled vocabularies.

Stylesheets
-----------

These stylesheets convert XCRI-CAP 1.2 into RDF/XML using appropriate
vocabularies.

You will probably want to extend and override parts of the main stylesheet
(``xcri2rdf.xsl``) in order to model locally-important concepts and provide
identifiers for your courses, presentations, and so forth.


Using
~~~~~

Make sure you have an XSLT 2.0 processor installed (we'll assume `saxon
<http://saxon.sourceforge.net/>`_).

Then, simply::

    $ saxon your-xcri-feed.xml xcri2rdf.xsl > your-xcri-feed.rdf


Overriding
~~~~~~~~~~

The ``daisy2rdf.xsl`` stylesheet should give you some clues. Note the ``<xsl:import />`` line, and how we have overriden the ``rdf-about`` template to check some special case before deferring to the implementation in ``xcri2rdf.xsl`` using ``<xsl:apply-imports />``.


Python script
-------------

Prerequisites
~~~~~~~~~~~~~

You'll need the ``rdflib`` module, which you can install using either ``easy_install`` or ``pip``, or using a Linux distribution package manager.

API
~~~

``python/xcri_rdf.py`` contains an ``XCRICAPSerializer`` class which takes an ``rdflib.Graph`` instance as its only argument. The graph must contain a subject of type ``xcri:catalog``::

    import rdflib
    from xcri_rdf import XCRICAPSerializer

    graph = rdflib.ConjunctiveGraph()
    graph.parse('course-data.rdf')
    serializer = XCRICAPSerializer(graph)

You can then serialize the graph to XML using either its ``serialize`` or ``generator`` methods. The former takes a file-like object (e.g. a file, or a socket), whereas the later yield strings::

    import sys
    serializer.serialize(sys.stdout)

    # or

    for str in serializer.generator():
        print str

As a script
~~~~~~~~~~~

The Python module may also be invoked as a script::

    $ python -m xcri_rdf file-one.rdf thesauri/*/*.rdf

The script is invoked with some number of RDF/XML files as arguments. Include the thesauri files so that things like studyMode and attendancePattern are suitably serialized.


Feedback
--------

Feedback is very welcome to `COURSEDATASTAGE1@JISCMAIL.AC.UK
<mailto:COURSEDATASTAGE1@JISCMAIL.AC.UK>`_.
