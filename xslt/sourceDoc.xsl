<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" version="2.0">
   <xsl:import href="elementTemplates.xsl"/>
   <xsl:output method="html" encoding="UTF-8"/>
   <!-- Param 'resources' specifies the root folder for css and scripts -->
   <xsl:param name="resources" select="'resources'"/>
   <!-- Param 'fullpage' specifies whether output should be a standalone html page or just a transkription as part of a <div> -->
   <xsl:param name="fullpage" select="'true'"/>
   <xsl:param name="editorModus" select="'true'"/>
   <xsl:param name="facsimileUrl"/>
   <xsl:param name="fonts"/>
   <xsl:param name="fontLinks"/>
   <xsl:variable name="TITLE" select="//tei:titleStmt/tei:title"/>
   <!-- Transform root to html either as standalone or as part of a page depending on param 'fullpage' -->
   <xsl:template match="/">
      <xsl:choose>
         <xsl:when test="$fullpage = 'true'">
           <html>
              <head>
                  <title>
                      <xsl:value-of select="$TITLE"/>
                  </title>
                  
                  <xsl:for-each select="tokenize($fontLinks)">
                      <link href="{.}" rel="stylesheet" type="text/css"/>
                  </xsl:for-each>
                  <xsl:if test="$fonts">
                     <xsl:element name="style">
                        <xsl:value-of select="$fonts"/>
                     </xsl:element>
                  </xsl:if>
                  <link rel="stylesheet" href="{concat($resources, '/css/gui_style.css')}"/>
                  <script type="text/javascript" src="{concat($resources, '/scripts/gui_transcription.js')}"/>
              </head>
              <body>
                  <h1>Diplomatische Transkription: <xsl:value-of select="$TITLE"/>
                        </h1>
                  <xsl:apply-templates select="/tei:TEI/tei:text/tei:body"/>
              </body>
           </html>
         </xsl:when>
         <xsl:otherwise>
            <div>
                <xsl:choose>
                    <xsl:when test="$editorModus != 'false'">
                        <h1>Diplomatische Transkription: <xsl:value-of select="$TITLE"/>
                            </h1>
                    </xsl:when>
                    <xsl:otherwise>
                        <h2 id="{$TITLE}">
                                <xsl:value-of select="$TITLE"/>
                            </h2>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:if test="$facsimileUrl">
                    <a class="facsimileUrl" href="{$facsimileUrl}" target="_blank"><xsl:value-of select="$facsimileUrl"/></a>
                </xsl:if>
                <xsl:apply-templates select="/tei:TEI/tei:text/tei:body"/>
             </div>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   <!-- Process tei:div1: produce top forme work container, transkription and bottom forme work container -->
   <xsl:template match="tei:body/tei:div1">
      <!--<div class="fw-container">
         <xsl:apply-templates select="tei:fw[@place='top-left' or @place='top-right']"/>
      </div>-->
      <xsl:apply-templates select="//tei:sourceDoc/tei:surface[@start = concat('#', //tei:pb/@xml:id)]"/>
      <!--<div class="fw-container">
         <xsl:apply-templates select="tei:fw[@place='bottom-left']"/>
      </div>-->
   </xsl:template>
   <xsl:template match="tei:surface">
      <xsl:variable name="style" select="if (empty(@style) and tei:zone/tei:zone and not(tei:zone/tei:line)) then (concat('min-width: 56em;min-height: ', count(//tei:line)*3,'em;')) else (@style)"/>
      <div id="{@xml:id}" class="transkriptionField" style="{$style}">
         <xsl:apply-templates/>
      </div>
   </xsl:template>
   <xsl:template match="tei:zone">
      <xsl:variable name="zone" select="substring-after(@start, '#')"/>
      <xsl:element name="div">
         <xsl:if test="@xml:id and (empty(@type) or ends-with(@type, 'Block') or not(tei:line))">
            <xsl:attribute name="id">
               <xsl:value-of select="@xml:id"/>
            </xsl:attribute>
         </xsl:if>
         <xsl:if test="@style and (empty(@type) or ends-with(@type, 'Block') or not(tei:line))">
            <xsl:attribute name="style">
               <xsl:value-of select="@style"/>
            </xsl:attribute>
         </xsl:if>
         <xsl:if test="@type">
            <xsl:variable name="class" select="if (ends-with(@type,'Block') and not(starts-with(@type, 'text'))) then (concat(@type, ' textBlock')) else (@type)"/>
            <xsl:attribute name="class">
               <xsl:value-of select="$class"/>
            </xsl:attribute>
         </xsl:if>
         <xsl:choose>
            <xsl:when test="tei:line|tei:zone">
               <xsl:apply-templates>
                  <xsl:with-param name="zoneId" select="$zone"/>
               </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
               <xsl:call-template name="zoneItems">
                  <xsl:with-param name="id" select="$zone"/>
               </xsl:call-template>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:element>
   </xsl:template>
  
   <xsl:template match="tei:line">
      <div id="{@xml:id}" class="line empty" style="{@style}">
      </div>
   </xsl:template>
   <xsl:template match="tei:line[@start]">
      <xsl:param name="zoneId"/>
      <xsl:variable name="lineClass" select="if (empty(parent::tei:zone/@type) or ends-with(parent::tei:zone/@type, 'Block')) then ('line') else ('zoneLine')"/>
      <xsl:variable name="startId" select="substring-after(@start, '#')"/>
      <xsl:variable name="endId" select="if (following::tei:line[@start]) then (substring-after(following::tei:line[@start][1]/@start, '#')) else (if (parent::tei:zone/following-sibling::tei:*[1]/local-name() = 'line') then (substring-after(parent::tei:zone/following-sibling::tei:line[@start][1]/@start, '#'))        else (substring-after(parent::tei:zone/following-sibling::tei:zone[1]/tei:line[@start][1]/@start,'#')))"/>
      <xsl:variable name="isZone" select="if (contains(parent::tei:zone/@type, 'zone') or tei:zone/@type = 'head' or tei:zone/@type = 'flushRight') then ('true') else ('false')"/>
      <!--<xsl:variable name="isInline" select="if (($isZone = 'true' and not(tei:zone/@type = 'head' or tei:zone/@type = 'flushRight')) 
      and (($endId and count(//tei:add[preceding::tei:lb[1]/@xml:id = $startId and following::tei:lb[1]/@xml:id = $endId and (empty(@place) or @place='inline')]) gt 0) 
      or (count(//tei:add[preceding::tei:lb[1]/@xml:id = $startId and (empty(@place) or @place='inline')]) gt 0))) then ('true') else ('false')"/> -->
      <xsl:variable name="isInline" select="if (($isZone = 'true' and not(tei:zone/@type = 'head' or tei:zone/@type = 'flushRight')) and (//tei:add[(empty(@place) or @place='inline') and not(@instant='true') and child::tei:lb[@xml:id = $startId]])) then ('true') else ('false')"/>
      <!-- old with 'inline' <xsl:variable name="spanType" select="replace(concat(@hand, ' ', @rend,' ',tei:zone/@type, ' ', if ($isInline = 'true') then ('inline') else ()), '#', '')"/> -->
      <xsl:variable name="spanType" select="replace(concat(@hand, ' ', @rend,' ',tei:zone/@type), '#', '')"/>
      <xsl:variable name="spanStyle" select="if ($isZone = 'true') then (         if (tei:zone/@xml:id) then (tei:zone/@style) else (parent::tei:zone/@style)) else ()"/>
      <xsl:element name="div">
         <xsl:attribute name="id">
            <xsl:value-of select="@xml:id"/>
         </xsl:attribute>
         <xsl:attribute name="class">
            <xsl:value-of select="$lineClass"/>
         </xsl:attribute>
         <xsl:attribute name="style">
            <xsl:value-of select="@style"/>
         </xsl:attribute>
         <xsl:if test="@type='zz-right'">
            <xsl:attribute name="data-right-line-number">
               <xsl:value-of select="//tei:lb[@xml:id = $startId]/@n"/>
            </xsl:attribute>
         </xsl:if>
         <xsl:call-template name="writeLineNumber">
            <xsl:with-param name="lineType" select="$lineClass"/>
            <xsl:with-param name="n" select="//tei:lb[@xml:id = $startId]/@n"/>
            <xsl:with-param name="zoneId" select="parent::tei:zone/@xml:id"/>
         </xsl:call-template>
         <xsl:element name="span">
            <xsl:call-template name="writeContentSpanAttributes">
              <xsl:with-param name="parentZoneId" select="if (tei:zone/@xml:id) then (tei:zone/@xml:id) else (parent::tei:zone/@xml:id)"/>
               <xsl:with-param name="isZone" select="$isZone"/>
               <xsl:with-param name="spanClass" select="normalize-space($spanType)"/>
               <xsl:with-param name="spanStyle" select="$spanStyle"/>
            </xsl:call-template>
            <xsl:element name="span">
               <xsl:if test="$isInline = 'true'">
                  <xsl:attribute name="class">
                     <xsl:value-of select="'inline'"/>
                  </xsl:attribute>
               </xsl:if>
               <xsl:choose>
                  <!-- Simple case: nodes/text between two lb -->
                  <xsl:when test="$endId and count(//(*|text())[preceding-sibling::tei:lb[@xml:id = $startId] and following-sibling::tei:lb[@xml:id = $endId]]) gt 0">
                        <xsl:apply-templates select="//(*|text())[preceding-sibling::tei:lb[@xml:id = $startId] and following-sibling::tei:lb[@xml:id = $endId]]">
                        <xsl:with-param name="startId" select="$startId"/>
                        <xsl:with-param name="id" select="$zoneId"/>
                        <xsl:with-param name="type" select="$SIMPLE_BETWEEN_TWO_LBS"/>
                     </xsl:apply-templates>
                  </xsl:when>
                  <!-- Hierarchical case 1: nodes/text between two lb, second lb inside a tag -->
                  <xsl:when test="$endId and count(//(*|text())[preceding-sibling::tei:lb[@xml:id = $startId]]/../node()//tei:lb[@xml:id = $endId]) gt 0">
                     <xsl:apply-templates select="//(*|text())[(preceding-sibling::tei:lb[@xml:id = $startId] or ancestor::*/preceding-sibling::tei:lb[@xml:id = $startId])                                                                             and (following-sibling::*//tei:lb[@xml:id = $endId] or following-sibling::tei:lb[@xml:id = $endId])]">
                        <xsl:with-param name="startId" select="$startId"/>
                        <xsl:with-param name="type" select="$SECOND_LB_INSIDE_TAG"/>
                     </xsl:apply-templates>
                  </xsl:when>
                  <!-- Hierarchical case 2: first lb inside a tag -->
                  <xsl:when test="$endId">
                        <xsl:choose>
                           <!-- Hierarchical case 2a: only one lb inside a tag -->
                           <xsl:when test="count(//(*|text())[preceding-sibling::tei:lb[@xml:id = $startId]]/../tei:lb[@xml:id = $endId]) eq 1">
                              <!--
                              <xsl:apply-templates select="//(*|text())[(preceding-sibling::tei:lb[@xml:id = $startId] and count(following-sibling::tei:lb) eq 0) or (ancestor::*/preceding-sibling::*/tei:lb[@xml:id = $startId] and ancestor::*/following-sibling::tei:lb[@xml:id = $endId]) or (preceding-sibling::*//tei:lb[@xml:id = $startId] and following-sibling::tei:lb[@xml:id = $endId])]">-->
                              <xsl:apply-templates select="//(*|text())[(preceding-sibling::tei:lb[@xml:id = $startId] and count(following-sibling::tei:lb) eq 0) or (preceding-sibling::*//tei:lb[@xml:id = $startId] and following-sibling::tei:lb[@xml:id = $endId])]">
                        <xsl:with-param name="startId" select="$startId"/>
                        <xsl:with-param name="type" select="$FIRST_LB_INSIDE_TAG"/>
                     </xsl:apply-templates>
                           </xsl:when>
                           <!-- Hierarchical case 2b: several lbs inside a tag, current lb is last lb inside tag -->
                           <xsl:otherwise>
                              <xsl:apply-templates select="//(*|text())[preceding::tei:lb[@xml:id = $startId] and following::tei:lb[@xml:id = $endId] and not(parent::*/preceding::tei:lb[@xml:id = $startId] and parent::*/following::tei:lb[@xml:id = $endId])]">
                              <!--TODO<xsl:apply-templates select="//(*|text())[preceding-sibling::tei:lb[@xml:id = $startId] or (preceding-sibling::*/tei:lb[@xml:id = $startId] and (following-sibling::*/tei:lb[@xml:id = $endId] or following-sibling::tei:lb[@xml:id = $endId]) or (ancestor::*/preceding-sibling::*/tei:lb[@xml:id = $startId] and following-sibling::tei:lb[@xml:id = $endId]))]">-->
                                 <xsl:with-param name="id" select="$startId"/>
                                 <xsl:with-param name="startId" select="$startId"/>
                                 <xsl:with-param name="type" select="$CURRENT_LB_IS_LAST_INSIDE_TAG"/>
                              </xsl:apply-templates>
                           </xsl:otherwise>
                        </xsl:choose>
                  </xsl:when>
                  <xsl:when test="//tei:lb[@xml:id = $startId and not(ancestor::tei:div2)]">
                     <xsl:variable name="lbParent" select="//*[tei:lb[@xml:id = $startId]]"/>
                     <!--<DATA><xsl:copy-of select="//(*|text())[ancestor::* = $lbParent and preceding::tei:lb[@xml:id = $startId] and not(parent::*/preceding::tei:lb[@xml:id = $startId])]"/></DATA>-->
                     <xsl:apply-templates select="//(*|text())[ancestor::* = $lbParent and preceding::tei:lb[@xml:id = $startId] and not(parent::*/preceding::tei:lb[@xml:id = $startId])]">
                        <xsl:with-param name="id" select="$startId"/>
                        <xsl:with-param name="startId" select="$startId"/>
                        <xsl:with-param name="type" select="$NO_ENDID"/>
                     </xsl:apply-templates>
                  </xsl:when>
                  <!-- Nodes/text after last lb in div2 -->
                  <xsl:otherwise>
                     <!--<DATA><xsl:copy-of select="//(*|text())[ancestor::tei:div2 and preceding::tei:lb[@xml:id = $startId] and not(parent::*/preceding::tei:lb[@xml:id = $startId])]"/></DATA>-->
                     <xsl:apply-templates select="//(*|text())[ancestor::tei:div2 and preceding::tei:lb[@xml:id = $startId] and not(parent::*/preceding::tei:lb[@xml:id = $startId])]">
                        <xsl:with-param name="id" select="$startId"/>
                        <xsl:with-param name="startId" select="$startId"/>
                        <xsl:with-param name="type" select="$NO_ENDID"/>
                     </xsl:apply-templates>
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:element>
         </xsl:element>
      </xsl:element>
   </xsl:template>
</xsl:stylesheet>