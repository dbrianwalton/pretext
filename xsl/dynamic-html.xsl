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

<xsl:import href="./pretext-html.xsl" />
<xsl:import href="./dynamic-runestone.xsl" />

<xsl:template match="dynamic">
  <!-- The only supported structural elements representing *content* are statement|hint|solution. -->
  <!-- In addition, there can be dynamic elements: setup|evaluation. -->
  <!-- For client-based implementation (HTML/javascript), -->
  <!-- all of the components are encoded in a JSON structure -->
  <!-- statement|hint|solution elements are structured HTML, serialized and escaped. -->
  <!-- Placeholders for dynamic content are included as {{DNAME}} -->
  <!-- where DNAME represents the name of dynamic content. -->
  <xsl:element name="div">
    <xsl:attribute name="class">runestone</xsl:attribute>
    <xsl:element name="div">
      <xsl:attribute name="data-component">fillintheblank</xsl:attribute>
      <xsl:attribute name="data-question_label">???</xsl:attribute>
      <xsl:attribute name="id">
        <xsl:apply-templates select="." mode="visible-id" />
      </xsl:attribute>
      <xsl:attribute name="style">visibility: hidden;</xsl:attribute>
      <xsl:element name="script">
        <xsl:attribute name="type">application/json</xsl:attribute>
        <xsl:text>{&#xa;</xsl:text>
        <xsl:call-template name="comma-join">
          <xsl:with-param name="entries">
            <xsl:if test="statement">
              <xsl:element name="json-entry">
                <xsl:attribute name="name">problemHtml</xsl:attribute>
                <xsl:text>"</xsl:text>
                <xsl:call-template name="jsonescape">
                  <xsl:with-param name="str">
                    <xsl:apply-templates select="statement">
                      <xsl:with-param name="b-original" select="true()" />
                    </xsl:apply-templates>
                  </xsl:with-param>
                </xsl:call-template>
                <xsl:text>"</xsl:text>
              </xsl:element>
            </xsl:if>
            <xsl:if test="setup">
              <xsl:element name="json-entry">
                <xsl:attribute name="name">dyn_vars</xsl:attribute>
                <xsl:text>"</xsl:text>
                <xsl:call-template name="jsonescape">
                  <xsl:with-param name="str">
                    <xsl:apply-templates select="setup" mode="runestone-fitb" />
                  </xsl:with-param>
                </xsl:call-template>
                <xsl:text>"</xsl:text>
              </xsl:element>
            </xsl:if>
            <xsl:if test="statement//fillin[@name]">
              <xsl:element name="json-entry">
                <xsl:attribute name="name">blankNames</xsl:attribute>
                <xsl:text>{</xsl:text>
                <xsl:call-template name="comma-join">
                  <xsl:with-param name="entries">
                    <xsl:for-each select="statement//fillin">
                      <xsl:if test="@name">
                        <xsl:element name="json-entry">
                          <xsl:attribute name="name" select="@name" />
                          <xsl:value-of select="position()" />
                        </xsl:element>
                      </xsl:if>
                    </xsl:for-each>
                  </xsl:with-param>
                </xsl:call-template>
                <xsl:text>}</xsl:text>
              </xsl:element>
            </xsl:if>
            <xsl:if test="evaluation">
              <xsl:element name="json-entry">
                <xsl:attribute name="name">feedbackArray</xsl:attribute>
                <xsl:call-template name="jsonescape">
                  <xsl:with-param name="str">
                    <xsl:apply-templates select="evaluation" mode="runestone-fitb" />
                  </xsl:with-param>
                </xsl:call-template>
              </xsl:element>
            </xsl:if>
            <xsl:if test="hint">
              <xsl:element name="json-entry">
                <xsl:attribute name="name">hint</xsl:attribute>
                <xsl:call-template name="jsonescape">
                  <xsl:with-param name="str">
                    <xsl:apply-templates select="hint" mode="runestone-fitb" />
                  </xsl:with-param>
                </xsl:call-template>
              </xsl:element>
            </xsl:if>
            <xsl:if test="solution">
              <xsl:element name="json-entry">
                <xsl:attribute name="name">solution</xsl:attribute>
                <xsl:call-template name="jsonescape">
                  <xsl:with-param name="str">
                    <xsl:apply-templates select="solution" mode="runestone-fitb" />
                  </xsl:with-param>
                </xsl:call-template>
              </xsl:element>
            </xsl:if>
          </xsl:with-param>
        </xsl:call-template>
        <xsl:text>&#xa;}&#xa;</xsl:text>
      </xsl:element>
    </xsl:element>
  </xsl:element>
</xsl:template>

<xsl:template name="comma-join">
  <xsl:param name="entries" select=""/>
  <xsl:for-each select="$entries">
    <xsl:if test="not(position() = 1)">
      <xsl:text>,</xsl:text>
    </xsl:if>
    <xsl:value-of select="." />
  </xsl:for-each>
</xsl:template>

<xsl:template name="jsonescape">
  <xsl:param name="str" select="."/>
  <xsl:param name="escapeChars" select="'\&quot;'" />
  <xsl:variable name="first" select="substring(translate($str, translate($str, $escapeChars, ''), ''), 1, 1)" />
  <xsl:choose>
    <xsl:when test="$first">
      <xsl:value-of select="concat(substring-before($str, $first), '\', $first)"/>
      <xsl:call-template name="jsonescape">
        <xsl:with-param name="str" select="substring-after($str, $first)"/>
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
        <xsl:value-of select="$str"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="*" mode="serialize">
  <xsl:text>&lt;</xsl:text>
  <xsl:value-of select="name()"/>
  <xsl:apply-templates select="@*" mode="serialize" />
  <xsl:choose>
      <xsl:when test="node()">
          <xsl:text>&gt;</xsl:text>
          <xsl:apply-templates mode="serialize" />
          <xsl:text>&lt;/</xsl:text>
          <xsl:value-of select="name()"/>
          <xsl:text>&gt;</xsl:text>
      </xsl:when>
      <xsl:otherwise>
          <xsl:text> /&gt;</xsl:text>
      </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="@*" mode="serialize">
    <xsl:text> </xsl:text>
    <xsl:value-of select="name()"/>
    <xsl:text>="</xsl:text>
    <xsl:value-of select="."/>
    <xsl:text>"</xsl:text>
</xsl:template>

<xsl:template match="var">
  <xsl:text>{{</xsl:text>
  <xsl:value-of select="@name" />
  <xsl:text>}}</xsl:text>
</xsl:template>

<!-- Need to add to pretext-common -->
<!-- Do not number #dynamic -->
<xsl:template match="dynamic" mode="serial-number" />

</xsl:stylesheet>