<xsl:stylesheet xmlns="http://www.tei-c.org/ns/1.0" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="no"/>
  
 
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>
  <!--  <xsl:template match="tei:rdg[@wit='#Dm']">
    <xsl:variable name="id" select="concat('#', replace(@n, ',', '_lb'))"/>
    <xsl:element name="{local-name()}">
      <xsl:for-each select="@*">
           <xsl:variable name="attName" select="if (starts-with(name(),'xml:')) then (name()) else (local-name())"/>
           <xsl:attribute name="{$attName}">
             <xsl:value-of select="."/>
           </xsl:attribute>
      </xsl:for-each>
      <xsl:attribute name="source">
          <xsl:value-of select="$id"/>
      </xsl:attribute>
      <xsl:apply-templates/>
    </xsl:element>
  </xsl:template>-->
  <xsl:template match="tei:pb[empty(@edRef)]">
    <xsl:variable name="id" select="concat('E40_', @n)"/>
    <xsl:element name="{local-name()}">
      <xsl:for-each select="@*">
           <xsl:variable name="attName" select="if (starts-with(name(),'xml:')) then (name()) else (local-name())"/>
           <xsl:attribute name="{$attName}">
             <xsl:value-of select="."/>
           </xsl:attribute>
      </xsl:for-each>
      <xsl:attribute name="xml:id">
          <xsl:value-of select="$id"/>
      </xsl:attribute>
      <xsl:apply-templates/>
    </xsl:element>
  </xsl:template>

</xsl:stylesheet>
