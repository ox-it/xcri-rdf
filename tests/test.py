import os
import subprocess
import threading
import unittest

from lxml import etree
import rdflib

def relative_path(*args):
    return os.path.join(os.path.dirname(__file__), *args)

class Namespaces(dict):
    def __getattr__(self, name): return self[name]
NS = {'dc': 'http://purl.org/dc/elements/1.1/',
      'dcterms': 'http://purl.org/dc/terms/',
      'mlo': 'http://purl.org/net/mlo/',
      'xcri': 'http://xcri.org/profiles/1.2/',
      'xtypes': 'http://purl.org/xtypes/',
      'rdf': 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
      'xhtml': 'http://www.w3.org/1999/xhtml#',
      'skos': 'http://www.w3.org/2004/02/skos/core#'}
XMLNS = NS.copy()
# Some namespaces differ between RDF and XML
XMLNS.update({'mlo': 'http://purl.org/net/mlo',
              'xcri': 'http://xcri.org/profiles/1.2/catalog',
              'xhtml': 'http://www.w3.org/1999/xhtml',
              'xsi': 'http://www.w3.org/2001/XMLSchema-instance'})
NS = Namespaces((k, rdflib.Namespace(NS[k])) for k in NS)

common_descriptive_elements = [(NS.dcterms.description, 'dc:description'),
                               (NS.xcri.abstract, 'xcri:abstract'),
                               (NS.xcri.applicationProcedure, 'xcri:applicationProcedure'),
                               (NS.mlo.assessment, 'mlo:assessment'),
                               (NS.xcri.learningOutcome, 'xcri:learningOutcome'),
                               (NS.mlo.objective, 'mlo:objective'),
                               (NS.mlo.prerequisite, 'mlo:prerequisite'),
                               (NS.xcri.regulations, 'xcri:regulations')]

filenames = [('Conted', relative_path('data', 'conted.xcricap')),
             ('AdamSmith', relative_path('data', 'adamsmith.xcricap'))]

class XSLTTestCase(unittest.TestCase):
    _cache = threading.local()
    _cache.graph, _cache.xml = {}, {}
    filename = None

    bases = {'catalog': 'http://example.org/catalog/',
             'provider': 'http://example.org/provider/',
             'course': 'http://example.org/course/',
             'presentation': 'http://example.org/presentation/',
             'venue': 'http://example.org/venue/'}

    def assertXMLEqual(self, one, two, message=None):
        self.assertEqual(one.tag, two.tag, message)
        self.assertEqual(one.attrib, two.attrib, message)
        self.assertEqual(one.text, two.text, message)
        for children in zip(one, two):
            self.assertXMLEqual(children[0], children[1], message)
        self.assertEqual(one.tail, two.tail, message)

    def assertComplexEqual(self, rdf, xml, message=None):
        if isinstance(rdf, rdflib.URIRef):
            self.assertEqual(rdf, xml.attrib['href'], message)
        elif not isinstance(rdf, rdflib.Literal):
            raise AssertionError("Unexpected RDF term: %r" % rdf)
        elif rdf.datatype == NS.xtypes['Fragment-XHTML']:
            self.assertXMLEqual(etree.fromstring(rdf), xml[0], message)
        elif rdf.datatype == None:
            self.assertEqual(rdf, xml.text, message)
        else:
            raise AssertionError("Unexpected RDF datatype: %s" % rdf.datatype)

    def checkIdentifier(self, rdf, xml):
        if isinstance(rdf, rdflib.URIRef):
            if xml.xpath("dc:identifier[text()='{0}']".format(rdf), namespaces=XMLNS):
                return True
            elif xml.xpath("dc:identifier[not(@xsi:type) and text()='{0}{1}']".format(self.bases[xml.tag.rsplit('}')[-1]], rdf), namespaces=XMLNS):
                return True
            else:
                return False
        elif isinstance(rdf, rdflib.BNode):
            if xml.xpath("dc:identifier[not(@xsi:type) and text()='{0}{1}']".format(self.bases[xml.tag.rsplit('}')[-1]], rdf), namespaces=XMLNS):
                return False
        else:
            return False
        return True
    def assertValidIdentifier(self, rdf, xml):
        if not self.checkIdentifier(rdf, xml):
            raise AssertionError("{0} doesn't match expected identifier for {1}".format(rdf, xml))

    def assertPropertyEqual(self, node, predicate, xml, xpath):
        value = self.graph.value(node, predicate, any=False)
        elements = xml.xpath(xpath, namespaces=XMLNS)
        if value is not None:
            self.assertEqual(value, elements[0].text or '')
        else:
            self.assertEqual(len(elements), 0)
    
    def zipThings(self, nodes, elements):
        nodes = list(nodes)
        nodes.sort(key=lambda n: self.graph.value(n, NS.xcri['x-order']).toPython())
        return zip(nodes, elements)

    @property
    def saxon_path(self):
        candidates = ['/usr/bin/saxon', '/usr/bin/saxonb-xslt']
        for candidate in candidates:
            if os.path.exists(candidate):
                return candidate
        raise ImproperlyConfigured("Couldn't find saxon.")

    @property
    def graph(self):
        if not self.filename:
            raise NotImplementedError("filename not set")
        if not self._cache.graph.get(self.filename):
            saxon = subprocess.Popen([self.saxon_path,
                                      self.filename,
                                      relative_path('..', 'stylesheets', 'xcri2rdf.xsl'),
                                      "catalog-base="+self.bases['catalog'],
                                      "provider-base="+self.bases['provider'],
                                      "course-base="+self.bases['course'],
                                      "presentation-base="+self.bases['presentation'],
                                      "venue-base="+self.bases['venue'],
                                      "order-annotation=true"],
                                     stdout=subprocess.PIPE,
                                     stderr=open('/dev/null', 'w'))
            self._cache.graph[self.filename] = rdflib.ConjunctiveGraph()
            self._cache.graph[self.filename].parse(saxon.stdout)
        return self._cache.graph[self.filename]

    @property
    def xml(self):
        if not self._cache.xml.get(self.filename):
            with open(self.filename) as f:
                self._cache.xml[self.filename] = etree.parse(f)
        return self._cache.xml[self.filename]

    def testTransform(self):
        self.graph

    def testCatalog(self):
        graph, xml = self.graph, self.xml
        catalog = self.graph.value(None, NS.rdf.type, NS.xcri.catalog, any=False)
        xml_catalog = xml.xpath('/xcri:catalog', namespaces=XMLNS)[0]

        self.assertValidIdentifier(catalog, xml_catalog)

        # Check that catalog title and description were picked up correctly.
        self.assertPropertyEqual(catalog, NS.dcterms.title, xml_catalog, 'dc:title')
        self.assertPropertyEqual(catalog, NS.dcterms.description, xml_catalog, 'dc:description')

        # Check that there were courses to serialize, and that we've
        # serialized the right number.
        self.assert_(len(xml_catalog.xpath('xcri:provider/xcri:course', namespaces=XMLNS)))
        self.assertEqual(len(list(graph.objects(catalog, NS.skos.member))),
                         len(xml_catalog.xpath('xcri:provider/xcri:course', namespaces=XMLNS)))

    def testProvider(self):
        graph = self.graph
        providers = list(graph.subjects(NS.rdf.type, NS.xcri.provider))

        # There should be at least one provider
        self.assert_(len(providers) > 0)

        for provider, xml_provider in self.zipThings(providers, self.xml.xpath('/xcri:catalog/xcri:provider', namespaces=XMLNS)):

            # Check that the provider's name and description made it across
            self.assertPropertyEqual(provider, NS.dcterms.title, xml_provider, 'dc:title')
            self.assertPropertyEqual(provider, NS.dcterms.description, xml_provider, 'dc:description')

    def testCourse(self):
        graph, xml = self.graph, self.xml
        courses = list(graph.subjects(NS.rdf.type, NS.xcri.course))

        # There should be at least one course
        self.assert_(len(courses) > 0)


        for course, xml_course in self.zipThings(courses, self.xml.xpath('.//xcri:course', namespaces=XMLNS)):

            # Check title and description
            self.assertEqual(graph.value(course, NS.dcterms['title']),
                             xml_course.xpath('dc:title', namespaces=XMLNS)[0].text)

            for predicate, element in common_descriptive_elements:
                rdf_cde = list(graph.objects(course, predicate))
                xml_cde = xml_course.xpath(element, namespaces=XMLNS)
                self.assertEqual(len(rdf_cde), len(xml_cde), "Missing {0} for {1}".format(element, course))
                if len(rdf_cde) == 1:
                    self.assertComplexEqual(rdf_cde[0], xml_cde[0])
                elif len(rdf_cde) > 1:
                    raise AssertionError("More than one descriptive element: %s" % element)

def load_tests(loader, tests, pattern):
    suite = unittest.TestSuite()
    for name, filename in filenames:
        test_class = type('{0}TestCase'.format(name),
                          (XSLTTestCase,),
                          {'filename': filename})
        tests = loader.loadTestsFromTestCase(test_class)
        suite.addTests(tests)
    return suite


if __name__ == '__main__':
    unittest.main()
