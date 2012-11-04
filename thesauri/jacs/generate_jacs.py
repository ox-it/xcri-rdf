import csv
import sys

import rdflib

BASE = rdflib.URIRef('http://jacs.dataincubator.org/')
SKOS = rdflib.Namespace('http://www.w3.org/2004/02/skos/core#')
RDF = rdflib.Namespace('http://www.w3.org/1999/02/22-rdf-syntax-ns#')
notation = rdflib.URIRef(BASE + 'notation')

def main(rows):
    # Skip the first two rows
    rows.next()
    rows.next()

    yield (BASE, RDF.type, SKOS.ConceptScheme)
    yield (BASE, SKOS.prefLabel, rdflib.Literal('JACS codes'))
    for row in rows:
        code, label, definition = row[:3]
        uri = rdflib.URIRef(BASE + code.lower())
        if len(code) == 1:
            yield (BASE, SKOS.hasTopConcept, uri)
        else:
            yield (rdflib.URIRef(BASE + code.lower()[0]), SKOS.narrower, uri)
        yield (uri, RDF.type, SKOS.Concept)
        yield (uri, SKOS.prefLabel, rdflib.Literal(label))
        yield (uri, SKOS.notation, rdflib.Literal(code, datatype=notation))
        if definition:
            yield (uri, SKOS.definition, rdflib.Literal(definition))

if __name__ == '__main__':
    graph = rdflib.ConjunctiveGraph()
    with open('jacs.csv') as f:
        for triple in main(csv.reader(f)):
            graph.add(triple)
    graph.serialize(sys.stdout, format='pretty-xml')
