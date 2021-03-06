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
    xmlns:ex="http://example.org/"
    xmlns:dcterms="http://purl.org/dc/terms/"
    xmlns:foaf="http://xmlns.com/foaf/0.1/"
    xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0"
    xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0"
    xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0">
  <xsl:output method="xml" indent="yes"/>

  <xsl:variable name="scheme-uri">https://data.ox.ac.uk/id/ox-rdf/concept-scheme</xsl:variable>
  <xsl:variable name="notation-uri">https://data.ox.ac.uk/id/ox-rdf/notation</xsl:variable>
  <xsl:variable name="concept-uri-base">https://data.ox.ac.uk/id/ox-rdf/descriptor/</xsl:variable>
  <xsl:variable name="domain-uri-base">https://data.ox.ac.uk/id/ox-rdf/domain/</xsl:variable>
  <xsl:variable name="vitae-concept-uri-base">http://id.vitae.ac.uk/rdf/descriptor/</xsl:variable>

  <xsl:function name="ex:slugify">
    <xsl:param name="term"/>
    <xsl:choose>
      <xsl:when test="contains($term, '(')">
        <xsl:value-of select="ex:slugify(substring-before($term, '('))"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="replace(lower-case(normalize-space($term)), '[^a-z0-9]+', '-')"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:template match="/">
    <xsl:variable name="simplified">
      <xsl:apply-templates select=".//table:table[1]" mode="simplify"/>
    </xsl:variable>
    <rdf:RDF>
      <xsl:apply-templates select="$simplified/table"/>
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

  <xsl:template match="table:table-cell|table:covered-table-cell" mode="simplify">
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
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <xsl:template name="simplify-cell">
    <xsl:param name="count"/>
    <xsl:param name="repeated"/>
    <cell>
      <xsl:if test="self::table:covered-table-cell">
        <xsl:attribute name="covered">true</xsl:attribute>
      </xsl:if>
      <xsl:if test="$repeated">
        <xsl:attribute name="repeated">true</xsl:attribute>
      </xsl:if>
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
    <foaf:Document rdf:about="">
      <cc:attributionName>University of Oxford</cc:attributionName>
      <cc:attributionURL rdf:resource="https://data.ox.ac.uk/doc/ox-rdf/concept-scheme"/>
      <dcterms:license rdf:resource="http://creativecommons.org/publicdomain/zero/1.0/"/>
    </foaf:Document>

    <skos:ConceptScheme rdf:about="{$scheme-uri}">
      <skos:prefLabel xml:lang="en">Oxford Skills Classification</skos:prefLabel>
      <skos:altLabel>OxSC</skos:altLabel>
      <rdfs:comment>The Oxford Skills Classification is a simple way to categorize skills courses by subject area.</rdfs:comment>
      <cc:attributionName>University of Oxford</cc:attributionName>
      <cc:attributionURL rdf:resource="https://data.ox.ac.uk/doc/ox-rdf/concept-scheme"/>
      <dcterms:license rdf:resource="http://creativecommons.org/publicdomain/zero/1.0/"/>

      <skos:hasTopConcept>
        <skos:Concept rdf:about="{$concept-uri-base}RD">
          <skos:prefLabel>General Researcher Development</skos:prefLabel>
          <skos:notation rdf:datatype="{$notation-uri}">RD</skos:notation>
          <skos:inScheme rdf:resource="{$scheme-uri}"/>
          <xsl:for-each-group select="row[position() &gt; 1]" group-starting-with="row[not(cell[1]/@covered)]">
            <xsl:if test="cell[1]/text:p/text()">
              <skos:narrower>
                <xsl:apply-templates select="." mode="gap-category"/>
              </skos:narrower>
            </xsl:if>
          </xsl:for-each-group>
        </skos:Concept>
      </skos:hasTopConcept>
      <skos:hasTopConcept>
        <skos:Concept rdf:about="{$domain-uri-base}top">
          <skos:prefLabel>Root skill domain</skos:prefLabel>
          <xsl:variable name="domains">
            <xsl:for-each select="row[position() gt 1]/cell[8][not(@covered)]">
              <xsl:for-each select="tokenize(text:p/text(), ';')">
                <domain>
                  <xsl:value-of select="normalize-space(.)"/>
                </domain>
              </xsl:for-each>
            </xsl:for-each>
          </xsl:variable>

          <xsl:for-each-group select="$domains/domain/text()" group-by=".">
            <skos:narrower>
              <skos:Concept rdf:about="{$domain-uri-base}{ex:slugify(.)}">
                <skos:prefLabel>
                  <xsl:value-of select="."/>
                </skos:prefLabel>
              </skos:Concept>
            </skos:narrower>
          </xsl:for-each-group>
        </skos:Concept>
      </skos:hasTopConcept>
    </skos:ConceptScheme>
  </xsl:template>

  <xsl:template match="row" mode="gap-category">
    <xsl:variable name="notation" select="cell[1]/text:p/text()"/>
    <skos:Concept rdf:about="{$concept-uri-base}{$notation}">
      <skos:prefLabel>
        <xsl:value-of select="cell[2]/text:p/text()"/>
      </skos:prefLabel>
      <skos:notation rdf:datatype="{$notation-uri}">
        <xsl:value-of select="$notation"/>
      </skos:notation>
      <skos:definition>
        <xsl:value-of select="cell[7]/text:p/text()"/>
      </skos:definition>
      <xsl:for-each select="tokenize(cell[8], ';')">
        <skos:related rdf:resource="{$domain-uri-base}{ex:slugify(.)}"/>
      </xsl:for-each>

      <skos:inScheme rdf:resource="{$scheme-uri}"/>
<!-- This is not allowed, apparently.
      <xsl:for-each select="current-group()">
        <xsl:if test="cell[3]/text:p/text()">
          <xsl:for-each select="tokenize(cell[3]/text:p/text(), ' ')">
            <skos:narrower rdf:resource="{$vitae-concept-uri-base}{.}"/>
          </xsl:for-each>
        </xsl:if>
      </xsl:for-each>
      <xsl:for-each select="current-group()">
        <xsl:if test="cell[5]/text:p/text()">
          <skos:related rdf:resource="{$vitae-concept-uri-base}{cell[5]/text:p/text()}"/>
        </xsl:if>
      </xsl:for-each>
-->
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
