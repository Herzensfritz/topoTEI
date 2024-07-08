<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" 
    xmlns:xs="http://www.w3.org/2001/XMLSchema" version="2.0">
    <xsl:output method="text"/>
    <xsl:strip-space elements="*"/>
    <xsl:template match="//tei:handNotes">
        <xsl:variable name="numHands" select="count(tei:handNote)"/>
        <xsl:text>{&#10;  "hand":&#10;  {&#10;</xsl:text>
            <xsl:for-each select="tei:handNote">
               <xsl:variable name="info" select="if (contains(text(), '(')) then (concat('(', substring-after(text(), '('))) else (concat('(', @scribe,')'))"/>
               <xsl:text>        "</xsl:text><xsl:value-of select="@xml:id"/><xsl:text>":"</xsl:text><xsl:value-of select="concat(@medium,' ', $info)"/><xsl:text>"</xsl:text>
               <xsl:if test="position() lt $numHands"><xsl:text>,&#10;</xsl:text></xsl:if>
            </xsl:for-each>
        <xsl:text> &#10;}&#10;}</xsl:text>
    </xsl:template>
    <xsl:template match="text()"/>
    <xsl:template match="tei:note"/>
</xsl:stylesheet>
