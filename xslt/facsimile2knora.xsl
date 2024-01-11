<xsl:stylesheet xmlns="https://dasch.swiss/schema" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" version="1.0">
  <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
   <xsl:param name="shortcode" select="0837"/>
   <xsl:param name="debug"/>
  <xsl:template match="/">
      <xsl:apply-templates select="//tei:facsimile"/>
  </xsl:template>
 
  <xsl:template match="//tei:facsimile">
      <knora xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="https://dasch.swiss/schema https://raw.githubusercontent.com/dasch-swiss/dsp-tools/main/src/dsp_tools/resources/schema/data.xsd" shortcode="{$shortcode}" default-ontology="nietzsche-dm">
    <!-- :permissions see https://docs.dasch.swiss/latest/DSP-API/05-internals/design/api-admin/administration/#permissions -->
    <permissions id="res-default">
        <allow group="UnknownUser">V</allow>
        <allow group="KnownUser">V</allow>
        <allow group="Creator">CR</allow>
        <allow group="ProjectAdmin">CR</allow>
    </permissions>
    <permissions id="res-restricted">
        <allow group="Creator">M</allow>
        <allow group="ProjectAdmin">D</allow>
    </permissions>
    <permissions id="prop-default">
        <allow group="UnknownUser">V</allow>
        <allow group="KnownUser">V</allow>
        <allow group="Creator">CR</allow>
        <allow group="ProjectAdmin">CR</allow>
    </permissions>
    <permissions id="prop-restricted">
        <allow group="Creator">M</allow>
        <allow group="ProjectAdmin">D</allow>
    </permissions>
    <xsl:choose>
        <xsl:when test="$debug">
           <xsl:apply-templates select="tei:surface[concat('#',@xml:id) = //tei:pb/@facs][1]"/> 
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="tei:surface"/>
        </xsl:otherwise>
    </xsl:choose>
    
   </knora>
  </xsl:template>
 
  <xsl:template match="tei:surface[empty(tei:graphic/@corresp)]">
     <xsl:if test="//tei:pb[@facs = concat('#', current()/@xml:id)]">
        <xsl:variable name="label" select="//tei:pb[@facs = concat('#', current()/@xml:id)]/@xml:id"/>
        <xsl:variable name="filename" select="substring-after(tei:graphic/@url, 'download/')"/>
        <xsl:variable name="url" select="if (starts-with($filename, 'D-20a')) then ('http://www.nietzschesource.org/DFGA/D-20a') else ('http://www.nietzschesource.org/DFGA/D-20b')"/>
        <resource label="{concat('D20 ', $label)}" restype=":Facsimile" id="{@xml:id}" permissions="res-default">
           <bitstream permissions="prop-default">
                    <xsl:value-of select="concat($filename, '.jpg')"/>
                </bitstream>
           <text-prop name=":hasLicense">
               <text permissions="prop-default" encoding="utf8">CC BY-NC-ND 4.0</text>
           </text-prop>
           <uri-prop name=":hasOriginalUrl">
              <uri permissions="prop-default">
                        <xsl:value-of select="$url"/>
                    </uri>
           </uri-prop>
       </resource>
    </xsl:if>

  </xsl:template>
</xsl:stylesheet>