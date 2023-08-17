<xsl:stylesheet xmlns="http://www.tei-c.org/ns/1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" xpath-default-namespace="http://www.tei-c.org/ns/1.0" exclude-result-prefixes="tei" version="2.0">
    <xsl:output method="xml" encoding="UTF-8"/>
    <xsl:variable name="TITLE" select="//tei:title/text()"/>
    <xsl:template match="/">
         <xsl:apply-templates/>
   </xsl:template>
   <xsl:template match="tei:div2|tei:div1">
      <xsl:variable name="id" select="if (@xml:id) then (@xml:id) else (generate-id())"/>
      <xsl:element name="{name()}">
         <xsl:copy-of select="@*"/>
         <xsl:element name="anchor">
            <xsl:attribute name="xml:id">
             <xsl:value-of select="concat($TITLE,'_',local-name(),'_',$id)"/>
           </xsl:attribute>
         </xsl:element>
        <xsl:apply-templates/>
      </xsl:element>
   </xsl:template>
   <xsl:template match="(tei:lb|tei:add|tei:fw|tei:head|tei:note)[not(@xml:id)]">
      <xsl:variable name="id" select="if (@n) then (@n) else (generate-id())"/>
      <xsl:variable name="name" select="if (@n) then (local-name()) else (concat(local-name(), '_'))"/>
      <xsl:element name="{name()}">
         <xsl:copy-of select="@*"/>
         <xsl:attribute name="xml:id">
          <xsl:value-of select="concat($TITLE,'_',$name,$id)"/>
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
