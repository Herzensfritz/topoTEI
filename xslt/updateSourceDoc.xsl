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
   <xsl:template name="sourceDoc" match="tei:sourceDoc">
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
                     <xsl:if test="//tei:sourceDoc/tei:surface/@style">
                        <xsl:attribute name="style">
                          <xsl:value-of select="//tei:sourceDoc/tei:surface/@style"/>
                        </xsl:attribute>
                     </xsl:if>
                     <xsl:call-template name="zones">
                        <xsl:with-param name="anchor_id" select="tei:anchor[1]/@xml:id"/>
                     </xsl:call-template>
              </xsl:element>
           </xsl:for-each>
         </xsl:element>
   </xsl:template>
   <xsl:template match="tei:surface|tei:zone|tei:line"/>
   <xsl:template name="zones">
      <xsl:param name="anchor_id"/>
      <xsl:for-each select="tei:div2[ancestor::div1/tei:anchor[1]/@xml:id = $anchor_id]">
         <xsl:variable name="blockType" select="tei:getBlockType(current())"/> 
         <xsl:variable name="xmlId" select="concat('srcD_zone_', tei:anchor[1]/@xml:id)"/>
         <xsl:element name="zone">
           <xsl:attribute name="xml:id">
                <xsl:value-of select="$xmlId"/>
            </xsl:attribute>
            <xsl:attribute name="start">
               <xsl:value-of select="concat('#', tei:anchor[1]/@xml:id)"/>
            </xsl:attribute>
            <xsl:choose>
               <xsl:when test="$blockType eq $FIRST_BLOCK_TYPE or $blockType eq $SINGLE_BLOCK_TYPE">
                  <xsl:attribute name="type">
                     <xsl:value-of select="if ($blockType eq $SINGLE_BLOCK_TYPE) then ('singleBlock') else ('firstBlock')"/>
                  </xsl:attribute>
                  <xsl:attribute name="style">
                     <xsl:value-of select="if (//tei:zone[@xml:id = $xmlId]/@style) then (//tei:zone[@xml:id = $xmlId]/@style) else (if ($blockType eq $SINGLE_BLOCK_TYPE) then ('padding-top:5em;padding-bottom:5em;') else ('padding-top:5em;'))"/>
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
               <xsl:when test="$blockType eq $LAST_BLOCK_TYPE">
                  <xsl:attribute name="type">
                     <xsl:value-of select="'lastBlock'"/>
                  </xsl:attribute>
                  <xsl:attribute name="style">
                     <xsl:value-of select="if (//tei:zone[@xml:id = $xmlId]/@style) then (//tei:zone[@xml:id = $xmlId]/@style) else ('padding-bottom:5em;')"/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:otherwise>
                   <xsl:attribute name="type">
                     <xsl:value-of select="'textBlock'"/>
                  </xsl:attribute>
               </xsl:otherwise>
            </xsl:choose>
            <xsl:call-template name="lines">
               <xsl:with-param name="anchor_id" select="tei:anchor[1]/@xml:id"/>
               <xsl:with-param name="blockType" select="$blockType"/>
            </xsl:call-template>
            <xsl:if test="count(following-sibling::tei:div2) gt 0 and descendant::tei:note">
               <xsl:for-each select="descendant::tei:note">
                  <xsl:if test="tei:getLineType(preceding-sibling::tei:lb[1]) ne $NOTE_LINE_TYPE_F and not(descendant::tei:lb)">
                     <xsl:call-template name="note-zone">
                        <xsl:with-param name="noteId" select="@xml:id"/>
                        <xsl:with-param name="place" select="'bottom'"/>
                     </xsl:call-template>
                  </xsl:if>
               </xsl:for-each>
            </xsl:if>
            <xsl:if test="count(following-sibling::tei:div2) lt 1">
               <xsl:for-each select="following-sibling::tei:note|tei:note">
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
      <xsl:param name="id_prefix">srcD_line_</xsl:param>
      <xsl:param name="rend"/>
      <xsl:param name="hand"/>
      <xsl:param name="anchor_id"/>
      <xsl:param name="style"/>
      <xsl:variable name="xmlId" select="concat($id_prefix, $id)"/>
      <xsl:element name="line">
        <xsl:attribute name="xml:id">
            <xsl:value-of select="$xmlId"/>
        </xsl:attribute>
         <xsl:attribute name="start">
           <xsl:value-of select="concat('#', $id)"/>
         </xsl:attribute>
         <xsl:if test="$style or //tei:line[@xml:id = $xmlId]/@style">
            <xsl:attribute name="style">
              <xsl:value-of select="if (//tei:line[@xml:id = $xmlId]/@style) then (//tei:line[@xml:id = $xmlId]/@style) else ($style)"/>
            </xsl:attribute>
         </xsl:if>
         <xsl:if test="$rend != ''">
            <xsl:attribute name="rend">
              <xsl:value-of select="$rend"/>
            </xsl:attribute>
         </xsl:if>
         <xsl:if test="$hand !=''">
            <xsl:attribute name="hand">
              <xsl:value-of select="$hand"/>
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
      <xsl:param name="blockType"/>
      <xsl:for-each select="//tei:lb[@n and ancestor::tei:div2/tei:anchor[1]/@xml:id = $anchor_id and @xml:id]">
         <xsl:variable name="lineType" select="tei:getLineType(current())"/>
         <xsl:choose>
            <xsl:when test="$lineType eq $DEFAULT_LINE_TYPE">
               <xsl:call-template name="line">
                  <xsl:with-param name="id" select="@xml:id"/>
                  <xsl:with-param name="rend" select="@rend"/>
                  <xsl:with-param name="hand" select="@hand"/>
                  <xsl:with-param name="anchor_id" select="$anchor_id"/>
               </xsl:call-template>
            </xsl:when>
            <xsl:when test="$lineType eq $HEAD_LINE_TYPE or $lineType eq $HEAD_LINE_TYPE_F">
               <xsl:call-template name="head-line">
                  <xsl:with-param name="id" select="@xml:id"/>
                  <xsl:with-param name="head" select="if ($lineType eq $HEAD_LINE_TYPE) then (ancestor::tei:head[1]) else (following-sibling::tei:head[1])"/>
               </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
               <xsl:variable name="hand" select="tei:getAttribute(current(), 'hand', $lineType)"/>
               <xsl:variable name="rend" select="tei:getAttribute(current(), 'rend', $lineType)"/>
               <xsl:variable name="topValue" select="number(replace(@n, '[a-zA-Z]', ''))"/>
               <xsl:variable name="bottomValue" select="if ($blockType eq $MIDDLE_BLOCK_TYPE) then (0) else (count(//tei:lb/@n) - index-of(//tei:lb/@n, @n) + 1)"/>
               <xsl:variable name="style" select="if (index-of(//tei:lb/@n, @n) lt (count(//tei:lb) div 2)) then (concat('top:',$topValue,'em;')) else (concat('bottom:',$bottomValue,'em;'))"/>
               <xsl:element name="zone">   
                  <xsl:choose>
                     <xsl:when test="$lineType eq $NOTE_LINE_TYPE or $lineType eq $NOTE_LINE_TYPE_F">
                        <xsl:variable name="place" select="if (ancestor::tei:note/@place) then (ancestor::tei:note/@place) else (following-sibling::tei:note[1]/@place)"/>
                        <xsl:variable name="id" select="if (ancestor::tei:note/@xml:id) then (ancestor::tei:note/@xml:id) else (following-sibling::tei:note[1]/@xml:id)"/>
                        <xsl:variable name="xmlId" select="concat('srcD_zone_', @xml:id)"/>
                        <xsl:attribute name="xml:id">
                           <xsl:value-of select="$xmlId"/>
                        </xsl:attribute>
                        <xsl:attribute name="start">
                           <xsl:value-of select="concat('#', @xml:id)"/>
                        </xsl:attribute>
                        <xsl:attribute name="type">
                           <xsl:value-of select="'note-zone'"/>
                        </xsl:attribute>
                        <xsl:if test="//tei:zone[@xml:id = $xmlId]/@style">
                           <xsl:attribute name="style">
                              <xsl:value-of select="//tei:zone[@xml:id = $xmlId]/@style"/>
                           </xsl:attribute>
                        </xsl:if>
                     </xsl:when>
                     <xsl:when test="$lineType eq $AB_LINE_TYPE or $lineType eq $AB_LINE_TYPE_F">
                        <xsl:variable name="id" select="if (ancestor::tei:ab/@xml:id) then (ancestor::tei:ab/@xml:id) else (following-sibling::tei:ab[1]/@xml:id)"/>
                        <xsl:variable name="xmlId" select="concat('srcD_zone_', $id, '_',@xml:id)"/>
                        <xsl:attribute name="xml:id">
                           <xsl:value-of select="$xmlId"/>
                        </xsl:attribute>
                        <xsl:attribute name="start">
                           <xsl:value-of select="concat('#', @xml:id)"/>
                        </xsl:attribute>
                        <xsl:attribute name="type">
                           <xsl:value-of select="'ab-zone'"/>
                        </xsl:attribute>
                        <xsl:if test="//tei:zone[@xml:id = $xmlId]/@style">
                           <xsl:attribute name="style">
                              <xsl:value-of select="//tei:zone[@xml:id = $xmlId]/@style"/>
                           </xsl:attribute>
                        </xsl:if>
                     </xsl:when>
                     <xsl:otherwise>
                        <xsl:variable name="xmlId" select="concat('srcD_zone_', @xml:id)"/>
                        <xsl:attribute name="xml:id">
                           <xsl:value-of select="$xmlId"/>
                        </xsl:attribute>
                        <xsl:attribute name="start">
                           <xsl:value-of select="concat('#', @xml:id)"/>
                        </xsl:attribute>
                        <xsl:attribute name="type">
                           <xsl:value-of select="'add-zone'"/>
                        </xsl:attribute>
                        <xsl:if test="//tei:zone[@xml:id = $xmlId]/@style">
                           <xsl:attribute name="style">
                              <xsl:value-of select="//tei:zone[@xml:id = $xmlId]/@style"/>
                           </xsl:attribute>
                        </xsl:if>
                     </xsl:otherwise>
                  </xsl:choose>
                  <xsl:call-template name="line">
                     <xsl:with-param name="id" select="@xml:id"/>
                     <xsl:with-param name="hand" select="$hand"/>
                     <xsl:with-param name="rend" select="$rend"/>
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
      <xsl:param name="updateId"/>
      <xsl:for-each select="//tei:add[@xml:id and (contains(@place, 'above') or contains(@place, 'below')) and ancestor::tei:div2/tei:anchor[1]/@xml:id = $anchor_id and preceding::tei:lb[1][@xml:id = $lb_id] and not(ancestor::tei:add[contains(@place, 'above') or contains(@place, 'below')])]">
         <xsl:choose>
            <xsl:when test="$updateId and //tei:line[@xml:id = $updateId]//tei:*[@* = concat('#', current()/@xml:id)]">
               <xsl:copy-of select="if (//tei:line[@xml:id = $updateId]//tei:metamark[@target=concat('#', current()/@xml:id)]) then (//tei:line[@xml:id = $updateId]//tei:metamark[@target=concat('#', current()/@xml:id)]) else (//tei:line[@xml:id = $updateId]//tei:add[@corresp = concat('#', current()/@xml:id)])"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:call-template name="add">
                  <xsl:with-param name="id" select="@xml:id"/>
                  <xsl:with-param name="rend" select="@rend"/>
               </xsl:call-template>
            </xsl:otherwise>
         </xsl:choose>
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
            <xsl:variable name="metamarkXmlId" select="concat('srcD_metamark_', $id)"/>
            <xsl:element name="metamark">
                <xsl:attribute name="xml:id">
                    <xsl:value-of select="$metamarkXmlId"/>
               </xsl:attribute>
               <xsl:attribute name="function">
                 <xsl:value-of select="'insertion'"/>
               </xsl:attribute>
               <xsl:attribute name="target">
                 <xsl:value-of select="concat('#', $id)"/>
               </xsl:attribute>
               <xsl:if test="//tei:metamark[@xml:id = $metamarkXmlId]/@style">
                  <xsl:attribute name="style">
                    <xsl:value-of select="//tei:metamark[@xml:id = $metamarkXmlId]/@style"/>
                  </xsl:attribute>
               </xsl:if>
               <xsl:element name="add">
                   <xsl:variable name="addXmlId" select="concat('srcD_insM_add_', $id)"/>
                   <xsl:attribute name="xml:id">
                       <xsl:value-of select="$addXmlId"/>
                  </xsl:attribute>
                  <xsl:attribute name="corresp">
                    <xsl:value-of select="concat('#', $id)"/>
                  </xsl:attribute>
                  <xsl:if test="//tei:add[@xml:id = $addXmlId]/@style">
                     <xsl:attribute name="style">
                        <xsl:value-of select="//tei:add[@xml:id = $addXmlId]/@style"/>
                     </xsl:attribute>
                  </xsl:if>
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
                <xsl:variable name="addXmlId" select="concat('srcD_add_', $id)"/>
                <xsl:attribute name="xml:id">
                    <xsl:value-of select="$addXmlId"/>
                </xsl:attribute>
               <xsl:attribute name="corresp">
                 <xsl:value-of select="concat('#', $id)"/>
               </xsl:attribute>
               <xsl:if test="//tei:add[@xml:id = $addXmlId]/@style">
                     <xsl:attribute name="style">
                        <xsl:value-of select="//tei:add[@xml:id = $addXmlId]/@style"/>
                     </xsl:attribute>
                  </xsl:if>
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
      <xsl:variable name="xmlId" select="concat('srcD_zone_', $head/@xml:id, '_', $id)"/>
      <xsl:variable name="lineXmlId" select="concat('srcD_line_', $head/@xml:id, '_', $id)"/>
      <xsl:element name="line">
         <xsl:attribute name="xml:id">
             <xsl:value-of select="$lineXmlId"/>
         </xsl:attribute>
         <xsl:attribute name="start">
           <xsl:value-of select="concat('#', $id)"/>
         </xsl:attribute>
         <xsl:if test="//tei:lb[@xml:id = $id]/@rend">
            <xsl:attribute name="rend">
              <xsl:value-of select="//tei:lb[@xml:id = $id]/@rend"/>
            </xsl:attribute>
         </xsl:if>
         <xsl:if test="//tei:line[@xml:id = $lineXmlId]/@style">
            <xsl:attribute name="style">
              <xsl:value-of select="//tei:line[@xml:id = $lineXmlId]/@style"/>
            </xsl:attribute>
         </xsl:if>
         <xsl:element name="zone">
            <xsl:attribute name="xml:id">
                <xsl:value-of select="$xmlId"/>
            </xsl:attribute>
            <xsl:attribute name="type">
              <xsl:value-of select="'head'"/>
            </xsl:attribute>
            <xsl:if test="//tei:zone[@xml:id = $xmlId]/@style">
               <xsl:attribute name="style">
                 <xsl:value-of select="//tei:zone[@xml:id = $xmlId]/@style"/>
               </xsl:attribute>
            </xsl:if>
            <xsl:call-template name="parentHeadAdd">
               <xsl:with-param name="head" select="$head"/>
               <xsl:with-param name="lb_id" select="$id"/>
            </xsl:call-template>
         </xsl:element>
      </xsl:element>
   </xsl:template>
   <xsl:template name="head-zone">
      <xsl:param name="head"/>
      <xsl:variable name="xmlId" select="concat('srcD_head_', $head)"/>
      <xsl:element name="zone">
            <xsl:attribute name="xml:id">
                <xsl:value-of select="$xmlId"/>
            </xsl:attribute>
            <xsl:attribute name="type">
               <xsl:value-of select="'head-zone'"/>
            </xsl:attribute>
            <xsl:attribute name="start">
               <xsl:value-of select="concat('#', $head/@xml:id)"/>
            </xsl:attribute>
             <xsl:if test="//tei:zone[@xml:id = $xmlId]/@style">
               <xsl:attribute name="style">
                  <xsl:value-of select="//tei:zone[@xml:id = $xmlId]/@style"/>
               </xsl:attribute>
            </xsl:if>
            <xsl:for-each select="$head/tei:lb">
               <xsl:call-template name="head-line">
                  <xsl:with-param name="id" select="@xml:id"/>
                  <xsl:with-param name="head" select="$head"/>
               </xsl:call-template>
            </xsl:for-each>
         </xsl:element>
   </xsl:template>
   <xsl:template name="note-zone">
      <xsl:param name="noteId"/>
      <xsl:param name="place">somewhere</xsl:param>
      <xsl:choose>
         <xsl:when test="//tei:lb[@n and parent::tei:note[@xml:id = $noteId]]">
            <xsl:for-each select="//tei:lb[ancestor::tei:note[@xml:id = $noteId]]">
                <xsl:variable name="xmlId" select="concat('srcD_zone_', $noteId, '_', @xml:id)"/>
                <xsl:variable name="line_id_prefix" select="concat('srcD_line', '_', $noteId, '_')"/>
                <xsl:variable name="bottomValue" select="count(//tei:lb/@n) - index-of(//tei:lb/@n, @n) + 1"/>
                <xsl:variable name="topValue" select="number(@n)"/>
                <xsl:variable name="style" select="if (index-of(//tei:lb/@n, @n) lt (count(//tei:lb) div 2)) then (concat('top:',$topValue,'em;')) else (concat('bottom:',$bottomValue,'em;'))"/>
                <xsl:element name="zone">
                    <xsl:attribute name="xml:id">
                        <xsl:value-of select="$xmlId"/>
                    </xsl:attribute>
                     <xsl:attribute name="type">
                        <xsl:value-of select="'note-zone'"/>
                     </xsl:attribute>
                     <xsl:attribute name="start">
                        <xsl:value-of select="concat('#', @xml:id)"/>
                     </xsl:attribute>
                     <xsl:if test="//tei:zone[@xml:id = $xmlId]/@style">
                        <xsl:attribute name="style">
                           <xsl:value-of select="//tei:zone[@xml:id = $xmlId]/@style"/>
                        </xsl:attribute>
                     </xsl:if>
                      <xsl:call-template name="line">
                        <xsl:with-param name="id" select="@xml:id"/>
                        <xsl:with-param name="id_prefix" select="$line_id_prefix"/>
                        <xsl:with-param name="rend" select="//tei:note[@xml:id = $noteId]/@hand"/>
                        <xsl:with-param name="style" select="$style"/>
                     </xsl:call-template>
               </xsl:element>
            </xsl:for-each>
         </xsl:when>
            <xsl:otherwise>
               <xsl:variable name="xmlId" select="concat('srcD_zone_', $noteId)"/>
               <xsl:element name="zone">
                   <xsl:attribute name="xml:id">
                     <xsl:value-of select="$xmlId"/>
                   </xsl:attribute>
                  <xsl:attribute name="type">
                     <xsl:value-of select="concat('note-', $place)"/>
                  </xsl:attribute>
                  <xsl:attribute name="start">
                     <xsl:value-of select="concat('#', $noteId)"/>
                  </xsl:attribute>
                  <xsl:if test="//tei:zone[@xml:id = $xmlId]/@style">
                     <xsl:attribute name="style">
                        <xsl:value-of select="//tei:zone[@xml:id = $xmlId]/@style"/>
                     </xsl:attribute>
                  </xsl:if>
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
         <xsl:variable name="xmlId" select="concat('srcD_zone_', current()/@xml:id)"/>
         <xsl:element name="zone">
            <xsl:attribute name="xml:id">
                <xsl:value-of select="$xmlId"/>
            </xsl:attribute>
            <xsl:attribute name="type">
               <xsl:value-of select="concat('fw-', $place)"/>
            </xsl:attribute>
            <xsl:attribute name="start">
               <xsl:value-of select="concat('#', current()/@xml:id)"/>
            </xsl:attribute>
            <xsl:if test="//tei:zone[@xml:id = $xmlId]/@style">
               <xsl:attribute name="style">
                  <xsl:value-of select="//tei:zone[@xml:id = $xmlId]/@style"/>
               </xsl:attribute>
            </xsl:if>
         </xsl:element>
      </xsl:for-each>
   </xsl:template>
</xsl:stylesheet>