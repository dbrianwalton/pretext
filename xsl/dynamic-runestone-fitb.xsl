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


<!-- Utility templates -->
<xsl:template match="exercise[@exercise-interactive='fillin-dynamic']//fillin">
    <xsl:param name="b-human-readable" />
    <xsl:element name="input">
        <xsl:attribute name="types"><xsl:text>text</xsl:text></xsl:attribute>
        <xsl:attribute name="name"><xsl:value-of select="@submit"/></xsl:attribute>
    </xsl:element>
</xsl:template>

<xsl:template match="exercise[@exercise-interactive='fillin-dynamic']//var[@name]">
    <xsl:text>[%= </xsl:text>
    <xsl:value-of select="@name"/>
    <xsl:text>.toTeX() %]</xsl:text>
</xsl:template>

<xsl:template name="quote-string">
    <xsl:param name="string" />
    <xsl:text>"</xsl:text>
    <xsl:value-of select="$string" />
    <xsl:text>"</xsl:text>
</xsl:template>

<xsl:template name="escape-quote-string">
    <xsl:param name="string" />
    <xsl:call-template name="quote-string">
        <xsl:with-param name="string">
            <xsl:call-template name="escape-json-string">
                <xsl:with-param name="text" select="$string"/>
            </xsl:call-template>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<xsl:template match="*" mode="stringify-content">
    <xsl:variable name="html_content">
        <xsl:apply-templates select="." mode="body"/>
    </xsl:variable>
    <xsl:variable name="html_string">
        <xsl:apply-templates select="exsl:node-set($html_content)" mode="serialize"/>
    </xsl:variable>
    <xsl:call-template name="escape-quote-string">
        <xsl:with-param name="string" select="$html_string"/>
    </xsl:call-template>
</xsl:template>


<xsl:template match="dynamic-graph" mode="body">
    <div class="jxgbox">
        <xsl:attribute name="id">
            <xsl:text>[%=divid%]-</xsl:text>
            <xsl:value-of select="@sub-id"/>
        </xsl:attribute>
        <xsl:attribute name="style">
            <xsl:text>width:300px; height:300px;</xsl:text>
            <xsl:value-of select="@sub-id"/>
        </xsl:attribute>
    </div>
</xsl:template>

<xsl:template match="dynamic-graph" mode="runestone-setup">
    <xsl:variable name="board-id">
        <xsl:value-of select="@sub-id"/>
    </xsl:variable>
    <xsl:text>{&#xa;let curBoard;&#xa;</xsl:text>
    <xsl:text>curBoard = v.jsx_</xsl:text>
    <xsl:value-of select="@sub-id"/>
    <xsl:text> = JXG.JSXGraph.initBoard(v.divid+"-</xsl:text>
    <xsl:value-of select="$board-id"/>
    <xsl:text>", {</xsl:text>
    <xsl:apply-templates select="./board-settings" mode="runestone-setup" />
    <xsl:text>});&#xa;</xsl:text>
    <!-- Add graphics elements. -->
    <xsl:apply-templates select="./contents/*" mode="graph-setup"/>
    <xsl:text>}&#xa;</xsl:text>
</xsl:template>

<xsl:template match="*" mode="graph-setup">
    <xsl:text>// </xsl:text>
    <xsl:value-of select="name()"/>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<xsl:template match="graph-point" mode="graph-setup">
    <!-- When a name is provided, store this for access. -->
    <xsl:if test="@name">
        <xsl:text>v.</xsl:text>
        <xsl:value-of select="@name"/>
        <xsl.text>=</xsl.text>
    </xsl:if>
    <xsl:apply-templates select="." mode="graph-create"/>
    <xsl:text>;&#xa;</xsl:text>
</xsl:template>

<xsl:template match="graph-point" mode="graph-create">
    <xsl:param name="visible">true</xsl:param>
    <xsl:text>curBoard.create('point', [</xsl:text>
    <xsl:apply-templates select="coord" mode="graph-create"/>
    <xsl:text>],  {fixed:true, visible:</xsl:text>
    <xsl:value-of select="$visible"/>
    <xsl:text>})</xsl:text>
</xsl:template>

<xsl:template match="coord" mode="graph-create">
    <xsl:if test="position() > 1">
        <xsl:text>, </xsl:text>
    </xsl:if>
    <xsl:choose>
        <xsl:when test="var">
            <xsl:apply-templates select="var" mode="evaluate">
                <xsl:with-param name="setupMode"><xsl:text>1</xsl:text></xsl:with-param>
            </xsl:apply-templates>
            <xsl:text>.value()</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="."/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="graph-circle" mode="graph-setup">
    <!-- When a name is provided, store this for access. -->
    <xsl:if test="@name">
        <xsl:text>v.</xsl:text>
        <xsl:value-of select="@name"/>
        <xsl.text>=</xsl.text>
    </xsl:if>
    <xsl:apply-templates select="." mode="graph-create"/>
    <xsl:text>;&#xa;</xsl:text>
</xsl:template>

<xsl:template match="graph-circle" mode="graph-create">
    <xsl:text>curBoard.create('circle', [</xsl:text>
    <xsl:choose>
        <xsl:when test="center/var">
            <xsl:apply-templates select="center/var" mode="evaluate">
                <xsl:with-param name="setupMode">1</xsl:with-param>
            </xsl:apply-templates>
        </xsl:when>
        <xsl:when test="center/graph-point">
            <xsl:apply-templates select="center/graph-point" mode="graph-create">
                <xsl:with-param name="visible">false</xsl:with-param>
            </xsl:apply-templates>
        </xsl:when>
    </xsl:choose>
    <xsl:text>, </xsl:text>
    <xsl:choose>
        <xsl:when test="radius/var">
            <xsl:apply-templates select="center/radius" mode="evaluate">
                <xsl:with-param name="setupMode">1</xsl:with-param>
            </xsl:apply-templates>
            <xsl:text>.value()</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="radius"/>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>],  {fixed:true})</xsl:text>
</xsl:template>

<xsl:template match="graph-label" mode="graph-setup">
    <!-- When a name is provided, store this for access. -->
    <xsl:if test="@name">
        <xsl:text>v.</xsl:text>
        <xsl:value-of select="@name"/>
        <xsl.text>=</xsl.text>
    </xsl:if>
    <xsl:apply-templates select="." mode="graph-create"/>
    <xsl:text>;&#xa;</xsl:text>
</xsl:template>

<xsl:template match="graph-text" mode="graph-create">
    <xsl:text>curBoard.create('text', [</xsl:text>
    <xsl:choose>
        <xsl:when test="position/var">
            <xsl:apply-templates select="position/var" mode="evaluate">
                <xsl:with-param name="setupMode">1</xsl:with-param>
            </xsl:apply-templates>
            <xsl:text>.X(), </xsl:text>
            <xsl:apply-templates select="position/var" mode="evaluate">
                <xsl:with-param name="setupMode">1</xsl:with-param>
            </xsl:apply-templates>
            <xsl:text>.Y()</xsl:text>
        </xsl:when>
        <xsl:when test="position/graph-point">
            <xsl:apply-templates select="position/graph-point/coord" mode="graph-create"/>
        </xsl:when>
    </xsl:choose>
    <xsl:text>, </xsl:text>
    <xsl:choose>
        <xsl:when test="text">
            <xsl:call-template name="quote-string">
                <xsl:with-param name="string" select="text"/>
            </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>"?"</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>],  {fixed:true})</xsl:text>
</xsl:template>

<xsl:template match="graph-function" mode="graph-setup">
    <!-- When a name is provided, store this for access. -->
    <xsl:if test="@name">
        <xsl:text>v.</xsl:text>
        <xsl:value-of select="@name"/>
        <xsl.text>=</xsl.text>
    </xsl:if>
    <xsl:text>{&#xa;let formulaObj = </xsl:text>
    <xsl:apply-templates select="formula" mode="evaluate">
        <xsl:with-param name="setupMode"><xsl:text>1</xsl:text></xsl:with-param>
    </xsl:apply-templates>
    <xsl:text>;&#xa;</xsl:text>
    <xsl:text>curBoard.create('functiongraph', [&#xa;</xsl:text>
    <xsl:text>function(x){ return formulaObj.evaluate({</xsl:text>
        <xsl:call-template name="quote-string">
            <xsl:with-param name="string" select="variable/name"/>
        </xsl:call-template>
        <xsl:text>: x</xsl:text>
    <xsl:text>}); },&#xa;</xsl:text>
    <xsl:value-of select="variable/min"/>
    <xsl:text>, </xsl:text>
    <xsl:value-of select="variable/max"/>
    <xsl:text>]);&#xa;</xsl:text>
    <xsl:text>}&#xa;</xsl:text>
</xsl:template>

<xsl:template match="board-settings" mode="runestone-setup">
    <xsl:variable name="xmin">
        <xsl:choose>
            <xsl:when test="xmin"><xsl:value-of select="xmin"/></xsl:when>
            <xsl:otherwise><xsl:text>-10</xsl:text></xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="xmax">
        <xsl:choose>
            <xsl:when test="xmax"><xsl:value-of select="xmax"/></xsl:when>
            <xsl:otherwise><xsl:text>10</xsl:text></xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="ymin">
        <xsl:choose>
            <xsl:when test="ymin"><xsl:value-of select="ymin"/></xsl:when>
            <xsl:otherwise><xsl:text>-10</xsl:text></xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="ymax">
        <xsl:choose>
            <xsl:when test="ymax"><xsl:value-of select="ymax"/></xsl:when>
            <xsl:otherwise><xsl:text>10</xsl:text></xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:text>boundingbox: [</xsl:text>
        <xsl:value-of select="$xmin"/><xsl:text>,</xsl:text>
        <xsl:value-of select="$ymax"/><xsl:text>,</xsl:text>
        <xsl:value-of select="$xmax"/><xsl:text>,</xsl:text>
        <xsl:value-of select="$ymin"/>
    <xsl:text>]</xsl:text>
    <xsl:variable name="show-axis">
        <xsl:choose>
            <xsl:when test="show-axis"><xsl:value-of select="show-axis"/></xsl:when>
            <xsl:otherwise><xsl:text>true</xsl:text></xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:text>, axis:</xsl:text>
    <xsl:value-of select="$show-axis"/>
    <xsl:variable name="allow-drag">
        <xsl:choose>
            <xsl:when test="allow-drag"><xsl:value-of select="allow-drag"/></xsl:when>
            <xsl:otherwise><xsl:text>false</xsl:text></xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:text>, drag:{enabled:</xsl:text>
        <xsl:value-of select="$allow-drag"/>
    <xsl:text>}</xsl:text>
    <xsl:variable name="show-navigation">
        <xsl:choose>
            <xsl:when test="show-navigation"><xsl:value-of select="show-navigation"/></xsl:when>
            <xsl:otherwise><xsl:text>false</xsl:text></xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:text>, showNavigation:</xsl:text>
    <xsl:value-of select="$allow-drag"/>
</xsl:template>

<!-- Generate a JSON script element for the dynamic exercise. -->
<xsl:template match="exercise[@exercise-interactive='fillin-dynamic']" mode="body">
    <xsl:variable name="the-id">
        <xsl:apply-templates select="." mode="html-id"/>
    </xsl:variable>
    <div class="runestone">
        <div data-component="fillintheblank" class="fillintheblank" style="visibility: hidden;">
            <xsl:attribute name="id">
                <xsl:value-of select="$the-id"/>
            </xsl:attribute>
            <script type="application/json">
                <xsl:text>{&#xa;</xsl:text>
                    <!-- The formatted HTML presentation of the problem, -->
                    <!-- with escape codes for dynamic content, all of   -->
                    <!-- which is serialized and escaped to a string.    -->
                    <xsl:text>"problemHtml": </xsl:text>
                    <xsl:apply-templates select="statement" mode="stringify-content" />
                    <!-- Names assigned to the blanks. (Inclusion is     -->
                    <!-- really so that evaluation of answers can refer  -->
                    <!-- to submitted work by name.                      -->
                    <xsl:text>,&#xa;"blankNames": {</xsl:text>
                    <xsl:apply-templates select="statement//fillin" mode="declare-blanks" />
                    <!-- The actual setup code is javascript enclosed in quotes. -->
                    <!-- The declaration creates the objects that are needed.    -->
                    <!-- The script is included as an escaped string             -->
                    <xsl:text>},&#xa;"dyn_vars": </xsl:text>
                    <xsl:call-template name="dynamic-setup"></xsl:call-template>
                    <!-- An array of tests and feedback for answer evaluation    -->
                    <!-- Each blank has a corresponding array of test/feedback   -->
                    <!-- response. The test is Javascript (stringified) that     -->
                    <!-- returns a boolean response. The first test is for       -->
                    <!-- correctness. The last response is default.              -->
                    <xsl:text>,&#xa;"feedbackArray": [</xsl:text>
                    <!-- In case all answers are based on one test               -->
                    <xsl:variable name="multiAns">
                        <xsl:call-template name="get-multianswer-check" />
                    </xsl:variable>
                    <!-- Generate test/feedback pair for each fillin             -->
                    <xsl:apply-templates select="statement//fillin" mode="dynamic-feedback">
                        <xsl:with-param name="multiAns" select="$multiAns" />
                    </xsl:apply-templates>
                    <xsl:text>]</xsl:text>
                <xsl:text>&#xa;}</xsl:text>
            </script>
        </div>
        <xsl:text>&#xa;</xsl:text>
    </div>
</xsl:template>

<!-- Runestone does not support hints or solutions. -->
<!-- Included implementation just in case           -->
<xsl:template match="hint" mode="runestone-json">
    <xsl:text>,&#xa;"problemHintHtml": </xsl:text>
    <xsl:apply-templates select="." mode="stringify-content" />
</xsl:template>

<xsl:template match="solution" mode="runestone-json">
    <xsl:text>,&#xa;"problemSolutionHtml": </xsl:text>
    <xsl:apply-templates select="." mode="stringify-content" />
</xsl:template>

<!-- Creating a list of blank names. -->
<xsl:template match="fillin" mode="declare-blanks">
    <xsl:if test="position()>1">
        <xsl:text>, </xsl:text>
    </xsl:if>
    <xsl:if test="@submit">
        <xsl:call-template name="quote-string">
            <xsl:with-param name="string" select="@submit"/>
        </xsl:call-template>
        <xsl:text>: </xsl:text>
        <xsl:value-of select="position()-1"/>
    </xsl:if>
</xsl:template>

<!-- Create the dynamic aspect of the problem.           -->
<!-- Define all of the mathematical elements as well as  -->
<!-- objects (e.g. graphs) that might depend on them     -->
<xsl:template name="dynamic-setup">
    <xsl:variable name="js_code">
        <!-- Initialize the math environment -->
        <xsl:call-template name="set-dynamic-environment"/>
        <!-- Generate all of the declared math objects -->
        <xsl:apply-templates select="dynamic-setup/de-object" mode="runestone-setup"/>
        <!-- Prepare evaluation and feedback -->
        <xsl:call-template name="set-blank-types"/>
        <!-- Any additional post-processing would go here,    -->
        <!-- such as needed content to define graphs.         -->
        <xsl:call-template name="setup-postContent"/>
    </xsl:variable>
    <xsl:call-template name="escape-quote-string">
        <xsl:with-param name="string" select="$js_code"/>
    </xsl:call-template>
</xsl:template>

<!-- Parse any settings for the math environment for the problem -->
<xsl:template name="set-dynamic-environment">
    <xsl:text>v._menv = new BTM({</xsl:text>
        <!-- Setup seeded random number generator                      -->
        <!-- At the moment, just rely on RS version                    -->
        <!-- Should probably have seeding process outside that context -->
        <xsl:text>'rand': rand</xsl:text>
        <!-- Pull additional settings from an environment element -->
        <xsl:apply-templates select="de-environment" mode="runestone-setup"/>
    <xsl:text>});&#xa;</xsl:text>
</xsl:template>

<xsl:template name="setup-postContent">
    <xsl:text>v.afterContentRender = function() {&#xa;</xsl:text>
        <xsl:apply-templates select="statement//dynamic-graph" mode="runestone-setup"/>
    <xsl:text>};&#xa;</xsl:text>
</xsl:template>

<!-- Template for answer checking. Actual work done by specialized templates. -->
<xsl:template match="fillin" mode="dynamic-feedback">
    <xsl:param name="multiAns"/>
    <xsl:variable name="curFillIn" select="."/>
    <xsl:variable name="check" select="ancestor::exercise[@exercise-interactive='fillin-dynamic']//dynamic-evaluation/evaluate[@submit = $curFillIn/@submit]" />
    <xsl:if test="position() > 1">
        <xsl:text>, </xsl:text>
    </xsl:if>
    <!-- First check is for correctness. -->
    <xsl:text>[{"solution_code": </xsl:text>
    <xsl:call-template name="escape-quote-string">
        <xsl:with-param name="string">
            <xsl:choose>
                <xsl:when test="string-length($multiAns)>0">
                    <xsl:value-of select="$multiAns"/>
                </xsl:when>
                <xsl:when test="$check/test[@correct='yes']">
                    <xsl:call-template name="create-test">
                        <xsl:with-param name="test" select="$check/test[@correct='yes']/*" />
                        <xsl:with-param name="submit" select="$curFillIn/@submit" />
                    </xsl:call-template>
                </xsl:when>
                <!-- If no explicit test, must be on the fillin. -->
                <xsl:otherwise>
                    <xsl:text>function() {&#xa;</xsl:text>
                    <xsl:text>    return _menv.compareExpressions(</xsl:text>
                    <xsl:value-of select="$curFillIn/@correct"/>
                    <xsl:text>, </xsl:text>
                    <xsl:value-of select="$curFillIn/@submit"/>
                    <xsl:text>);&#xa;}</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:text>()</xsl:text>
        </xsl:with-param>
    </xsl:call-template>
    <xsl:text>, "feedback": </xsl:text>
    <xsl:choose>
        <xsl:when test="$check/test[@correct='yes']/feedback">
            <xsl:call-template name="quote-string">
                <xsl:with-param name="string" select="$check/test[@correct='yes']/feedback"/>
            </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>"Correct."</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>}</xsl:text>
    <!-- Now add additional checks for feedback. -->
    <xsl:for-each select="$check/test[not(@correct='yes')]">
        <xsl:text>, {"solution_code": </xsl:text>
        <xsl:call-template name="escape-quote-string">
            <xsl:with-param name="string">
                <xsl:call-template name="create-test">
                    <xsl:with-param name="test" select="*" />
                    <xsl:with-param name="submit" select="$curFillIn/@submit" />
                </xsl:call-template>
                <xsl:text>()</xsl:text>
            </xsl:with-param>
        </xsl:call-template>
        <xsl:text>, "feedback": </xsl:text>
        <xsl:choose>
            <xsl:when test="feedback">
                <xsl:call-template name="quote-string">
                    <xsl:with-param name="string" select="feedback"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>"Try again."</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:text>}</xsl:text>
    </xsl:for-each>
    <!-- Default feedback for the blank. Always evaluates true.   -->
    <xsl:text>, {"feedback": </xsl:text>
    <xsl:choose>
        <!-- Allow the problem to define it: feedback with no test   -->
        <xsl:when test="$check/feedback">
            <xsl:call-template name="quote-string">
                <xsl:with-param name="string" select="$check/feedback"/>
            </xsl:call-template>
        </xsl:when>
        <!-- Maybe this should be a configurable default???   -->
        <xsl:otherwise>
            <xsl:text>"Try again."</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>}]</xsl:text>         
</xsl:template>


<!-- Each fillin defines a blank. Establish the list of parsers. -->
<!-- During setup and called while creating dyn_vars.            -->
<xsl:template match="fillin" mode="setup-blank-types">
    <xsl:if test="position() > 1">
        <xsl:text>, </xsl:text>
    </xsl:if>
    <!-- Future: There may be attributes of the fillin that declare parser type. -->
    <!-- For now, simply assuming everything is an expression.                   -->
    <xsl:text>v._menv.getParser()</xsl:text>
</xsl:template>

<xsl:template name="set-blank-types">
    <xsl:text>v.types = [</xsl:text>
    <xsl:apply-templates select="statement//fillin" mode="setup-blank-types" />
    <xsl:text>];&#xa;</xsl:text>
</xsl:template>

<!-- Part of Setup: Define the mathematical objects -->
<xsl:template match="de-object" mode="runestone-setup">
    <xsl:text>v.</xsl:text><xsl:value-of select="@name"/>
    <xsl:text> = v._menv.addMathObject(</xsl:text>
    <xsl:call-template name="quote-string">
        <xsl:with-param name="string" select="@name"/>
    </xsl:call-template>
    <xsl:text>, </xsl:text>
    <xsl:call-template name="quote-string">
        <xsl:with-param name="string">
            <xsl:apply-templates select="." mode="context"/>
        </xsl:with-param>
    </xsl:call-template>
    <xsl:text>, </xsl:text>
    <xsl:apply-templates select="." mode="evaluate">
        <xsl:with-param name="setupMode"><xsl:text>1</xsl:text></xsl:with-param>
    </xsl:apply-templates>
    <xsl:text>);&#xa;</xsl:text>
</xsl:template>

<xsl:template match="de-object" mode="context">
    <xsl:choose>
        <!-- Some of these could use value of @context but in case strings change. -->
        <xsl:when test="@context='number'">
            <xsl:text>number</xsl:text>
        </xsl:when>
        <xsl:when test="@context='formula'">
            <xsl:text>formula</xsl:text>
        </xsl:when>
        <xsl:when test="@context='interval' or @context='set'">
            <xsl:text>set</xsl:text>
        </xsl:when>
        <xsl:when test="@context='list'">
            <xsl:text>list</xsl:text>
        </xsl:when>
    </xsl:choose>
</xsl:template>

<xsl:template match="de-object[@context='number']" mode="evaluate">
    <xsl:param name="setupMode" />
    <xsl:variable name="prefix">
        <xsl:if test="$setupMode">
            <xsl:text>v.</xsl:text>
        </xsl:if>
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="@mode='value' or @mode='formula'">
            <xsl:value-of select="$prefix"/>
            <xsl:text>_menv.parseExpression(</xsl:text>
            <xsl:call-template name="quote-string">
                <xsl:with-param name="string" select="."/>
            </xsl:call-template>
            <xsl:text>, "number")</xsl:text>
        </xsl:when>
        <xsl:when test="@mode='evaluate'">
            <xsl:value-of select="$prefix"/>
            <xsl:text>_menv.evaluateMathObject(</xsl:text>
                <xsl:apply-templates select="formula/*" mode="evaluate">
                    <xsl:with-param name="setupMode" select="$setupMode"/>
                </xsl:apply-templates>
                <xsl:text>, "number", {</xsl:text>
                <xsl:apply-templates select="variable" mode="evaluation-binding" >
                    <xsl:with-param name="setupMode" select="$setupMode" />
                </xsl:apply-templates>
            <xsl:text>.value()}).reduce()</xsl:text>
        </xsl:when>
        <xsl:when test="@mode='random'">
            <xsl:choose>
                <xsl:when test="options[@distribution='discrete']">
                    <xsl:variable name="rnd-min">
                        <xsl:choose>
                            <xsl:when test="options/@min">
                                <xsl:value-of select="options/@min"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:text>0</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:variable name="rnd-max">
                        <xsl:choose>
                            <xsl:when test="options/@max">
                                <xsl:value-of select="options/@max"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:text>1</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:variable name="rnd-by">
                        <xsl:choose>
                            <xsl:when test="options/@by">
                                <xsl:value-of select="options/@by"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:text>1</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:variable name="rnd-nonzero">
                        <xsl:choose>
                            <xsl:when test="options/@nonzero = 'yes'">
                                <xsl:text>true</xsl:text>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:text>false</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:call-template name="generate-random-number">
                        <xsl:with-param name="rnd-dist">
                            <xsl:text>discrete</xsl:text>
                        </xsl:with-param>
                        <xsl:with-param name="rnd-options">
                            <xsl:text>{ min:</xsl:text>
                            <xsl:value-of select="$rnd-min"/>
                            <xsl:text>, max:</xsl:text>
                            <xsl:value-of select="$rnd-max"/>
                            <xsl:text>, by:</xsl:text>
                            <xsl:value-of select="$rnd-by"/>
                            <xsl:text>, nonzero:</xsl:text>
                            <xsl:value-of select="$rnd-nonzero"/>
                            <xsl:text>}</xsl:text>
                        </xsl:with-param>
                    </xsl:call-template>
                </xsl:when>
            </xsl:choose>
        </xsl:when>
    </xsl:choose>
</xsl:template>

<xsl:template match="de-object[@context='formula']" mode="evaluate">
    <xsl:param name="setupMode" />
    <xsl:variable name="prefix">
        <xsl:if test="$setupMode">
            <xsl:text>v.</xsl:text>
        </xsl:if>
    </xsl:variable>
    <xsl:choose>
        <!-- Simple formula is provided, with or without pattern matching -->
        <xsl:when test="@mode='formula'">
            <xsl:value-of select="$prefix"/>
            <xsl:text>_menv.parseExpression(</xsl:text>
            <xsl:call-template name="quote-string">
                <xsl:with-param name="string" select="."/>
            </xsl:call-template>
            <xsl:text>, "formula")</xsl:text>
        </xsl:when>
        <!-- Composition of two formulas (same look as evaluation)                -->
        <!-- Requires descendent nodes: formula and values to substitute          -->
        <xsl:when test="@mode='substitution'">
            <xsl:apply-templates select="formula/*" mode="evaluate">
                <xsl:with-param name="setupMode" select="$setupMode"/>
            </xsl:apply-templates>
            <xsl:text>.compose({</xsl:text>
                <xsl:apply-templates select="variable" mode="evaluation-binding" >
                    <xsl:with-param name="setupMode" select="$setupMode" />
                </xsl:apply-templates>
            <xsl:text>}).reduce()</xsl:text>
        </xsl:when>
        <!-- Derivative of a formula.                        -->
        <!-- Requires descendent nodes: formula, variable    -->
        <xsl:when test="@mode='derivative'">
            <xsl:apply-templates select="formula" mode="evaluate">
                <xsl:with-param name="setupMode" select="$setupMode" />
            </xsl:apply-templates>
            <xsl:text>.derivative(</xsl:text>
            <xsl:call-template name="quote-string">
                <xsl:with-param name="string" select="variable/@name"/>
            </xsl:call-template>
            <xsl:text>)</xsl:text>
        </xsl:when>
        <!-- Evaluate a formula at specific values.          -->
        <!-- Values for variables define a binding.          -->
        <xsl:when test="@mode='evaluate'">
            <xsl:apply-templates select="formula" mode="evaluate">
                <xsl:with-param name="setupMode" select="$setupMode"/>
            </xsl:apply-templates>
            <xsl:text>.evaluate({</xsl:text>
            <xsl:apply-templates select="variable" mode="evaluation-binding" >
                <xsl:with-param name="setupMode" select="$setupMode" />
            </xsl:apply-templates>
            <xsl:text>})</xsl:text>
        </xsl:when>
    </xsl:choose>
</xsl:template>

<!-- Used during composition or evaluation of a variable-->
<xsl:template match="variable" mode="evaluation-binding">
    <xsl:param name="setupMode" />
    <xsl:variable name="prefix">
        <xsl:if test="$setupMode">
            <xsl:text>v.</xsl:text>
        </xsl:if>
    </xsl:variable>
    <xsl:if test="position() > 1">
        <xsl:text>, </xsl:text>
    </xsl:if>
    <xsl:call-template name="quote-string">
        <xsl:with-param name="string" select="@name" />
    </xsl:call-template>
    <xsl:text>: </xsl:text>
    <xsl:choose>
        <xsl:when test="var or de-object">
            <xsl:apply-templates select="var|/de-object" mode="evaluate">
                <xsl:with-param name="setupMode" select="$setupMode" />
            </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="." />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- @random means the parameter is random -->
<!-- otherwise, defined by a constant or in terms of earlier parameters using mustache substitution -->
<xsl:template match="de-parameter" mode="runestone-setup">
    <xsl:text>v.</xsl:text><xsl:value-of select="@name"/>
    <xsl:text> = v._menv.addMathObject(</xsl:text>
    <xsl:choose>
        <xsl:when test="@random">
    <xsl:variable name="param-rnd-min">
        <xsl:choose>
            <xsl:when test="@min">
                <xsl:value-of select="@min"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>0</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="param-rnd-max">
        <xsl:choose>
            <xsl:when test="@max">
                <xsl:value-of select="@max"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>1</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="param-rnd-by">
        <xsl:choose>
            <xsl:when test="@by">
                <xsl:value-of select="@by"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>1</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="param-rnd-nonzero">
        <xsl:choose>
            <xsl:when test="@nonzero = 'yes'">
              <xsl:text>true</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>false</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
                <xsl:call-template name="random-parameter" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:call-template name="calculate-parameter" >
                <xsl:with-param name="formula" select="."/>
            </xsl:call-template>
        </xsl:otherwise>
        <xsl:text>;&#xa;</xsl:text>
    </xsl:choose>
</xsl:template>

<!-- Generate a random parameter. -->
<xsl:template name="generate-random-number">
    <xsl:param name="rnd-dist" />
    <xsl:param name="rnd-options" />
    <xsl:text>v._menv.generateRandom(</xsl:text>
        <xsl:call-template name="quote-string">
            <xsl:with-param name="string" select="$rnd-dist"/>
        </xsl:call-template>
        <xsl:text>, </xsl:text>
        <xsl:value-of select="$rnd-options"/>
    <xsl:text>)&#xa;</xsl:text>
</xsl:template>

<!-- Calculate a parameter based on a formula of other parameters. -->
<xsl:template name="calculate-parameter">
    <xsl:param name="formula" />
    <xsl:text>v._menv.addParameter(</xsl:text>
    <xsl:call-template name="quote-string">
        <xsl:with-param name="string" select="@name"/>
    </xsl:call-template>
    <xsl:text>, { mode: 'calculate'</xsl:text>
    <xsl:text>, formula: </xsl:text>
    <xsl:call-template name="quote-string">
        <xsl:with-param name="string" select="$formula"/>
    </xsl:call-template>
    <xsl:text> });&#xa;</xsl:text>
</xsl:template>

<!-- mode="evaluate" is used during setup and during feedback evaluation            -->
<!-- Define an expressions that will be parsed in their math context                -->
<!-- The expression can be defined in terms of the parameters and other expressions -->
<xsl:template match="de-object[@context='formula' and @mode='formula']|de-term[@context='formula']" mode="evaluate">
    <xsl:param name="setupMode" />
    <xsl:variable name="prefix">
        <xsl:if test="$setupMode">
            <xsl:text>v.</xsl:text>
        </xsl:if>
    </xsl:variable>
    <xsl:value-of select="$prefix"/>
    <xsl:text>_menv.parseExpression(</xsl:text>
    <xsl:call-template name="quote-string">
        <xsl:with-param name="string" select="."/>
    </xsl:call-template>
    <xsl:text>).reduce()</xsl:text>
</xsl:template>


<!-- var elements in expressions (evaluate) are replaced by their name -->
<!-- During setup, we need to use the context of the `v` object        -->
<xsl:template match="var" mode="evaluate">
    <xsl:param name="setupMode" />
    <xsl:variable name="prefix">
        <xsl:if test="$setupMode">
            <xsl:text>v.</xsl:text>
        </xsl:if>
    </xsl:variable>
    <xsl:value-of select="$prefix"/>
    <xsl:value-of select="@name"/>
</xsl:template>

<!-- Nothing else is defined for evaluation during setup  -->
<xsl:template match="/" mode="evaluate"/>

<!-- How to *add* expressions/formulas to the math context -->
<xsl:template match="de-object[@context='formula' and @mode='formula']|de-term[@context='formula']" mode="runestone-setup-old">
    <xsl:text>v.</xsl:text><xsl:value-of select="@name"/>
    <xsl:text> = v._menv.addMathObject(</xsl:text>
    <xsl:call-template name="quote-string">
        <xsl:with-param name="string" select="@name"/>
    </xsl:call-template>
    <xsl:text>, "formula", </xsl:text>
    <xsl:apply-templates select="." mode="evaluate">
        <xsl:with-param name="setupMode"><xsl:text>1</xsl:text></xsl:with-param>
    </xsl:apply-templates>
    <xsl:text>);&#xa;</xsl:text>
</xsl:template>

<!-- How to *add* expressions defined by substitution to the math context -->
<xsl:template match="de-object[@context='formula' and @mode='substitution']|de-term[@context='substitution']" mode="runestone-setup-old">
    <xsl:text>v.</xsl:text><xsl:value-of select="@name"/>
    <xsl:text> = v._menv.addExpression(</xsl:text>
    <xsl:call-template name="quote-string">
        <xsl:with-param name="string" select="@name"/>
    </xsl:call-template>
    <xsl:text>, </xsl:text>
    <xsl:apply-templates select="." mode="evaluate">
        <xsl:with-param name="setupMode"><xsl:text>1</xsl:text></xsl:with-param>
    </xsl:apply-templates>
    <xsl:text>);&#xa;</xsl:text>
</xsl:template>


<!-- Deal with possibility of global checker for all blanks -->
<xsl:template name="get-multianswer-check">
    <xsl:variable name="responseTree" select="ancestor::exercise[@exercise-interactive='fillin-dynamic']//fillin" />
    <xsl:if test="count($responseTree) > 1 and ancestor::exercise[@exercise-interactive='fillin-dynamic']//dynamic-evaluation/evaluate[@all='yes']/test">
        <xsl:variable name="check_all" select="ancestor::exercise[@exercise-interactive='fillin-dynamic']//dynamic-evaluation/evaluate[@all='yes']/test" />
        <xsl:call-template name="build-checker">
            <xsl:with-param name="test" select="$check_all" />
        </xsl:call-template>>
    </xsl:if>
</xsl:template>

<!-- Template for simple answer checkers: no interaction between different fillins. -->
<!-- Add a post-filter to deal with additional feedback, similar to AnswerHints but allowing more complex logic. -->

<xsl:template name="create-test">
    <xsl:param name="submit" />
    <xsl:param name="test" />
    <xsl:text>function() {&#xa;</xsl:text>
    <!-- Create a checker function. Initialize a stack of flag variables to track results. -->
    <xsl:text>    var testResults = new Array();&#xa;</xsl:text>
    <xsl:choose>
        <xsl:when test="count($test[name() != 'feedback']) = 1">
            <xsl:call-template name="checker-simple">
                <xsl:with-param name="submit" select="$submit" />
                <xsl:with-param name="curTest" select="$test" />
                <xsl:with-param name="level" select="0" />
            </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
            <xsl:call-template name="checker-layer">
                <xsl:with-param name="tests" select="$test" />
                <xsl:with-param name="level" select="0" />
                <xsl:with-param name="logic" select="'and'" /> <!-- All tests at first layer must be true -->
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>    return (testResults[0]);&#xa;</xsl:text>
    <xsl:text>}</xsl:text>
</xsl:template>


<!-- This template is called for a simple test (no compound logic). -->
<xsl:template name="checker-simple">
    <xsl:param name="curTest" />
    <xsl:param name="submit" />
    <xsl:param name="level" select="0" />
    <xsl:text>    testResults[</xsl:text>
    <xsl:value-of select="$level" />
    <xsl:text>] = </xsl:text>
    <!-- A test can have an implied equal or an explicit equal -->
    <!-- At root level, the test might also have a feedback. Skip that. -->
    <xsl:variable name="actualTest" select="$curTest[name() != 'feedback']"/>
    <xsl:text>_menv.compareExpressions(</xsl:text>
    <xsl:choose>
        <!-- An equal element must have two expression children. -->
        <xsl:when test="name($actualTest) = 'equal'">
            <xsl:apply-templates select="$actualTest/*[1]" mode="evaluate"/>
            <xsl:text>, </xsl:text>
            <xsl:apply-templates select="$actualTest/*[2]" mode="evaluate"/>
        </xsl:when>
        <!-- An implied equal compares the submitted answer to the given expression. -->
        <xsl:otherwise>   <!-- Must be expression: #var or #de-term -->
          <xsl:apply-templates select="$actualTest" mode="evaluate"/>
          <xsl:text>, </xsl:text>
          <xsl:value-of select="$submit" />
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>);&#xa;</xsl:text>
</xsl:template>

<!-- A test can also be composite involving a combination of logical tests -->
<!-- This template works through one layer, recursively dealing with deeper layers as needed -->
<xsl:template name="checker-layer" >
    <xsl:param name="submit" />
    <xsl:param name="tests" />                   <!-- The layer of tests (subtree) -->
    <xsl:param name="level" select="0" />        <!-- Level (or depth) of the layer -->
    <xsl:param name="logic" select="'and'" />    <!-- and = all must be true, or = at least one, not = negation -->
    <xsl:choose>
        <xsl:when test="$logic = 'and'">         <!-- Treat logic like multipication. A single false (0) makes product zero -->
            <xsl:text>    testResults[</xsl:text><xsl:value-of select="$level" /><xsl:text>] = 1;&#xa;</xsl:text>
        </xsl:when>
        <xsl:when test="$logic = 'or'">         <!-- Treat logic like addition. A single true makes sum positive -->
            <xsl:text>testResults[</xsl:text><xsl:value-of select="$level" /><xsl:text>] = 0;&#xa;</xsl:text>
        </xsl:when>
    </xsl:choose>
    <xsl:for-each select="$tests">    <!-- Work through the layer of tests one at a time. -->
        <xsl:choose>
            <xsl:when test="name()='and'">
                <xsl:text>    testResults[</xsl:text>
                <xsl:value-of select="$level+1" />
                <xsl:text>] = 1;&#xa;</xsl:text>
                <xsl:call-template name="checker-layer">
                    <xsl:with-param name="submit" select="$submit" />
                    <xsl:with-param name="tests" select="./*" />
                    <xsl:with-param name="level" select="$level+1" />
                    <xsl:with-param name="logic" select="'and'" /> <!-- Default: All tests at first layer must be true -->
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="name()='or'">
                <xsl:text>    testResults[</xsl:text>
                <xsl:value-of select="$level+1" />
                <xsl:text>] = 0;&#xa;</xsl:text>
                <xsl:call-template name="checker-layer">
                    <xsl:with-param name="submit" select="$submit" />
                    <xsl:with-param name="tests" select="./*" />
                    <xsl:with-param name="level" select="$level+1" />
                    <xsl:with-param name="logic" select="'or'" /> <!-- Default: All tests at first layer must be true -->
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="name()='not'">
                <xsl:call-template name="checker-layer">
                    <xsl:with-param name="submit" select="$submit" />
                    <xsl:with-param name="tests" select="./*" />
                    <xsl:with-param name="level" select="$level+1" />
                    <xsl:with-param name="logic" select="'not'" /> <!-- Default: All tests at first layer must be true -->
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="checker-simple">
                    <xsl:with-param name="submit" select="$submit" />
                    <xsl:with-param name="curTest" select="." />
                    <xsl:with-param name="level" select="$level+1" />
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:for-each>
    <xsl:choose> <!-- Deal with the results of that recursive call to a deeper layer. -->
        <xsl:when test="$logic = 'and'">
            <xsl:text>    testResults[</xsl:text><xsl:value-of select="$level" />
            <xsl:text>] &amp;= testResults[</xsl:text><xsl:value-of select="$level+1" /><xsl:text>];&#xa;</xsl:text>
        </xsl:when>
        <xsl:when test="$logic = 'or'">
            <xsl:text>    testResults[</xsl:text><xsl:value-of select="$level" />
            <xsl:text>] |= testResults[</xsl:text><xsl:value-of select="$level+1" /><xsl:text>];&#xa;</xsl:text>
        </xsl:when>
        <xsl:when test="$logic = 'not'">
            <xsl:text>    testResults[</xsl:text><xsl:value-of select="$level" />
            <xsl:text>] = !(testResults[</xsl:text><xsl:value-of select="$level+1" /><xsl:text>]);&#xa;</xsl:text>
        </xsl:when>
    </xsl:choose>
</xsl:template>

</xsl:stylesheet>