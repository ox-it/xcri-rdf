
all: vitaeRDF.rdf

clean:
	rm -f content.xml vitaeRDF.rdf

content.xml:
	unzip -o vitaeRDF.ods content.xml

vitaeRDF.rdf: content.xml
	saxon content.xml vitaeRDF.xsl > vitaeRDF.rdf

