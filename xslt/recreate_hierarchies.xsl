<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.tei-c.org/ns/1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" version="2.0">
    <xsl:output method="xml" encoding="UTF-8" indent="yes"/>
    <xsl:param name="GENERIC_EDITOR" select="'knister0'"/>
    <xsl:template match="tei:p[@spanTo]">
       <xsl:copy-of select="preceding-sibling::tei:*"/>
       <xsl:variable name="id" select="substring-after(current()/@spanTo, '#')"/>
       <test><xsl:value-of select="name()"/></test>
       <xsl:call-template name="createHierarchy"> 
	      <xsl:with-param name="id" select="$id"/>
	      <xsl:with-param name="tagname" select="local-name()"/>
	      <xsl:with-param name="tag" select="name()"/>
       </xsl:call-template>
   </xsl:template>
   <xsl:template name="createHierarchy">
      <xsl:param name="id"/>
      <xsl:param name="tagname"/>
      <xsl:param name="tag"/>
         <xsl:element name="{$tagname}">
            <xsl:for-each select="@*">
               <xsl:if test="not(contains(., 'HIERARCHY')) and . != concat('#', $GENERIC_EDITOR)">
                  <xsl:variable name="attName" select="if (name() = 'xml:id') then ('xml:id') else (local-name())"/>
                 <xsl:attribute name="{$attName}">
                   <xsl:value-of select="."/>
                 </xsl:attribute>
              </xsl:if>
            </xsl:for-each>
            <xsl:call-template name="all">
               <xsl:with-param name="nodes" select="following-sibling::tei:anchor[@xml:id = $id]/preceding-sibling::*[count(preceding-sibling::*[@spanTo = concat('#', $id)])=1]
               |following-sibling::tei:anchor[@xml:id = $id]/preceding-sibling::text()[count(preceding-sibling::*[@spanTo = concat('#', $id)])=1]"/>
            </xsl:call-template>
         </xsl:element>
   </xsl:template>
   <xsl:template name="all">
      <xsl:param name="nodes"/>
      <xsl:for-each select="$nodes">
         <xsl:choose>
            <xsl:when test="@spanTo">
               <xsl:variable name="id" select="substring-after(@spanTo, '#')"/>
               <xsl:call-template name="createHierarchy">
                  <xsl:with-param name="id" select="$id"/>
                  <xsl:with-param name="tagname" select="local-name()"/>
                  <xsl:with-param name="tag" select="name()"/>
               </xsl:call-template>
            </xsl:when>
            <xsl:when test="local-name() = 'anchor' and index-of(preceding-sibling::*[@spanTo]/@spanTo, concat('#', @xml:id))"/>
            <xsl:when test=". instance of text() and following-sibling::*[1][local-name() = 'anchor'] and index-of(preceding-sibling::*[@spanTo]/@spanTo, concat('#', following-sibling::tei:anchor[1]/@xml:id))">
               <between><xsl:copy-of select="."/></between>
            </xsl:when>
            <xsl:when test="not(starts-with(@xml:id, 'TEMPORARY') or current()/*[starts-with(@xml:id, 'TEMPORARY')])">
               <xsl:copy-of select="."/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:element name="{name()}">
                  <xsl:for-each select="@*">
                     <xsl:if test="not(starts-with(., 'TEMPORARY')) and . != concat('#', $GENERIC_EDITOR)">
                        <xsl:variable name="attName" select="if (name() = 'xml:id') then ('xml:id') else (local-name())"/>
                       <xsl:attribute name="{$attName}">
                         <xsl:value-of select="."/>
                       </xsl:attribute>
                    </xsl:if>
                  </xsl:for-each>
                  <xsl:call-template name="all">
                     <xsl:with-param name="nodes" select="current()/*|text()"/>
                  </xsl:call-template>
               </xsl:element>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:for-each>
   </xsl:template>


   <xsl:template match="tei:div1[@type='apparatus']|tei:pb|tei:fw">
      <xsl:copy-of select="."/>
   </xsl:template>
   <xsl:template match="tei:text|tei:div2|tei:div1|tei:div|tei:body">
      <xsl:element name="{name()}">
         <xsl:for-each select="@*">
            <xsl:if test="not(starts-with(., 'TEMPORARY')) and . != concat('#', $GENERIC_EDITOR)">
            <xsl:attribute name="{name()}">
                    <xsl:value-of select="."/>
                </xsl:attribute>
            </xsl:if>
         </xsl:for-each>
         <xsl:apply-templates select="node()"/>
      </xsl:element>
   </xsl:template>
   <!-- <xsl:template match="tei:head">
         <xsl:copy-of select="."/>
   </xsl:template>-->
   <xsl:template match="tei:teiHeader">
      <xsl:choose>
         <xsl:when test="//tei:publicationStmt/tei:p">
            <xsl:copy-of select="."/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:call-template name="createHeader">
               <xsl:with-param name="title" select="//tei:title/text()"/>
            </xsl:call-template>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   <xsl:template name="createHeader">
      <xsl:param name="title"/>
      <teiHeader>
         <fileDesc>
         <titleStmt>
            <title>
                <xsl:value-of select="$title"/>
            </title>
             </titleStmt>
         <publicationStmt>
                    <p/>
                </publicationStmt>
                <sourceDesc>
                    <p/>
                </sourceDesc>
            </fileDesc>
      </teiHeader>
   </xsl:template>
   <xsl:template match="/">
      <TEI version="{tei:TEI/@version}">
         <xsl:apply-templates/>
      </TEI>
   </xsl:template>

   <xsl:template match="text()"/>
</xsl:stylesheet>
