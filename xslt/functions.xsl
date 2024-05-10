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
   <xsl:variable name="EMPTY_LINE" select="9" as="xs:decimal"/>
   <xsl:variable name="ADD_LINE_TYPE_F" select="8" as="xs:decimal"/>
   <xsl:variable name="ADD_LINE_TYPE" select="7" as="xs:decimal"/>
   <xsl:variable name="HEAD_LINE_TYPE_F" select="6" as="xs:decimal"/>
   <xsl:variable name="HEAD_LINE_TYPE" select="5" as="xs:decimal"/>
   <xsl:variable name="NOTE_LINE_TYPE_F" select="4" as="xs:decimal"/>
   <xsl:variable name="NOTE_LINE_TYPE" select="3" as="xs:decimal"/>
   <xsl:variable name="AB_LINE_TYPE_F" select="2" as="xs:decimal"/>
   <xsl:variable name="AB_LINE_TYPE" select="1" as="xs:decimal"/>
   <xsl:variable name="DEFAULT_LINE_TYPE" select="0" as="xs:decimal"/>
   <xsl:variable name="FIRST_BLOCK_TYPE" select="0" as="xs:decimal"/>
   <xsl:variable name="SINGLE_BLOCK_TYPE" select="1" as="xs:decimal"/>
   <xsl:variable name="MIDDLE_BLOCK_TYPE" select="2" as="xs:decimal"/>
   <xsl:variable name="LAST_BLOCK_TYPE" select="3" as="xs:decimal"/>
   <xsl:function name="tei:getBlockType" as="xs:decimal">
      <xsl:param name="currentNode" as="element()"/>
      <xsl:choose>
         <xsl:when test="count($currentNode/preceding-sibling::tei:div2) lt 1 and count($currentNode/following-sibling::tei:div2) ne 0">
            <xsl:value-of select="$FIRST_BLOCK_TYPE"/>
         </xsl:when>
         <xsl:when test="count($currentNode/preceding-sibling::tei:div2) lt 1 and count($currentNode/following-sibling::tei:div2) lt 1">
            <xsl:value-of select="$SINGLE_BLOCK_TYPE"/>
         </xsl:when>
         <xsl:when test="count($currentNode/preceding-sibling::tei:div2) ne 0 and count($currentNode/following-sibling::tei:div2) lt 1">
            <xsl:value-of select="$LAST_BLOCK_TYPE"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:value-of select="$MIDDLE_BLOCK_TYPE"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   <!-- get a specific attribute from the node that determines the current line type -->
   <xsl:function name="tei:getAttribute">
      <xsl:param name="currentNode" as="element()"/> 
      <xsl:param name="attr" as="xs:string"/> <!-- attribute, e.g. 'hand', 'rend' -->
      <xsl:param name="lineType" as="xs:decimal"/> <!-- line type from tei:getLineType -->
      <xsl:choose>
         <xsl:when test="$lineType eq $NOTE_LINE_TYPE">
            <xsl:value-of select="replace($currentNode/ancestor::tei:note[1]/@*[local-name() = $attr], '[\*]', '')"/>
         </xsl:when>
         <xsl:when test="$lineType eq $NOTE_LINE_TYPE_F">
            <xsl:value-of select="replace($currentNode/following-sibling::tei:note[1]/@*[local-name() = $attr], '[\*]', '')"/>
         </xsl:when>
         <xsl:when test="$lineType eq $ADD_LINE_TYPE">
            <xsl:value-of select="replace($currentNode/ancestor::tei:add[1]/@*[local-name() = $attr], '[\*]', '')"/>
         </xsl:when>
         <xsl:when test="$lineType eq $ADD_LINE_TYPE_F">
            <xsl:value-of select="replace($currentNode/following-sibling::tei:add[1]/@*[local-name() = $attr], '[\*]', '')"/>
         </xsl:when>
         <xsl:when test="$lineType eq $HEAD_LINE_TYPE">
            <xsl:value-of select="replace($currentNode/ancestor::tei:head[1]/@*[local-name() = $attr], '[\*]', '')"/>
         </xsl:when>
         <xsl:when test="$lineType eq $HEAD_LINE_TYPE_F">
            <xsl:value-of select="replace($currentNode/following-sibling::tei:head[1]/@*[local-name() = $attr], '[\*]', '')"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:value-of select="''"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   <xsl:function name="tei:getLineType" as="xs:decimal">
      <xsl:param name="currentNode"/>
      <xsl:choose>
        <xsl:when test="$currentNode/not(@n)">
           <xsl:value-of select="$EMPTY_LINE"/>
        </xsl:when>
        <xsl:when test="$currentNode/following-sibling::tei:ab[1]/preceding-sibling::tei:lb[1]/@xml:id = $currentNode/@xml:id and count($currentNode/following-sibling::tei:*[local-name() != 'lb' and preceding-sibling::tei:lb[1][@xml:id = $currentNode/@xml:id]]) eq 1"> 
            <xsl:value-of select="$AB_LINE_TYPE_F"/><!-- following sibling is tei:ab  -->
         </xsl:when>
         <xsl:when test="$currentNode/ancestor::tei:ab"> <!-- parent is tei:ab -->
            <xsl:value-of select="$AB_LINE_TYPE"/>
         </xsl:when>
         <xsl:when test="((count($currentNode/following-sibling::tei:lb[1]/preceding-sibling::tei:*[ preceding-sibling::tei:lb[1][@xml:id = $currentNode/@xml:id]]) eq 1 and count($currentNode/following-sibling::tei:lb[1]/preceding-sibling::tei:add[(empty(@place) or @place = 'inline') and preceding-sibling::tei:lb[1][@xml:id = $currentNode/@xml:id]]) eq 1) or (count($currentNode/following-sibling::tei:lb) eq 0 and $currentNode/following-sibling::tei:add[1][empty(@place) or @place = 'inline'])) and (count($currentNode/following-sibling::tei:add[1][empty(@place) or @place = 'inline']/preceding-sibling::text()[preceding-sibling::tei:lb[@xml:id = $currentNode/@xml:id]][normalize-space()]) eq 0 or count($currentNode/following-sibling::tei:add[1][(empty(@place) or @place = 'inline') and preceding-sibling::tei:lb[1][@xml:id = $currentNode/@xml:id]]/preceding-sibling::text()[preceding-sibling::tei:lb[@xml:id = $currentNode/@xml:id]][normalize-space()]) eq 0) and ($currentNode/following-sibling::tei:add[1]/tei:lb[1] or count($currentNode/following-sibling::tei:add[1][empty(@place) or @place = 'inline']/following-sibling::text()[1][normalize-space()]) eq 0)"> 
            <xsl:value-of select="$ADD_LINE_TYPE_F"/><!-- following sibling is tei:add -->
         </xsl:when>
         <xsl:when test="$currentNode/ancestor::tei:add"> <!-- parent is tei:add -->
            <xsl:value-of select="$ADD_LINE_TYPE"/>
         </xsl:when>
         <xsl:when test="$currentNode/following-sibling::tei:head[1]/preceding-sibling::tei:lb[1]/@xml:id = $currentNode/@xml:id           and (count($currentNode/following-sibling::tei:*[local-name() != 'lb' and preceding-sibling::tei:lb[1][@xml:id = $currentNode/@xml:id]]) eq 1          or count($currentNode/following-sibling::tei:*[local-name() != 'p' and following-sibling::tei:p[1]/tei:lb[1]]) eq 1)"> 
            <xsl:value-of select="$HEAD_LINE_TYPE_F"/><!-- following sibling is tei:head -->
         </xsl:when>
         <xsl:when test="$currentNode/ancestor::tei:head"> <!-- parent is tei:head -->
            <xsl:value-of select="$HEAD_LINE_TYPE"/>
         </xsl:when>
         <xsl:when test="$currentNode/ancestor::tei:note"> <!-- parent is tei:note -->
            <xsl:value-of select="$NOTE_LINE_TYPE"/>
         </xsl:when>
         <xsl:when test="$currentNode/following-sibling::tei:note[1]/preceding-sibling::tei:lb[1]/@xml:id = $currentNode/@xml:id           and count($currentNode/following-sibling::tei:*[local-name() != 'lb' and preceding-sibling::tei:lb[1][@xml:id = $currentNode/@xml:id]]) eq 1"> 
            <xsl:value-of select="$NOTE_LINE_TYPE_F"/><!--  following sibling is tei:note -->
         </xsl:when>
          <xsl:otherwise> <!-- normal line -->
            <xsl:value-of select="$DEFAULT_LINE_TYPE"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   
   <xsl:function name="tei:getStyle" as="xs:string"> <!-- deprecated -->
      <xsl:param name="topValue"/>
      <xsl:param name="bottomValue"/>
      <xsl:param name="lineType" as="xs:decimal"/>
      <xsl:choose>
         <xsl:when test="$lineType eq $NOTE_LINE_TYPE_F or $lineType eq $NOTE_LINE_TYPE or $lineType eq $AB_LINE_TYPE or $lineType eq $AB_LINE_TYPE_F"> <!-- tei:node and tei:ab -->
            <xsl:value-of select="concat('bottom:',$bottomValue,'em;')"/>
         </xsl:when>
         <xsl:when test="$lineType eq $ADD_LINE_TYPE or $lineType eq $ADD_LINE_TYPE_F"> <!--  -->
            <xsl:value-of select="concat('top:',$topValue,'em;')"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:value-of select="''"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
</xsl:stylesheet>