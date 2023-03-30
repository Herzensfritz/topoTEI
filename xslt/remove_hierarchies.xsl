<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.tei-c.org/ns/1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" xpath-default-namespace="http://www.tei-c.org/ns/1.0" exclude-result-prefixes="tei" version="2.0">
    <xsl:output method="xml" encoding="UTF-8"/>
    <xsl:param name="GENERIC_EDITOR" select="'knister0'"/>
    <xsl:template match="/">
         <xsl:apply-templates/>
   </xsl:template>
    <xsl:template match="tei:p">
         <xsl:apply-templates/>
   </xsl:template>
    <xsl:template match="tei:p[tei:lb]|tei:ab[tei:lb]">
      <xsl:variable name="TO" select="concat('HIERARCHY-', generate-id())"/>
      <xsl:element name="{name()}">
          <xsl:attribute name="spanTo">
                <xsl:value-of select="concat('#', $TO)"/>
            </xsl:attribute>
         <xsl:for-each select="@*">
            <xsl:attribute name="{name()}">
                    <xsl:value-of select="."/>
                </xsl:attribute>
         </xsl:for-each>
      </xsl:element>
      <xsl:apply-templates/>
      <xsl:element name="tei:anchor">
         <xsl:attribute name="xml:id">
                <xsl:value-of select="$TO"/>
            </xsl:attribute>
      </xsl:element>
   </xsl:template>
   <xsl:template match="tei:lb[empty(@n)]">
      <xsl:element name="{name()}">
         <xsl:attribute name="n">
                <xsl:value-of select="generate-id()"/>
            </xsl:attribute>
         <xsl:for-each select="@*">
            <xsl:attribute name="{name()}">
                    <xsl:value-of select="."/>
                </xsl:attribute>
         </xsl:for-each>
      </xsl:element>
   </xsl:template>
   <xsl:template match="tei:seg[tei:lb]|tei:subst[tei:lb]|tei:subst[child::*/tei:lb]|tei:addSpan[not(@spanTo)]">
      <xsl:variable name="TO" select="concat('HIERARCHY-', generate-id())"/>
      <xsl:element name="{name()}">
         <xsl:attribute name="spanTo">
                <xsl:value-of select="concat('#', $TO)"/>
            </xsl:attribute>
         <xsl:for-each select="@*">
            <xsl:attribute name="{name()}">
                    <xsl:value-of select="."/>
                </xsl:attribute>
         </xsl:for-each>
      </xsl:element>
      <xsl:apply-templates/>
      <xsl:element name="anchor">
         <xsl:attribute name="xml:id">
                <xsl:value-of select="$TO"/>
            </xsl:attribute>
      </xsl:element>
   </xsl:template>
   <xsl:template match="tei:del[tei:lb]|tei:add[tei:lb]">
      <xsl:variable name="TO" select="concat('TRANSFORM-', generate-id())"/>
      <xsl:element name="{concat(name(),'Span')}">
         <xsl:attribute name="spanTo">
                <xsl:value-of select="concat('#', $TO)"/>
            </xsl:attribute>
         <xsl:for-each select="@*">
            <xsl:attribute name="{name()}">
                    <xsl:value-of select="."/>
                </xsl:attribute>
         </xsl:for-each>
      </xsl:element>
       <xsl:apply-templates/>
      <xsl:element name="anchor">
         <xsl:attribute name="xml:id">
                <xsl:value-of select="$TO"/>
            </xsl:attribute>
      </xsl:element>
   </xsl:template>
   <xsl:template match="tei:add[not(@xml:id) and not(tei:lb)]">
      <xsl:element name="tei:add">
         <xsl:copy-of select="@*"/>
         <xsl:attribute name="tei:resp">
          <xsl:value-of select="concat('#', $GENERIC_EDITOR)"/>
        </xsl:attribute>
         <xsl:attribute name="xml:id">
          <xsl:value-of select="concat('TEMPORARY_ID_',generate-id())"/>
        </xsl:attribute>
        <xsl:apply-templates/>
      </xsl:element>
   </xsl:template>
      <xsl:template match="tei:lb[not(@xml:id)]">
      <xsl:element name="tei:lb">
         <xsl:copy-of select="@*"/>
         <xsl:attribute name="tei:resp">
          <xsl:value-of select="concat('#', $GENERIC_EDITOR)"/>
        </xsl:attribute>
         <xsl:attribute name="xml:id">
          <xsl:value-of select="concat('TEMPORARY_ID_',generate-id())"/>
        </xsl:attribute>
        <xsl:apply-templates/>
      </xsl:element>
   </xsl:template>
   <xsl:template match="*">
      <xsl:element name="{name()}">
         <xsl:for-each select="@*">
            <xsl:attribute name="{name()}">
                    <xsl:value-of select="."/>
                </xsl:attribute>
         </xsl:for-each>
         <xsl:apply-templates/>
      </xsl:element>
   </xsl:template>
</xsl:stylesheet>