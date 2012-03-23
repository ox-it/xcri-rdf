<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:html="http://www.w3.org/1999/xhtml#"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:skos="http://www.w3.org/2004/02/skos/core#"
    xmlns:gr="http://purl.org/goodrelations/v1#"
    xmlns:event="http://purl.org/NET/c4dm/event.owl#"
    xmlns:prog="http://purl.org/prog/"
    xmlns:tl="http://purl.org/NET/c4dm/timeline.owl#"
    xmlns:foaf="http://xmlns.com/foaf/0.1/"
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:dcterms="http://purl.org/dc/terms/"
    xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
    xmlns:mlo="http://purl.org/net/mlo/"
    xmlns:xcri="http://xcri.org/profiles/1.2/"
    xmlns="http://xcri.org/profiles/1.2/catalog"
    xpath-default-namespace="http://xcri.org/profiles/1.2/catalog">
  <xsl:output method="xml" indent="yes"/>

  <xsl:template match="*" mode="rdf-about">
    <!-- Override this to attach identifiers to your RDF resources. If you
         don't, you'll end up with blank nodes, which would be Bad. -->
    <xsl:variable name="identifier" select="dc:identifier[matches('^http:', text()) and not(@xsi:type)]"/>
    <xsl:if test="$identifier">
      <xsl:attribute name="rdf:about">
        <xsl:value-of select="$identifier[1]/text()"/>
      </xsl:attribute>
    </xsl:if>
  </xsl:template>

  <xsl:template match="/">
    <rdf:RDF>
      <xsl:apply-templates select="*"/>
    </rdf:RDF>
  </xsl:template>

  <xsl:template match="catalog">
    <xsl:apply-templates select="*"/>
  </xsl:template>

  <xsl:template match="provider">
    <xcri:provider>
      <xsl:apply-templates select="." mode="rdf-about"/>
      <xsl:apply-templates select="*"/>
    </xcri:provider>
  </xsl:template>

  <xsl:template match="course">
    <mlo:offers>
      <xcri:course>
        <xsl:apply-templates select="." mode="rdf-about"/>
        <xsl:apply-templates select="*"/>
      </xcri:course>
    </mlo:offers>
  </xsl:template>

  <xsl:template match="presentation">
    <mlo:specifies>
      <xcri:presentation>
        <xsl:apply-templates select="." mode="rdf-about"/>
        <xsl:apply-templates select="*"/>
      </xcri:presentation>
    </mlo:specifies>
  </xsl:template>

  <xsl:template match="dc:title">
    <rdfs:label>
      <xsl:value-of select="text()"/>
    </rdfs:label>
  </xsl:template>

  <xsl:template match="dc:description">
    <dcterms:description>
      <xsl:value-of select="text()"/>
    </dcterms:description>
  </xsl:template>

  <xsl:template match="mlo:url">
    <foaf:homepage rdf:resource="{text()}"/>
  </xsl:template>

  <xsl:template match="dc:identifier">
    <xsl:choose>
      <xsl:when test="@xsi:type and contains(@xsi:type, ':')">
        <xsl:variable name="prefix" select="substring-before(@xsi:type, ':')"/>
        <xsl:variable name="localpart" select="substring-after(@xsi:type, ':')"/>
        <xsl:choose>
          <xsl:when test="$prefix and index-of(in-scope-prefixes(.), $prefix)">
            <skos:notation rdf:datatype="{concat(namespace-uri-for-prefix($prefix, .), $localpart)}">
              <xsl:value-of select="text()"/>
            </skos:notation>
          </xsl:when>
          <xsl:otherwise>
            <xsl:message>Prefix "<xsl:value-of select="$prefix"/>" not defined.</xsl:message>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <dcterms:identifier>
          <xsl:value-of select="text()"/>
        </dcterms:identifier>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="*|@*|text()|processing-instruction()"/>
</xsl:stylesheet>

