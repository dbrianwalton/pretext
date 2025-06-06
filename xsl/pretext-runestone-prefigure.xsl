<?xml version='1.0'?> <!-- As XML file -->

<!DOCTYPE xsl:stylesheet>

<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:exsl="http://exslt.org/common"
    xmlns:date="http://exslt.org/dates-and-times"
    xmlns:str="http://exslt.org/strings"
    xmlns:pf="https://prefigure.org"
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

<xsl:template match="*"/>

<!-- This is the root element -->
<xsl:template match="image/prefigure">
    <xsl:apply-templates select="diagram" mode="prefigure-jsx"/>
</xsl:template>

<xsl:template match="pf:diagram" mode="prefigure-jsx">
    <xsl:text>board = JXG.JSXGraph.initBoard('</xsl:text>
    <xsl:text>jxgbox</xsl:text>
    <xsl:text>', { boundingbox: [-5, 5, -5, 5], </xsl:text>
    <xsl:text>axis: true});&#xa;</xsl:text>
    <xsl:text>_diagram_env = </xsl:text>
    <xsl:apply-templates select="*" mode="prefigure-jsx"/>
</xsl:template>

<!-- Outline is a grouping object. Just look inside. -->
<xsl:template match="pf:group-outline" mode="prefigure-jsx">
    <xsl:apply-templates select="*" mode="prefigure-jsx"/>
</xsl:template>

<xsl:template match="pf:coordinates" mode="prefigure-jsx">
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
            <xsl:value-of select="$bbox-entries"/><xsl:text>,</xsl:text>
            <xsl:value-of select="$bbox-entries"/><xsl:text>,</xsl:text>
            <xsl:value-of select="$bbox-entries"/><xsl:text>,</xsl:text>
            <xsl:value-of select="$bbox-entries"/>
            <xsl:text>]);&#xa;</xsl:text>
        </xsl:when>
    </xsl:choose>
    <!-- Now parse every object within the graph -->
    <xsl:apply-templates select="*" mode="prefigure-jsx"/>
</xsl:template>

<xsl:template match="pf:grid-axes" mode="prefigure-jsx">
    <xsl:variable name="xlabel">
        <xsl:choose>
            <xsl:when test="@xlabel">
                <xsl:value-of select="@xlabel"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>x</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="ylabel">
        <xsl:choose>
            <xsl:when test="@ylabel">
                <xsl:value-of select="@ylabel"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>y</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <xsl:text>board.setAttribute({&#xa;</xsl:text>
    <xsl:text>    defaultAxes: {&#xa;</xsl:text>
    <xsl:text>      x: { label:'</xsl:text><xsl:value-of select="$xlabel"/><xsl:text>' },&#xa;</xsl:text>
    <xsl:text>      y: { label:'</xsl:text><xsl:value-of select="$ylabel"/><xsl:text>' },&#xa;</xsl:text>
    <xsl:text>    }&#xa;</xsl:text>
    <xsl:text>});</xsl:text>
</xsl:template>

<!-- Extract comma separated from inside parens, then make list -->
<xsl:template name="ptuple-to-list">
    <xsl:param name="ptuple"/>
    <xsl:variable name="tuple">
        <xsl:value-of select="substring-before(substring-after($ptuple, '('), ')')"/>
    </xsl:variable>
    <xsl:message>
        <xsl:text>TUPLE:</xsl:text>
        <xsl:value-of select="$tuple"/>
        <xsl:text>:ELPUT:</xsl:text>
    </xsl:message>
    <xsl:call-template name="tuple-to-list">
        <xsl:with-param name="tuple" select="$tuple"/>
    </xsl:call-template>
</xsl:template>

<!-- Make list from comma separated string -->
<xsl:template name="tuple-to-list">
    <xsl:param name="tuple"/>
    <xsl:value-of select="str:tokenize($tuple, ', *')"/>
</xsl:template>

<xsl:template match="/">
    <xsl:text>$Begin$&#xa;</xsl:text>
    <xsl:for-each select="//pf:diagram">
        <xsl:value-of select="position()"/>
        <xsl:text>&#xa;</xsl:text>
        <xsl:apply-templates select="." mode="prefigure-jsx"/>
    </xsl:for-each>
    <xsl:text>$End$</xsl:text>
</xsl:template>

</xsl:stylesheet>
