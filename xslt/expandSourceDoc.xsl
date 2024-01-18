<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" version="2.0">
   <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
   <xsl:variable name="METAMARK_EXCLUDE_STRING" select="'xml:id target'"/>
   <xsl:variable name="ADD_EXCLUDE_STRING" select="'xml:id'"/>
   <xsl:variable name="DEFAULT_EXCLUDE_STRING" select="'xml:id'"/>
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
            <xsl:with-param name="parentSequence" select="//tei:lb[@xml:id = $startId]/ancestor::*[local-name() = 'del' or local-name() = 'hi']"/>
         </xsl:call-template>
         </xsl:element>
   </xsl:template>
   <xsl:template match="tei:foreign">
      <xsl:element name="hi" namespace="http://www.tei-c.org/ns/1.0">
         <xsl:attribute name="rend">
            <xsl:value-of select="@xml:lang"/>
         </xsl:attribute>
         <xsl:apply-templates select="tei:reg/text()"/>
      </xsl:element>
   </xsl:template>
   <xsl:template match="tei:subst|tei:head|tei:reg">
      <xsl:apply-templates/>
   </xsl:template>
   <xsl:template match="tei:subst[descendant::*[@place='superimposed'] and descendant::*[@rend='overwritten' or @rend='erased']]">
      <xsl:variable name="subst_id" select="@xml:id"/>
      <xsl:variable name="superimposed_key" select="concat($subst_id, '_superimposed')"/>
      <xsl:variable name="overwritten_key" select="concat($subst_id, '_overwritten')"/>
      <xsl:element name="substJoin" namespace="http://www.tei-c.org/ns/1.0">
         <xsl:attribute name="target">
            <xsl:for-each select="descendant::tei:add[@place='superimposed']">
               <xsl:sequence select="concat('#', $superimposed_key, '_', generate-id(.), ' ')"/>
            </xsl:for-each>
            <xsl:for-each select="descendant::tei:del[(@rend='overwritten' or (@rend='erased' and parent::tei:subst and not(ancestor::tei:del[@rend='overwritten']))) and not(@cause)]">
               <xsl:sequence select="concat('#',$overwritten_key, '_', generate-id(.), ' ')"/>
            </xsl:for-each>
         </xsl:attribute>
      </xsl:element>
      <xsl:apply-templates>
         <xsl:with-param name="superimposed_key" select="$superimposed_key"/>
         <xsl:with-param name="overwritten_key" select="$overwritten_key"/>
      </xsl:apply-templates>
   </xsl:template>
   <xsl:template match="tei:add[@place='superimposed']|tei:del[(@rend='overwritten' or (@rend='erased' and parent::tei:subst and not(ancestor::tei:del[@rend='overwritten']))) and not(@cause)]">
      <xsl:param name="superimposed_key"><xsl:value-of select="concat(@place,'_', generate-id(.))"/></xsl:param>
      <xsl:param name="overwritten_key"><xsl:value-of select="concat(@rend,'_', generate-id(.))"/></xsl:param>
      <xsl:variable name="id" select="if (@place = 'superimposed') then (concat($superimposed_key, '_',generate-id(.))) else (concat($overwritten_key, '_',generate-id(.)))"/>
      <xsl:element name="{local-name()}" namespace="http://www.tei-c.org/ns/1.0">
            <xsl:call-template name="copyNodeAttributes">
               <xsl:with-param name="node" select="current()"/>
               <xsl:with-param name="excludeString" select="$DEFAULT_EXCLUDE_STRING"/>
            </xsl:call-template>
            <xsl:attribute name="xml:id">
                <xsl:value-of select="$id"/>
           </xsl:attribute>
           <xsl:apply-templates/>
      </xsl:element>
   </xsl:template>
   <xsl:template match="tei:add[@place='above' or @place='below']">
      <xsl:variable name="content" select="."/>
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

                  <xsl:call-template name="copyNodeAttributes">
                     <xsl:with-param name="node" select="//tei:metamark[@target= concat('#', current()/@xml:id)]/tei:add"/>
                     <xsl:with-param name="excludeString" select="$ADD_EXCLUDE_STRING"/>
                  </xsl:call-template>
                  </xsl:if>
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
                  <xsl:apply-templates/>
            </xsl:element>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   <xsl:template match="tei:sic|tei:corr"/>
   <xsl:template name="choice" match="tei:choice">
      <xsl:param name="startId"/>
      <xsl:param name="endId"/>
      <xsl:param name="parents"/>
      <xsl:param name="choice"/>
      <xsl:param name="isOpening" as="xs:boolean">false</xsl:param>
      <xsl:variable name="id" select="if ($choice) then ($choice/@xml:id) else (@xml:id)"/>
      <xsl:variable name="indexId" select="concat($id, '_index')"/>
      <xsl:variable name="anchorId" select="concat($id, '_anchor')"/>
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
         <xsl:apply-templates select="tei:sic/text()">
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
   <xsl:template match="*">
      <xsl:param name="startId"/>
      <xsl:param name="endId"/>
      <xsl:param name="parents"/>
      <xsl:element name="{local-name()}" namespace="http://www.tei-c.org/ns/1.0">
         <xsl:call-template name="copyAttributes">
            <xsl:with-param name="id2corresp">true</xsl:with-param>
         </xsl:call-template>
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
      <xsl:if test="count($openingChoice) gt 0">
         <xsl:call-template name="choice">
            <xsl:with-param name="choice" select="$openingChoice[1]"/>
            <xsl:with-param name="isOpening" select="true()"/>
         </xsl:call-template>
      </xsl:if>
      <xsl:choose>
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
      <xsl:if test="count($endingChoice) gt 0">
         <xsl:call-template name="choice">
            <xsl:with-param name="choice" select="$endingChoice[1]"/>
         </xsl:call-template>
      </xsl:if>
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
                        <xsl:for-each select="$parentSequence[1]/@*">
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
                        <xsl:for-each select="$parentSequence[1]/@*">
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