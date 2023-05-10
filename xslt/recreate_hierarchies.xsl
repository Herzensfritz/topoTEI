<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.tei-c.org/ns/1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" version="2.0">
    <xsl:output method="xml" encoding="UTF-8" indent="yes"/>
    <xsl:param name="GENERIC_EDITOR" select="'knister0'"/>
    <!--<xsl:template match="*[following-sibling::tei:p[1][@spanTo]]">
       <xsl:copy-of select="."/>
    </xsl:template>-->
    <xsl:template match="*[@spanTo and contains(@spanTo, 'HIERARCHY')]">
       <xsl:param name="id"/>
       <xsl:variable name="process" select="tei:processNode(preceding-sibling::*[@spanTo and contains(@spanTo, 'HIERARCHY')]/@spanTo, following-sibling::tei:anchor[contains(@xml:id, 'HIERARCHY')]/@xml:id, $id)"/>
       <!--<test name="{local-name()}" id="{$id}" spanTo="{@spanTo}"><xsl:value-of select="$process"/></test>-->
       <xsl:if test="$process = 1">
          <xsl:variable name="currentId" select="substring-after(current()/@spanTo, '#')"/>
          <xsl:element name="{local-name()}">
              <xsl:for-each select="@*">
                  <xsl:if test="not(contains(., 'HIERARCHY')) and . != concat('#', $GENERIC_EDITOR)">
                     <xsl:variable name="attName" select="if (name() = 'xml:id') then ('xml:id') else (local-name())"/>
                    <xsl:attribute name="{$attName}">
                      <xsl:value-of select="."/>
                    </xsl:attribute>
                 </xsl:if>
               </xsl:for-each>
               <xsl:apply-templates select="following-sibling::tei:anchor[@xml:id = $currentId]/preceding-sibling::*[count(preceding-sibling::*[@spanTo = concat('#', $currentId)])=1]
                  |following-sibling::tei:anchor[@xml:id = $currentId]/preceding-sibling::text()[count(preceding-sibling::*[@spanTo = concat('#', $currentId)])=1]">
                   <xsl:with-param name="id" select="$currentId"/>
               </xsl:apply-templates>
          </xsl:element>
       </xsl:if>
   </xsl:template>
   <xsl:function name="tei:processNode">
      <xsl:param name="spanTo"/>
      <xsl:param name="xmlId"/>
      <xsl:param name="parentId"/>
      <xsl:variable name="indexOfSpanTo" select="index-of($spanTo, concat('#', $parentId))"/>
      <xsl:variable name="indexOfXmlId" select="index-of($xmlId, $parentId)"/>
      <xsl:variable name="subSpanTo" select="subsequence($spanTo, number($indexOfSpanTo)+1)"/>
      <xsl:variable name="subXmlId" select="subsequence($xmlId, 1, number($indexOfXmlId)-1)"/>
      <xsl:variable name="isEnclosed" select="tei:seqContains($spanTo, $xmlId)"/>
      <xsl:choose>
         <xsl:when test="$isEnclosed = 0 or ($isEnclosed = 1 and (empty($parentId) or $parentId = ''))">
            <xsl:value-of select="if ($isEnclosed = 0) then (1) else (0)"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:value-of select="if((number($indexOfSpanTo) gt 0 and number($indexOfXmlId) gt 0) 
            and tei:seqContains($subSpanTo, $subXmlId) = 0) then (1) else (0)"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   <xsl:function name="tei:seqContains">
      <xsl:param name="spanTo"/>
      <xsl:param name="xmlId"/>
      <xsl:choose>
         <xsl:when test="count($xmlId) = 0 or count($spanTo) = 0 or number(index-of($xmlId, substring-after($spanTo[1], '#'))) gt 0">
            <xsl:value-of select="if (count($xmlId) = 0 or count($spanTo) = 0) then (0) else (1)"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:value-of select="tei:seqContains(subsequence($spanTo, 2), $xmlId)"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   <xsl:template match="tei:note|tei:pc|tei:metamark|tei:milestone|tei:lb|tei:add|tei:del|tei:subst|tei:hi[not(contains(@spanTo, 'HIERARCHY'))]">
      <xsl:param name="id"/>
      <xsl:call-template name="writeNode"> 
	      <xsl:with-param name="id" select="$id"/>
	      <xsl:with-param name="tagname" select="local-name()"/>
       </xsl:call-template>
   </xsl:template>
   <xsl:template match="text()">
      <xsl:param name="id"/>
      <xsl:variable name="spanTo" select="preceding-sibling::*[@spanTo and contains(@spanTo, 'HIERARCHY')]/@spanTo"/>
      <xsl:variable name="xmlId" select="following-sibling::tei:anchor[contains(@xml:id, 'HIERARCHY')]/@xml:id"/>
      <xsl:variable name="process" select="tei:processNode($spanTo, $xmlId, $id)"/>

      <!--<test name="{local-name()}" id="{$id}" spanTo="{$spanTo}" xmlId="{$xmlId}" subSpanTo="{subsequence($spanTo, 2)}"
      subXmlId="{subsequence($xmlId, 1, number(index-of($xmlId, $id))-1)}"><xsl:value-of select="$process"/></test>-->
      <xsl:if test="number($process) = 1">
         <xsl:copy-of select="."/>
      </xsl:if>
   </xsl:template>
   <xsl:template name="writeNode">
      <xsl:param name="id"/>
      <xsl:param name="tagname"/>
      <xsl:if test="tei:processNode(preceding-sibling::*[@spanTo and contains(@spanTo, 'HIERARCHY')]/@spanTo, following-sibling::tei:anchor[contains(@xml:id, 'HIERARCHY')]/@xml:id, $id) = 1">
         <xsl:element name="{$tagname}">
            <xsl:for-each select="@*">
               <xsl:if test="not(starts-with(., 'TEMPORARY')) and . != concat('#', $GENERIC_EDITOR)">
               <xsl:attribute name="{name()}">
                       <xsl:value-of select="."/>
                   </xsl:attribute>
               </xsl:if>
            </xsl:for-each>
            <xsl:apply-templates select="node()">
               <xsl:with-param name="id" select="$id"/>
            </xsl:apply-templates>
         </xsl:element>
      </xsl:if>
   </xsl:template>
   <xsl:template match="tei:div1[@type='apparatus']|tei:pb|tei:fw">
      <xsl:copy-of select="."/>
   </xsl:template>
   <xsl:template match="tei:text|tei:div2|tei:div1|tei:div|tei:body">
      <xsl:element name="{local-name()}">
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

</xsl:stylesheet>
