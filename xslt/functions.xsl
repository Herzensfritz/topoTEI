<xsl:stylesheet xmlns="http://www.tei-c.org/ns/1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" version="2.0">
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
                  <xsl:message terminate="no">ERROR: Input does not specify a place [above|below] and a target [parent|child]! <xsl:value-of select="concat($place,' : ',$target,' : ',$style)"/>
                  </xsl:message>
               </xsl:otherwise>
           </xsl:choose>
       </xsl:if>
   </xsl:function>
   <xsl:function name="tei:getHand">
      <xsl:param name="currentNode"/>
      <xsl:choose>
         <xsl:when test="$currentNode/ancestor::tei:note or $currentNode/following-sibling::tei:note[1]">
            <xsl:value-of select="if ($currentNode/ancestor::tei:note)              then ((substring-after($currentNode/ancestor::tei:note[1]/@hand, '#'))) else (substring-after($currentNode/following-sibling::note[1]/@hand, '#'))"/>
         </xsl:when>
         <xsl:when test="$currentNode/ancestor::tei:add">
            <xsl:value-of select="if ($currentNode/ancestor::tei:add)              then (substring-after($currentNode/ancestor::tei:add[1]/@hand, '#')) else (substring-after($currentNode/following-sibling::tei:add[1]/@hand, '#'))"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:value-of select="if ($currentNode/ancestor::tei:head)              then (substring-after($currentNode/ancestor::tei:head[1]/@hand, '#')) else (substring-after($currentNode/following-sibling::tei:head[1]/@hand, '#'))"/>
         </xsl:otherwise>
      </xsl:choose>

   </xsl:function>
   <xsl:function name="tei:getLineType" as="xs:decimal">
      <xsl:param name="currentNode"/>
      <xsl:choose>
         <xsl:when test="(count($currentNode/following-sibling::tei:lb[1]/preceding-sibling::tei:*[ preceding-sibling::tei:lb[1][@xml:id = $currentNode/@xml:id]]) eq 1           and count($currentNode/following-sibling::tei:lb[1]/preceding-sibling::tei:add[(empty(@place) or @place = 'inline') and preceding-sibling::tei:lb[1][@xml:id = $currentNode/@xml:id]]) eq 1)    and count($currentNode/following-sibling::tei:add[1][(empty(@place) or @place = 'inline') and preceding-sibling::tei:lb[1][@xml:id = $currentNode/@xml:id]]/preceding-sibling::text()[normalize-space()]) eq 0          and ($currentNode/following-sibling::tei:add[1]/tei:lb[1] or count($currentNode/following-sibling::tei:add[1][empty(@place) or @place = 'inline']/following-sibling::text()[1][normalize-space()]) eq 0)"> 
            <xsl:value-of select="8"/><!-- type 6: following sibling is tei:add -->
         </xsl:when>
         <xsl:when test="$currentNode/parent::tei:add"> <!-- type 5: parent is tei:add -->
            <xsl:value-of select="7"/>
         </xsl:when>
         <xsl:when test="$currentNode/following-sibling::tei:head[1]/preceding-sibling::tei:lb[1]/@xml:id = $currentNode/@xml:id           and (count($currentNode/following-sibling::tei:*[local-name() != 'lb' and preceding-sibling::tei:lb[1][@xml:id = $currentNode/@xml:id]]) eq 1          or count($currentNode/following-sibling::tei:*[local-name() != 'p' and following-sibling::tei:p[1]/tei:lb[1]]) eq 1)"> 
            <xsl:value-of select="6"/><!-- type 6: following sibling is tei:head -->
         </xsl:when>
         <xsl:when test="$currentNode/ancestor::tei:head"> <!-- type 5: parent is tei:head -->
            <xsl:value-of select="5"/>
         </xsl:when>
         <xsl:when test="$currentNode/ancestor::tei:note"> <!-- type 4: parent is tei:note -->
            <xsl:value-of select="4"/>
         </xsl:when>
         <xsl:when test="$currentNode/following-sibling::tei:note[1]/preceding-sibling::tei:lb[1]/@xml:id = $currentNode/@xml:id           and count($currentNode/following-sibling::tei:*[local-name() != 'lb' and preceding-sibling::tei:lb[1][@xml:id = $currentNode/@xml:id]]) eq 1"> 
            <xsl:value-of select="3"/><!-- type 3: following sibling is tei:note -->
         </xsl:when>
         <xsl:when test="$currentNode/following-sibling::tei:ab[1]/preceding-sibling::tei:lb[1]/@xml:id = $currentNode/@xml:id           and count($currentNode/following-sibling::tei:*[local-name() != 'lb' and preceding-sibling::tei:lb[1][@xml:id = $currentNode/@xml:id]]) eq 1"> 
            <xsl:value-of select="2"/><!-- type 2: follwoign sibling is tei:ab  -->
         </xsl:when>
         <xsl:when test="$currentNode/ancestor::tei:ab"> <!-- type 1: parent is tei:ab -->
            <xsl:value-of select="1"/>
         </xsl:when>
         <xsl:otherwise> <!-- type 0: normal line -->
            <xsl:value-of select="0"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   <xsl:function name="tei:getStyle" as="xs:string">
      <xsl:param name="topValue"/>
      <xsl:param name="bottomValue"/>
      <xsl:param name="lineType" as="xs:decimal"/>
      <xsl:choose>
         <xsl:when test="$lineType gt 0 and $lineType lt 5"> <!-- tei:node and tei:ab -->
            <xsl:value-of select="concat('bottom:',$bottomValue,'em;')"/>
         </xsl:when>
         <xsl:when test="$lineType gt 6 and $lineType lt 9"> <!--  -->
            <xsl:value-of select="concat('top:',$topValue,'em;')"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:value-of select="''"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
</xsl:stylesheet>