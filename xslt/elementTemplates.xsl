<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" version="2.0">
   <xsl:import href="functions.xsl"/>
   <xsl:output method="html" encoding="UTF-8"/>
   <xsl:variable name="apos">'</xsl:variable>
   <xsl:variable name="SIMPLE_BETWEEN_TWO_LBS" select="0" as="xs:decimal"/>
   <xsl:variable name="SECOND_LB_INSIDE_TAG" select="1" as="xs:decimal"/>
   <xsl:variable name="FIRST_LB_INSIDE_TAG" select="2" as="xs:decimal"/>
   <xsl:variable name="CURRENT_LB_IS_LAST_INSIDE_TAG" select="3" as="xs:decimal"/>
   <xsl:variable name="NO_ENDID" select="4" as="xs:decimal"/>
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
      <xsl:param name="lineType"/>
      <xsl:param name="zoneId"/>
      <xsl:if test="$n">
         <xsl:choose>
            <xsl:when test="$fullpage = 'true' or $editorModus = 'false'">
               <span class="lnr">
                  <xsl:value-of select="if (number(replace($n, '[a-z]','')) lt 10) then (concat(' ', $n)) else ($n)"/>:
               </span>
            </xsl:when>
            <xsl:otherwise>
               <xsl:variable name="paramName" select="if (number(replace($n, '[a-z]',''))  lt 12) then ('top') else ('bottom')"/>
               <xsl:variable name="className" select="if ($lineType = 'line') then ('lnr') else ('zlnr')"/>
                <xsl:variable name="function" select="if ($lineType = 'line') then (concat('showTextBlockDialog(',$apos,$zoneId,$apos,')')) else (concat('showLinePositionDialog(this, ',$apos,$paramName,$apos,')'))"/>
               <xsl:element name="span">
                   <xsl:attribute name="class">
                       <xsl:value-of select="$className"/>
                   </xsl:attribute>
                   <xsl:if test="$className = 'zlnr'">
                      <xsl:attribute name="data-param-name">
                          <xsl:value-of select="$paramName"/>
                      </xsl:attribute>
                   </xsl:if>
                   <xsl:attribute name="onClick">
                       <xsl:value-of select="$function"/>
                   </xsl:attribute>
                   <xsl:value-of select="if (number(replace($n, '[a-z]','')) lt 10) then (concat(' ', $n)) else ($n)"/>:
               </xsl:element>
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
      <xsl:variable name="inline" select="if(@instant = 'true' or following-sibling::tei:add/@instant = 'true') then ('inline instantaneous') else ('inline')"/>
      <span class="box {$hand} {$inline}" title="{following-sibling::tei:del[@rend='overwritten'][1]/text()} (überschrieben)">
         <xsl:value-of select="following-sibling::tei:add[@place='superimposed'][1]/text()"/>
      </span>
   </xsl:template>
   <xsl:template match="tei:choice[not(tei:sic/tei:lb)]">
      <span class="editorCorrection" title="{tei:sic/text()} &gt;{tei:corr/text()}">
         <xsl:apply-templates select="tei:sic"/>
      </span>
   </xsl:template>
   <xsl:template match="tei:sic">
      <xsl:apply-templates/>
   </xsl:template>
   <xsl:template match="text()[parent::tei:sic/tei:lb]">
      <span class="editorCorrection" title="{normalize-space(string-join(parent::tei:sic/text(), ''))} &gt;{ancestor::tei:choice/tei:corr/text()}">
         <xsl:value-of select="normalize-space(.)"/>
      </span>
   </xsl:template>
   <!-- Process overwritten text in case of normal substitution, also for forme work -->
   <xsl:template name="superimposed">
      <xsl:variable name="inline" select="if(@instant = 'true' or tei:add/@instant = 'true') then ('inline instantaneous') else ('inline')"/>
      <xsl:variable name="hand" select="replace(tei:add[@place = 'superimposed']/@hand,'#','')"/>
      <xsl:variable name="dict">
         <tei:entry key="erased" value="radiert:"/>
         <tei:entry key="overwritten" value="überschrieben:"/>
      </xsl:variable>
      <span class="{if (parent::tei:fw) then (concat($hand, ' ', 'fw-box')) else (concat('box ', $hand))}">
         <xsl:choose>
            <xsl:when test="($fullpage = 'true' or $editorModus = 'false') and current()/tei:del/node()">
               <xsl:apply-templates select="current()/tei:add[@place = 'superimposed']/(*|text())"/>
                 <span class="tooltip">
                        <xsl:value-of select="$dict/tei:entry[@key = current()/tei:del/@rend]/@value"/>
                  <span class="transkriptionField small">
                            <xsl:apply-templates select="./tei:del/(*|text())"/>
                        </span>
               </span>
            </xsl:when>
            <xsl:otherwise>
               <span class="{if (parent::tei:fw) then ('fw-box') else ('box')} {$inline}" title="{$dict/tei:entry[@key = current()/tei:del/@rend]/@value} {current()/tei:del/text()} ">
                  <xsl:apply-templates select="current()/tei:add[@place = 'superimposed']/(*|text())"/>
               </span>
            </xsl:otherwise>
         </xsl:choose>
         <xsl:apply-templates select="current()/tei:add[empty(@place) or not(@place = 'superimposed')]"/>
      </span>
   </xsl:template>
   <xsl:template match="tei:add[@place='superimposed' and parent::tei:subst/tei:del[@rend='overwritten' or @rend='erased']]">
      <xsl:variable name="inline" select="if(@instant = 'true' or parent::tei:subst/@instant = 'true') then ('inline instantaneous') else ('inline')"/>
      <xsl:variable name="hand" select="replace(@hand,'#','')"/>
      <xsl:variable name="delRend" select="parent::tei:subst/tei:del[@rend='overwritten' or @rend='erased']/@rend"/>
      <xsl:variable name="dict">
         <tei:entry key="erased" value="radiert:"/>
         <tei:entry key="overwritten" value="überschrieben:"/>
      </xsl:variable>
      <span class="{if (ancestor::tei:fw) then (concat($hand, ' ', 'fw-box')) else (concat('box ', $hand))} {$inline}">
          <xsl:choose>
            <xsl:when test="($fullpage = 'true' or $editorModus = 'false') and parent::tei:subst/tei:del[@rend='overwritten' or @rend='erased']/node()">
               <xsl:apply-templates/>
               <span class="tooltip" data-debug="{$delRend}">
                  <xsl:value-of select="$dict/tei:entry[@key = $delRend]/@value"/>
                  <span class="transkriptionField small">
                            <xsl:apply-templates select="parent::tei:subst/tei:del[@rend='overwritten' or @rend='erased']/(*|text())"/>
                        </span>
               </span>
            </xsl:when>
            <xsl:otherwise>
               <span class="{if (ancestor::tei:fw) then ('fw-box') else ('box')}" title="{$dict/tei:entry[@key = $delRend]/@value} {parent::tei:subst/tei:del[@rend='overwritten' or @rend='erased']/text()} ">
                  <xsl:apply-templates/>
               </span>
            </xsl:otherwise>
         </xsl:choose>
      </span>
   </xsl:template>
   <!-- Process deletions -->
   <xsl:template name="del" match="tei:del">
      <xsl:variable name="deleted" select="concat('deleted',replace(replace(@hand, '@', '0'),'#','-'))"/>
      <xsl:choose>
         <xsl:when test="@rend != ''">
            <span class="{concat(@rend, replace(@hand,'#','-'))}" title="{text()}">
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
      <xsl:param name="type" as="xs:decimal">-1</xsl:param>
      <xsl:param name="startId"/>
      <xsl:param name="debug"/>
      <xsl:choose>
         <xsl:when test="parent::tei:restore/@type = 'strike'">
            <span class="deleted-{@rend}">
               <xsl:apply-templates/>
            </span>
         </xsl:when>
         <xsl:when test="($type eq $SIMPLE_BETWEEN_TWO_LBS) and (ancestor::*[@rend]/tei:lb[@xml:id = $startId])">
            <span class="{ancestor::*[@rend and (tei:lb[@xml:id = $startId] or child::*/tei:lb[@xml:id = $startId])]/@rend} {@rend}">
               <xsl:apply-templates/>
            </span>
         </xsl:when>
         <xsl:otherwise>
            <span data-debug="{$type}" data-msg="{$debug}" class="{@rend}">
               <xsl:apply-templates>
               <xsl:with-param name="type" select="-1"/>
               </xsl:apply-templates>
         </span>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   <!-- Write content span -->
   <xsl:template name="writeContentSpanAttributes">
      <xsl:param name="parentZoneId"/>
      <xsl:param name="isZone"/>
      <xsl:param name="spanClass"/>
      <xsl:param name="spanStyle"/>
      <xsl:variable name="class" select="if ($isZone = 'true' and $spanClass != 'flushRight') then (concat('marginLeft', ' ', $spanClass)) else ($spanClass)"/>
      <xsl:attribute name="id">
            <xsl:value-of select="$parentZoneId"/>
      </xsl:attribute>
      <xsl:if test="$spanStyle">
         <xsl:attribute name="style">
            <xsl:value-of select="$spanStyle"/>
         </xsl:attribute>
      </xsl:if>
      <xsl:if test="$class">
         <xsl:attribute name="class">
            <xsl:value-of select="$class"/>
         </xsl:attribute>
      </xsl:if>
      <xsl:if test="$isZone = 'true' and $fullpage != 'true' and $editorModus != 'false'">
         <xsl:attribute name="draggable">
            <xsl:value-of select="'true'"/>
         </xsl:attribute>
         <xsl:attribute name="onClick">
            <xsl:value-of select="'clickItem(this, event)'"/>
         </xsl:attribute>
      </xsl:if>
   </xsl:template>
   <!-- Write addition, in editor mode make text draggable and create a call to javascript function onClick -->
   <xsl:template name="writeAdd">
      <xsl:param name="childId"/>
      <xsl:param name="parentId"/>
      <xsl:param name="childClass"/>
      <xsl:param name="parentClass"/>
      <xsl:param name="childStyle"/>
      <xsl:param name="parentStyle"/>
      <xsl:param name="type">-1</xsl:param>
      <xsl:choose>
         <xsl:when test="$fullpage = 'true' and $editorModus != 'false'">
            <span id="{$parentId}" class="{$parentClass}" style="{$parentStyle}">
               <span id="{$childId}" class="{$childClass}" style="{$childStyle}">
                 <xsl:apply-templates>
                     <xsl:with-param name="type" select="$type"/>
                 </xsl:apply-templates>
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
    <!-- Write zoneItems, in editor mode make text draggable and create a call to javascript function onClick -->
    <xsl:template name="zoneItems">
      <xsl:param name="id"/>
      <xsl:if test="$fullpage != 'true' and $editorModus != 'false'">
          <xsl:attribute name="draggable">
              <xsl:value-of select="'true'"/>
          </xsl:attribute>
          <xsl:attribute name="onClick">
              <xsl:value-of select="'clickItem(this, event)'"/>
          </xsl:attribute>
      </xsl:if>
      <xsl:apply-templates select="//*[@xml:id = $id ]">
         <xsl:with-param name="id" select="$id"/>
      </xsl:apply-templates>
   </xsl:template>
   
   <!-- Process additions -->
   <xsl:template name="add" match="tei:add">
      <xsl:param name="id"/>
      <xsl:param name="type">-1</xsl:param>
      <xsl:param name="startId"/>
      <xsl:variable name="hand" select="if (@hand) then (replace(@hand,'#','')) else (replace(ancestor::*[@hand and preceding::tei:lb[@xml:id = $startId]]/@hand, '#',''))"/>
      <xsl:choose>
         <xsl:when test="@place and (contains(@place,'above') or contains(@place,'below'))">
            <xsl:variable name="addId" select="concat('#', @xml:id)"/>
            <xsl:variable name="childId" select="//tei:sourceDoc//tei:add[@corresp=$addId]/@xml:id"/>
            <xsl:variable name="childStyle" select="//tei:sourceDoc//tei:add[@corresp=$addId]/@style"/>
            <xsl:variable name="parentId" select="//tei:sourceDoc//tei:metamark[@target=$addId]/@xml:id"/>
            <xsl:variable name="parentStyle" select="//tei:sourceDoc//tei:metamark[@target=$addId]/@style"/>
            <xsl:variable name="rend" select="if (//tei:sourceDoc//tei:metamark[@target=$addId]/@rend) then (//tei:sourceDoc//tei:metamark[@target=$addId][1]/@rend) else (             if(@rend = 'insM' or @rend = 'Ez') then (@rend) else ())"/>
            <xsl:call-template name="writeAdd">
                <xsl:with-param name="childId" select="$childId"/>
                <xsl:with-param name="parentId" select="$parentId"/>
               <!-- <xsl:with-param name="childClass" select="concat(@place, ' ', $hand, ' centerLeft')"/> -->
               <xsl:with-param name="childClass" select="if (@instant = 'true') then (concat(@place, ' instantaneous')) else (@place)"/>
                <xsl:with-param name="parentClass" select="if ($rend) then (concat($rend, 'insertion-', @place, ' ', $hand)) else (concat('insertion-', @place, ' ', $hand))"/>
                <xsl:with-param name="childStyle" select="$childStyle"/>
                <xsl:with-param name="parentStyle" select="$parentStyle"/>
                <xsl:with-param name="type" select="$type"/>
            </xsl:call-template>
         </xsl:when>
         <xsl:otherwise>
            <xsl:variable name="inline" select="if (//tei:sourceDoc//tei:zone[@start = concat('#',$id)]/@type = 'add-zone') then () else (@place)"/>
            <xsl:variable name="instant" select="if (@instant = 'true' or parent::tei:subst/@instant = 'true') then ('instantaneous') else ()"/>
            <span id="{//tei:sourceDoc//tei:zone[@start = concat('#',$id)]/@xml:id}" class="{$inline} {$instant} {$hand}">
               <xsl:apply-templates>
                   <xsl:with-param name="type" select="$type"/>
                </xsl:apply-templates>
            </span>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   <!-- Process notes -->
   <xsl:template match="tei:note[@type = 'authorial']">
      <xsl:param name="id"/>
      <xsl:if test="preceding-sibling::tei:lb[1][@xml:id = $id] or @xml:id = $id">
         <span class="{@place} {replace(@hand, '#', '')} {@rend}">
            <xsl:apply-templates/>
         </span>
      </xsl:if>
   </xsl:template>
   <!-- Process metamarks -->
   <xsl:template match="tei:metamark">
      <xsl:param name="id"/>
      <xsl:choose>
         <xsl:when test="@target">
            <xsl:variable name="target" select="if (contains(@target, ' ')) then (substring-before(substring-after(@target, '#'), ' ')) else (substring-after(@target, '#'))"/>
            <span id="{@xml:id}" class="metamark {replace(replace(@rend, '#', ''), '\*','')}" onmouseover="toggleHighlight('{$target}', true)" onmouseout="toggleHighlight('{$target}', false)">
               <xsl:apply-templates/>
            </span>
         </xsl:when>
         <xsl:otherwise>
            <span id="{@xml:id}" class="{if (contains(@rend, '#') or contains(@rend, '*')) then (replace(replace(@rend, '#', ''), '*','')) else (@rend)}">
               <xsl:apply-templates/>
            </span>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   <xsl:template match="text()[preceding::tei:handShift[1]]">
      <xsl:param name="type" as="xs:decimal">-1</xsl:param>
      <xsl:param name="startId"/>
      <span class="{replace(preceding::tei:handShift[1]/@new, '#', '')}">
         <xsl:call-template name="text">
            <xsl:with-param name="type" select="$type"/>
            <xsl:with-param name="startId" select="$startId"/>
         </xsl:call-template>
      </span>
   </xsl:template>
   <xsl:template name="text" match="text()">
      <xsl:param name="type" as="xs:decimal">-1</xsl:param>
      <xsl:param name="startId"/>
      <xsl:choose>
         <xsl:when test="($type eq $SIMPLE_BETWEEN_TWO_LBS or $type eq $CURRENT_LB_IS_LAST_INSIDE_TAG or $type eq $NO_ENDID or $type eq $FIRST_LB_INSIDE_TAG) and (ancestor::*[@rend]/tei:lb[@xml:id = $startId] or ancestor::*[@rend]/preceding-sibling::*/tei:lb[@xml:id = $startId])">
            <span data-debug="{$type}" data-msg="first-when" class="{ancestor::*[@rend and (tei:lb[@xml:id = $startId] or child::*/tei:lb[@xml:id = $startId] or preceding-sibling::*/tei:lb[@xml:id = $startId])]/@rend}">
               <xsl:value-of select="."/>
            </span>
         </xsl:when>
         <xsl:when test="($type eq $SIMPLE_BETWEEN_TWO_LBS or $type eq $NO_ENDID or $type eq $CURRENT_LB_IS_LAST_INSIDE_TAG) and (ancestor::tei:add[empty(@place) or contains(@place, 'inline')]//tei:lb[@xml:id = $startId])">
            <span data-debug="{$type}" data-msg="second-when" class="inline {ancestor::tei:add[empty(@place) or contains(@place, 'inline') and tei:lb[@xml:id = $startId]]/replace(@hand, '#', '')}">
               <xsl:value-of select="."/>
            </span>
         </xsl:when>

         <xsl:when test="$type eq $SECOND_LB_INSIDE_TAG and ancestor::*[@rend or @hand]/preceding-sibling::tei:lb[@xml:id = $startId]">
            <xsl:variable name="inline" select="if (ancestor::tei:add[empty(@place) or contains(@place, 'inline')]/preceding::tei:lb[@xml:id = $startId]) then ('inline') else ()"/>
            <span data-debug="{$type}" class="{$inline} {replace(ancestor::*[@hand and (preceding-sibling::tei:lb[@xml:id = $startId] or ancestor::*/preceding-sibling::tei:lb[@xml:id = $startId])]/@hand, '#','')} {ancestor::*[@rend and (preceding-sibling::tei:lb[@xml:id = $startId] or ancestor::*/preceding-sibling::tei:lb[@xml:id = $startId])]/@rend}">
               <xsl:value-of select="."/>
            </span>
         </xsl:when>
         <xsl:when test="matches(., '^\s*\n+\s*$', 's') or . = ''">
         </xsl:when>
         <xsl:otherwise>
            <span data-debug="{$type}" data-msg="default">
               <xsl:value-of select="."/>
            </span>
         </xsl:otherwise>

      </xsl:choose>
   </xsl:template>
   <xsl:template match="tei:lb[not(@n)]">
       <br/>
   </xsl:template>
   <!-- unprocessed tags ...-->
   <xsl:template match="tei:note[@type = 'private']"/>
   <xsl:template match="tei:choice[tei:sic/tei:lb]"/>
   <xsl:template match="text()[parent::tei:corr]"/>
   <xsl:template match="tei:certainty"/>
   <xsl:template match="tei:noteGrp|tei:note[empty(@type) or not(@type = 'authorial')]"/>
   <xsl:template match="tei:pb"/>
   <xsl:template match="tei:del[@rend='overwritten']"/>
</xsl:stylesheet>