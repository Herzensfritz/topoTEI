<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" version="2.0">
   <xsl:import href="elementTemplates.xsl"/>
   <xsl:output method="html" encoding="UTF-8"/>
   <!-- Param 'resources' specifies the root folder for css and scripts -->
   <xsl:param name="resources" select="'resources'"/>
   <!-- Param 'fullpage' specifies whether output should be a standalone html page or just a transkription as part of a <div> -->
   <xsl:param name="fullpage" select="'true'"/>
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
                  <link rel="stylesheet" href="{concat($resources, '/css/gui_style.css')}"/>
                  <script src="{concat($resources, '/scripts/gui_transcription.js')}"/>
              </head>
              <!--<body onload="updatePositions()">-->
              <body>
                  <h1>Diplomatische Transkription: <xsl:value-of select="$TITLE"/>
                        </h1>
                  <xsl:apply-templates select="/tei:TEI/tei:text/tei:body"/>
              </body>
           </html>
         </xsl:when>
         <xsl:otherwise>
            <div>
                <h1>Diplomatische Transkription: <xsl:value-of select="$TITLE"/>
                    </h1>
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
      <xsl:variable name="style" select="@style"/>
      <div id="transkription" class="transkriptionField" style="{$style}">
         <xsl:apply-templates/>
      </div>
   </xsl:template>
   <xsl:template match="tei:zone">
      <xsl:variable name="zone" select="substring-after(@start, '#')"/>
      <xsl:element name="div">
         <xsl:if test="@xml:id and not(tei:line)">
            <xsl:attribute name="id">
               <xsl:value-of select="@xml:id"/>
            </xsl:attribute>
         </xsl:if>
         <xsl:if test="@style and not(tei:line)">
            <xsl:attribute name="style">
               <xsl:value-of select="@style"/>
            </xsl:attribute>
         </xsl:if>
         <xsl:if test="@type">
            <xsl:attribute name="class">
               <xsl:value-of select="@type"/>
            </xsl:attribute>
         </xsl:if>
         <xsl:choose>
            <xsl:when test="tei:line">
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
   <xsl:template name="zoneItems">
      <xsl:param name="id"/>
      <xsl:apply-templates select="//*[@xml:id = $id ]">
         <xsl:with-param name="id" select="$id"/>
      </xsl:apply-templates>
   </xsl:template>
   <xsl:template match="tei:line">
      <xsl:param name="zoneId"/>
      <xsl:variable name="lineClass" select="if (empty(parent::tei:zone/@type) or ends-with(parent::tei:zone/@type, 'Block')) then ('line') else ('zoneLine')"/>
      <xsl:variable name="startId" select="substring-after(@start, '#')"/>
      <xsl:variable name="endId" select="if (following-sibling::tei:line) then (substring-after(following-sibling::tei:line[1]/@start, '#'))        else (if (parent::tei:zone/following-sibling::tei:*[1]/local-name() = 'line') then (substring-after(parent::tei:zone/following-sibling::tei:line[1]/@start, '#'))        else (substring-after(parent::tei:zone/following-sibling::tei:zone[1]/tei:line[1]/@start,'#')))"/>
      <xsl:variable name="isZone" select="if (contains(parent::tei:zone/@type, 'zone')) then ('true') else ('false')"/>
      <xsl:variable name="spanType" select="concat(@rend,' ',tei:zone/@type)"/>
      <xsl:variable name="spanStyle" select="if ($isZone = 'true') then (parent::tei:zone/@style) else ()"/>
      <div class="{$lineClass}" style="{@style}">
         <xsl:call-template name="writeLineNumber">
            <xsl:with-param name="n" select="//tei:lb[@xml:id = $startId]/@n"/>
         </xsl:call-template>
         <xsl:element name="span">
            <xsl:call-template name="writeContentSpanAttributes">
               <xsl:with-param name="isZone" select="$isZone"/>
               <xsl:with-param name="spanClass" select="$spanType"/>
               <xsl:with-param name="spanStyle" select="$spanStyle"/>
            </xsl:call-template>
            <xsl:choose>
               <!-- Simple case: nodes/text between two lb -->
               <xsl:when test="$endId and count(//(*|text())[preceding-sibling::tei:lb[@xml:id = $startId] and following-sibling::tei:lb[@xml:id = $endId]]) gt 0">
                     <xsl:apply-templates select="//(*|text())[preceding-sibling::tei:lb[@xml:id = $startId] and following-sibling::tei:lb[@xml:id = $endId]]"/>
               </xsl:when>
               <!-- Hierarchical case 1: nodes/text between two lb, second lb inside a tag -->
               <xsl:when test="$endId and count(//(*|text())[preceding-sibling::tei:lb[@xml:id = $startId]]/../node()/tei:lb[@xml:id = $endId]) gt 0">
                  <xsl:apply-templates select="//(*|text())[(preceding-sibling::tei:lb[@xml:id = $startId] or ancestor::*/preceding-sibling::tei:lb[@xml:id = $startId])                and (following-sibling::*//tei:lb[@xml:id = $endId] or following-sibling::tei:lb[@xml:id = $endId])]"/>
               </xsl:when>
               <!-- Hierarchical case 2: first lb inside a tag -->
               <xsl:when test="$endId">
                     <xsl:choose>
                        <!-- Hierarchical case 2a: only one lb inside a tag -->
                        <xsl:when test="count(//(*|text())[preceding-sibling::tei:lb[@xml:id = $startId]]/../tei:lb) eq 1">
                           <xsl:apply-templates select="//(*|text())[preceding-sibling::tei:lb[@xml:id = $startId]]"/>
                        </xsl:when>
                        <!-- Hierarchical case 2b: several lbs inside a tag, current lb is last lb inside tag -->
                        <xsl:otherwise>
                           <xsl:apply-templates select="//(*|text())[preceding-sibling::tei:lb[@xml:id = $startId]]/../(*|text())[preceding-sibling::tei:lb[@xml:id = $startId]]"/>
                        </xsl:otherwise>
                     </xsl:choose>
               </xsl:when>
               <!-- Nodes/text after last lb in div2 -->
               <xsl:otherwise>
                  <xsl:apply-templates select="//(*|text())[preceding-sibling::tei:lb[@xml:id = $startId]]">
                     <xsl:with-param name="id" select="$startId"/>
                  </xsl:apply-templates>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:element>
      </div>
   </xsl:template>
</xsl:stylesheet>