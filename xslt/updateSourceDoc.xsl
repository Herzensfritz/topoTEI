<xsl:stylesheet xmlns="http://www.tei-c.org/ns/1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" xpath-default-namespace="http://www.tei-c.org/ns/1.0" exclude-result-prefixes="tei" version="2.0">
   <xsl:output method="xml" indent="yes" encoding="UTF-8"/>
   <xsl:import href="functions.xsl"/>
   <xsl:template match="/">
      <xsl:apply-templates/>
   </xsl:template>
   <xsl:template match="tei:TEI">
      <xsl:element name="{name()}">
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates/>
         <xsl:if test="empty(//tei:sourceDoc)">
            <xsl:call-template name="sourceDoc"/>
         </xsl:if>
      </xsl:element>
   </xsl:template>
   <xsl:template name="sourceDoc">
         <xsl:element name="sourceDoc">
            <xsl:for-each select="//tei:text/tei:body/tei:div1">
               <xsl:variable name="pb_id" select="tei:pb/@xml:id"/>
               <xsl:element name="surface">
                     <xsl:attribute name="xml:id">
                       <xsl:value-of select="concat('srcD_surface_', $pb_id)"/>
                     </xsl:attribute>
                     <xsl:attribute name="type">
                       <xsl:value-of select="'relative'"/>
                     </xsl:attribute>
                     <xsl:attribute name="start">
                       <xsl:value-of select="concat('#', $pb_id)"/>
                     </xsl:attribute>
                     <xsl:call-template name="zones">
                        <xsl:with-param name="anchor_id" select="tei:anchor[1]/@xml:id"/>
                     </xsl:call-template>
              </xsl:element>
           </xsl:for-each>
         </xsl:element>
   </xsl:template>

   <xsl:template name="zones">
      <xsl:param name="anchor_id"/>
      <xsl:for-each select="tei:div2[ancestor::div1/tei:anchor[1]/@xml:id = $anchor_id]">
         <xsl:element name="zone">
           <xsl:attribute name="xml:id">
                <xsl:value-of select="concat('srcD_zone_', tei:anchor[1]/@xml:id)"/>
            </xsl:attribute>
            <xsl:attribute name="start">
               <xsl:value-of select="concat('#', tei:anchor[1]/@xml:id)"/>
            </xsl:attribute>
            <xsl:choose>
               <xsl:when test="count(preceding-sibling::tei:div2) lt 1">
                  <xsl:attribute name="type">
                     <xsl:value-of select="if (count(following-sibling::tei:div2) lt 1) then ('singleBlock') else ('firstBlock')"/>
                  </xsl:attribute>
                  <xsl:attribute name="style">
                     <xsl:value-of select="if (count(following-sibling::tei:div2) lt 1) then ('padding-top:5em;padding-bottom:5em;') else ('padding-top:5em;')"/>
                  </xsl:attribute>
                  <xsl:call-template name="fw-zone">
                     <xsl:with-param name="start_id" select="$anchor_id"/>
                     <xsl:with-param name="end_id" select="tei:anchor[1]/@xml:id"/>
                     <xsl:with-param name="place" select="'top'"/>
                  </xsl:call-template>
                  <xsl:for-each select="preceding-sibling::tei:note">
                     <xsl:call-template name="note-zone">
                        <xsl:with-param name="noteId" select="@xml:id"/>
                        <xsl:with-param name="place" select="@place"/>
                     </xsl:call-template>
                  </xsl:for-each>
                  <xsl:if test="preceding-sibling::tei:head">
                     <xsl:call-template name="head-zone">
                        <xsl:with-param name="head" select="preceding-sibling::tei:head"/>
                     </xsl:call-template>
                  </xsl:if>
               </xsl:when>
               <xsl:when test="count(following-sibling::tei:div2) lt 1">
                  <xsl:attribute name="type">
                     <xsl:value-of select="'lastBlock'"/>
                  </xsl:attribute>
                  <xsl:attribute name="style">
                     <xsl:value-of select="'padding-bottom:5em;'"/>
                  </xsl:attribute>
               </xsl:when>
            </xsl:choose>
            <xsl:call-template name="lines">
               <xsl:with-param name="anchor_id" select="tei:anchor[1]/@xml:id"/>
            </xsl:call-template>
            <xsl:if test="count(following-sibling::tei:div2) lt 1">
               <xsl:for-each select="following-sibling::tei:note">
                     <xsl:call-template name="note-zone">
                        <xsl:with-param name="noteId" select="@xml:id"/>
                        <xsl:with-param name="place" select="@place"/>
                     </xsl:call-template>
                  </xsl:for-each>

               <xsl:call-template name="fw-zone">
                  <xsl:with-param name="start_id" select="$anchor_id"/>
                  <xsl:with-param name="end_id" select="tei:anchor[1]/@xml:id"/>
                  <xsl:with-param name="place" select="'bottom'"/>
               </xsl:call-template>
            </xsl:if>
         </xsl:element>
     </xsl:for-each>
   </xsl:template>
   <xsl:template name="addLineZone">
      <xsl:param name="lineId"/>
      <xsl:param name="include"/>
      <xsl:element name="zone">
        <xsl:attribute name="xml:id">
            <xsl:value-of select="concat('srcD_zone_', $lineId)"/>
        </xsl:attribute>
         <xsl:attribute name="start">
           <xsl:value-of select="concat('#', $lineId)"/>
         </xsl:attribute>
         <xsl:attribute name="include">
           <xsl:value-of select="$include"/>
         </xsl:attribute>
      </xsl:element>
   </xsl:template>
   <xsl:template name="line">
      <xsl:param name="id"/>
      <xsl:param name="rend"/>
      <xsl:param name="anchor_id"/>
      <xsl:param name="style"/>
      <xsl:element name="line">
        <xsl:attribute name="xml:id">
            <xsl:value-of select="concat('srcD_line_', $id)"/>
        </xsl:attribute>
         <xsl:attribute name="start">
           <xsl:value-of select="concat('#', $id)"/>
         </xsl:attribute>
         <xsl:if test="$style">
            <xsl:attribute name="style">
              <xsl:value-of select="$style"/>
            </xsl:attribute>
         </xsl:if>
         <xsl:if test="$rend">
            <xsl:attribute name="rend">
              <xsl:value-of select="$rend"/>
            </xsl:attribute>
         </xsl:if>
         <xsl:call-template name="parentAdd">
            <xsl:with-param name="anchor_id" select="$anchor_id"/>
            <xsl:with-param name="lb_id" select="$id"/>
         </xsl:call-template>
      </xsl:element>
   </xsl:template>

   <xsl:template name="lines">
      <xsl:param name="anchor_id"/>
      <xsl:for-each select="//tei:lb[ancestor::tei:div2/tei:anchor[1]/@xml:id = $anchor_id and @xml:id]">
         <xsl:variable name="lineType" select="tei:getLineType(current())"/>
         <xsl:choose>
            <xsl:when test="$lineType eq 0">
               <!--<xsl:if test="following-sibling::tei:head[1]">
                  <xsl:element name="test">
                        <xsl:attribute name="value">
                           <xsl:value-of select="tei:getLineType(current())"/>
                        </xsl:attribute>
                  </xsl:element>
               </xsl:if>-->
               <xsl:call-template name="line">
                  <xsl:with-param name="id" select="@xml:id"/>
                  <xsl:with-param name="rend" select="@rend"/>
                  <xsl:with-param name="anchor_id" select="$anchor_id"/>
               </xsl:call-template>
            </xsl:when>
            <xsl:when test="$lineType eq 5 or $lineType eq 6">
               <xsl:call-template name="head-line">
                  <xsl:with-param name="id" select="@xml:id"/>
                  <xsl:with-param name="head" select="if ($lineType eq 5) then (ancestor::tei:head[1]) else (following-sibling::tei:head[1])"/>
               </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
               <xsl:variable name="hand" select="tei:getHand(current())"/>
               <xsl:variable name="topValue" select="number(@n) * 8 + 2"/>
               <xsl:variable name="bottomValue" select="count(//tei:lb/@n) - index-of(//tei:lb/@n, @n) + 1"/>
               <xsl:variable name="style" select="tei:getStyle($topValue, $bottomValue, $lineType)"/>
               <xsl:element name="zone">   
                  <xsl:choose>
                     <xsl:when test="$lineType eq 3 or $lineType eq 4">
                        <xsl:variable name="place" select="if (ancestor::tei:note/@place) then (ancestor::tei:note/@place) else (following-sibling::tei:note[1]/@place)"/>
                        <xsl:variable name="id" select="if (ancestor::tei:note/@xml:id) then (ancestor::tei:note/@xml:id) else (following-sibling::tei:note[1]/@xml:id)"/>
                        <xsl:attribute name="xml:id">
                           <xsl:value-of select="concat('srcD_zone_', @xml:id)"/>
                        </xsl:attribute>
                        <xsl:attribute name="start">
                           <xsl:value-of select="concat('#', @xml:id)"/>
                        </xsl:attribute>
                        <xsl:attribute name="type">
                           <xsl:value-of select="'note-zone'"/>
                        </xsl:attribute>
                     </xsl:when>
                     <xsl:when test="$lineType eq 1 or $lineType eq 2">
                        <xsl:variable name="id" select="if (ancestor::tei:ab/@xml:id) then (ancestor::tei:ab/@xml:id) else (following-sibling::tei:ab[1]/@xml:id)"/>
                        <xsl:attribute name="xml:id">
                           <xsl:value-of select="concat('srcD_zone_', $id)"/>
                        </xsl:attribute>
                        <xsl:attribute name="start">
                           <xsl:value-of select="concat('#', @xml:id)"/>
                        </xsl:attribute>
                        <xsl:attribute name="type">
                           <xsl:value-of select="concat('ab-zone', tei:getStyle(1, 22,33))"/>
                        </xsl:attribute>
                     </xsl:when>
                     <xsl:when test="$lineType eq 5 or $lineType eq 6">
                        <xsl:variable name="id" select="if (ancestor::tei:head[1]/@xml:id) then (ancestor::tei:head[1]/@xml:id) else (following-sibling::tei:head[1]/@xml:id)"/>
                        <xsl:attribute name="xml:id">
                           <xsl:value-of select="concat('srcD_zone_', $id)"/>
                        </xsl:attribute>
                        <xsl:attribute name="start">
                           <xsl:value-of select="concat('#', @xml:id)"/>
                        </xsl:attribute>
                        <xsl:attribute name="type">
                           <xsl:value-of select="'head'"/>
                        </xsl:attribute>
                     </xsl:when>
                     <xsl:otherwise>
                        <xsl:attribute name="xml:id">
                           <xsl:value-of select="concat('srcD_zone_', @xml:id)"/>
                        </xsl:attribute>
                        <xsl:attribute name="start">
                           <xsl:value-of select="concat('#', @xml:id)"/>
                        </xsl:attribute>
                        <xsl:attribute name="type">
                           <xsl:value-of select="'add-zone'"/>
                        </xsl:attribute>
                     </xsl:otherwise>
                  </xsl:choose>
                  <xsl:call-template name="line">
                     <xsl:with-param name="id" select="@xml:id"/>
                     <xsl:with-param name="rend" select="$hand"/>
                     <xsl:with-param name="anchor_id" select="$anchor_id"/>
                     <xsl:with-param name="style" select="$style"/>
                  </xsl:call-template>
               </xsl:element>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:for-each>
   </xsl:template>
   <xsl:template name="parentAdd">
      <xsl:param name="anchor_id"/>
      <xsl:param name="lb_id"/>
      <xsl:for-each select="//tei:add[          @xml:id and (contains(@place, 'above') or contains(@place, 'below'))           and ancestor::tei:div2/tei:anchor[1]/@xml:id = $anchor_id          and (preceding-sibling::tei:lb[1][@xml:id = $lb_id] or                 (ancestor::tei:subst/preceding-sibling::tei:lb[1][@xml:id = $lb_id] and not(ancestor::tei:add[@place = 'above' or @place = 'below']))              )       ]">
         <xsl:call-template name="add">
            <xsl:with-param name="id" select="@xml:id"/>
            <xsl:with-param name="rend" select="@rend"/>
         </xsl:call-template>
      </xsl:for-each>
   </xsl:template>
   <xsl:template name="parentHeadAdd">
      <xsl:param name="head"/>
      <xsl:param name="lb_id"/>
      <xsl:for-each select="$head/tei:add[          @xml:id and (@place = 'above' or @place = 'below')           and (preceding-sibling::tei:lb[1][@xml:id = $lb_id] or                 (ancestor::tei:subst/preceding-sibling::tei:lb[1][@xml:id = $lb_id] and not(ancestor::tei:add[@place = 'above' or @place = 'below']))              )       ]">
         <xsl:call-template name="add">
            <xsl:with-param name="id" select="@xml:id"/>
         </xsl:call-template>
      </xsl:for-each>
   </xsl:template>

   <xsl:template name="add">
      <xsl:param name="id"/>
      <xsl:param name="rend"/>
      <xsl:choose>
         <xsl:when test="$rend = 'insM' or starts-with($rend, 'Ez')">
            <xsl:element name="metamark">
                <xsl:attribute name="xml:id">
                    <xsl:value-of select="concat('srcD_metamark_', $id)"/>
               </xsl:attribute>
               <xsl:attribute name="function">
                 <xsl:value-of select="'insertion'"/>
               </xsl:attribute>
               <xsl:attribute name="target">
                 <xsl:value-of select="concat('#', $id)"/>
               </xsl:attribute>
               <xsl:element name="add">
                   <xsl:attribute name="xml:id">
                       <xsl:value-of select="concat('srcD_add_', $id)"/>
                  </xsl:attribute>
                  <xsl:attribute name="corresp">
                    <xsl:value-of select="concat('#', $id)"/>
                  </xsl:attribute>
                  <xsl:for-each select="//tei:add[@xml:id = $id]//tei:add[contains(@place, 'above') or contains(@place, 'below')]">
                     <xsl:call-template name="add">
                        <xsl:with-param name="id" select="@xml:id"/>
                        <xsl:with-param name="rend" select="@rend"/>
                     </xsl:call-template>
                  </xsl:for-each>
               </xsl:element>
            </xsl:element>
         </xsl:when>
         <xsl:otherwise>
            <xsl:element name="add">
                <xsl:attribute name="xml:id">
                    <xsl:value-of select="concat('srcD_add_', $id)"/>
                </xsl:attribute>
               <xsl:attribute name="corresp">
                 <xsl:value-of select="concat('#', $id)"/>
               </xsl:attribute>
               <xsl:for-each select="//tei:add[@xml:id = $id]//tei:add[contains(@place, 'above') or contains(@place, 'below')]">
                  <xsl:call-template name="add">
                     <xsl:with-param name="id" select="@xml:id"/>
                     <xsl:with-param name="rend" select="@rend"/>
                  </xsl:call-template>
               </xsl:for-each>
            </xsl:element>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   <xsl:template match="*">
      <xsl:element name="{name()}">
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates/>
      </xsl:element>
   </xsl:template>
   <xsl:template name="head-line">
      <xsl:param name="id"/>
      <xsl:param name="head"/>
      <xsl:element name="line">
         <xsl:attribute name="start">
           <xsl:value-of select="concat('#', $id)"/>
         </xsl:attribute>
         <xsl:element name="zone">
            <xsl:attribute name="xml:id">
                <xsl:value-of select="concat('srcD_zone_', $head/@xml:id)"/>
            </xsl:attribute>
            <xsl:attribute name="type">
              <xsl:value-of select="'head'"/>
            </xsl:attribute>
            <xsl:call-template name="parentHeadAdd">
               <xsl:with-param name="head" select="$head"/>
               <xsl:with-param name="lb_id" select="$id"/>
            </xsl:call-template>
         </xsl:element>
      </xsl:element>
   </xsl:template>
   <xsl:template name="head-zone">
      <xsl:param name="head"/>
      <xsl:element name="zone">
            <xsl:attribute name="xml:id">
                <xsl:value-of select="concat('srcD_line_', $head)"/>
            </xsl:attribute>
            <xsl:attribute name="type">
               <xsl:value-of select="'head-zone'"/>
            </xsl:attribute>
            <xsl:attribute name="start">
               <xsl:value-of select="concat('#', $head/@xml:id)"/>
            </xsl:attribute>
            <xsl:for-each select="$head/tei:lb">
               <xsl:call-template name="head-line">
                  <xsl:with-param name="id" select="@xml:id"/>
                  <xsl:with-param name="head" select="$head"/>
               </xsl:call-template>
               <!--<xsl:element name="line">
                  <xsl:attribute name="start">
                    <xsl:value-of select="concat('#', @xml:id)"/>
                  </xsl:attribute>
                  <xsl:element name="zone">
                     <xsl:attribute name="type">
                       <xsl:value-of select="'head'"/>
                     </xsl:attribute>
                     <xsl:call-template name="parentHeadAdd">
                        <xsl:with-param name="head" select="$head"/>
                        <xsl:with-param name="lb_id" select="@xml:id"/>
                     </xsl:call-template>
                  </xsl:element>
               </xsl:element>-->
            </xsl:for-each>
         </xsl:element>
   </xsl:template>
   <xsl:template name="note-zone">
      <xsl:param name="noteId"/>
      <xsl:param name="place">somewhere</xsl:param>
      <xsl:choose>
         <xsl:when test="//tei:lb[parent::tei:note[@xml:id = $noteId]]">
            <xsl:for-each select="//tei:lb[ancestor::tei:note[@xml:id = $noteId]]">
                <xsl:variable name="bottomValue" select="count(//tei:lb/@n) - index-of(//tei:lb/@n, @n) + 1"/>
                <xsl:element name="zone">
                    <xsl:attribute name="xml:id">
                        <xsl:value-of select="concat('srcD_zone_', $noteId)"/>
                    </xsl:attribute>
                     <xsl:attribute name="type">
                        <xsl:value-of select="'note-zone'"/>
                     </xsl:attribute>
                     <xsl:attribute name="start">
                        <xsl:value-of select="concat('#', @xml:id)"/>
                     </xsl:attribute>
                      <xsl:call-template name="line">
                        <xsl:with-param name="id" select="@xml:id"/>
                        <xsl:with-param name="rend" select="//tei:note[@xml:id = $noteId]/@hand"/>
                        <xsl:with-param name="style" select="concat('bottom:',$bottomValue,'em;')"/>
                     </xsl:call-template>
               </xsl:element>
            </xsl:for-each>
         </xsl:when>
            <xsl:otherwise>
            <xsl:element name="zone">
                <xsl:attribute name="xml:id">
                        <xsl:value-of select="concat('srcD_zone_', $noteId)"/>
                </xsl:attribute>
               <xsl:attribute name="type">
                  <xsl:value-of select="concat('note-', $place)"/>
               </xsl:attribute>
               <xsl:attribute name="start">
                  <xsl:value-of select="concat('#', $noteId)"/>
               </xsl:attribute>
            </xsl:element>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   <xsl:template name="fw-zone">
      <xsl:param name="start_id"/>
      <xsl:param name="end_id"/>
      <xsl:param name="place"/>
      <xsl:for-each select="//tei:fw[ancestor::div1/tei:anchor[1]/@xml:id = $start_id and following-sibling::tei:div2/tei:anchor[1]/@xml:id = $end_id and starts-with(@place, $place)]">
         <xsl:variable name="place" select="if (@place) then (@place) else ($place)"/>
         <xsl:element name="zone">
            <xsl:attribute name="xml:id">
                <xsl:value-of select="concat('srcD_zone_', current()/@xml:id)"/>
            </xsl:attribute>
            <xsl:attribute name="type">
               <xsl:value-of select="concat('fw-', $place)"/>
            </xsl:attribute>
            <xsl:attribute name="start">
               <xsl:value-of select="concat('#', current()/@xml:id)"/>
            </xsl:attribute>
         </xsl:element>
      </xsl:for-each>
   </xsl:template>
</xsl:stylesheet>