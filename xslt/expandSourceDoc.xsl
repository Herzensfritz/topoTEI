<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" version="2.0">
   <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
   <xsl:variable name="METAMARK_EXCLUDE_STRING" select="'target'"/>
   <xsl:variable name="ADD_EXCLUDE_STRING" select="'xml:id'"/>
   <xsl:variable name="DEFAULT_EXCLUDE_STRING" select="'xml:id seq'"/>
   <xsl:function name="tei:filterOpeningTags">
      <xsl:param name="openingTags"/>
      <xsl:if test="count($openingTags) gt 0">
         <xsl:sequence select="if (tei:includeOpeningTag($openingTags[1]/local-name())) then ($openingTags[1], tei:filterOpeningTags(subsequence($openingTags, 2))) else (tei:filterOpeningTags(subsequence($openingTags, 2))) "/>
      </xsl:if>
   </xsl:function>
   <xsl:function name="tei:includeOpeningTag" as="xs:boolean">
      <xsl:param name="tagName"/>
      <xsl:choose>
         <xsl:when test="$tagName = 'subst'">
            <xsl:value-of select="false()"/>
         </xsl:when>
         <xsl:when test="$tagName = 'choice'">
            <xsl:value-of select="false()"/>
         </xsl:when>
         <xsl:when test="$tagName = 'sic'">
            <xsl:value-of select="false()"/>
         </xsl:when>
         <xsl:when test="$tagName = 'corr'">
            <xsl:value-of select="false()"/>
         </xsl:when>
         <xsl:when test="$tagName = 'supplied'">
            <xsl:value-of select="false()"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:value-of select="true()"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   <xsl:template match="/tei:TEI">
      <xsl:element name="TEI" namespace="http://www.tei-c.org/ns/1.0">
         <xsl:call-template name="copyAttributes"/>
         <xsl:copy-of select="//(tei:teiHeader|tei:text)"/> 
         <xsl:element name="sourceDoc" namespace="http://www.tei-c.org/ns/1.0">
            <xsl:apply-templates select="//tei:surface"/>
         </xsl:element>
      </xsl:element>
   </xsl:template>
   <xsl:template match="tei:surface">
      <xsl:element name="surface" namespace="http://www.tei-c.org/ns/1.0">
         <xsl:call-template name="copyAttributes"/>
         <xsl:attribute name="facs">
            <xsl:value-of select="//tei:pb[@xml:id = substring-after(current()/@start, '#')]/@facs"/>
         </xsl:attribute>
      <xsl:apply-templates/>
      </xsl:element>
   </xsl:template>
   <xsl:template match="tei:zone[tei:line]">
      <xsl:element name="zone" namespace="http://www.tei-c.org/ns/1.0">
         <xsl:call-template name="copyAttributes"/>
         <xsl:apply-templates/>
      </xsl:element>
   </xsl:template>
   <xsl:template match="tei:zone">
      <xsl:element name="zone" namespace="http://www.tei-c.org/ns/1.0">
         <xsl:call-template name="copyAttributes"/>
         <xsl:apply-templates select="//*[@xml:id = substring-after(current()/@start, '#')]"/>
      </xsl:element>
   </xsl:template>
   <xsl:template match="tei:line[tei:zone]">
      <xsl:variable name="startId" select="substring-after(@start, '#')"/>
      <xsl:variable name="endId" select="if (following::tei:line) then (substring-after(following::tei:line[1]/@start, '#')) else (if (parent::tei:zone/following-sibling::tei:*[1]/local-name() = 'line') then (substring-after(parent::tei:zone/following-sibling::tei:line[1]/@start, '#')) else (substring-after(parent::tei:zone/following-sibling::tei:zone[1]/tei:line[1]/@start,'#')))"/>
      <xsl:element name="line" namespace="http://www.tei-c.org/ns/1.0">
         <xsl:call-template name="copyAttributes"/>
         <xsl:attribute name="n">
            <xsl:value-of select="//tei:lb[@xml:id = $startId]/@n"/>
         </xsl:attribute>
         <xsl:if test="//tei:lb[@xml:id = $startId]/preceding::tei:handShift">
            <xsl:attribute name="hand">
               <xsl:value-of select="//tei:lb[@xml:id = $startId]/preceding::tei:handShift[1]/@new"/>
            </xsl:attribute>
         </xsl:if>
         <xsl:element name="zone" namespace="http://www.tei-c.org/ns/1.0">
            <xsl:call-template name="copyNodeAttributes">
               <xsl:with-param name="node" select="tei:zone"/>
            </xsl:call-template>
            <xsl:call-template name="selectLbContent">
               <xsl:with-param name="startId" select="$startId"/>
               <xsl:with-param name="endId" select="$endId"/>
               <xsl:with-param name="parentSequence" select="//tei:lb[@xml:id = $startId]/parent::*[local-name() = 'del' or local-name() = 'hi']"/>
            </xsl:call-template>
         </xsl:element>
      </xsl:element>
   </xsl:template>
   <xsl:template match="tei:line[empty(@start)]">
      <xsl:copy-of select="."/>
   </xsl:template>
   <xsl:template match="tei:line">
      <xsl:element name="line" namespace="http://www.tei-c.org/ns/1.0">
         <xsl:variable name="startId" select="substring-after(@start, '#')"/>
         <xsl:variable name="endId" select="if (following::tei:line) then (substring-after(following::tei:line[1]/@start, '#')) else (if (parent::tei:zone/following-sibling::tei:*[1]/local-name() = 'line') then (substring-after(parent::tei:zone/following-sibling::tei:line[1]/@start, '#')) else (substring-after(parent::tei:zone/following-sibling::tei:zone[1]/tei:line[1]/@start,'#')))"/>
         <xsl:call-template name="copyAttributes"/>
         <xsl:attribute name="n">
            <xsl:value-of select="//tei:lb[@xml:id = $startId]/@n"/>
         </xsl:attribute>
         <xsl:if test="//tei:lb[@xml:id = $startId]/preceding::tei:handShift">
            <xsl:attribute name="hand">
               <xsl:value-of select="//tei:lb[@xml:id = $startId]/preceding::tei:handShift[1]/@new"/>
            </xsl:attribute>
         </xsl:if>
         <xsl:call-template name="selectLbContent">
            <xsl:with-param name="startId" select="$startId"/>
            <xsl:with-param name="endId" select="$endId"/>
            <xsl:with-param name="parentSequence" select="//tei:lb[@xml:id = $startId]/ancestor::*[local-name() = 'del' or local-name() = 'hi' or local-name() = 'add']"/>
         </xsl:call-template>
         </xsl:element>
   </xsl:template>
   <xsl:template match="tei:foreign">
      <xsl:element name="hi" namespace="http://www.tei-c.org/ns/1.0">
         <xsl:attribute name="rend">
            <xsl:value-of select="@xml:lang"/>
         </xsl:attribute>
         <xsl:apply-templates select="if (tei:reg) then (tei:reg/text()) else (text())"/>
      </xsl:element>
   </xsl:template>
   <xsl:template match="tei:subst|tei:head|tei:reg|tei:supplied">
      <xsl:apply-templates>
         <xsl:with-param name="instant" select="@instant"/>
      </xsl:apply-templates>
   </xsl:template>
   <xsl:template match="tei:del[@rend='overwritten' and starts-with(@cause, 'insM') and (following-sibling::tei:add[@rend = current()/@cause and parent::tei:subst/@xml:id = current()/parent::tei:subst/@xml:id] or preceding-sibling::tei:add[@rend = current()/@cause and parent::tei:subst/@xml:id = current()/parent::tei:subst/@xml:id])]">
      <xsl:variable name="causeId" select="if (following-sibling::tei:add[@rend = current()/@cause and parent::tei:subst/@xml:id = current()/parent::tei:subst/@xml:id]) then (following-sibling::tei:add[@rend = current()/@cause and parent::tei:subst/@xml:id = current()/parent::tei:subst/@xml:id][1]/@xml:id) else (preceding-sibling::tei:add[@rend = current()/@cause and parent::tei:subst/@xml:id = current()/parent::tei:subst/@xml:id][1]/@xml:id)"/>
      <xsl:variable name="metamarkId" select="//tei:metamark[@target= concat('#', $causeId)]/@xml:id"/>
      <xsl:element name="{local-name()}" namespace="http://www.tei-c.org/ns/1.0">
         <xsl:call-template name="copyNodeAttributes">
            <xsl:with-param name="node" select="current()"/>
            <xsl:with-param name="excludeString" select="$DEFAULT_EXCLUDE_STRING"/>
         </xsl:call-template>
         <xsl:attribute name="cause">
             <xsl:value-of select="concat('#', $metamarkId)"/>
        </xsl:attribute>
        <xsl:apply-templates/>
      </xsl:element>
   </xsl:template> 
   <xsl:template match="tei:del[(following-sibling::tei:add[@place='superimposed' and ancestor::tei:subst/@xml:id = current()/ancestor::tei:subst/@xml:id] or preceding-sibling::tei:add[@place='superimposed' and ancestor::tei:subst/@xml:id = current()/ancestor::tei:subst/@xml:id]) and (@rend='overwritten' or (@rend='erased' and ancestor::tei:subst and not(ancestor::tei:del[@rend='overwritten']))) and not(@cause)]">
      <xsl:variable name="causeId" select="if (following-sibling::tei:add[@place='superimposed' and ancestor::tei:subst/@xml:id = current()/ancestor::tei:subst/@xml:id]) then (following-sibling::tei:add[@place='superimposed' and ancestor::tei:subst/@xml:id = current()/ancestor::tei:subst/@xml:id][1]/@xml:id) else (preceding-sibling::tei:add[@place='superimposed' and ancestor::tei:subst/@xml:id = current()/ancestor::tei:subst/@xml:id][1]/@xml:id)"/>
      <xsl:element name="{local-name()}" namespace="http://www.tei-c.org/ns/1.0">
         <xsl:call-template name="copyNodeAttributes">
            <xsl:with-param name="node" select="current()"/>
            <xsl:with-param name="excludeString" select="$DEFAULT_EXCLUDE_STRING"/>
         </xsl:call-template>
         <xsl:attribute name="cause">
             <xsl:value-of select="concat('#', $causeId)"/>
        </xsl:attribute>
        <xsl:apply-templates/>
      </xsl:element>
   </xsl:template> 
   <xsl:template match="tei:add[@place='above' or @place='below']">
      <xsl:param name="instant"/>
      <xsl:choose>
         <xsl:when test="//tei:metamark[@target= concat('#', current()/@xml:id)]">
            <xsl:element name="metamark" namespace="http://www.tei-c.org/ns/1.0">
               <xsl:call-template name="copyNodeAttributes">
                  <xsl:with-param name="node" select="//tei:metamark[@target= concat('#', current()/@xml:id)]"/>
                  <xsl:with-param name="excludeString" select="$METAMARK_EXCLUDE_STRING"/>
               </xsl:call-template>
               <xsl:element name="add" namespace="http://www.tei-c.org/ns/1.0">
                  <xsl:attribute name="place">
                      <xsl:value-of select="current()/@place"/>
                 </xsl:attribute>
                  <xsl:if test="current()/@hand">
                     <xsl:attribute name="hand">
                         <xsl:value-of select="current()/@hand"/>
                    </xsl:attribute>
                  </xsl:if>
                  <xsl:if test="current()/@instant or parent::tei:subst/@instant">
                     <xsl:attribute name="instant">
                         <xsl:value-of select="current()/@instant|parent::tei:subst/@instant"/>
                    </xsl:attribute>
                  </xsl:if>

                  <xsl:call-template name="copyNodeAttributes">
                     <xsl:with-param name="node" select="//tei:metamark[@target= concat('#', current()/@xml:id)]/tei:add"/>
                     <xsl:with-param name="excludeString" select="$ADD_EXCLUDE_STRING"/>
                  </xsl:call-template>
                  <xsl:apply-templates/>
               </xsl:element>
            </xsl:element>
         </xsl:when>
         <xsl:otherwise>
            <xsl:element name="add" namespace="http://www.tei-c.org/ns/1.0">
                  <xsl:call-template name="copyNodeAttributes">
                     <xsl:with-param name="node" select="//tei:add[@corresp = concat('#', current()/@xml:id)]"/>
                     <xsl:with-param name="excludeString" select="$ADD_EXCLUDE_STRING"/>
                  </xsl:call-template>
                  <xsl:attribute name="place">
                      <xsl:value-of select="current()/@place"/>
                 </xsl:attribute>
                 <xsl:if test="current()/@hand">
                     <xsl:attribute name="hand">
                         <xsl:value-of select="current()/@hand"/>
                    </xsl:attribute>
                  </xsl:if>
                  <xsl:if test="current()/@instant or parent::tei:subst/@instant">
                     <xsl:attribute name="instant">
                         <xsl:value-of select="current()/@instant|parent::tei:subst/@instant"/>
                    </xsl:attribute>
                  </xsl:if>

                  <xsl:apply-templates/>
            </xsl:element>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   <xsl:template match="tei:corr[parent::tei:choice[descendant::tei:lb]]"/>
   <!--
   <xsl:template match="tei:sic">
      <xsl:param name="startId"/>
      <xsl:param name="endId"/>
      <xsl:param name="parents"/>
      <xsl:apply-templates>
         <xsl:with-param name="parents" select="if($parents) then ($parents|current()) else (current())"/>
         <xsl:with-param name="endId" select="$endId"/>
         <xsl:with-param name="startId" select="$startId"/>
      </xsl:apply-templates>
   </xsl:template>-->
   <!--<xsl:template name="choice">
      <xsl:param name="startId"/>
      <xsl:param name="endId"/>
      <xsl:param name="parents"/>
      <xsl:param name="choice"/>
      <xsl:param name="isOpening" as="xs:boolean">false</xsl:param>
      <xsl:variable name="id" select="if ($choice) then ($choice/@xml:id) else (@xml:id)"/>
      <xsl:variable name="indexId" select="concat($id, '_index')"/>
      <xsl:variable name="anchorId" select="concat($id, '_anchor')"/>
      <xsl:variable name="tagName" select="if ($choice) then ($choice/local-name()) else (local-name())"/>
      <xsl:if test="$isOpening or not($choice)">
         <xsl:element name="index" namespace="http://www.tei-c.org/ns/1.0">
            <xsl:attribute name="indexName">
               <xsl:value-of select="if ($choice) then ($choice/local-name()) else (local-name())"/>
            </xsl:attribute>
            <xsl:attribute name="spanTo">
               <xsl:value-of select="concat('#', $anchorId)"/>
            </xsl:attribute>
            <xsl:attribute name="corresp">
               <xsl:value-of select="concat('#', $id)"/>
            </xsl:attribute>
         </xsl:element>
      </xsl:if>
      <xsl:if test="not($choice)">
         <xsl:apply-templates select="tei:sic">
            <xsl:with-param name="parents" select="if($parents) then ($parents|current()) else (current())"/>
            <xsl:with-param name="endId" select="$endId"/>
            <xsl:with-param name="startId" select="$startId"/>
         </xsl:apply-templates>
      </xsl:if>
      <xsl:if test="not($isOpening)">
         <xsl:element name="anchor" namespace="http://www.tei-c.org/ns/1.0">
            <xsl:attribute name="xml:id">
               <xsl:value-of select="$anchorId"/>
            </xsl:attribute>
         </xsl:element>
      </xsl:if>
   </xsl:template>

      -->
   <xsl:template name="choice">
      <xsl:param name="startId"/>
      <xsl:param name="endId"/>
      <xsl:param name="parents"/>
      <xsl:param name="choice"/>
      <xsl:param name="isOpening" as="xs:boolean">false</xsl:param>
      <xsl:variable name="lbId" select="$choice/descendant::tei:lb/@xml:id"/>
      <xsl:variable name="id" select="$choice/@xml:id"/>
      <xsl:element name="choice" namespace="http://www.tei-c.org/ns/1.0">
            <xsl:attribute name="corresp">
               <xsl:value-of select="concat('#', $id)"/>
            </xsl:attribute>
            <xsl:element name="orig" namespace="http://www.tei-c.org/ns/1.0">
                  <xsl:apply-templates select="if ($isOpening) then ($choice/tei:sic/(*|text())[following::tei:lb[@xml:id = $lbId]]) else ($choice/tei:sic/(*|text())[preceding::tei:lb[@xml:id = $lbId]])">
                  <xsl:with-param name="parents" select="if($parents) then ($parents|current()) else (current())"/>
                  <xsl:with-param name="endId" select="$endId"/>
                  <xsl:with-param name="startId" select="$startId"/>
               </xsl:apply-templates>
            </xsl:element>
            <xsl:copy-of select="$choice/(tei:sic|tei:corr)"/>
         </xsl:element>
   </xsl:template>
   <xsl:template match="*">
      <xsl:param name="startId"/>
      <xsl:param name="endId"/>
      <xsl:param name="parents"/>
      <xsl:param name="instant"/>
      <xsl:element name="{local-name()}" namespace="http://www.tei-c.org/ns/1.0">
         <xsl:call-template name="copyAttributes">
            <xsl:with-param name="id2corresp">true</xsl:with-param>
         </xsl:call-template>
         <xsl:if test="$instant and local-name() = 'add'">
            <xsl:attribute name="instant">
                <xsl:value-of select="$instant"/>
              </xsl:attribute>
         </xsl:if>
         <xsl:apply-templates>
            <xsl:with-param name="parents" select="if($parents) then ($parents|current()) else (current())"/>
            <xsl:with-param name="endId" select="$endId"/>
            <xsl:with-param name="startId" select="$startId"/>
         </xsl:apply-templates>
      </xsl:element>
   </xsl:template>
   <xsl:template name="printTextParents">
      <xsl:param name="openingTags"/>
      <xsl:param name="text"/>
      <xsl:param name="parentTag"/>
      <xsl:element name="{$openingTags[1]/local-name()}" namespace="http://www.tei-c.org/ns/1.0">
         <xsl:call-template name="copyNodeAttributes">
            <xsl:with-param name="node" select="$openingTags[1]"/>
            <xsl:with-param name="excludeString" select="$DEFAULT_EXCLUDE_STRING"/>
         </xsl:call-template>
         <xsl:choose>
            <xsl:when test="count($openingTags) gt 1">
               <xsl:call-template name="printTextParents">
                  <xsl:with-param name="openingTags" select="subsequence($openingTags, 2)"/>
                  <xsl:with-param name="text" select="$text"/>
                  <xsl:with-param name="parentTag" select="$parentTag"/>
               </xsl:call-template>
            </xsl:when>
            <xsl:when test="$parentTag">
               <xsl:element name="{$parentTag/name()}" namespace="http://www.tei-c.org/ns/1.0">
                  <xsl:call-template name="copyNodeAttributes">
                     <xsl:with-param name="node" select="$parentTag"/>
                     <xsl:with-param name="excludeString" select="$DEFAULT_EXCLUDE_STRING"/>
                  </xsl:call-template>
                  <xsl:value-of select="$text"/>
               </xsl:element>
            </xsl:when>
            <xsl:otherwise>
               <xsl:value-of select="$text"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:element>
   </xsl:template>
   <xsl:template match="tei:pc">
      <xsl:param name="startId"/>
      <xsl:param name="endId"/>
      <xsl:variable name="openingTags" select="if ($startId and $endId) then (ancestor::*[local-name() != 'subst' and preceding::tei:lb[@xml:id = $startId] and not(following::tei:lb[@xml:id = $endId])]) else ()"/>
      <xsl:choose>
         <xsl:when test="count($openingTags) gt 0 and not(matches(., '^\s+$'))">
            <xsl:call-template name="printTextParents">
               <xsl:with-param name="openingTags" select="$openingTags"/>
               <xsl:with-param name="text" select="text()"/>
               <xsl:with-param name="parentTag" select="."/>
            </xsl:call-template>
         </xsl:when>
         <xsl:otherwise>
            <xsl:copy-of select="."/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   <xsl:template match="text()">
      <xsl:param name="startId"/>
      <xsl:param name="endId"/>
      <xsl:variable name="openingTags" select="if ($startId and $endId) then (tei:filterOpeningTags(ancestor::*[preceding::tei:lb[@xml:id = $startId] and not(following::tei:lb[@xml:id = $endId])])) else ()"/>
      <xsl:variable name="openingChoice" select="if ($startId and $endId) then (ancestor::tei:choice[preceding::tei:lb[@xml:id = $startId] and not(following::tei:lb[@xml:id = $endId])]) else ()"/>
      <xsl:variable name="endingChoice" select="if ($startId and $endId) then (ancestor::tei:choice[descendant::tei:lb[@xml:id = $startId] and not(descendant::tei:lb[@xml:id = $endId])]) else ()"/>
      <xsl:choose>
         <xsl:when test="count($openingChoice) gt 0">
            <xsl:call-template name="choice">
               <xsl:with-param name="choice" select="$openingChoice[1]"/>
               <xsl:with-param name="isOpening" select="true()"/>
            </xsl:call-template>
         </xsl:when>
         <xsl:when test="count($endingChoice) gt 0">
               <xsl:call-template name="choice">
                  <xsl:with-param name="choice" select="$endingChoice[1]"/>
               </xsl:call-template>
            </xsl:when>
         <xsl:when test="count($openingTags) gt 0 and not(matches(., '^\s+$'))">
            <xsl:call-template name="printTextParents">
               <xsl:with-param name="openingTags" select="$openingTags"/>
               <xsl:with-param name="text" select="."/>
            </xsl:call-template>
         </xsl:when>
         <xsl:otherwise>
            <xsl:value-of select="."/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   <xsl:template name="selectLbContent">
      <xsl:param name="startId"/>
      <xsl:param name="startNode"/>
      <xsl:param name="endId"/>
      <xsl:param name="parentNode"/>
      <xsl:param name="parentSequence"/>
      <xsl:choose>
            <xsl:when test="count($parentSequence) gt 0">
               <xsl:choose>
                  <xsl:when test="($endId and //tei:lb[@xml:id = $endId and ancestor::* = $parentSequence[1]]) or ($parentNode and $parentNode/ancestor::* = $parentSequence[1])">
                     <xsl:element name="{$parentSequence[1]/local-name()}" namespace="http://www.tei-c.org/ns/1.0">
                        <xsl:for-each select="$parentSequence[1]/@*[name() != 'xml:id']">
                             <xsl:variable name="attName" select="if (starts-with(name(),'xml:')) then (name()) else (local-name())"/>
                             <xsl:attribute name="{$attName}">
                               <xsl:value-of select="."/>
                             </xsl:attribute>
                        </xsl:for-each>
                        <xsl:call-template name="selectLbContent">
                           <xsl:with-param name="startId" select="$startId"/>
                           <xsl:with-param name="endId" select="$endId"/>
                           <xsl:with-param name="parentSequence" select="subsequence($parentSequence, 2)"/>
                        </xsl:call-template>
                     </xsl:element>
                  </xsl:when>
                  <xsl:when test="($endId and //tei:lb[@xml:id = $endId and preceding::* = $parentSequence[1]]) or ($parentNode and $parentNode/preceding::* = $parentSequence[1])">
                     <xsl:variable name="newParentNode" select="$parentSequence[1]"/>
                     <xsl:element name="{$parentSequence[1]/local-name()}" namespace="http://www.tei-c.org/ns/1.0">
                        <xsl:for-each select="$parentSequence[1]/@*[name() != 'xml:id']">
                             <xsl:variable name="attName" select="if (starts-with(name(),'xml:')) then (name()) else (local-name())"/>
                             <xsl:attribute name="{$attName}">
                               <xsl:value-of select="."/>
                             </xsl:attribute>
                        </xsl:for-each>
                        <xsl:call-template name="selectLbContent">
                           <xsl:with-param name="startId" select="$startId"/>
                           <xsl:with-param name="parentNode" select="$newParentNode"/>
                           <xsl:with-param name="parentSequence" select="subsequence($parentSequence, 2)"/>
                        </xsl:call-template>
                     </xsl:element>
                     <xsl:call-template name="selectLbContent">
                           <xsl:with-param name="startNode" select="$parentSequence[1]"/>
                           <xsl:with-param name="endId" select="$endId"/>
                           <xsl:with-param name="parentNode" select="$parentNode"/>
                           <xsl:with-param name="parentSequence" select="subsequence($parentSequence, 2)"/>
                     </xsl:call-template>
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:variable name="newParentNode" select="$parentSequence[1]"/>
                     <xsl:element name="{$parentSequence[1]/local-name()}" namespace="http://www.tei-c.org/ns/1.0">
                        <xsl:for-each select="$parentSequence[1]/@*[name() != 'xml:id']">
                             <xsl:variable name="attName" select="if (starts-with(name(),'xml:')) then (name()) else (local-name())"/>
                             <xsl:attribute name="{$attName}">
                               <xsl:value-of select="."/>
                             </xsl:attribute>
                        </xsl:for-each>
                        <xsl:call-template name="selectLbContent">
                           <xsl:with-param name="startId" select="$startId"/>
                           <xsl:with-param name="parentNode" select="$newParentNode"/>
                           <xsl:with-param name="parentSequence" select="subsequence($parentSequence, 2)"/>
                        </xsl:call-template>
                     </xsl:element>
                     <xsl:call-template name="selectLbContent">
                           <xsl:with-param name="startNode" select="$parentSequence[1]"/>
                           <xsl:with-param name="endId" select="$endId"/>
                           <xsl:with-param name="parentNode" select="$parentNode"/>
                           <xsl:with-param name="parentSequence" select="subsequence($parentSequence, 2)"/>
                     </xsl:call-template>
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:when>
            <xsl:when test="$startNode and $parentNode">
               <xsl:apply-templates select="//tei:text//(*|text())[preceding::* = $startNode and ancestor::* = $parentNode and not((parent::*[preceding::* = $startNode and ancestor::* = $parentNode]))]">
                  <xsl:with-param name="endId" select="$endId"/>
                  <xsl:with-param name="startId" select="$startId"/>
                  <xsl:with-param name="parentNode" select="$parentNode"/>
               </xsl:apply-templates>
            </xsl:when>
            <xsl:when test="$startNode and $endId">
               <xsl:apply-templates select="//tei:text//(*|text())[preceding::* = $startNode and following::tei:lb[@xml:id = $endId] and not((parent::*[preceding::* = $startNode and following::tei:lb[@xml:id = $endId]]))]">
                  <xsl:with-param name="endId" select="$endId"/>
                  <xsl:with-param name="startId" select="$startId"/>
                  <xsl:with-param name="parentNode" select="$parentNode"/>
               </xsl:apply-templates>
            </xsl:when>
            <xsl:when test="$startId and $parentNode">
               <xsl:apply-templates select="//tei:text//(*|text())[preceding::tei:lb[@xml:id = $startId] and ancestor::* = $parentNode and not((parent::*[preceding::tei:lb[@xml:id = $startId] and ancestor::* = $parentNode]))]">
                  <xsl:with-param name="parentNode" select="$parentNode"/>
                  <xsl:with-param name="startId" select="$startId"/>
               </xsl:apply-templates>
            </xsl:when>
            <xsl:when test="$endId and count(//(*|text())[preceding::tei:lb[@xml:id = $startId] and following::tei:lb[@xml:id = $endId]]) gt 0">
               <xsl:apply-templates select="//tei:text//(*|text())[preceding::tei:lb[@xml:id = $startId] and following::tei:lb[@xml:id = $endId] and not((parent::*[preceding::tei:lb[@xml:id = $startId] and following::tei:lb[@xml:id = $endId]]))]">
                  <xsl:with-param name="endId" select="$endId"/>
                  <xsl:with-param name="startId" select="$startId"/>
               </xsl:apply-templates>
            </xsl:when>
            <xsl:when test="$startNode">
               <xsl:apply-templates select="//tei:text//(*|text())[preceding::* = $startNode and ancestor::tei:p and not(parent::*[preceding::* = $startNode and ancestor::tei:p ])]">
                  <xsl:with-param name="endId" select="$endId"/>
                  <xsl:with-param name="startId" select="$startId"/>
                  <xsl:with-param name="parentNode" select="$parentNode"/>
               </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
               <xsl:apply-templates select="//tei:text//(*|text())[preceding::tei:lb[1]/@xml:id = $startId and parent::* = preceding::tei:lb[1]/parent::* and not(parent::*[preceding::tei:lb[@xml:id = $startId]])]"/>
            </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   <xsl:template name="copyNodeAttributes">
      <xsl:param name="node"/>
      <xsl:param name="excludeString"/>
      <xsl:for-each select="$node/@*">
           <xsl:variable name="attName" select="if (starts-with(name(),'xml:')) then (name()) else (local-name())"/>
           <xsl:if test="not(contains($excludeString, $attName))">
              <xsl:attribute name="{$attName}">
                <xsl:value-of select="."/>
              </xsl:attribute>
           </xsl:if>
      </xsl:for-each>
   </xsl:template>
   <xsl:template name="copyAttributes">
      <xsl:param name="id2corresp"/>
      <xsl:for-each select="@*">
           <xsl:variable name="attName" select="if (starts-with(name(),'xml:')) then (name()) else (local-name())"/>
           <xsl:choose>
              <xsl:when test="$attName = 'seq'"/>
              <xsl:when test="$id2corresp = 'true' and $attName = 'xml:id'">
                 <xsl:attribute name="corresp">
                   <xsl:value-of select="concat('#',.)"/>
                 </xsl:attribute>
              </xsl:when>
              <xsl:otherwise>
                 <xsl:attribute name="{$attName}">
                   <xsl:value-of select="."/>
                 </xsl:attribute>
              </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
   </xsl:template>
   <xsl:template match="tei:note"/>
</xsl:stylesheet>
