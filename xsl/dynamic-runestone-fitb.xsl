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
<xsl:template match="exercise[@dynamic]//fillin">
    <xsl:param name="b-human-readable" />
    <xsl:element name="input">
        <xsl:attribute name="types"><xsl:text>text</xsl:text></xsl:attribute>
        <xsl:attribute name="name"><xsl:value-of select="@submit"/></xsl:attribute>
    </xsl:element>
</xsl:template>

<xsl:template match="exercise[@dynamic]//var[@name]">
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


<!-- Generate a JSON script element for the dynamic exercise. -->
<xsl:template match="exercise[@dynamic = 'runestone']" mode="body">
    <xsl:variable name="filename">
        <xsl:apply-templates select="." mode="visible-id" />
    </xsl:variable>
    <div class="runestone">
        <div data-component="fillintheblank" class="fillintheblank" style="visibility: hidden;">
            <xsl:attribute name="id">
                <xsl:apply-templates select="." mode="html-id"/>
            </xsl:attribute>
            <script type="application/json">
                <xsl:text>{&#xa;</xsl:text>
                    <xsl:text>"problemHtml": </xsl:text>
                    <xsl:apply-templates select="statement" mode="stringify-content" />
                    <xsl:text>,&#xa;"blankNames": {</xsl:text>
                    <xsl:apply-templates select="statement//fillin" mode="declare-blanks" />
                    <xsl:text>}</xsl:text>
                    <xsl:call-template name="dynamic-setup"></xsl:call-template>
                    <xsl:call-template name="dynamic-feedback"></xsl:call-template>
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
    <xsl:text>,&#xa;"dyn_vars": </xsl:text>
    <!-- The actual setup code is javascript enclosed in quotes. -->
    <!-- The declaration creates the objects that are needed.    -->
    <xsl:variable name="js_code">
        <!-- Initialize the math environment -->
        <xsl:text>v._menv = new BTM({'rand':rand});&#xa;</xsl:text>
        <!-- Generate all of the declared parameters -->
        <xsl:apply-templates select="dynamic-setup/de-parameter" mode="runestone-setup"/>
        <!-- Declare any variables -->
        <xsl:apply-templates select="dynamic-setup/de-variable" mode="runestone-setup"/>
        <!-- Construct expressions -->
        <xsl:apply-templates select="dynamic-setup/de-term" mode="runestone-setup"/>
        <!-- Prepare evaluation and feedback -->
        <xsl:call-template name="set-blank-types"/>
        <!-- Any additional post-processing would go here,    -->
        <!-- such as needed content to define graphs.         -->
    </xsl:variable>
    <xsl:call-template name="escape-quote-string">
        <xsl:with-param name="string" select="$js_code"/>
    </xsl:call-template>
</xsl:template>

<!-- Each fillin defines a blank. Here is where we would set the parsing for each blank. -->
<xsl:template name="set-blank-types">
    <xsl:text>v.types = [</xsl:text>
    <xsl:for-each select="statement//fillin">
        <xsl:if test="position() > 1">
            <xsl:text>, </xsl:text>
        </xsl:if>
        <!-- Future: There may be attributes of the fillin that declare parser type. -->
        <!-- For now, simply assuming everything is an expression to parse. -->
        <xsl:text>v._menv.getParser()</xsl:text>
    </xsl:for-each>
    <xsl:text>];&#xa;</xsl:text>
</xsl:template>

<!-- Part of Setup: Define a parameter -->
<!-- @random means the parameter is random -->
<!-- otherwise, defined by a constant or in terms of earlier parameters using mustache substitution -->
<xsl:template match="de-parameter" mode="runestone-setup">
    <xsl:text>v.</xsl:text><xsl:value-of select="@name"/><xsl:text> = </xsl:text>
    <xsl:choose>
        <xsl:when test="@random">
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
<!-- @min: lowest value -->
<!-- @max: highest value -->
<!-- @by: increment between values -->
<!-- @nonzero = 'yes': exclude value of zero from possibilities -->
<xsl:template name="random-parameter">
    <xsl:choose>
        <xsl:when test="@random='discrete'">
            <xsl:call-template name="random-parameter-discrete"/>
        </xsl:when>
    </xsl:choose>
</xsl:template>

<xsl:template name="random-parameter-discrete">
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
    <xsl:text>v._menv.addParameter(</xsl:text>
        <xsl:call-template name="quote-string">
            <xsl:with-param name="string" select="@name"/>
        </xsl:call-template>
        <xsl:text>, { mode: 'random'</xsl:text>
        <xsl:text>, min: </xsl:text><xsl:value-of select="$param-rnd-min"/>
        <xsl:text>, max: </xsl:text><xsl:value-of select="$param-rnd-max"/>
        <xsl:text>, by: </xsl:text><xsl:value-of select="$param-rnd-by"/>
        <xsl:text>, nonzero: </xsl:text><xsl:value-of select="$param-rnd-nonzero"/>
    <xsl:text> });&#xa;</xsl:text>
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

<!-- mode="evaluate" is used during setup and during feedback evaluation  -->
<!-- Define an expressions that will be parsed in their math context                -->
<!-- The expression can be defined in terms of the parameters and other expressions -->
<xsl:template match="de-term[@context='formula']" mode="evaluate">
    <xsl:param name="setupMode" />
    <xsl:variable name="prefix">
        <xsl:if test="$setupMode">
            <xsl:text>v.</xsl:text>
        </xsl:if>
    </xsl:variable>
    <xsl:value-of select="$prefix"/>
    <xsl:text>_menv.evaluateExpression(</xsl:text>
    <xsl:call-template name="quote-string">
        <xsl:with-param name="string" select="."/>
    </xsl:call-template>
    <xsl:text>).reduce()</xsl:text>
</xsl:template>

<!-- Define an expressions as substitution (composition) of other expressions   -->
<!-- ./start defines the outer (original) function                              -->
<!-- ./match defines the variable that will be replaced                         -->
<!-- ./replace defines the expression that will replace the variable            -->
<xsl:template match="de-term[@context='substitution']" mode="evaluate">
    <xsl:param name="setupMode" />
    <xsl:apply-templates select="./start/*" mode="evaluate">
        <xsl:with-param name="setupMode" select="$setupMode"/>
    </xsl:apply-templates>
    <xsl:text>.compose({</xsl:text>
    <xsl:call-template name="quote-string">
        <xsl:with-param name="string" select="./match"/>
    </xsl:call-template>
    <xsl:text>: </xsl:text>
    <xsl:apply-templates select="./replace/*" mode="evaluate">
        <xsl:with-param name="setupMode" select="$setupMode"/>
    </xsl:apply-templates>
    <xsl:text>}).reduce()</xsl:text>
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
<xsl:template match="de-term[@context='formula']" mode="runestone-setup">
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

<!-- How to *add* expressions defined by substitution to the math context -->
<xsl:template match="de-term[@context='substitution']" mode="runestone-setup">
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

<!-- Template for answer checking. Actual work done by specialized templates. -->
<xsl:template name="dynamic-feedback">
    <xsl:variable name="multiAns">
        <xsl:call-template name="get-multianswer-check" />
    </xsl:variable>
    <xsl:text>,&#xa;"feedbackArray": [</xsl:text>
    <xsl:for-each select="statement//fillin">
        <xsl:variable name="curFillIn" select="."/>
        <xsl:variable name="check" select="ancestor::exercise[@dynamic='runestone']//dynamic-evaluation/evaluate[@submit = $curFillIn/@submit]" />
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
        <xsl:text>, {"feedback": </xsl:text>
        <xsl:choose>
            <xsl:when test="$check/feedback">
                <xsl:call-template name="quote-string">
                    <xsl:with-param name="string" select="$check/feedback"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>"Try again."</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:text>}]</xsl:text>         
    </xsl:for-each>
    <xsl:text>]</xsl:text>
</xsl:template>


<!-- Deal with possibility of global checker for all blanks -->
<xsl:template name="get-multianswer-check">
    <xsl:variable name="responseTree" select="ancestor::exercise[@dynamic = 'runestone']//fillin" />
    <xsl:if test="count($responseTree) > 1 and ancestor::exercise[@dynamic = 'runestone']//dynamic-evaluation/evaluate[@all='yes']/test">
        <xsl:variable name="check_all" select="ancestor::exercise[@dynamic = 'runestone']//dynamic-evaluation/evaluate[@all='yes']/test" />
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