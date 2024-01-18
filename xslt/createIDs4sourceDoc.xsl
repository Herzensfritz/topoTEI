<xsl:stylesheet xmlns="http://www.tei-c.org/ns/1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" xpath-default-namespace="http://www.tei-c.org/ns/1.0" exclude-result-prefixes="tei" version="2.0">
    <xsl:output method="xml" encoding="UTF-8" indent="no"/>
    <xsl:variable name="TITLE" select="//tei:title/text()"/>
    <xsl:template match="/">
         <xsl:apply-templates/>
   </xsl:template>
   <xsl:template match="tei:div2|tei:div1">
      <xsl:variable name="id" select="if (@xml:id) then (translate(@xml:id, 'äöüÄÖÜ','aouAO')) else (generate-id())"/>
         <xsl:element name="{name()}">
            <xsl:copy-of select="@*"/>
            <xsl:if test="*[1]/local-name() != 'anchor'">
               <xsl:element name="anchor">
                  <xsl:attribute name="xml:id">
                   <xsl:value-of select="concat($TITLE,'_',local-name(),'_',$id)"/>
                 </xsl:attribute>
               </xsl:element>
            </xsl:if>
           <xsl:apply-templates/>
         </xsl:element>
   </xsl:template>
   <xsl:template match="tei:lb[@n and count(distinct-values(subsequence(//tei:lb/@n, 0, index-of(//tei:lb/@n, current()/@n)[1]))) lt count(subsequence(//tei:lb/@n, 0, index-of(//tei:lb/@n, current()/@n)[1]))]">
      <xsl:variable name="id" select="if (@n) then (@n) else (generate-id())"/>
      <xsl:variable name="name" select="if (@n) then (local-name()) else (concat(local-name(), '_'))"/>
      <xsl:element name="{name()}">
         <xsl:copy-of select="@*[not(local-name() = 'n')]"/>
         <xsl:attribute name="n">
          <xsl:value-of select="if (matches(@n, '.*[a-zA-Z]$')) then (concat(number(replace(@n, '[a-zA-Z]','')) + 2, replace(@n, '[0-9]+',''))) else (@n + 2)"/>
        </xsl:attribute>
         <xsl:attribute name="xml:id">
            <xsl:value-of select="if (not(@xml:id) or count(//tei:lb[@xml:id = current()/@xml:id]) gt 1) then (concat($TITLE,'_post_corr_',$name,$id)) else (@xml:id)"/>
        </xsl:attribute>
        <xsl:apply-templates/>
      </xsl:element>
   </xsl:template>
   <xsl:template match="tei:lb[@n and count(index-of(//tei:lb/@n, current()/@n)) gt 1]">
      <xsl:variable name="id" select="if (@n) then (@n) else (generate-id())"/>
      <xsl:variable name="name" select="if (@n) then (local-name()) else (concat(local-name(), '_'))"/>
      <xsl:element name="{name()}">
         <xsl:choose>
            <xsl:when test="preceding-sibling::tei:lb/@n = current()/@n or ancestor::*/preceding-sibling::tei:lb/@n = current()/@n or preceding-sibling::*/tei:lb/@n = current()/@n">
               <xsl:copy-of select="@*[not(local-name() = 'n')]"/>
               <xsl:attribute name="n">
          <xsl:value-of select="if (matches(@n, '.*[a-zA-Z]$')) then (concat(number(replace(@n, '[a-zA-Z]','')) + 2, replace(@n, '[0-9]+',''))) else (@n + 2)"/>
              </xsl:attribute>
               <xsl:attribute name="xml:id">
                  <xsl:value-of select="if (not(@xml:id) or count(//tei:lb[@xml:id = current()/@xml:id]) gt 1) then (concat($TITLE,'_corr_',$name,$id)) else (@xml:id)"/>
              </xsl:attribute>
            </xsl:when>
            <xsl:otherwise>
               <xsl:copy-of select="@*"/>
               <xsl:attribute name="xml:id">
                <xsl:value-of select="concat($TITLE,'_ok_',$name,$id)"/>
              </xsl:attribute>
           </xsl:otherwise>
        </xsl:choose>
        <xsl:apply-templates/>
      </xsl:element>
   </xsl:template>
   <xsl:template match="tei:lb[@n and not(@xml:id) and (count(index-of(//tei:lb/@n, current()/@n)) eq 1) and (count(distinct-values(subsequence(//tei:lb/@n, 0, index-of(//tei:lb/@n, current()/@n)[1]))) eq count(subsequence(//tei:lb/@n, 0, index-of(//tei:lb/@n, current()/@n)[1])))]">
      <xsl:variable name="id" select="if (@n) then (@n) else (generate-id())"/>
      <xsl:variable name="name" select="if (@n) then (local-name()) else (concat(local-name(), '_'))"/>
      <xsl:element name="{name()}">
         <xsl:copy-of select="@*"/>
         <xsl:attribute name="xml:id">
          <xsl:value-of select="concat($TITLE,'_',$name,$id)"/>
        </xsl:attribute>
        <xsl:apply-templates/>
      </xsl:element>
   </xsl:template>
   <xsl:template match="(tei:add|tei:choice|tei:fw|tei:subst|tei:head|tei:note|tei:ab)[not(@xml:id)]">
      <xsl:variable name="id" select="if (@n) then (@n) else (generate-id())"/>
      <xsl:variable name="name" select="if (@n) then (local-name()) else (concat(local-name(), '_'))"/>
      <xsl:element name="{name()}">
         <xsl:copy-of select="@*"/>
         <xsl:attribute name="xml:id">
          <xsl:value-of select="concat($TITLE,'_',$name,$id)"/>
        </xsl:attribute>
        <xsl:apply-templates/>
      </xsl:element>
   </xsl:template>
   <xsl:template match="*">
      <xsl:element name="{name()}">
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates/>
      </xsl:element>
   </xsl:template>
</xsl:stylesheet>