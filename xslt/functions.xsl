<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.tei-c.org/ns/1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" version="2.0">
   <!-- This function tests whether the spanTo sequence contains one value that is equal to one of the values of the xmlId sequence (by removing the # from the @spanTo) 
         Return value: 0 for false, 1 for true.
   -->
   <xsl:function name="tei:seqContains">
      <xsl:param name="spanTo"/>
      <xsl:param name="xmlId"/>
      <xsl:variable name="singleComparison" select="if (count($xmlId) = 1 and count($spanTo) gt 0) then (replace($xmlId, '#','') = replace($spanTo[1], '#', '')) else ()"/>
      <xsl:choose>
         <xsl:when test="count($xmlId) = 0 or count($spanTo) = 0 or number(index-of($xmlId, substring-after($spanTo[1], '#'))) gt 0 or $singleComparison">
            <xsl:value-of select="if (count($xmlId) = 0 or count($spanTo) = 0) then (0) else (1)"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:value-of select="tei:seqContains(subsequence($spanTo, 2), $xmlId)"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   <!-- This function parses the positional data and creates a css style for the different kinds of <add> {place: [above|below, target: [parent|child]}] -->
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
               <xsl:otherwise>
                  <xsl:message terminate="yes">ERROR: Input does not specify a place [above|below] and a target [parent|child]!
                  </xsl:message>
               </xsl:otherwise>
           </xsl:choose>
       </xsl:if>
   </xsl:function>
</xsl:stylesheet>