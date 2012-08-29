<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
  <!ENTITY xsd "http://www.w3.org/2001/XMLSchema#">
]>
<xsl:stylesheet version="2.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
    xmlns:skos="http://www.w3.org/2004/02/skos/core#"
    xmlns:cc="http://creativecommons.org/ns#"
    xmlns:dcterms="http://purl.org/dc/terms/"
    xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0"
    xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0"
    xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0">
  <xsl:output method="xml" indent="yes"/>

  <xsl:variable name="scheme-uri">http://id.vitae.ac.uk/rdf/concept-scheme</xsl:variable>
  <xsl:variable name="notation-uri">http://id.vitae.ac.uk/rdf/notation</xsl:variable>
  <xsl:variable name="concept-uri-base">http://id.vitae.ac.uk/rdf/descriptor/</xsl:variable>

  <xsl:template match="/">
    <xsl:variable name="simplified">
      <xsl:apply-templates select=".//table:table[@table:name='Descriptors']" mode="simplify"/>
    </xsl:variable>
    <rdf:RDF>
      <xsl:apply-templates select="$simplified/table"/>
<!--      <xsl:copy-of select="$simplified"/>-->
    </rdf:RDF>
  </xsl:template>

  <xsl:template match="@*|*|text()" mode="simplify"/>

  <xsl:template match="table:table" mode="simplify">
    <table>
      <xsl:apply-templates select="table:table-row" mode="simplify"/>
    </table>
  </xsl:template>

  <xsl:template match="table:table-row" mode="simplify">
    <row>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates select="table:table-cell|table:covered-table-cell" mode="simplify"/>
    </row>
  </xsl:template>

  <xsl:template match="table:table-cell" mode="simplify">
    <xsl:variable name="count">
      <xsl:choose>
        <xsl:when test="@table:number-columns-spanned">
          <xsl:value-of select="@table:number-columns-spanned"/>
        </xsl:when>
        <xsl:when test="@table:number-columns-repeated">
          <xsl:value-of select="@table:number-columns-repeated"/>
        </xsl:when>
        <xsl:otherwise>1</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:if test="following-sibling::* or *">
      <xsl:call-template name="simplify-cell">
        <xsl:with-param name="count" select="$count"/>
        <xsl:with-param name="repeated">false</xsl:with-param>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <xsl:template name="simplify-cell">
    <xsl:param name="count"/>
    <xsl:param name="repeated"/>
    <cell repeated="{$repeated}">
      <xsl:copy-of select="@*|*"/>
    </cell>
    <xsl:if test="$count &gt; 1">
      <xsl:call-template name="simplify-cell">
        <xsl:with-param name="count" select="$count - 1"/>
        <xsl:with-param name="repeated">true</xsl:with-param>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <xsl:template match="table">
    <skos:ConceptScheme rdf:about="{$scheme-uri}">
      <skos:prefLabel xml:lang="en">Vitae Researcher Development Framework</skos:prefLabel>
      <skos:altLabel>Vitae RDF</skos:altLabel>
      <rdfs:comment>The Researcher Development Framework (RDF) is a major new approach to researcher development, to enhance our capacity to build the UK workforce, develop world-class researchers and build our research base.

The RDF is a professional development framework for planning, promoting and supporting the personal, professional and career development of researchers in higher education. It articulates the knowledge, behaviours and attributes of successful researchers and encourages them to realise their potential.</rdfs:comment>
      <cc:attributionName>Vitae, Careers and Advisory Centre (CRAC), Limited</cc:attributionName>
      <cc:attributionURL rdf:resource="http://www.vitae.ac.uk/rdf"/>
      <dcterms:license>
        <dcterms:LicenseDocument rdf:about="http://www.vitae.ac.uk/researchers/274251/RDF-conditions-of-use.html">
        </dcterms:LicenseDocument>
      </dcterms:license>

      <xsl:for-each-group select="row[position() &gt; 2]" group-starting-with="row[cell[1]/text:p]">
        <skos:hasTopConcept>
          <xsl:apply-templates select="." mode="domain"/>
        </skos:hasTopConcept>
      </xsl:for-each-group>
    </skos:ConceptScheme>
  </xsl:template>

  <xsl:template match="row" mode="domain">
    <xsl:variable name="notation" select="cell[1]/text:p/text()"/>
    <skos:Concept rdf:about="{$concept-uri-base}{$notation}">
      <skos:prefLabel>
        <xsl:value-of select="cell[2]/text:p/text()"/>
      </skos:prefLabel>
      <skos:notation rdf:datatype="{$notation-uri}">
        <xsl:value-of select="$notation"/>
      </skos:notation>
      <skos:inScheme rdf:resource="{$scheme-uri}"/>
      <xsl:for-each-group select="current-group()" group-starting-with="row[cell[3][@office:value]]">
        <skos:narrower>
          <xsl:apply-templates select="." mode="subdomain">
            <xsl:with-param name="notation" select="concat($notation, '.', cell[3]/text:p/text())"/>
          </xsl:apply-templates>
        </skos:narrower>
      </xsl:for-each-group>
    </skos:Concept>
  </xsl:template>

  <xsl:template match="row" mode="subdomain">
    <xsl:param name="notation"/>
    <skos:Concept rdf:about="{$concept-uri-base}{$notation}">
      <skos:prefLabel>
        <xsl:value-of select="cell[4]/text:p/text()"/>
      </skos:prefLabel>
      <skos:notation rdf:datatype="{$notation-uri}">
        <xsl:value-of select="$notation"/>
      </skos:notation>
      <skos:inScheme rdf:resource="{$scheme-uri}"/>
      <xsl:for-each-group select="current-group()" group-starting-with="row[cell[5][@office:value]]">
        <skos:narrower>
          <xsl:apply-templates select="." mode="subsubdomain">
            <xsl:with-param name="notation" select="concat($notation, '.', cell[5]/text:p/text())"/>
          </xsl:apply-templates>
        </skos:narrower>
      </xsl:for-each-group>
    </skos:Concept>
  </xsl:template>

  <xsl:template match="row" mode="subsubdomain">
    <xsl:param name="notation"/>
    <skos:Concept rdf:about="{$concept-uri-base}{$notation}">
      <skos:prefLabel>
        <xsl:value-of select="cell[6]/text:p/text()"/>
      </skos:prefLabel>
      <skos:notation rdf:datatype="{$notation-uri}">
        <xsl:value-of select="$notation"/>
      </skos:notation>
      <skos:inScheme rdf:resource="{$scheme-uri}"/>
      <xsl:for-each select="cell[position() &gt; 6]">
        <xsl:if test="@repeated = 'false'">
          <skos:narrower>
            <skos:Concept rdf:about="{$concept-uri-base}{$notation}.{position()}">
              <skos:prefLabel>
                <xsl:text>Phase</xsl:text>
                <xsl:if test="@table:number-columns-spanned &gt; 1">s</xsl:if>
                <xsl:text> </xsl:text>
                <xsl:value-of select="position()"/>
                <xsl:if test="@table:number-columns-spanned &gt; 1">
                  <xsl:text>–</xsl:text>
                  <xsl:value-of select="position() + @table:number-columns-spanned - 1"/>
                </xsl:if>
                <xsl:text> of </xsl:text>
                <xsl:value-of select="../cell[6]/text:p/text()"/>
              </skos:prefLabel>
              <skos:notation rdf:datatype="{$notation-uri}">
                <xsl:value-of select="concat($notation, '.', position())"/>
              </skos:notation>
              <skos:inScheme rdf:resource="{$scheme-uri}"/>
              <xsl:if test="text:p">
                <skos:definition>
                  <xsl:for-each select="text:p">
                    <xsl:if test="position() &gt; 1"><xsl:text>&#10;</xsl:text></xsl:if>
                    <xsl:value-of select="."/>
                  </xsl:for-each>
                </skos:definition>
              </xsl:if>
            </skos:Concept>
          </skos:narrower>
        </xsl:if>
      </xsl:for-each>
    </skos:Concept>
  </xsl:template>

  <xsl:template match="*|@*|text()"/>

</xsl:stylesheet>
