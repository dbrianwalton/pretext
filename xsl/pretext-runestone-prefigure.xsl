<?xml version='1.0'?> <!-- As XML file -->

<!DOCTYPE xsl:stylesheet>

<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:exsl="http://exslt.org/common"
    xmlns:date="http://exslt.org/dates-and-times"
    xmlns:str="http://exslt.org/strings"
    extension-element-prefixes="exsl date str"
>

<!-- ==================================================== -->
<!-- PreFigure in randomized Runestone Component          -->
<!-- ==================================================== -->

<!-- Preprocessing: -->
<!-- Dynamic? Convert to interactive jsxgraph      -->
<!-- Static? Leave as PreFigure with substitutions -->

<!-- Create javascript using jsxgraph notation -->
<!-- Ignore elements whose template has not been defined. -->
<xsl:template match="*" mode="prefigure-jsx"/>

<!-- This is the root element -->
<xsl:template match="diagram" mode="prefigure-jsx">
    <xsl:text>board = JXG.JSXGraph.initBoard('</xsl:text>
    <xsl:text>jxgbox</xsl:text>
    <xsl:text>', { boundingbox: [-5, 5, -5, 5], </xsl:text>
    <xsl:text>axis: true});\n</xsl:text>
    <xsl:text>_diagram_env = </xsl:text>
    <xsl:apply-templates select="*" mode="prefigure-jsx"/>
</xsl:template>

<!-- Outline is a grouping object. Just look inside. -->
<xsl:template match="group-outline" mode="prefigure-jsx">
    <xsl:apply-templates select="*" mode="prefigure-jsx"/>
</xsl:template>

<xsl:template match="coordinates" mode="prefigure-jsx">
    <xsl:choose>
        <xsl:when test="@bbox">
            <!-- PreFigure provides left, bottom, right, top -->
            <!-- jsxgraph needs left, top, right, bottom -->
            <xsl:variable name="bbox-entries">
                <xsl:call-template name="ptuple-to-list">
                    <xsl:with-param name="ptuple" select="@bbox"/>
                </xsl:call-template>
            </xsl:variable>
            <xsl:text>board.setBoundingBox([</xsl:text>
            <xsl:value-of select="$bbox-entries[1]"/><xsl:text>,</xsl:text>
            <xsl:value-of select="$bbox-entries[4]"/><xsl:text>,</xsl:text>
            <xsl:value-of select="$bbox-entries[3]"/><xsl:text>,</xsl:text>
            <xsl:value-of select="$bbox-entries[2]"/>
            <xsl:text>]);\n</xsl:text>
        </xsl:when>
    </xsl:choose>
    <!-- Now parse every object within the graph -->
    <xsl:apply-templates select="*" mode="prefigure-jsx"/>
</xsl:template>

<xsl:template match="grid-axes" mode="prefigure-jsx">
    <xsl:text>board.setAttribute({</xsl:text>
    <xsl:text>    defaultAxes: {</xsl:text>
    <xsl:if test="@xlabel">
        <xsl:text>      x: { label:</xsl:text>
        <xsl:value-of select="@xlabel"/>
        <xsl:text> }, </xsl:text>
    </xsl:if>
    <xsl:if test="@ylabel">        
        <xsl:text>      y: { label:</xsl:text>
        <xsl:value-of select="@ylabel"/>
        <xsl:text> }, </xsl:text>
    </xsl:if>
    <xsl:text>});</xsl:text>
</xsl:template>

<!-- Extract comma separated from inside parens, then make list -->
<xsl:template name="ptuple-to-list">
    <xsl:param name="ptuple"/>
    <xsl:call-template name="tuple-to-list">
        <xsl:with-param name="tuple">
            <xsl:value-of select="substring-before(substring-after($ptuple, '('), ')')"/>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- Make list from comma separated string -->
<xsl:template name="tuple-to-list">
    <xsl:param name="tuple"/>
    <xsl:value-of select="tokenize($tuple, ', *')"/>
</xsl:template>

</xsl:stylesheet>
