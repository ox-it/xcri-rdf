<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
  <!ENTITY xsd "http://www.w3.org/2001/XMLSchema#">
]>
<xsl:stylesheet version="2.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:skos="http://www.w3.org/2004/02/skos/core#"
    xpath-default-namespace="http://www.imsglobal.org/xsd/imsvdex_v1p0">
  <xsl:output method="xml" indent="yes"/>

  <xsl:param name="scheme-uri">
    <xsl:value-of select="/vdex/vocabIdentifier/text()"/>
  </xsl:param>
  <xsl:param name="concept-uri-base">
    <xsl:value-of select="concat($scheme-uri, '/')"/>
  </xsl:param>
  <xsl:param name="notation-uri">
    <xsl:value-of select="concat($scheme-uri, '/notation')"/>
  </xsl:param>

  <xsl:template match="/">
    <rdf:RDF>
      <xsl:apply-templates select="vdex"/>
    </rdf:RDF>
  </xsl:template>

  <xsl:template match="vdex">
    <skos:ConceptScheme rdf:about="{$scheme-uri}">
      <skos:prefLabel>
        <xsl:value-of select="vocabName/langstring"/>
      </skos:prefLabel>
      <xsl:for-each select="term">
        <skos:hasTopConcept>
          <xsl:apply-templates select="."/>
        </skos:hasTopConcept>
      </xsl:for-each>
    </skos:ConceptScheme>
  </xsl:template>

  <xsl:template match="term">
    <skos:Concept rdf:about="{$concept-uri-base}{termIdentifier}">
      <skos:prefLabel>
        <xsl:value-of select="caption/langstring/text()"/>
      </skos:prefLabel>
      <skos:definition>
        <xsl:value-of select="description/langstring/text()"/>
      </skos:definition>
      <skos:inScheme rdf:resource="{$scheme-uri}"/>
      <skos:notation rdf:datatype="{$notation-uri}">
        <xsl:value-of select="termIdentifier/text()"/>
      </skos:notation>
    </skos:Concept>
  </xsl:template>
</xsl:stylesheet>
