<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" version="2.0">
   <xsl:import href="functions.xsl"/>
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
      <div class="fw-container">
         <xsl:apply-templates select="tei:fw[@place='top-left' or @place='top-right']"/>
      </div>
      <div id="transkription">
         <xsl:apply-templates select="node()[local-name() != 'fw']"/>
      </div>
      <div class="fw-container">
         <xsl:apply-templates select="tei:fw[@place='bottom-left']"/>
      </div>
   </xsl:template>
   <!-- process forme work by using a dictionary that translates @hand keys to human readable information  -->
   <xsl:template match="tei:fw">
      <xsl:variable name="dict">
         <tei:entry key="#XXX_red" value="unbekannte fremde Hand"/>
         <tei:entry key="#N-Archiv_red" value="fremde Hand: Nietzsche Archiv"/>
         <tei:entry key="#GSA_pencil" value="fremde Hand: GSA, Bleistift"/>
      </xsl:variable>
      <span class="{@place} {replace(@hand, '#', '')}" title="{$dict/tei:entry[@key = current()/@hand]/@value}"> 
         <xsl:apply-templates/>
      </span>
   </xsl:template>
   <!-- Write the line number, if in editor mode write also a call to a javascript function onClick -->
   <xsl:template name="writeLineNumber">
      <xsl:param name="n"/>
      <xsl:if test="number($n) and number($n) = $n">
         <xsl:choose>
            <xsl:when test="$fullpage = 'true'">
               <span class="lnr">
                  <xsl:value-of select="$n"/>:
               </span>
            </xsl:when>
            <xsl:otherwise>
               <span class="lnr" onClick="getLineHeightInput(this, 'lineInput')">
                  <xsl:value-of select="$n"/>:
               </span>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:if>
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

   <!-- Match text between addSpan and lb: display it depending on param 'show' -->
   <xsl:template match="text()[preceding-sibling::tei:addSpan[1]/following-sibling::tei:lb[1]/@n = following-sibling::tei:lb[1]/@n]">
      <xsl:param name="show"/>
      <xsl:if test="$show = 'true'">
         <xsl:copy-of select="."/> 
      </xsl:if>
   </xsl:template>
   <!-- Match tags between addSpan and lb: process them depending on param 'show' -->
   <xsl:template match="*[preceding-sibling::tei:addSpan[1]/following-sibling::tei:lb[1]/@n = following-sibling::tei:lb[1]/@n]">
      <xsl:param name="show"/>
      <xsl:if test="$show = 'true'">
         <xsl:choose>
            <xsl:when test="local-name() = 'add'">
               <xsl:call-template name="add"/>
            </xsl:when>
            <xsl:when test="local-name() = 'del'">
               <xsl:call-template name="del"/>
            </xsl:when>
            <xsl:when test="local-name() = 'hi' and not(@spanTo)">
               <xsl:call-template name="hi"/>
            </xsl:when>
            <xsl:when test="local-name() = 'subst' and tei:add/@place = 'superimposed' and tei:del">
               <xsl:call-template name="superimposed"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:apply-templates select="."/> 
            </xsl:otherwise>
         </xsl:choose>
      </xsl:if>
   </xsl:template>
   <!-- Match addSpan: apply templates to following nodes until the corresponding anchor -->
   <xsl:template match="tei:addSpan">
      <xsl:variable name="nextLineNumber" select="following-sibling::tei:lb[1]/@n"/> 
      <xsl:variable name="hand" select="replace(@hand, '#', '')"/>
      <span class="addSpan {$hand}">
         <xsl:apply-templates select="following-sibling::*[following-sibling::tei:lb/@n = $nextLineNumber]|following-sibling::text()[following-sibling::tei:lb/@n = $nextLineNumber]">
            <xsl:with-param name="show" select="'true'"/>
         </xsl:apply-templates>
      </span>
   </xsl:template>
   <!-- Process overwritten text in case of substitution with @spanTo -->
   <xsl:template match="tei:subst[@spanTo and (following-sibling::tei:del[1]/@rend = 'overwritten' or following-sibling::tei:add[1]/@place = 'superimposed')]">
      <xsl:variable name="hand" select="replace(following-sibling::tei:add/@hand,'#','')"/>
      <span class="box {$hand}" title="{following-sibling::tei:del[@rend='overwritten'][1]/text()} (überschrieben)">
         <xsl:value-of select="following-sibling::tei:add[@place='superimposed'][1]/text()"/>
      </span>
   </xsl:template>
   <!-- Process overwritten text in case of normal substitution, also for forme work -->
   <xsl:template name="superimposed" match="tei:subst[tei:add/@place = 'superimposed' and tei:del                                             and not(preceding-sibling::tei:addSpan[1]/following-sibling::tei:lb[1]/@n = following-sibling::tei:lb[1]/@n)]">
      <xsl:variable name="dict">
         <tei:entry key="erased" value="(radiert)"/>
         <tei:entry key="overwritten" value="(überschrieben)"/>
      </xsl:variable>
      <span class="{if (parent::tei:fw) then ('fw-box') else ('box')}" title="{current()/tei:del/text()} {$dict/tei:entry[@key = current()/tei:del/@rend]/@value}">
         <xsl:value-of select="current()/tei:add/text()"/>
      </span>
   </xsl:template>
   <!-- Process deletions -->
   <xsl:template name="del" match="tei:del">
      <xsl:variable name="deleted" select="concat('deleted',replace(replace(@hand, '@', '0'),'#','-'))"/>
      <xsl:choose>
         <xsl:when test="@rend != ''">
            <span class="{@rend} {replace(@hand,'#','')}" title="{text()}">
               <xsl:apply-templates/>
            </span>
         </xsl:when>
         <xsl:otherwise>
            <span class="{$deleted}" title="{text()}">
               <xsl:apply-templates>
               </xsl:apply-templates>
            </span>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   <!-- Process space -->
   <xsl:template match="tei:space[@unit='char']">
         <xsl:call-template name="insertSpace">
            <xsl:with-param name="counter" select="@quantity"/>
         </xsl:call-template>
   </xsl:template>
   <!-- Create empty space output -->
   <xsl:template name="insertSpace">
      <xsl:param name="counter"/>
      <xsl:text> </xsl:text>
      <xsl:if test="$counter &gt; 0">
         <xsl:call-template name="insertSpace">
            <xsl:with-param name="counter" select="$counter - 1"/>
         </xsl:call-template>
      </xsl:if>
   </xsl:template>
   <!-- Process head -->
   <xsl:template match="tei:head">
      <span class="head">
         <xsl:apply-templates/>
      </span>
   </xsl:template>
   <!-- Process all text that is contained between one or several <hi spanTo="..."/> and <anchor xml:id="..."/> -->
   <xsl:template match="text()[tei:seqContains(preceding-sibling::tei:hi/@spanTo, following-sibling::tei:anchor/@xml:id)=1]                               |text()[tei:seqContains(../preceding-sibling::tei:hi/@spanTo, ../following-sibling::tei:anchor/@xml:id)=1]">
         <span class="{distinct-values(preceding-sibling::tei:hi[@spanTo and index-of(current()/following-sibling::tei:anchor/@xml:id, replace(@spanTo, '#','')) gt 0]/@rend                                  |../preceding-sibling::tei:hi[@spanTo and index-of(current()/../following-sibling::tei:anchor/@xml:id, replace(@spanTo, '#','')) gt 0]/@rend)}">
               <xsl:copy-of select="."/>
         </span>
   </xsl:template>
   <!-- Process highlights -->
   <xsl:template name="hi" match="tei:hi[not(@spanTo) and not(preceding-sibling::tei:addSpan[1]/following-sibling::tei:lb[1]/@n = following-sibling::tei:lb[1]/@n)]">
      <xsl:choose>
         <xsl:when test="parent::tei:restore/@type = 'strike'">
            <span class="deleted-{@rend}">
               <xsl:apply-templates/>
            </span>
         </xsl:when>
         <xsl:otherwise>
         <span class="{@rend}">
               <xsl:apply-templates/>
         </span>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   <!-- Write addition, in editor mode make text draggable and create a call to javascript function onClick -->
   <xsl:template name="writeAdd">
      <xsl:param name="childId"/>
      <xsl:param name="parentId"/>
      <xsl:param name="childClass"/>
      <xsl:param name="parentClass"/>
      <xsl:param name="childStyle"/>
      <xsl:param name="parentStyle"/>
      <xsl:choose>
         <xsl:when test="$fullpage = 'true'">
            <span id="{$parentId}" class="{$parentClass}" style="{$parentStyle}">
               <span id="{$childId}" class="{$childClass}" style="{$childStyle}">
                 <xsl:apply-templates/>
              </span>
           </span>
         </xsl:when>
         <xsl:otherwise>
            <span id="{$parentId}" class="{$parentClass}" style="{$parentStyle}">
               <span id="{$childId}" class="{$childClass}" onClick="clickItem(this, event)" draggable="true" style="{$childStyle}">
                 <xsl:apply-templates/>
              </span>
           </span>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   <!-- Process additions -->
   <xsl:template name="add" match="tei:add">
      <xsl:variable name="hand" select="replace(@hand,'#','')"/>
      <xsl:choose>
         <xsl:when test="@place and (contains(@place,'above') or contains(@place,'below'))">
                   <xsl:call-template name="writeAdd">
                      <xsl:with-param name="childId" select="@xml:id"/>
                      <xsl:with-param name="parentId" select="concat('parent-', @xml:id)"/>
                      <xsl:with-param name="childClass" select="concat(@place, ' ', $hand, ' centerLeft')"/>
                      <xsl:with-param name="parentClass" select="if (@rend) then (concat(@rend, 'insertion-', @place, ' ', $hand)) else (concat('insertion-', @place, ' ', $hand))"/>
                      <xsl:with-param name="childStyle" select="if (@rend) then (tei:createStyle(@style, 'child', @place)) else (@style)"/>
                      <xsl:with-param name="parentStyle" select="if (@rend) then (tei:createStyle(@style, 'parent', @place)) else ()"/>
                   </xsl:call-template>
         </xsl:when>
         <xsl:otherwise>
            <span class="inline {$hand}">
               <xsl:apply-templates/>
            </span>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>

   <!-- unprocessed tags ...-->
   <xsl:template match="tei:certainty"/>
   <xsl:template match="tei:noteGrp|tei:note"/>
   <xsl:template match="tei:pb"/>
   <xsl:template match="tei:del[@rend='overwritten']|tei:add[@place='superimposed']"/>
</xsl:stylesheet>