<xsl:stylesheet xmlns="http://www.tei-c.org/ns/1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" xpath-default-namespace="http://www.tei-c.org/ns/1.0" exclude-result-prefixes="tei" version="2.0">
    <xsl:output method="xml" encoding="UTF-8"/>
    <xsl:variable name="TITLE" select="//tei:title/text()"/>
    <xsl:template match="/">
         <xsl:apply-templates/>
   </xsl:template>
   <xsl:template match="(tei:div2|tei:div1|tei:lb|tei:add)[not(@xml:id)]">
      <xsl:element name="{name()}">
         <xsl:copy-of select="@*"/>
         <xsl:attribute name="xml:id">
          <xsl:value-of select="concat($TITLE,'_',generate-id())"/>
        </xsl:attribute>
        <xsl:apply-templates/>
      </xsl:element>
   </xsl:template>
   <xsl:template match="*">
      <xsl:element name="{name()}">
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates/>
      </xsl:element>
   </xsl:template>
</xsl:stylesheet>
