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
              <body onload="updatePositions()">
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
   <!-- Create keys for all tei:*/nodes -->
   <xsl:key name="following-nodes" match="tei:*/node()" use="concat(generate-id(..), '|', count(following-sibling::tei:lb))"/>
   <!-- Process tei:div1: produce top forme work container, transkription and bottom forme work container -->
   <xsl:template match="tei:body/tei:div1">
      <xsl:variable name="style" select="//tei:sourceDoc/tei:surface[@start = concat('#', current()/@xml:id)]/@style"/>
      <div class="fw-container">
         <xsl:apply-templates select="tei:fw[@place='top-left' or @place='top-right']"/>
      </div>
      <div id="transkription" style="{$style}">
         <xsl:apply-templates select="node()[local-name() != 'fw']"/>
      </div>
      <div class="fw-container">
         <xsl:apply-templates select="tei:fw[@place='bottom-left']"/>
      </div>
   </xsl:template>
   <!-- Process the text linewise using the generated keys 'following-nodes' -->
   <xsl:template match="tei:div2|tei:div2/tei:p|tei:div2/tei:p/tei:seg">
      <xsl:variable name="parentId" select="generate-id()"/>
      <xsl:variable name="handShift" select="replace(//tei:handShift/@new, '#','')"/>
      <xsl:for-each select="node()[generate-id() = generate-id(key('following-nodes', concat($parentId, '|', count(following-sibling::tei:lb)))[1])]">
         <xsl:choose>
            <xsl:when test="@n != '' or name() = 'lb'">
               <xsl:variable name="oldtestAddSpan" select="count(following-sibling::tei:lb)"/>
               <xsl:variable name="addSpan" select="if (following-sibling::tei:anchor[@xml:id = replace(current()/preceding-sibling::tei:addSpan[1]/@spanTo, '#', '')]/@xml:id) then ('addSpan') else ()"/>
               <xsl:variable name="nextXmlId" select="following-sibling::tei:anchor[@xml:id = replace(current()/preceding-sibling::tei:addSpan[1]/@spanTo, '#', '')]/@xml:id"/>
               <xsl:variable name="addSpanHand" select="preceding-sibling::tei:addSpan[@spanTo = concat('#', $nextXmlId)]/@hand"/>
               <div id="{@xml:id}" class="line {$handShift} {replace($addSpanHand[1], '#','')}" style="{@style}">
                  <xsl:variable name="noNumber" select="if (number(@n) != @n) then ('nolnr') else ()"/>
                  <xsl:call-template name="writeLineNumber">
                     <xsl:with-param name="n" select="@n"/>
                  </xsl:call-template>
                  
                  <xsl:choose>
                     <xsl:when test="@rend != '' or $addSpan != '' or $noNumber != ''">
                        <span class="{@rend} {$addSpan} {$noNumber}">
                              <xsl:apply-templates select="key('following-nodes', concat($parentId, '|', count(following-sibling::tei:lb)))[not(self::tei:lb)]"/>
                        </span>
                     </xsl:when>
                     <xsl:otherwise>
                           <xsl:apply-templates select="key('following-nodes', concat($parentId, '|', count(following-sibling::tei:lb)))[not(self::tei:lb)]"/>
                     </xsl:otherwise>
                  </xsl:choose>
                  <!--
                  <xsl:if test="$addSpanHand[1]">
                     <xsl:variable name="nextXmlId" select="following-sibling::tei:anchor[@xml:id = replace(preceding-sibling::tei:addSpan[1]/@spanTo, '#', '')]/@xml:id"/>
                     <span><xsl:value-of select="preceding-sibling::tei:addSpan[@spanTo = concat('#', $nextXmlId)]/@hand"/></span>
                  </xsl:if>-->
               </div>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="key('following-nodes', concat($parentId, '|', count(following-sibling::tei:lb)))[not(self::tei:lb)]"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:for-each>
   </xsl:template>
</xsl:stylesheet>
