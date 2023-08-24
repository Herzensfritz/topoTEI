<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" version="2.0">
   <xsl:import href="functions.xsl"/>
   <xsl:output method="html" encoding="UTF-8"/>
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
      <xsl:if test="$n">
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
   <!-- Match text between addSpan and lb: display it depending on param 'show' -->
   <xsl:template match="text()[preceding-sibling::tei:addSpan[1]/following-sibling::tei:lb[1]/@n = following-sibling::tei:lb[1]/@n]|text()[preceding-sibling::tei:addSpan[@spanTo = concat('#',current()/following-sibling::tei:anchor[1]/@xml:id)]]">
   <xsl:param name="show"/>
      <xsl:param name="debug"/>
      <xsl:if test="$show = 'true'">
            <xsl:copy-of select="."/>
      </xsl:if>
   </xsl:template>
     <xsl:template match="*[preceding-sibling::tei:addSpan[@spanTo = concat('#',current()/following-sibling::tei:anchor[1]/@xml:id)]]|*[preceding-sibling::tei:addSpan[1]/following-sibling::tei:lb[1]/@n = following-sibling::tei:lb[1]/@n]">
        <xsl:param name="show"/>
        <xsl:param name="debug"/>
        
        <xsl:if test="$show = 'true'">
            <xsl:call-template name="showSelected">
                <xsl:with-param name="localName" select="local-name()"/>
            </xsl:call-template>
        </xsl:if>
   </xsl:template>
 
 
   <xsl:template name="showSelected">
      <xsl:param name="localName"/>
         <xsl:choose>
            <xsl:when test="$localName = 'head'">
                <xsl:call-template name="head"/>
            </xsl:when>
            <xsl:when test="$localName = 'pc'">
               <xsl:apply-templates/>
            </xsl:when>
            <xsl:when test="$localName = 'add'">
               <xsl:call-template name="add"/>
            </xsl:when>
            <xsl:when test="$localName = 'del'">
               <xsl:call-template name="del"/>
            </xsl:when>
            <xsl:when test="($localName = 'hi' or $localName = 'restore') and not(@spanTo)">
               <xsl:call-template name="hi"/>
            </xsl:when>
            <xsl:when test="$localName = 'subst' and tei:add/@place = 'superimposed' and tei:del">
               <xsl:call-template name="superimposed"/>
            </xsl:when>
            <xsl:when test="$localName = 'subst'">
               <xsl:apply-templates/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:apply-templates select="."/> 
            </xsl:otherwise>
         </xsl:choose>
      
   </xsl:template>
   <!-- Match addSpan: apply templates to following nodes until the corresponding anchor -->
   <xsl:template match="tei:addSpan">
      <xsl:variable name="nextLineNumber" select="following-sibling::tei:lb[1]/@n"/> 
      <xsl:variable name="anchorId" select="replace(@spanTo, '#', '')"/>
      <xsl:variable name="hand" select="replace(@hand, '#', '')"/>
      <span class="addSpan {$hand} {@rend}">
            <xsl:choose>
                <xsl:when test="$nextLineNumber">
                    <xsl:apply-templates select="following-sibling::*[following-sibling::tei:lb/@n = $nextLineNumber]|following-sibling::text()[following-sibling::tei:lb/@n = $nextLineNumber]">
                        <xsl:with-param name="show" select="'true'"/>
                        <xsl:with-param name="debug" select="$nextLineNumber"/>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="following-sibling::*[following-sibling::tei:anchor/@xml:id = $anchorId]|following-sibling::text()[following-sibling::tei:anchor/@xml:id = $anchorId]">
                        <xsl:with-param name="show" select="'true'"/>
                        <xsl:with-param name="debug" select="$anchorId"/>
                    </xsl:apply-templates>
                </xsl:otherwise>
            </xsl:choose>
      </span>
   </xsl:template>
   <xsl:template match="tei:anchor[@xml:id = substring-after(preceding-sibling::tei:lb[1]/preceding-sibling::tei:addSpan[1]/@spanTo, '#')]">
      <xsl:variable name="hand" select="substring-after(preceding-sibling::tei:lb[1]/preceding-sibling::tei:addSpan[1]/@hand, '#')"/>
      <xsl:variable name="previousLineNumber" select="preceding-sibling::tei:lb[1]/@n"/>
      <xsl:variable name="numberAfterAddSpan" select="preceding-sibling::tei:addSpan[@spanTo = concat('#', current()/@xml:id)]/following-sibling::tei:lb[1]/@n"/>
    
      <xsl:if test="$previousLineNumber = $numberAfterAddSpan">
      
      <span class="{$hand}">
      <xsl:apply-templates select="preceding-sibling::*[preceding-sibling::tei:lb[1]/@n = $previousLineNumber]|preceding-sibling::text()[preceding-sibling::tei:lb[1]/@n = $previousLineNumber]">
                        <xsl:with-param name="show" select="'true'"/>
                        <xsl:with-param name="debug" select="$previousLineNumber"/>
                    </xsl:apply-templates>
      </span>
      </xsl:if>
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
         <tei:entry key="erased" value="radiert:"/>
         <tei:entry key="overwritten" value="überschrieben:"/>
      </xsl:variable>
      <span class="{if (parent::tei:fw) then ('fw-box') else ('box')}">
         <xsl:choose>
            <xsl:when test="current()/tei:del/node()">
               <xsl:apply-templates select="current()/tei:add[@place = 'superimposed']/(*|text())"/><span class="tooltip"><xsl:value-of select="$dict/tei:entry[@key = current()/tei:del/@rend]/@value"/>
                  <span class="transkriptionField small"><xsl:apply-templates select="./tei:del/(*|text())"/></span>
               </span>
            </xsl:when>
            <xsl:otherwise>
               <span class="{if (parent::tei:fw) then ('fw-box') else ('box')}" title="{current()/tei:del/text()} {$dict/tei:entry[@key = current()/tei:del/@rend]/@value}">
                  <xsl:apply-templates select="current()/tei:add[@place = 'superimposed']/(*|text())"/>
               </span>
            </xsl:otherwise>
         </xsl:choose>
         <xsl:apply-templates select="current()/tei:add[empty(@place) or not(@place = 'superimposed')]"/>
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
   <xsl:template name="head" match="tei:head">
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
                     <!-- <xsl:with-param name="childClass" select="concat(@place, ' ', $hand, ' centerLeft')"/> -->
                     <xsl:with-param name="childClass" select="@place"/>
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
   <!-- Process notes -->
   <xsl:template match="tei:note[@type = 'authorial']">
      <xsl:param name="id"/>
      <xsl:if test="preceding-sibling::tei:lb[1][@xml:id = $id]">
         <span class="{@place} {replace(@hand, '#', '')}">
            <xsl:apply-templates/>
         </span>
      </xsl:if>
   </xsl:template>
   <!-- Process metamarks -->
   <xsl:template match="tei:metamark">
      <xsl:param name="id"/>
      <xsl:choose>
         <xsl:when test="@target">
            <xsl:variable name="target" select="substring-before(substring-after(@target, '#'), ' ')"/>
            <span id="{@xml:id}" class="metamark {replace(replace(@rend, '#', ''), '\*','')}" onmouseover="toggleHighlight('{$target}', true)" onmouseout="toggleHighlight('{$target}', false)">
               <xsl:apply-templates/>
            </span>
         </xsl:when>
         <xsl:otherwise>
            <span id="{@xml:id}" class="{replace(replace(@rend, '#', ''), '*','')}">
               <xsl:apply-templates/>
            </span>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>

   <!-- unprocessed tags ...-->
   <xsl:template match="tei:certainty"/>
   <xsl:template match="tei:noteGrp|tei:note[empty(@type) or not(@type = 'authorial')]"/>
   <xsl:template match="tei:pb"/>
   <xsl:template match="tei:del[@rend='overwritten']|tei:add[@place='superimposed']"/>
</xsl:stylesheet>
