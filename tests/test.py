import os
import subprocess
import unittest

import rdflib

def relative_path(*args):
    return os.path.join(os.path.dirname(__file__), *args)

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

    def testTransform(self):
        self.graph


if __name__ == '__main__':
    unittest.main()
