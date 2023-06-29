<xsl:stylesheet xmlns="http://www.tei-c.org/ns/1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" xpath-default-namespace="http://www.tei-c.org/ns/1.0" exclude-result-prefixes="tei" version="2.0">
   <xsl:output method="xml" indent="yes" encoding="UTF-8" />
   <xsl:template match="/">
      <xsl:apply-templates/>
   </xsl:template>
   <xsl:template match="tei:TEI">
      <xsl:element name="{name()}">
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates/>
         <xsl:call-template name="sourceDoc"/>
      </xsl:element>
   </xsl:template>
   <xsl:template name="sourceDoc">
         <xsl:element name="sourceDoc">
            <xsl:for-each select="//tei:text/tei:body/tei:div1[@xml:id]">
               <xsl:choose>
                  <xsl:when test="//tei:surface[@start = concat('#', current()/@xml:id)]">
                     <xsl:element name="surface">
                        <xsl:copy-of select="//tei:surface[@start = concat('#', current()/@xml:id)]/@*"/>
                        <xsl:if test="empty(//tei:surface[@start = concat('#', current()/@xml:id)]/@type)">
                           <xsl:attribute name="type">
                             <xsl:value-of select="'relative'"/>
                           </xsl:attribute>
                        </xsl:if>
                        <xsl:call-template name="zones">
                           <xsl:with-param name="div1_id" select="current()/@xml:id"/>
                        </xsl:call-template>
                     </xsl:element>
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:element name="surface">
                        <xsl:attribute name="type">
                          <xsl:value-of select="'relative'"/>
                        </xsl:attribute>
                        <xsl:attribute name="start">
                          <xsl:value-of select="concat('#', @xml:id)"/>
                        </xsl:attribute>
                        <xsl:call-template name="zones">
                           <xsl:with-param name="div1_id" select="@xml:id"/>
                        </xsl:call-template>
                       </xsl:element>
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:for-each>
         </xsl:element>
   </xsl:template>

   <xsl:template name="zones">
      <xsl:param name="div1_id"/>
      <xsl:for-each select="tei:div2[ancestor::div1/@xml:id = $div1_id and @xml:id]">
         <xsl:element name="zone">
            <xsl:attribute name="start">
              <xsl:value-of select="concat('#', @xml:id)"/>
            </xsl:attribute>
            <xsl:call-template name="lines">
               <xsl:with-param name="div2_id" select="@xml:id"/>
            </xsl:call-template>
         </xsl:element>
     </xsl:for-each>
   </xsl:template>
   <xsl:template name="lines">
      <xsl:param name="div2_id"/>
      <xsl:for-each select="//tei:lb[ancestor::div2/@xml:id = $div2_id and @xml:id]">
         <xsl:element name="line">
            <xsl:attribute name="start">
              <xsl:value-of select="concat('#', @xml:id)"/>
            </xsl:attribute>
            <xsl:call-template name="parentAdd">
               <xsl:with-param name="div2_id" select="$div2_id"/>
               <xsl:with-param name="lb_id" select="@xml:id"/>
            </xsl:call-template>
         </xsl:element>
      </xsl:for-each>
   </xsl:template>
   <xsl:template name="parentAdd">
      <xsl:param name="div2_id"/>
      <xsl:param name="lb_id"/>
      <xsl:for-each select="//tei:add[
         @xml:id and (@place = 'above' or @place = 'below') 
         and ancestor::tei:div2/@xml:id = $div2_id 
         and (preceding-sibling::tei:lb[1][@xml:id = $lb_id] or 
               (ancestor::tei:subst/preceding-sibling::tei:lb[1][@xml:id = $lb_id] and not(ancestor::tei:add[@place = 'above' or @place = 'below']))
             )
      ]">
         <xsl:call-template name="add">
            <xsl:with-param name="id" select="@xml:id"/>
         </xsl:call-template>
      </xsl:for-each>
   </xsl:template>
   <xsl:template name="add">
      <xsl:param name="id"/>
      <xsl:choose>
         <xsl:when test="@rend = 'insM'">
            <xsl:element name="metamark">
               <xsl:attribute name="function">
                 <xsl:value-of select="'insertion'"/>
               </xsl:attribute>
               <xsl:attribute name="target">
                 <xsl:value-of select="concat('#', $id)"/>
               </xsl:attribute>
               <xsl:element name="add">
                  <xsl:attribute name="corresp">
                    <xsl:value-of select="concat('#', $id)"/>
                  </xsl:attribute>
                  <xsl:for-each select="//tei:add[@xml:id = $id]//tei:add[@place = 'above' or @place = 'below']">
                     <xsl:call-template name="add">
                        <xsl:with-param name="id" select="@xml:id"/>
                     </xsl:call-template>
                  </xsl:for-each>
               </xsl:element>
            </xsl:element>
         </xsl:when>
         <xsl:otherwise>
            <xsl:element name="add">
               <xsl:attribute name="corresp">
                 <xsl:value-of select="concat('#', $id)"/>
               </xsl:attribute>
               <xsl:for-each select="//tei:add[@xml:id = $id]//tei:add[@place = 'above' or @place = 'below']">
                  <xsl:call-template name="add">
                     <xsl:with-param name="id" select="@xml:id"/>
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
</xsl:stylesheet>
