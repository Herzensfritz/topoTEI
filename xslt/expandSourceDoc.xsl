<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" version="2.0">
   <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
   <xsl:variable name="METAMARK_EXCLUDE_STRING" select="'xml:id target'"/>
   <xsl:variable name="ADD_EXCLUDE_STRING" select="'xml:id'"/>
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
         <!-- TODO copy //*[@xml:id = substring-after(@start, '#')] -->
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
            <xsl:with-param name="parentSequence" select="//tei:lb[@xml:id = $startId]/parent::*[local-name() = 'del' or local-name() = 'hi']"/>
         </xsl:call-template>
         </xsl:element>
   </xsl:template>
   <xsl:template match="tei:subst[not(child::*[@place='superimposed' or @rend='overwritten'])]">
      <xsl:apply-templates/>
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
                  <xsl:call-template name="copyNodeAttributes">
                     <xsl:with-param name="node" select="//tei:metamark[@target= concat('#', current()/@xml:id)]/tei:add"/>
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
            </xsl:element>
         </xsl:when>
         <xsl:otherwise>
            <xsl:element name="add" namespace="http://www.tei-c.org/ns/1.0">
                  <xsl:call-template name="copyNodeAttributes">
                     <xsl:with-param name="node" select="//tei:add[@corresp = concat('#', current()/@xml:id)]"/>
                  </xsl:call-template>
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
   <xsl:template match="*">
      <xsl:element name="{local-name()}" namespace="http://www.tei-c.org/ns/1.0">
         <xsl:call-template name="copyAttributes">
            <xsl:with-param name="id2corresp">true</xsl:with-param>
         </xsl:call-template>
         <xsl:apply-templates/>
      </xsl:element>
   </xsl:template>
   <xsl:template name="selectLbContent">
      <xsl:param name="startId"/>
      <xsl:param name="endId"/>
      <xsl:param name="parentSequence"/>
      <xsl:choose>
            <xsl:when test="count($parentSequence) gt 0">
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
            <xsl:when test="$endId and count(//(*|text())[preceding::tei:lb[@xml:id = $startId] and following::tei:lb[@xml:id = $endId]]) gt 0">
               <xsl:apply-templates select="//tei:text//(*|text())[preceding::tei:lb[@xml:id = $startId] and following::tei:lb[@xml:id = $endId] and not((parent::*[preceding::tei:lb[@xml:id = $startId] and following::tei:lb[@xml:id = $endId]]))]"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:apply-templates select="//tei:text//(*|text())[ancestor::tei:div2 and preceding::tei:lb[@xml:id = $startId] and not(parent::*[preceding::tei:lb[@xml:id = $startId]])]"/>
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
