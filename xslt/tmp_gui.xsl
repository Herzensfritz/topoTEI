<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" version="2.0">
   <xsl:import href="functions.xsl"/>
    <xsl:output method="html" encoding="UTF-8"/>
<xsl:param name="resources" select="'resources'"/>
<xsl:param name="fullpage" select="'true'"/>
<xsl:variable name="TITLE" select="//tei:titleStmt/tei:title"/>
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
           <xsl:apply-templates select="/tei:TEI/tei:text/tei:body">
           </xsl:apply-templates>
           </body>
        </html>
</xsl:when>
<xsl:otherwise>
    <div>
    <h1>Diplomatische Transkription: <xsl:value-of select="$TITLE"/>
                        </h1>
           <xsl:apply-templates select="/tei:TEI/tei:text/tei:body">
           </xsl:apply-templates>
    </div>
</xsl:otherwise>
</xsl:choose>
</xsl:template>

<xsl:key name="following-nodes" match="tei:*/node()" use="concat(generate-id(..), '|', count(following-sibling::tei:lb))"/>
       <!--<xsl:key name="following-nodes" match="tei:div1/node()|tei:div2/node()|tei:p/node()|tei:seg/node()" use="concat(generate-id(..), '|', count(following-sibling::tei:lb))" />-->
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
<xsl:template match="tei:certainty"/>
<xsl:template match="tei:noteGrp|tei:note"/>
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
<xsl:template name="writeLineNumber">
   <xsl:param name="n"/>
   <xsl:if test="number($n) = $n">
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
<xsl:template match="tei:div2|tei:div2/tei:p|tei:div2/tei:p/tei:seg">
<xsl:variable name="parentId" select="generate-id()"/>
<xsl:variable name="handShift" select="replace(//tei:handShift/@new, '#','')"/>
<xsl:for-each select="node()[generate-id() = generate-id(key('following-nodes', concat($parentId, '|', count(following-sibling::tei:lb)))[1])]">
   <xsl:choose>
      <xsl:when test="@n != '' or name() = 'lb'">
         <xsl:variable name="oldtestAddSpan" select="count(following-sibling::tei:lb)"/>
         <xsl:variable name="addSpan" select="if (following-sibling::tei:anchor[@xml:id = replace(current()/preceding-sibling::tei:addSpan[1]/@spanTo, '#', '')]/@xml:id) then ('addSpan') else ()"/>
         <xsl:variable name="nextXmlId" select="following-sibling::tei:anchor[@xml:id = replace(preceding-sibling::tei:addSpan[1]/@spanTo, '#', '')]/@xml:id"/>
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

<!--or following-sibling::tei:anchor[@xml:id = replace(current()/preceding-sibling::tei:hi[@spanTo][1]/@spanTo, '#','')]/preceding-sibling::tei:lb[1]/@n = following-sibling::tei:lb[1]/@n-->
<xsl:template match="text()[preceding-sibling::tei:addSpan[1]/following-sibling::tei:lb[1]/@n = following-sibling::tei:lb[1]/@n                   or tei:seqContains(current()/preceding-sibling::tei:hi/@spanTo, current()/following-sibling::tei:anchor/@xml:id) = 1]">
   <xsl:param name="show"/>
   <xsl:if test="$show = 'true' or tei:seqContains(preceding-sibling::tei:hi[@spanTo][1]/@spanTo, $show) = 1">
      <span><xsl:value-of select="tei:seqContains(preceding-sibling::tei:hi/@spanTo, $show)"/></span>
      <xsl:copy-of select="."/> 
   </xsl:if>
</xsl:template>
<xsl:template match="*[preceding-sibling::tei:addSpan[1]/following-sibling::tei:lb[1]/@n = following-sibling::tei:lb[1]/@n or following-sibling::tei:anchor[@xml:id = replace(current()/preceding-sibling::tei:hi[@spanTo][1]/@spanTo, '#','')]/preceding-sibling::tei:lb[1]/@n = following-sibling::tei:lb[1]/@n]">
   <xsl:param name="show"/>
   <xsl:if test="$show = 'true' or $show = preceding-sibling::tei:hi[@spanTo][1]/@spanTo">
      <xsl:choose>
         <xsl:when test="local-name() = 'add'">
            <xsl:call-template name="add"/>
         </xsl:when>
         <xsl:when test="local-name() = 'del'">
            <xsl:call-template name="del"/>
         </xsl:when>
         <xsl:when test="local-name() = 'hi'">
            <xsl:call-template name="hi"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:apply-templates select="."/> 
         </xsl:otherwise>
      </xsl:choose>
   </xsl:if>
</xsl:template>
<xsl:template match="tei:addSpan">
   <xsl:variable name="nextLineNumber" select="following-sibling::tei:lb[1]/@n"/> 
   <xsl:variable name="hand" select="replace(@hand, '#', '')"/>
   <span class="addSpan {$hand}">
      <xsl:apply-templates select="following-sibling::*[following-sibling::tei:lb/@n = $nextLineNumber]|following-sibling::text()[following-sibling::tei:lb/@n = $nextLineNumber]">
         <xsl:with-param name="show" select="'true'"/>
      </xsl:apply-templates>
   </span>
</xsl:template>
<xsl:template match="tei:del[@rend='overwritten']|tei:add[@place='superimposed']"/>
<xsl:template match="tei:subst[@spanTo and (following-sibling::tei:del[1]/@rend = 'overwritten' or following-sibling::tei:add[1]/@place = 'superimposed')]">
   <xsl:variable name="hand" select="replace(following-sibling::tei:add/@hand,'#','')"/>
   <span class="box {$hand}" title="{following-sibling::tei:del[@rend='overwritten'][1]/text()} (überschrieben)">
      <xsl:value-of select="following-sibling::tei:add[@place='superimposed'][1]/text()"/>
   </span>
</xsl:template>

<xsl:template match="tei:subst[tei:add/@place = 'superimposed' and tei:del]">
<xsl:variable name="dict">
   <tei:entry key="erased" value="(radiert)"/>
   <tei:entry key="overwritten" value="(überschrieben)"/>
</xsl:variable>
<span class="{if (parent::tei:fw) then ('fw-box') else ('box')}" title="{current()/tei:del/text()} {$dict/tei:entry[@key = current()/tei:del/@rend]/@value}">
   <xsl:value-of select="current()/tei:add/text()"/>
	</span>
   <!--<xsl:apply-templates/>TODO-->
</xsl:template>
<xsl:template name="del" match="tei:del">
   <xsl:variable name="deleted" select="concat('deleted',replace(replace(@hand, '@', '0'),'#','-'))"/>
   <xsl:choose>
      <xsl:when test="@rend != ''">
         <span class="{@rend} {replace(@hand,'#','')}" title="{text()}">
            <xsl:apply-templates>
            </xsl:apply-templates>
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
<xsl:template match="tei:pb">
	<!--<h3> Seite: <xsl:value-of select="@xml:id"/></h3>-->
</xsl:template>
<xsl:template match="tei:space[@unit='char']">
      <xsl:call-template name="insertSpace">
         <xsl:with-param name="counter" select="@quantity"/>
      </xsl:call-template>
</xsl:template>
<xsl:template name="insertSpace">
   <xsl:param name="counter"/>
   <xsl:text> </xsl:text>
   <xsl:if test="$counter &gt; 0">
      <xsl:call-template name="insertSpace">
         <xsl:with-param name="counter" select="$counter - 1"/>
      </xsl:call-template>
   </xsl:if>
</xsl:template>
<xsl:template match="tei:head">
   <span class="head">
      <xsl:apply-templates>
      </xsl:apply-templates>
   </span>
</xsl:template>

<xsl:template name="hi" match="tei:hi">
   <xsl:variable name="nextLineNumber" select="following-sibling::tei:lb[1]/@n"/> 
   <xsl:choose>
      <xsl:when test="parent::tei:restore/@type = 'strike'">
         <span class="deleted-{@rend}">
            <xsl:choose>
               <xsl:when test="@spanTo">
                  <xsl:apply-templates select="(following-sibling::*|following-sibling::text())[following-sibling::tei:anchor/@xml:id = replace(@spanTo, '#','')]">
                     <xsl:with-param name="show" select="@spanTo"/>
                  </xsl:apply-templates>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:apply-templates/>
               </xsl:otherwise>
            </xsl:choose>
         </span>
      </xsl:when>
      <xsl:otherwise>
      <span class="{@rend}">
            <xsl:choose>
               <xsl:when test="@spanTo">
                  <xsl:apply-templates select="(following-sibling::*|following-sibling::text())[following-sibling::tei:lb[1]/@n = $nextLineNumber]">
                     <xsl:with-param name="show" select="@spanTo"/>
                  </xsl:apply-templates>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:apply-templates/>
               </xsl:otherwise>
            </xsl:choose>
      </span>
      </xsl:otherwise>
   </xsl:choose>
</xsl:template>
<xsl:function name="tei:createStyle">
    <xsl:param name="style"/>
    <xsl:param name="target"/>
    <xsl:param name="place"/>
    <xsl:if test="$style">
         <xsl:variable name="left" select="if (contains(substring-after($style, 'left:'), ';')) then (substring-before(substring-after($style, 'left:'), ';')) else (substring-after($style, 'left:'))"/>
        <xsl:variable name="top" select="if (contains(substring-after($style, 'top:'), ';')) then (substring-before(substring-after($style, 'top:'), ';')) else (substring-after($style, 'top:'))"/>
        <xsl:variable name="height" select="if (contains(substring-after($style, 'height:'), ';')) then (substring-before(substring-after($style, 'height:'), ';')) else (substring-after($style, 'height:'))"/>
        <xsl:choose>
            <xsl:when test="contains($place,'above') and $target = 'parent'">
                <xsl:value-of select="concat('top:',$top, ';', 'height:', $height, ';')"/>        
            </xsl:when>
            <xsl:when test="contains($place,'above') and $target = 'child'">
                <xsl:value-of select="concat('left:',$left, ';')"/>        
            </xsl:when>
             <xsl:when test="contains($place,'below') and $target = 'parent'">
                <xsl:value-of select="concat('height:', $height, ';')"/>        
            </xsl:when>
             <xsl:when test="contains($place,'below') and $target = 'child'">
                <xsl:value-of select="concat('left:',$left, ';', 'top:', $top,';')"/>        
            </xsl:when>
        </xsl:choose>
    </xsl:if>
</xsl:function>
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
<xsl:template name="add" match="tei:add">
   <xsl:variable name="hand" select="replace(@hand,'#','')"/>
   <xsl:choose>
      <xsl:when test="@place">
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

</xsl:stylesheet>