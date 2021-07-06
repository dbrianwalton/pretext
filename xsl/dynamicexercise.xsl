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

<xsl:import href="./extract-pg.xsl" />

<xsl:strip-space elements="setup"/>


<!-- Begin the process. -->
<xsl:template match="/">
    <xsl:apply-templates select="mathbook|pretext" mode="generic-warnings" />
    <xsl:apply-templates select="mathbook|pretext" mode="deprecation-warnings" />
    <xsl:text>localization = '</xsl:text>
    <xsl:value-of select="$document-language"/>
    <xsl:text>'&#xa;</xsl:text>
    <!-- Initialize empty dictionaries, then define key-value pairs -->
    <xsl:text>origin = {}&#xa;</xsl:text>
    <xsl:text>copiedfrom = {}&#xa;</xsl:text>
    <xsl:text>seed = {}&#xa;</xsl:text>
    <xsl:text>source = {}&#xa;</xsl:text>
    <xsl:text>pghuman = {}&#xa;</xsl:text>
    <xsl:text>pgdense = {}&#xa;</xsl:text>
    <xsl:text>pgdense['hint_no_solution_no'] = {}&#xa;</xsl:text>
    <xsl:text>pgdense['hint_no_solution_yes'] = {}&#xa;</xsl:text>
    <xsl:text>pgdense['hint_yes_solution_no'] = {}&#xa;</xsl:text>
    <xsl:text>pgdense['hint_yes_solution_yes'] = {}&#xa;</xsl:text>
    <xsl:apply-templates select="*" mode="webwork"/>
</xsl:template>


<xsl:template match="exercise[@dynamic]" mode="webwork">
<problem>
    <xsl:variable name="filename">
        <xsl:apply-templates select="." mode="visible-id" />
    </xsl:variable>
    <exsl:document href="{$filename}.pg" method="text">
        <xsl:call-template name="sanitize-text">
            <xsl:with-param name="text" select="pg" />
        </xsl:call-template>
        <xsl:call-template name="webwork-pg-header" />
        <xsl:apply-templates select="setup" mode="webwork-setup" />
        <xsl:apply-templates select="feedback" mode="webwork" />
        <xsl:apply-templates select="statement" mode="webwork" />
        <xsl:call-template name="webwork-pg-footer" />    
    </exsl:document>
</problem>
</xsl:template>

<xsl:template name="webwork-pg-header">
    <xsl:text>DOCUMENT();&#10;</xsl:text>
    <xsl:text>loadMacros(&#10;</xsl:text>
    <xsl:text>  "PGstandard.pl",&#10;</xsl:text>
    <xsl:text>  "PGML.pl",&#10;</xsl:text>
    <xsl:text>  "MathObjects.pl",&#10;</xsl:text>
    <xsl:text>  "PGcourse.pl",&#10;</xsl:text>
    <xsl:text>  "parserNumberWithUnits.pl",&#10;</xsl:text>
    <xsl:text>  "contextArbitraryString.pl",&#10;</xsl:text>
    <xsl:text>  "parserMultiAnswer.pl",&#10;</xsl:text>
    <xsl:text>  "parserPopUp.pl",&#10;</xsl:text>
    <xsl:text>  "contextInequalities.pl",&#10;</xsl:text>
    <xsl:text>  "PGgraphmacros.pl",&#10;</xsl:text>
    <xsl:text>);&#10;</xsl:text>
    <xsl:text>TEXT(beginproblem());&#10;</xsl:text>
    <xsl:text>$showPartialCorrectAnswers = 1;&#10;</xsl:text>
    <xsl:text>Context("Numeric");&#10;</xsl:text>
</xsl:template>

<xsl:template name="webwork-pg-footer">
    <xsl:text>ENDDOCUMENT();&#10;</xsl:text>
</xsl:template>

<xsl:template name="webwork-open-problem">
    <xsl:text>################################################&#10;</xsl:text>
    <xsl:text>BEGIN_PGML&#10;</xsl:text>
</xsl:template>
<xsl:template name="webwork-close-problem">
    <xsl:text>END_PGML&#10;</xsl:text>
    <xsl:text>################################################&#10;</xsl:text>
</xsl:template>

<xsl:template name="webwork-open-hint">
    <xsl:text>################################################&#10;</xsl:text>
    <xsl:text>BEGIN_PGML_HINT&#10;</xsl:text>
</xsl:template>
<xsl:template name="webwork-close-hint">
    <xsl:text>END_PGML_HINT&#10;</xsl:text>
    <xsl:text>################################################&#10;</xsl:text>
</xsl:template>

<xsl:template name="webwork-open-solution">
    <xsl:text>################################################&#10;</xsl:text>
    <xsl:text>BEGIN_PGML_SOLUTION&#10;</xsl:text>
</xsl:template>
<xsl:template name="webwork-close-solution">
    <xsl:text>END_PGML_SOLUTION&#10;</xsl:text>
    <xsl:text>################################################&#10;</xsl:text>
</xsl:template>

<xsl:template name="random-parameter">
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
    <xsl:choose>
        <xsl:when test="@nonzero = 'yes'">
            <xsl:text>non_zero_random</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>random</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>(</xsl:text>
    <xsl:value-of select="$param-rnd-min"/>
    <xsl:text>,</xsl:text>
    <xsl:value-of select="$param-rnd-max"/>
    <xsl:text>,</xsl:text>
    <xsl:value-of select="$param-rnd-by"/>
    <xsl:text>);&#10;</xsl:text>
</xsl:template>

<xsl:template match="parameter" mode="webwork-setup">
    <xsl:text>$</xsl:text><xsl:value-of select="@name"/><xsl:text> = </xsl:text>
    <xsl:choose>
        <xsl:when test="@random='uniform'">
            <xsl:call-template name="random-parameter" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:text select="."/>
        </xsl:otherwise>
        <xsl:text>;&#10;</xsl:text>
    </xsl:choose>
</xsl:template>

<!-- PGML answer input               -->
<!-- Example: [_____]{$ans}          -->
<xsl:template match="fillin">
    <xsl:param name="b-human-readable" />
    <xsl:apply-templates select="." mode="field">
        <xsl:with-param name="b-human-readable" select="$b-human-readable" />
    </xsl:apply-templates>
    <xsl:apply-templates select="." mode="form-help"/>
</xsl:template>

<!-- MathObject answers -->
<!-- with variant for MathObjects like Matrix, Vector, ColumnVector      -->
<!-- where the shape of the MathObject guides the array of answer blanks -->
<xsl:template match="fillin" mode="field">
    <xsl:param name="b-human-readable" />
    <xsl:variable name="multiAns">
        <xsl:call-template name="de-requires-multianswer" />
    </xsl:variable>
    <xsl:variable name="width">
        <xsl:choose>
            <xsl:when test="@width">
                <xsl:value-of select="@width"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>5</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- when an answer blank is the first thing on a line, indent -->
    <!-- this is a styling preference that can't be customized     -->
    <xsl:if test="(count(preceding-sibling::*)+count(preceding-sibling::text()))=0 and parent::p/parent::statement">
        <xsl:text>    </xsl:text>
    </xsl:if>
    <xsl:text>[_]</xsl:text>
    <!-- multiplier for MathObjects like Matrix, Vector, ColumnVector -->
    <xsl:if test="@form='array'">
        <xsl:text>*</xsl:text>
    </xsl:if>
    <xsl:choose>
        <xsl:when test="string-length($multiAns) > 0">
            <xsl:text>{$_mc_cmp}</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>{$_</xsl:text>
            <xsl:value-of select="@correct" />
            <xsl:text>_cmp}</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>{</xsl:text>
    <xsl:value-of select="$width"/>
    <xsl:text>}</xsl:text>
</xsl:template>


<xsl:template match="de-term[@context='formula']" mode="webwork-setup">
    <xsl:text>$</xsl:text><xsl:value-of select="@name"/>
    <xsl:text> = "</xsl:text>
    <xsl:apply-templates select="." mode="compute" />
    <xsl:text>"->reduce;&#10;</xsl:text>
</xsl:template>

<!-- WeBWorK implements variable substitution for Formula MathObjects. -->
<xsl:template match="de-term[@context='substitution']" mode="webwork-setup">
    <!-- New name of the generated term -->
    <xsl:text>$</xsl:text>
    <xsl:value-of select="@name"/>
    <xsl:text> = </xsl:text>
    <xsl:apply-templates select="." mode="compute" />
    <xsl:text>->reduce;&#10;</xsl:text>
</xsl:template>

<xsl:template match="de-term[@context='formula']" mode="compute">
    <xsl:param name="term" />
    <xsl:text>Compute("</xsl:text>
    <xsl:call-template name="webwork-mustache-names" >
        <xsl:with-param name="mustache-string" select="." />
    </xsl:call-template>
    <xsl:text>")</xsl:text>
</xsl:template>

<xsl:template match="de-term[@context='substitution']" mode="compute">
    <xsl:choose>
        <!-- User might have provided a pre-generated term's name -->
        <xsl:when test="./start/var/@name">
            <xsl:text>${</xsl:text>
            <xsl:value-of select="./start/var/@name" />
            <xsl:text>}</xsl:text>
        </xsl:when>
        <!-- or they might have provided a formula that needs to be generated first. -->
        <xsl:otherwise>
            <xsl:text>Compute("</xsl:text>
            <xsl:call-template name="webwork-mustache-names" >
                <xsl:with-param name="mustache-string" select="./start" />
            </xsl:call-template>
            <xsl:text>")</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <!-- With that object, apply the substitution -->
    <xsl:text>.substitute(</xsl:text>
    <xsl:value-of select="./match" />
    <xsl:text disable-output-escaping="yes"> =&gt; </xsl:text>
    <xsl:choose>
        <xsl:when test="./replace/var/@name">
            <xsl:text>${</xsl:text>
            <xsl:value-of select="./replace/var/@name" />
            <xsl:text>}</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>"</xsl:text>
            <xsl:call-template name="webwork-mustache-names" >
                <xsl:with-param name="mustache-string" select="./replace" />
            </xsl:call-template>
            <xsl:text>")</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>)</xsl:text>
</xsl:template>


<xsl:template match="exercise[@dynamic]//statement" mode="webwork">
    <xsl:call-template name="webwork-open-problem" mode="webwork" />
    <xsl:apply-templates select="*" />
    <xsl:call-template name="webwork-close-problem" mode="webwork" />
</xsl:template>

<xsl:template match="feedback/check" />

<xsl:template match="exercise[@dynamic]//feedback" mode="webwork">
    <xsl:variable name="responseTree" select="ancestor::exercise[@dynamic]//fillin"/>
    <xsl:variable name="numberAnswers" select="count($responseTree)"/>
    <xsl:variable name="multiAns">
        <xsl:call-template name="de-requires-multianswer" />
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="string-length($multiAns)">
            <xsl:call-template name="de-multiple-answers">
                <xsl:with-param name="responseTree" select="$responseTree"/>
            </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
            <xsl:call-template name="de-single-answers">
                <xsl:with-param name="responseTree" select="$responseTree"/>
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template name="de-requires-multianswer">
    <xsl:variable name="responseTree" select="ancestor::exercise[@dynamic]//fillin" />
    <xsl:if test="count($responseTree) > 1 and ancestor::exercise[@dynamic]//feedback[@answers-coupled='yes']">
        <xsl:text>1</xsl:text>
    </xsl:if>
</xsl:template>

<xsl:template name="de-multiple-answers">
    <xsl:param name="responseTree" />

    <xsl:variable name="partialAnswers" select="count(//check[@all]) = 0" />
    <xsl:text>$_mc_cmp = MultiAnswer(</xsl:text>
    <xsl:call-template name="de-correct-answers-comma">
        <xsl:with-param name="subtree" select="$responseTree" />
        <xsl:with-param name="namePrefix" select="'$'" />
    </xsl:call-template>
    <xsl:text>)-&gt;with(&#10;</xsl:text>
    <xsl:text>  checker =&gt; sub {&#10;</xsl:text>
    <xsl:text>    code&#10;</xsl:text>
    <xsl:text>  }&#10;</xsl:text>
    <xsl:text>);&#10;</xsl:text>
</xsl:template>

<xsl:template name="de-single-answers">
    <xsl:param name="responseTree" />

    <!-- Generate the correct answer checkers. -->
    <xsl:for-each select="$responseTree">
        <xsl:variable name="curFillIn" select="." />
        <xsl:variable name="check" select="ancestor::exercise[@dynamic]//feedback/check[@submit = $curFillIn/@submit]" />
        <xsl:text>$_</xsl:text>
        <xsl:value-of select="@correct" />
        <xsl:text>_cmp = ${</xsl:text>
        <xsl:value-of select="$curFillIn/@correct" />
        <xsl:text>}->cmp(</xsl:text>
        <!-- There is no special compare necessary unless one of the check values has @correct='yes' -->
        <xsl:if test="$check/test[@correct='yes']">
            <xsl:variable name="curTest" select="$check/test[@correct='yes']" />

            <!-- Create a checker function. Initialize a stack of flag variables to track results. -->
            <xsl:text>&#10;</xsl:text>
            <xsl:text>  checker => sub {&#10;</xsl:text>
            <xsl:text>    my ( $correct, $student, $ansHash ) = @_;&#10;</xsl:text>
            <xsl:text>    my @testResults = [ 1 ], $testDepth = 0;&#10;</xsl:text>
            <xsl:call-template name="checker-layer">
                <xsl:with-param name="rules" select="$curTest" />
                <xsl:with-param name="level" select="0" />
                <xsl:with-param name="logic" select="'and'" /> <!-- All tests at first layer must be true -->
            </xsl:call-template>
            <xsl:text>  }&#10;</xsl:text>
        </xsl:if>
        <xsl:text>)</xsl:text>
        <!-- This is where AnswerHints will go. -->
        <xsl:text>;&#10;</xsl:text>
    </xsl:for-each>
</xsl:template>

<xsl:template name="checker-layer" >
    <xsl:param name="rules" />
    <xsl:param name="level" select="0" />
    <xsl:param name="logic" select="'and'" />
    <xsl:for-each select="$rules">
        <xsl:variable name="curRule" select="." />
        <xsl:choose>
            <xsl:when test="name($curRule)='test'">
                <xsl:text>    $testResults[</xsl:text><xsl:value-of select="$level+1" />
                <xsl:text>] = (</xsl:text>
                <!-- A test can have an implied equal or an explicit equal -->
                <xsl:choose>
                    <!-- An equal element must have two expression children. -->
                    <xsl:when test="$curRule/equal">

                    </xsl:when>
                    <!-- An implied equal compares the submitted answer to the given expression. -->
                    <!-- #var means it was previously calculated. -->
                    <xsl:when test="$curRule/var">
                        <xsl:text>$</xsl:text>
                        <xsl:value-of select="$curRule/var/@name" />
                    </xsl:when>
                    <!-- #de-term means we calculate it now. -->
                    <xsl:when test="$curRule/de-term">
                        <xsl:apply-templates select="$curRule/de-term" mode="compute" />
                    </xsl:when>
                </xsl:choose>
                <xsl:text> == $student);&#10;</xsl:text>
            </xsl:when>
            <xsl:when test="name($curRule)='and'">
                
            </xsl:when>
            <xsl:when test="name($curRule)='or'">
                
            </xsl:when>
            <xsl:when test="name($curRule)='not'">
                
            </xsl:when>
        </xsl:choose>
        <xsl:choose>
            <xsl:when test="$logic = 'and'">
                <xsl:text>    $testResults[</xsl:text><xsl:value-of select="$level" />
                <xsl:text>] *= $testResults[</xsl:text><xsl:value-of select="$level+1" /><xsl:text>];&#10;</xsl:text>
            </xsl:when>
            <xsl:when test="$logic = 'or'">
                <xsl:text>    $testResults[</xsl:text><xsl:value-of select="$level" />
                <xsl:text>] += $testResults[</xsl:text><xsl:value-of select="$level+1" /><xsl:text>];&#10;</xsl:text>
            </xsl:when>
            <xsl:when test="$logic = 'not'">
                <xsl:text>    $testResults[</xsl:text><xsl:value-of select="$level" />
                <xsl:text>] = not($testResults[</xsl:text><xsl:value-of select="$level+1" /><xsl:text>]);&#10;</xsl:text>
            </xsl:when>
        </xsl:choose>
    </xsl:for-each>
</xsl:template>

<xsl:template name="de-correct-answers-comma">
    <xsl:param name="subtree" />
    <xsl:param name="namePrefix" />
    <xsl:variable name="length" select="count($subtree)"/>
    <xsl:for-each select="$subtree" >
        <xsl:variable name="answerBlank">
            <xsl:value-of select="$namePrefix"/>
        </xsl:variable>
        <xsl:text>$</xsl:text>
        <xsl:value-of select="./@correct"/>
        <xsl:if test="not(position() = $length)">
            <xsl:text>,</xsl:text>
        </xsl:if>
    </xsl:for-each>
</xsl:template>

<xsl:template match="var[@name]">
    <xsl:text>[$</xsl:text>
    <xsl:value-of select="@name" />
    <xsl:text>]</xsl:text>
</xsl:template>



<xsl:template match="hint" />

<xsl:template name="webwork-mustache-names">
    <!-- Want to replace all instances of {{name}} to ${name}. -->
    <!-- Will parse through the string recursively to find and make replacements -->
    <xsl:param name="mustache-string" />
    <xsl:choose>
        <xsl:when test="$mustache-string = ''" />
        <xsl:otherwise>
            <xsl:variable name="before-subst">
                <xsl:value-of select="substring-before($mustache-string, '{{')"/>
            </xsl:variable>
            <xsl:variable name="start-subst">
                <xsl:value-of select="substring-after($mustache-string, '{{')" />
            </xsl:variable>
            <xsl:choose>
                <!-- One possibility is that there are no more substitutions. -->
                <xsl:when test="$before-subst = '' and $start-subst = ''">
                    <xsl:value-of select="$mustache-string" />
                </xsl:when>
                <!-- Otherwise there was a substitution -->
                <xsl:otherwise>
                    <xsl:value-of select="$before-subst" />
                    <xsl:text>$</xsl:text>
                    <xsl:value-of select="substring-before($start-subst, '}}')" />
                    <xsl:text></xsl:text>
                    <xsl:call-template name="webwork-mustache-names">
                        <xsl:with-param name="mustache-string" select="substring-after($start-subst, '}}')"/>
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>
</xsl:stylesheet>