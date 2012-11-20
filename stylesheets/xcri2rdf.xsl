<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
  <!ENTITY xsd "http://www.w3.org/2001/XMLSchema#">
  <!ENTITY xhtml "http://www.w3.org/1999/xhtml">
  <!ENTITY xtypes "http://purl.org/xtypes/">
]>
<xsl:stylesheet version="2.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xhtml="http://www.w3.org/1999/xhtml#"
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
    xmlns:xmlo="http://purl.org/net/mlo"
    xmlns:xcri="http://xcri.org/profiles/1.2/"
    xmlns:geo="http://www.w3.org/2003/01/geo/wgs84_pos#"
    xmlns:v="http://www.w3.org/2006/vcard/ns#"
    xmlns:time="http://www.w3.org/2006/time#"
    xmlns="http://xcri.org/profiles/1.2/catalog"
    xpath-default-namespace="http://xcri.org/profiles/1.2/catalog">
  <xsl:import href="xml-to-string.xsl"/>
  <xsl:output method="xml" indent="yes"/>

  <xsl:param name="order-annotation"/>
  <xsl:variable name="publisher-uri"/>

  <xsl:template match="*" mode="rdf-about-attribute">
    <xsl:variable name="value">
      <xsl:apply-templates select="." mode="rdf-about"/>
    </xsl:variable>
    <xsl:choose>
     <xsl:when test="$value/text()">
       <xsl:attribute name="rdf:about">
         <xsl:value-of select="$value"/>
       </xsl:attribute>
     </xsl:when>
     <xsl:otherwise>
       <xsl:attribute name="rdf:nodeID">
         <xsl:value-of select="generate-id()"/>
       </xsl:attribute>
     </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="*" mode="rdf-resource-attribute">
    <xsl:variable name="value">
      <xsl:apply-templates select="." mode="rdf-about"/>
    </xsl:variable>
    <xsl:choose>
     <xsl:when test="$value/text()">
       <xsl:attribute name="rdf:resource">
         <xsl:value-of select="$value"/>
       </xsl:attribute>
     </xsl:when>
     <xsl:otherwise>
       <xsl:attribute name="rdf:nodeID">
         <xsl:value-of select="generate-id()"/>
       </xsl:attribute>
     </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="*" mode="rdf-about">
    <!-- Override this to attach identifiers to your RDF resources. If you
         don't, you'll end up with blank nodes, which would be Bad. -->
    <xsl:variable name="identifier" select="dc:identifier[not(@xsi:type) and (starts-with(text(), 'http:') or starts-with(text(), 'https:'))]"/>
    <xsl:if test="$identifier">
        <xsl:value-of select="$identifier[1]/text()"/>
    </xsl:if>
  </xsl:template>

  <xsl:template match="xmlo:start|end" mode="rdf-about">
    <xsl:variable name="parentURI">
      <xsl:apply-templates select=".." mode="rdf-about"/>
    </xsl:variable>
    <xsl:if test="$parentURI/text()">
      <xsl:value-of select="concat($parentURI, '/', (if (self::xmlo:start) then 'start' else 'end'))"/>
    </xsl:if>
  </xsl:template>

  <xsl:template match="xmlo:applyFrom|xmlo:applyUntil" mode="rdf-about">
    <xsl:variable name="parentURI">
      <xsl:apply-templates select=".." mode="rdf-about"/>
    </xsl:variable>
    <xsl:if test="$parentURI/text()">
      <xsl:value-of select="concat($parentURI, '/', (if (self::xmlo:applyFrom) then 'applyFrom' else 'applyUntil'))"/>
    </xsl:if>
  </xsl:template>

  <xsl:template match="xmlo:location" mode="rdf-about">
    <xsl:variable name="parentURI">
      <xsl:apply-templates select=".." mode="rdf-about"/>
    </xsl:variable>
    <xsl:if test="$parentURI/text()">
      <xsl:value-of select="concat($parentURI, '/address')"/>
    </xsl:if>
  </xsl:template>

  <xsl:template match="venue" mode="rdf-about">
    <xsl:variable name="parentURI">
      <xsl:apply-templates select=".." mode="rdf-about"/>
    </xsl:variable>
    <xsl:variable name="identifier" select="provider/dc:identifier[not(@xsi:type) and (starts-with(text(), 'http:') or starts-with(text(), 'https:'))]"/>
    <xsl:choose>
      <xsl:when test="$identifier/text()">
        <xsl:value-of select="$identifier"/>
      </xsl:when>
      <xsl:when test="$parentURI/text()">
        <xsl:value-of select="concat($parentURI, '/venue')"/>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="xmlo:phone" mode="rdf-about">
    <xsl:variable name="parentURI">
      <xsl:apply-templates select="ancestor::provider[1]" mode="rdf-about"/>
    </xsl:variable>
    <xsl:if test="$parentURI/text()">
      <xsl:value-of select="concat($parentURI, '/phone')"/>
    </xsl:if>
  </xsl:template>


  <xsl:template match="/">
    <rdf:RDF>
      <xsl:apply-templates select="*"/>
    </rdf:RDF>
  </xsl:template>

  <xsl:template match="catalog">
    <xcri:catalog>
      <xsl:apply-templates select="." mode="rdf-about-attribute"/>
      <dcterms:publisher>
        <xsl:choose>
          <xsl:when test="$publisher-uri">
            <xsl:attribute name="rdf:resource">
              <xsl:value-of select="$publisher-uri"/>
            </xsl:attribute>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="provider[1]" mode="rdf-resource-attribute"/>
          </xsl:otherwise>
        </xsl:choose>
      </dcterms:publisher>
      <xsl:apply-templates select="*[not(self::provider)]"/>
      <xsl:apply-templates select="provider/course" mode="in-catalog"/>
    </xcri:catalog>
    <xsl:apply-templates select="provider"/>
  </xsl:template>

  <xsl:template match="catalog/provider">
      <xcri:provider>
        <xsl:apply-templates select="." mode="rdf-about-attribute"/>
        <xsl:apply-templates select="." mode="order-annotation"/>
        <xsl:apply-templates select="*[not(self::course)]"/>
        <xsl:for-each select="course">
          <mlo:offers>
            <xsl:apply-templates select="." mode="rdf-resource-attribute"/>
          </mlo:offers>
        </xsl:for-each>
      </xcri:provider>
  </xsl:template>

  <xsl:template match="course" mode="in-catalog">
    <skos:member>
      <xsl:apply-templates select="."/>
    </skos:member>
  </xsl:template>

  <xsl:template match="course">
    <xcri:course>
      <xsl:apply-templates select="." mode="rdf-about-attribute"/>
      <xsl:apply-templates select="." mode="order-annotation"/>
      <xsl:apply-templates select="@*|*"/>
    </xcri:course>
  </xsl:template>

  <xsl:template match="presentation">
    <mlo:specifies>
      <xcri:presentation>
        <xsl:apply-templates select="." mode="rdf-about-attribute"/>
        <xsl:apply-templates select="." mode="order-annotation"/>
        <xsl:apply-templates select="@*|*"/>
      </xcri:presentation>
    </mlo:specifies>
  </xsl:template>

  <xsl:template match="venue">
    <!-- There's no physical venue for an online course. -->
    <xsl:if test="not(../attendanceMode[@identifier = 'ON'])">
      <xcri:venue>
        <geo:SpatialThing>
          <xsl:apply-templates select="." mode="rdf-about-attribute"/>
          <xsl:apply-templates select="." mode="order-annotation"/>
          <xsl:apply-templates select="provider/*"/>
        </geo:SpatialThing>
      </xcri:venue>
    </xsl:if>
  </xsl:template>

  <xsl:template match="dc:title">
    <dcterms:title>
      <xsl:value-of select="text()"/>
    </dcterms:title>
  </xsl:template>

  <xsl:template match="dc:description|abstract|applicationProcedure|learningOutcome
                      |regulations|xmlo:assessment|xmlo:objective|xmlo:prerequisite">
    <xsl:variable name="elementName">
      <xsl:choose>
        <xsl:when test="self::dc:description">dcterms:description</xsl:when>
        <xsl:when test="namespace-uri(.) = 'http://xcri.org/profiles/1.2/catalog'">
          <xsl:value-of select="concat('xcri:', local-name(.))"/>
        </xsl:when>
        <xsl:when test="namespace-uri(.) = 'http://purl.org/net/mlo'">
          <xsl:value-of select="concat('mlo:', local-name(.))"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:message terminate="yes">You forgot to map an XCRI-CAP element name (<xsl:value-of select="name()"/>) into an RDF property.</xsl:message>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:element name="{$elementName}">
      <xsl:choose>
        <xsl:when test="@href">
          <xsl:attribute name="rdf:resource" select="@href"/>
        </xsl:when>
        <xsl:when test="*[1][namespace-uri() = '&xhtml;']">
          <xsl:attribute name="rdf:datatype">&xtypes;Fragment-XHTML</xsl:attribute>
          <xsl:call-template name="xml-to-string">
            <xsl:with-param name="node-set" select="*[1]"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:copy-of select="@xml:lang"/>
          <xsl:value-of select="text()"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:element>
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
      <!-- Ignore HTTP/HTTPS URIs -->
      <xsl:when test="matches(., '^https?:')"/>
      <xsl:when test="text()">
        <dcterms:identifier>
          <xsl:value-of select="text()"/>
        </dcterms:identifier>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="xmlo:location">
    <v:adr>
      <v:Address>
        <xsl:apply-templates select="." mode="rdf-about-attribute"/>
        <xsl:variable name="addressLines" select="xmlo:address[not(@xsi:type)]"/>
        <xsl:if test="count($addressLines) &gt; 0">
          <v:street-address><xsl:value-of select="$addressLines[1]"/></v:street-address>
        </xsl:if>
        <xsl:if test="count($addressLines) &gt; 2">
          <v:extended-address><xsl:value-of select="$addressLines[2]"/></v:extended-address>
        </xsl:if>
        <xsl:if test="count($addressLines) &gt; 1">
          <v:locality><xsl:value-of select="$addressLines[count($addressLines)]"/></v:locality>
        </xsl:if>
        <xsl:if test="xmlo:postcode">
          <v:postal-code><xsl:value-of select="xmlo:postcode"/></v:postal-code>
        </xsl:if>
      </v:Address>
    </v:adr>

    <!-- FIXME: this doesn't actually do the namespace look-up. -->
    <xsl:if test="xmlo:address[@xsi:type='geo:lat']">
      <geo:lat rdf:datatype="&xsd;float"><xsl:value-of select="xmlo:address[@xsi:type='geo:lat']"/></geo:lat>
    </xsl:if>
    <xsl:if test="xmlo:address[@xsi:type='geo:long']">
      <geo:long rdf:datatype="&xsd;float"><xsl:value-of select="xmlo:address[@xsi:type='geo:long']"/></geo:long>
    </xsl:if>

    <xsl:apply-templates select="xmlo:phone|xmlo:email"/>
  </xsl:template>

  <xsl:template match="catalog/provider/xmlo:location/xmlo:email">
    <v:email rdf:resource="mailto:{text()}"/>
  </xsl:template>

  <xsl:template match="catalog/provider/xmlo:location/xmlo:phone">
    <v:tel>
      <v:Voice>
        <xsl:apply-templates select="." mode="rdf-about-attribute"/>
        <rdf:value>
          <xsl:attribute name="rdf:resource">
            <xsl:call-template name="normalize-phone"/>
          </xsl:attribute>
        </rdf:value>
      </v:Voice>
    </v:tel>
  </xsl:template>

  <xsl:template name="normalize-phone">
    <xsl:value-of select="concat('tel:+44', replace(substring(text(), 2), ' ', ''))"/>
  </xsl:template>

  <xsl:template match="xmlo:start|end|applyFrom|applyUntil">
    <xsl:if test="(@dtf and string-length(@dtf))or text()">
    <xsl:variable name="element-name">
      <xsl:choose>
        <xsl:when test="self::xmlo:start">mlo:start</xsl:when>
        <xsl:when test="self::end">xcri:end</xsl:when>
        <xsl:when test="self::applyFrom">xcri:applyFrom</xsl:when>
        <xsl:when test="self::applyUntil">xcri:applyUntil</xsl:when>
      </xsl:choose>
    </xsl:variable>
    <xsl:element name="{$element-name}">
      <time:Instant>
        <xsl:apply-templates select="." mode="rdf-about-attribute"/>
        <xsl:if test="text()">
          <rdfs:label>
            <xsl:value-of select="text()"/>
          </rdfs:label>
        </xsl:if>
        <xsl:choose>
          <xsl:when test="@dtf and string-length(@dtf) &gt; 15">
            <time:inXSDDateTime rdf:datatype="&xsd;dateTime">
              <xsl:value-of select="replace(@dtf, ' ', 'T')"/>
            </time:inXSDDateTime>
          </xsl:when>
          <xsl:when test="matches(text(), '^\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}:\d{2}(Z|([-+]\d{2}:\d{2}))?$')">
            <time:inXSDDateTime rdf:datatype="&xsd;dateTime">
              <xsl:value-of select="replace(text(), ' ', 'T')"/>
            </time:inXSDDateTime>
          </xsl:when>
          <xsl:when test="@dtf and string-length(@dtf)">
            <rdf:value rdf:datatype="&xsd;date">
              <xsl:value-of select="@dtf"/>
            </rdf:value>
          </xsl:when>
          <xsl:when test="matches(text(), '^\d{4}-\d{2}-\d{2}$')">
            <rdf:value rdf:datatype="&xsd;date">
              <xsl:value-of select="text()"/>
            </rdf:value>
          </xsl:when>
        </xsl:choose>
      </time:Instant>
    </xsl:element>
    </xsl:if>
  </xsl:template>

  <xsl:template match="xmlo:url">
    <foaf:homepage rdf:resource="{text()}"/>
  </xsl:template>

  <xsl:template match="xmlo:places">
    <xsl:if test="text()">
      <mlo:places rdf:datatype="&xsd;int">
        <xsl:value-of select="text()"/>
      </mlo:places>
    </xsl:if>
  </xsl:template>

  <xsl:template match="attendanceMode[@identifier]">
    <xcri:attendanceMode rdf:resource="http://xcri.org/profiles/catalog/1.2/attendanceMode/{@identifier}"/>
  </xsl:template>
  <xsl:template match="attendancePattern[@identifier]">
    <xcri:attendancePattern rdf:resource="http://xcri.org/profiles/catalog/1.2/attendancePattern/{@identifier}"/>
  </xsl:template>
  <xsl:template match="studyMode">
    <xcri:studyMode rdf:resource="http://xcri.org/profiles/catalog/1.2/studyMode/{@identifier}"/>
  </xsl:template>

  <xsl:template match="dc:subject">
    <xsl:choose>
      <xsl:when test="@xsi:type and contains(@xsi:type, ':')">
        <xsl:variable name="prefix" select="substring-before(@xsi:type, ':')"/>
        <xsl:variable name="localpart" select="substring-after(@xsi:type, ':')"/>
        <xsl:choose>
          <xsl:when test="@xsi:type and index-of(('hesa:jacs', 'courseDataProgramme:JACS3'), @xsi:type)">
            <dcterms:subject rdf:resource="http://jacs.dataincubator.org/{lower-case(@identifier)}"/>
          </xsl:when>
          <xsl:when test="$prefix and index-of(in-scope-prefixes(.), $prefix)">
            <dcterms:subject>
              <skos:Concept>
                <rdfs:label>
                  <xsl:value-of select="text()"/>
                </rdfs:label>
                <skos:notation rdf:datatype="{concat(namespace-uri-for-prefix($prefix, .), $localpart)}">
                  <xsl:value-of select="@identifier"/>
                </skos:notation>
              </skos:Concept>
            </dcterms:subject>
          </xsl:when>
          <xsl:otherwise>
            <xsl:message>Prefix "<xsl:value-of select="$prefix"/>" not defined.</xsl:message>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <dc:subject>
          <xsl:value-of select="text()"/>
        </dc:subject>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="applyTo">
    <xcri:applyTo rdf:resource="{text()}"/>
  </xsl:template>

  <xsl:template match="*" mode="order-annotation">
    <xsl:if test="$order-annotation">
      <xcri:x-order rdf:datatype="&xsd;int">
        <xsl:value-of select="count(preceding::*)"/>
      </xcri:x-order>
    </xsl:if>
  </xsl:template>

  <xsl:template match="*|@*|text()|processing-instruction()"/>
</xsl:stylesheet>

