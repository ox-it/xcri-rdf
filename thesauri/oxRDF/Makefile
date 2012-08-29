
all: oxRDF.rdf

clean:
	rm -f content.xml oxRDF.rdf

content.xml:
	unzip -o oxRDF.ods content.xml

oxRDF.rdf: content.xml
	saxon content.xml oxRDF.xsl > oxRDF.rdf

