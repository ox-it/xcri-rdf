import os
import subprocess
import unittest

from lxml import etree
import rdflib

def relative_path(*args):
    return os.path.join(os.path.dirname(__file__), *args)

class Namespaces(dict):
    def __getattr__(self, name): return self[name]
NS = {'dc': 'http://purl.org/dc/elements/1.1/',
      'dcterms': 'http://purl.org/dc/terms/',
      'xcri': 'http://xcri.org/profiles/1.2/',
      'rdf': 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
      'skos': 'http://www.w3.org/2004/02/skos/core#'}
XMLNS = NS.copy()
XMLNS.update({'xcri': 'http://xcri.org/profiles/1.2/catalog'})
NS = Namespaces((k, rdflib.Namespace(NS[k])) for k in NS)


class XSLTTestCase(unittest.TestCase):
    @property
    def saxon_path(self):
        candidates = ['/usr/bin/saxon', '/usr/bin/saxonb-xslt']
        for candidate in candidates:
            if os.path.exists(candidate):
                return candidate
        raise ImproperlyConfigured("Couldn't find saxon.")

    @property
    def graph(self):
        if not hasattr(self, '_graph'):
            saxon = subprocess.Popen([self.saxon_path,
                                      relative_path('data', 'conted.xcricap'),
                                      relative_path('..', 'stylesheets', 'xcri2rdf.xsl')],
                                     stdout=subprocess.PIPE)
            self._graph = rdflib.ConjunctiveGraph()
            self._graph.parse(saxon.stdout)
        return self._graph

    @property
    def xml(self):
        if not hasattr(self, '_xml'):
            with open(relative_path('data', 'conted.xcricap')) as f:
                self._xml = etree.parse(f)
        return self._xml

    def testTransform(self):
        self.graph

    def testCatalog(self):
        graph, xml = self.graph, self.xml
        catalog = self.graph.value(None, NS.rdf.type, NS.xcri.catalog, any=False)
        self.assertIsInstance(catalog, rdflib.URIRef)

        # Check that catalog title and description were picked up correctly.
        self.assertEqual(graph.value(catalog, NS.dcterms.title),
                         xml.xpath('/xcri:catalog/dc:title', namespaces=XMLNS)[0].text)
        self.assertEqual(graph.value(catalog, NS.dcterms.description),
                         xml.xpath('/xcri:catalog/dc:description', namespaces=XMLNS)[0].text)

        # Check that there were courses to serialize, and that we've
        # serialized the right number.
        self.assert_(len(xml.xpath('/xcri:catalog/xcri:provider/xcri:course', namespaces=XMLNS)))
        self.assertEqual(len(list(graph.objects(catalog, NS.skos.member))),
                         len(xml.xpath('/xcri:catalog/xcri:provider/xcri:course', namespaces=XMLNS)))

    def testProvider(self):
        providers = list(self.graph.subjects(NS.rdf.type, NS.xcri.provider))

        # There should be at least one provider
        self.assert_(len(providers) > 0)

        for provider in providers:
            self.assertIsInstance(provider, rdflib.URIRef)
            


if __name__ == '__main__':
    unittest.main()
