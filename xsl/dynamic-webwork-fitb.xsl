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


<!-- Enter the processing tree. -->
<xsl:template match="/">
    <xsl:apply-templates select="mathbook|pretext" mode="generic-warnings" />
    <xsl:apply-templates select="mathbook|pretext" mode="deprecation-warnings" />
    <xsl:apply-templates select="*//exercise[@exercise-interactive='fillin-dynamic']" mode="webwork"/>
</xsl:template>


<!-- Currently only designed to address #exercise elements with attribute @dynamic -->
<!-- Generate a separate .pg file for each such element. -->
<xsl:template match="exercise[@exercise-interactive='fillin-dynamic']" mode="webwork">
    <xsl:variable name="filename">
        <xsl:apply-templates select="." mode="long-name" />
    </xsl:variable>
    <exsl:document href="{$filename}.pg" method="text">
        <!-- Common setup: define document, load macros, etc. -->
        <xsl:call-template name="webwork-pg-header" />
        <!-- Randomization and creation of expressions. -->
        <xsl:apply-templates select="dynamic-setup/de-object" mode="webwork-setup" />
        <!-- Create the answer checkers and feedback (answer hints). -->
        <xsl:apply-templates select="dynamic-evaluation" mode="webwork" />
        <!-- Generate the content of the exercise. -->
        <xsl:apply-templates select="statement" mode="webwork" />
        <xsl:apply-templates select="hint" mode="webwork" />
        <xsl:apply-templates select="solution" mode="webwork" />
        <!-- Close the .pg file as needed -->
        <xsl:call-template name="webwork-pg-footer" />    
    </exsl:document>
</xsl:template>

<!-- Common setup: define document, load macros, etc. -->
<xsl:template name="webwork-pg-header">
    <xsl:text>DOCUMENT();&#xa;</xsl:text>
    <xsl:text>loadMacros(&#xa;</xsl:text>
    <xsl:text>  "PGstandard.pl",&#xa;</xsl:text>
    <xsl:text>  "PGML.pl",&#xa;</xsl:text>
    <xsl:text>  "MathObjects.pl",&#xa;</xsl:text>
    <xsl:text>  "PGcourse.pl",&#xa;</xsl:text>
    <xsl:text>  "parserNumberWithUnits.pl",&#xa;</xsl:text>
    <xsl:text>  "contextArbitraryString.pl",&#xa;</xsl:text>
    <xsl:text>  "parserMultiAnswer.pl",&#xa;</xsl:text>
    <xsl:text>  "parserPopUp.pl",&#xa;</xsl:text>
    <xsl:text>  "contextInequalities.pl",&#xa;</xsl:text>
    <xsl:text>  "PGgraphmacros.pl",&#xa;</xsl:text>
    <xsl:text>);&#xa;</xsl:text>
    <xsl:text>TEXT(beginproblem());&#xa;</xsl:text>
    <xsl:text>$showPartialCorrectAnswers = 1;&#xa;</xsl:text>
    <xsl:text>Context("Numeric");&#xa;</xsl:text>
</xsl:template>

<!-- Parse the statement using extract-pg.xsl inside the open/close calls. -->
<xsl:template match="exercise[@exercise-interactive='fillin-dynamic']//statement" mode="webwork">
    <xsl:text>################################################&#xa;</xsl:text>
    <xsl:text>BEGIN_PGML&#xa;</xsl:text>
    <xsl:apply-templates select="*" />
    <xsl:text>END_PGML&#xa;</xsl:text>
    <xsl:text>################################################&#xa;</xsl:text>
</xsl:template>

<!-- Parse the hint using extract-pg.xsl inside the open/close calls. -->
<xsl:template match="exercise[@exercise-interactive='fillin-dynamic']//hint" mode="webwork">
    <xsl:text>################################################&#xa;</xsl:text>
    <xsl:text>BEGIN_PGML_HINT&#xa;</xsl:text>
    <xsl:apply-templates select="*" />
    <xsl:text>END_PGML_HINT&#xa;</xsl:text>
    <xsl:text>################################################&#xa;</xsl:text>
</xsl:template>

<!-- Parse the solution using extract-pg.xsl inside the open/close calls. -->
<xsl:template match="exercise[@exercise-interactive='fillin-dynamic']//solution" mode="webwork">
    <xsl:text>################################################&#xa;</xsl:text>
    <xsl:text>BEGIN_PGML_SOLUTION&#xa;</xsl:text>
    <xsl:apply-templates select="*" />
    <xsl:text>END_PGML_SOLUTION&#xa;</xsl:text>
    <xsl:text>################################################&#xa;</xsl:text>
</xsl:template>

<!-- Close the .pg file as needed -->
<xsl:template name="webwork-pg-footer">
    <xsl:text>ENDDOCUMENT();&#xa;</xsl:text>
</xsl:template>



<!-- Parse the Math Objects that define the problem.               -->
<!-- Using @mode='evaluate' will implement the different contexts. -->
<xsl:template match="de-object" mode="webwork-setup">
    <xsl:text>$</xsl:text><xsl:value-of select="@name"/>
    <xsl:text> = </xsl:text>
    <xsl:apply-templates select="." mode="evaluate" />
    <xsl:text>;&#xa;</xsl:text>
</xsl:template>


<!-- Part of Setup: Define a pure number (constant/parameter)  -->
<!-- Multiple possible modes: value/formula, evaluate (from    -->
<!-- a formula at a point), and random                         -->
<xsl:template match="de-object[@context='number']" mode="evaluate">
    <xsl:choose>
        <xsl:when test="@mode='value'">
            <xsl:value-of select="." />
        </xsl:when>
        <xsl:when test="@mode='formula'">
            <xsl:text>Number("</xsl:text>
            <xsl:call-template name="webwork-mustache-names" >
                <xsl:with-param name="mustache-string" select="."/>
            </xsl:call-template>
            <xsl:text>")</xsl:text>
        </xsl:when>
        <xsl:when test="@mode='evaluate'">
            <xsl:apply-templates select="formula/*" mode="evaluate" />
            <xsl:text>->eval(</xsl:text>
                <xsl:apply-templates select="variable" mode="evaluation-binding" />
            <xsl:text>)</xsl:text>
        </xsl:when>
        <xsl:when test="@mode='random'">
            <xsl:apply-templates select="." mode="evaluate-random" />
        </xsl:when>
        <xsl:otherwise>
        </xsl:otherwise>
        <xsl:text>;&#xa;</xsl:text>
    </xsl:choose>
</xsl:template>

<!-- Part of Setup: Define expressions/formulas -->
<!-- Multiple possible modes: value/formula, evaluate (from    -->
<!-- a formula at a point), and random                         -->
<xsl:template match="de-object[@context='formula']" mode="evaluate">
    <xsl:choose>
        <xsl:when test="@mode='formula'">
            <xsl:text>Formula("</xsl:text>
            <xsl:call-template name="webwork-mustache-names" >
                <xsl:with-param name="mustache-string" select="."/>
            </xsl:call-template>
            <xsl:text>")</xsl:text>
        </xsl:when>
        <xsl:when test="@mode='substitution' or @mode='evaluate'">
            <xsl:apply-templates select="formula/*" mode="evaluate" />
            <xsl:text>->substitute(</xsl:text>
                <xsl:apply-templates select="variable" mode="evaluation-binding" />
            <xsl:text>)</xsl:text>
        </xsl:when>
        <xsl:when test="@mode='derivative'">
            <xsl:apply-templates select="formula/*" mode="evaluate" />
            <xsl:text>->D(</xsl:text>
                <xsl:apply-templates select="variable" mode="quote-list" />
            <xsl:text>)</xsl:text>
        </xsl:when>
        <xsl:otherwise>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>->reduce</xsl:text>
</xsl:template>

<!-- Used during composition and evaluation of a variable-->
<xsl:template match="variable" mode="evaluation-binding">
    <xsl:if test="position() > 1">
        <xsl:text>, </xsl:text>
    </xsl:if>
    <xsl:value-of select="@name" />
    <xsl:text>=></xsl:text>
    <xsl:choose>
        <xsl:when test="var or de-object">
            <xsl:apply-templates select="var|de-object" mode="evaluate"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="." />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Used in @mode='derivative' to specify variable of differentiation -->
<xsl:template match="variable" mode="quote-list">
    <xsl:if test="position() > 1">
        <xsl:text>, </xsl:text>
    </xsl:if>
    <xsl:text>"</xsl:text>
    <xsl:value-of select="@name" />
    <xsl:text>"</xsl:text>
</xsl:template>

<!-- var elements in expressions (evaluate) are replaced by their name -->
<!-- In WeBWorK we need to precede with dollar $, and to avoid name    -->
<!-- errors, we'll also bracket the name to have a clear ending.       -->
<xsl:template match="var" mode="evaluate">
    <xsl:text>${</xsl:text>
    <xsl:value-of select="@name"/>
    <xsl:text>}</xsl:text>
</xsl:template>


<!-- WeBWorK: Generate a random parameter. -->
<xsl:template match="de-object[@context='number' and @mode='random']" mode="evaluate-random">
    <xsl:choose>
        <!-- Support possible different distributions.                  -->
        <!-- ########################################################## -->
        <!-- Case 1: discrete uniform on arithmetic sequence of values  -->
        <!-- @min: lowest value                                         -->
        <!-- @max: highest value                                        -->
        <!-- @by: increment between values                              -->
        <!-- @nonzero = 'yes': exclude value of zero from possibilities -->
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
            <xsl:choose>
                <xsl:when test="options/@nonzero = 'yes'">
                    <xsl:text>non_zero_random</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>random(</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:text>(</xsl:text><xsl:value-of select="$rnd-min"/>
            <xsl:text>,</xsl:text><xsl:value-of select="$rnd-max"/>
            <xsl:text>,</xsl:text><xsl:value-of select="$rnd-by"/>
            <xsl:text>)</xsl:text>
        </xsl:when>
    </xsl:choose>
</xsl:template>

<!-- PGML answer input               -->
<!-- Example: [_____]{$ans}          -->
<xsl:template match="exercise[@exercise-interactive='fillin-dynamic']//fillin">
    <xsl:param name="b-human-readable" />
    <xsl:apply-templates select="." mode="field">
        <xsl:with-param name="b-human-readable" select="$b-human-readable" />
    </xsl:apply-templates>
    <xsl:apply-templates select="." mode="form-help"/>
</xsl:template>

<!-- MathObject answer blanks. Pass correct answer as well as size of answer blank. -->
<!-- Copied from extract.pg with variant for MathObjects like Matrix, Vector, ColumnVector      -->
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
            <xsl:text>{$_</xsl:text><xsl:value-of select="@correct" /><xsl:text>_cmp}</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>{</xsl:text><xsl:value-of select="$width"/><xsl:text>}</xsl:text>
</xsl:template>



<!-- Template for answer checking. Actual work done by specialized templates. -->
<xsl:template match="exercise[@exercise-interactive='fillin-dynamic']//dynamic-evaluation" mode="webwork">
    <xsl:variable name="responseTree" select="ancestor::exercise[@exercise-interactive='fillin-dynamic']//fillin"/>
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

<!-- utility template to test if a problem requires MultiAnswer -->
<xsl:template name="de-requires-multianswer">
    <xsl:variable name="responseTree" select="ancestor::exercise[@exercise-interactive='fillin-dynamic']//fillin" />
    <xsl:if test="count($responseTree) > 1 and ancestor::exercise[@exercise-interactive='fillin-dynamic']//evaluation[@answers-coupled='yes']">
        <xsl:text>1</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Template for simple answer checkers: no interaction between different fillins. -->
<!-- Add a post-filter to deal with additional feedback, similar to AnswerHints but allowing more complex logic. -->
<xsl:template name="de-single-answers">
    <xsl:param name="responseTree" />
    <!-- Generate the correct answer evaluateers, looping through the fillins. -->
    <xsl:for-each select="$responseTree">
        <xsl:variable name="curFillIn" select="." />
        <xsl:variable name="check" select="ancestor::exercise[@exercise-interactive='fillin-dynamic']//evaluation/evaluate[@submit = $curFillIn/@submit]" />
        <xsl:text>$_</xsl:text>
        <xsl:value-of select="@correct" />
        <xsl:text>_cmp = ${</xsl:text>
        <xsl:value-of select="$curFillIn/@correct" />
        <xsl:text>}->cmp(&#xa;</xsl:text>
        <xsl:text>  checker => sub {&#xa;</xsl:text>
        <xsl:text>    my ( $_correct, $_student, $_ansHash ) = @_;&#xa;</xsl:text>
        <xsl:choose>
            <!-- Custom checking if a test has @correct='yes' -->
            <xsl:when test="$check/test[@correct='yes']">
                <xsl:variable name="curTest" select="$check/test[@correct='yes']" />

                <!-- Create a checker function. Initialize a stack of flag variables to track results. -->
                <xsl:text>    my @_testResults;&#xa;</xsl:text>
                <xsl:choose>
                    <xsl:when test="count($curTest/*[name() != 'feedback']) = 1">
                        <xsl:call-template name="checker-simple">
                            <xsl:with-param name="curTest" select="$curTest/*" />
                            <xsl:with-param name="level" select="0" />
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="checker-layer">
                            <xsl:with-param name="tests" select="$curTest/*" />
                            <xsl:with-param name="level" select="0" />
                            <xsl:with-param name="logic" select="'and'" /> <!-- All tests at first layer must be true -->
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:text>    return $_testResults[0];&#xa;</xsl:text>
            </xsl:when>
            <!-- Otherwise just do a direct comparison with correct. -->
            <xsl:otherwise>
                <xsl:text>    return ($correct == $student ? 1 : 0);&#xa;</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:text>  }&#xa;</xsl:text>
        <xsl:text>)</xsl:text>
        <!-- Feedback in post filter (custom checker possibly not required). -->
        <xsl:if test="$check/test[not(@correct='yes')]">
            <xsl:variable name="feedback-tests" select="$check/test[not(@correct='yes')]" />
            <xsl:text>-&gt;withPostFilter( sub {&#xa;</xsl:text>
            <xsl:text>    my $_ansHash = shift;&#xa;</xsl:text>
            <xsl:text>    my $_correct = $_ansHash->{correct_value};&#xa;</xsl:text>
            <xsl:text>    my $_student = $_ansHash->{student_value};&#xa;</xsl:text>
            <xsl:text>    ## Advance through the tests for additional feedback. &#xa;</xsl:text>
            <xsl:for-each select="$feedback-tests">
                <xsl:text>    my @_testResults;&#xa;</xsl:text>
                <xsl:choose>
                    <xsl:when test="count(./*[name() != 'feedback']) = 1">
                        <xsl:call-template name="checker-simple">
                            <xsl:with-param name="curTest" select="./*" />
                            <xsl:with-param name="level" select="0" />
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="checker-layer">
                            <xsl:with-param name="tests" select="./*" />
                            <xsl:with-param name="level" select="0" />
                            <xsl:with-param name="logic" select="'and'" /> <!-- All tests at first layer must be true -->
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:text>    $_ansHash->{ans_message} = "</xsl:text>
                <xsl:apply-templates select="./feedback" />
                <xsl:text>" if ($_ansHash->{ans_message} == "" and $testResults[0]);&#xa;</xsl:text>
            </xsl:for-each>
            <xsl:text>    return $_ansHash;&#xa;</xsl:text>
            <xsl:text>  }&#xa;</xsl:text>
            <xsl:text>)</xsl:text>
        </xsl:if>
        <xsl:text>;&#xa;</xsl:text>
    </xsl:for-each>
</xsl:template>

<!-- Template for multiple answer checkers when evaluation requires coupling between answer blanks. -->
<!-- Feedback is part of the MultiAnswer checker. -->
<xsl:template name="de-multiple-answers">
    <xsl:param name="responseTree" />
    <xsl:variable name="checks" select="ancestor::exercise[@exercise-interactive='fillin-dynamic']//evaluation/evaluate" />
    <xsl:variable name="single-check" select="$checks[@all='yes']" />
    <xsl:text>$_mc_cmp = MultiAnswer(</xsl:text>
    <xsl:call-template name="de-correct-answers-comma">
        <xsl:with-param name="responses" select="$responseTree" />
    </xsl:call-template>
    <xsl:text>)-&gt;with(&#xa;</xsl:text>
    <xsl:choose>
        <xsl:when test="$single-check">
            <xsl:text>  singleResult =&gt; 1,&#xa;</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>  singleResult =&gt; 0,&#xa;</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>  checker =&gt; sub {&#xa;</xsl:text>
    <xsl:text>    my ( $_correct, $_student, $_ansHash ) = @_;&#xa;</xsl:text>
    <xsl:text>    my @_results, @_hasFeedback;&#xa;</xsl:text>
    <xsl:text>    ## Extract blanks based on names ##&#xa;</xsl:text>
    <xsl:for-each select="$responseTree">
        <xsl:text>    my $</xsl:text>
        <xsl:value-of select="@submit"/>
        <xsl:text> = @{$_student}[</xsl:text>
        <xsl:value-of select="position()-1"/>
        <xsl:text>];&#xa;</xsl:text>
    </xsl:for-each>
    <!-- Different pathway if *all* blanks scored at once vs each scored separately. -->
    <xsl:choose>
        <xsl:when test="$single-check">
            <xsl:variable name="single-correct-test" select="$single-check/test[@correct='yes']" />
            <xsl:text>    ## Single test for results. ##&#xa;</xsl:text>
            <xsl:text>    my @_testResults;&#xa;</xsl:text>
            <xsl:choose>
                <xsl:when test="count($single-correct-test/*[name() != 'feedback']) = 1">
                    <xsl:call-template name="checker-simple">
                        <xsl:with-param name="curTest" select="$single-correct-test/*" />
                        <xsl:with-param name="level" select="0" />
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="checker-layer">
                        <xsl:with-param name="tests" select="$single-correct-test/*" />
                        <xsl:with-param name="level" select="0" />
                        <xsl:with-param name="logic" select="'and'" /> <!-- All tests at first layer must be true -->
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:text>    $_results[0] = $_testResults[0];&#xa;</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:for-each select="$responseTree">
                <xsl:variable name="curFillIn" select="." />
                <xsl:variable name="curTest" select="$checks[@submit = $curFillIn/@submit]/test[@correct='yes']" />
                <xsl:text>    ## Checker for </xsl:text><xsl:value-of select="$curFillIn/@submit"/><xsl:text>##&#xa;</xsl:text>
                <xsl:text>    $_hasFeedback[</xsl:text><xsl:value-of select="position($curFillIn)"/><xsl:text>] = 0;&#xa;$</xsl:text>
                <xsl:choose>
                    <!-- There is no special compare necessary unless one of the check values has @correct='yes' -->
                    <xsl:when test="$curTest">
                        <xsl:text>    my @_testResults;&#xa;</xsl:text>
                        <xsl:choose>
                            <xsl:when test="count($curTest/*[name() != 'feedback']) = 1">
                                <xsl:call-template name="checker-simple">
                                    <xsl:with-param name="curTest" select="$curTest/*" />
                                    <xsl:with-param name="level" select="0" />
                                </xsl:call-template>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:call-template name="checker-layer">
                                    <xsl:with-param name="tests" select="$curTest/*" />
                                    <xsl:with-param name="level" select="0" />
                                    <xsl:with-param name="logic" select="'and'" /> <!-- All tests at first layer must be true -->
                                </xsl:call-template>
                            </xsl:otherwise>
                        </xsl:choose>
                        <xsl:text>    $_results[</xsl:text><xsl:value-of select="position($curFillIn)"/><xsl:text>] = $_testResults[0];&#xa;</xsl:text>
                    </xsl:when>
                    <!-- No test with @correct='yes' means simple comparison with given answer. -->
                    <xsl:otherwise>
                        <xsl:text>    $_results[</xsl:text>
                        <xsl:value-of select="position($curFillIn)"/>
                        <xsl:text>] = ($</xsl:text>
                        <xsl:value-of select="$curFillIn/@correct"/>
                        <xsl:text> == $</xsl:text>
                        <xsl:value-of select="$curFillIn/@submit"/>
                        <xsl:text>);&#xa;</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </xsl:otherwise>
    </xsl:choose>
    <!-- Now do the feedback. -->
    <xsl:for-each select="$responseTree">
        <xsl:variable name="curFillIndex" select="position()-1"/>
        <xsl:variable name="responseName" select="@submit"/>
        <xsl:variable name="feedbackTests" select="ancestor::exercise[@exercise-interactive='fillin-dynamic']//evaluation/evaluate[@submit = $responseName]/test[not(@correct='yes')]" />
        <xsl:for-each select="$feedbackTests">
            <xsl:text>    ## Feedback for </xsl:text><xsl:value-of select="$responseName"/><xsl:text> ##&#xa;</xsl:text>
            <xsl:text>    my @_testResults;&#xa;</xsl:text>
            <xsl:choose>
                <xsl:when test="count(./*[name() != 'feedback']) = 1">
                    <xsl:call-template name="checker-simple">
                        <xsl:with-param name="curTest" select="./*" />
                        <xsl:with-param name="level" select="0" />
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="checker-layer">
                        <xsl:with-param name="tests" select="./*" />
                        <xsl:with-param name="level" select="0" />
                        <xsl:with-param name="logic" select="'and'" /> <!-- All tests at first layer must be true -->
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:text>    if (not($_hasFeedback[</xsl:text><xsl:value-of select="$curFillIndex"/><xsl:text>]) and $testResults[0]) {&#xa;</xsl:text>
            <xsl:text>      $_hasFeedback[</xsl:text><xsl:value-of select="$curFillIndex"/><xsl:text>] = 1;&#xa;</xsl:text>
            <xsl:text>      $_ansHash->setMessage(</xsl:text><xsl:value-of select="$curFillIndex"/><xsl:text>, "</xsl:text><xsl:apply-templates select="./feedback" /><xsl:text>");&#xa;</xsl:text>
            <xsl:text>    }&#xa;</xsl:text>
        </xsl:for-each>
    </xsl:for-each>
    <xsl:text>    return [ @_results ];&#xa;</xsl:text>
    <xsl:text>  }&#xa;</xsl:text>
    <xsl:text>);&#xa;</xsl:text>
</xsl:template>

<!-- This template is called for a simple test (no compound logic). -->
<xsl:template name="checker-simple">
    <xsl:param name="curTest" />
    <xsl:param name="level" select="0" />
    <xsl:text>    $_testResults[</xsl:text>
    <xsl:value-of select="$level" />
    <xsl:text>] = (</xsl:text>
    <!-- A test can have an implied equal or an explicit equal -->
    <!-- At root level, the test might also have a feedback. Skip that. -->
    <xsl:variable name="actualTest" select="$curTest[name() != 'feedback']"/>
    <xsl:choose>
        <!-- An equal element must have two expression children. -->
        <xsl:when test="name($actualTest) = 'equal'">
            <xsl:apply-templates select="$actualTest/*[1]" mode="webwork" />
            <xsl:text> == </xsl:text>
            <xsl:apply-templates select="$actualTest/*[2]" mode="webwork" />
        </xsl:when>
        <!-- An implied equal compares the submitted answer to the given expression. -->
        <xsl:otherwise>   <!-- Must be expression: #var or #de-term -->
            <xsl:apply-templates select="$actualTest" mode="webwork" />
            <xsl:text> == $student</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>);&#xa;</xsl:text>
</xsl:template>

<!-- A test can also be composite involving a combination of logical tests -->
<!-- This template works through one layer, recursively dealing with deeper layers as needed -->
<xsl:template name="checker-layer" >
    <xsl:param name="tests" />                   <!-- The layer of tests (subtree) -->
    <xsl:param name="level" select="0" />        <!-- Level (or depth) of the layer -->
    <xsl:param name="logic" select="'and'" />    <!-- and = all must be true, or = at least one, not = negation -->
    <xsl:choose>
        <xsl:when test="$logic = 'and'">         <!-- Treat logic like multipication. A single false (0) makes product zero -->
            <xsl:text>    $_testResults[</xsl:text><xsl:value-of select="$level" /><xsl:text>] = 1;&#xa;</xsl:text>
        </xsl:when>
        <xsl:when test="$logic = 'or'">         <!-- Treat logic like addition. A single true makes sum positive -->
            <xsl:text>    $_testResults[</xsl:text><xsl:value-of select="$level" /><xsl:text>] = 0;&#xa;</xsl:text>
        </xsl:when>
    </xsl:choose>
    <xsl:for-each select="$tests">    <!-- Work through the layer of tests one at a time. -->
        <xsl:choose>
            <xsl:when test="name()='and'">
                <xsl:text>    $_testResults[</xsl:text><xsl:value-of select="$level+1" /><xsl:text>] = 1;&#xa;</xsl:text>
                <xsl:call-template name="checker-layer">
                    <xsl:with-param name="tests" select="./*" />
                    <xsl:with-param name="level" select="$level+1" />
                    <xsl:with-param name="logic" select="'and'" /> <!-- Default: All tests at first layer must be true -->
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="name()='or'">
                <xsl:text>    $_testResults[</xsl:text><xsl:value-of select="$level+1" /><xsl:text>] = 0;&#xa;</xsl:text>
                <xsl:call-template name="checker-layer">
                    <xsl:with-param name="tests" select="./*" />
                    <xsl:with-param name="level" select="$level+1" />
                    <xsl:with-param name="logic" select="'or'" /> <!-- Default: All tests at first layer must be true -->
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="name()='not'">
                <xsl:call-template name="checker-layer">
                    <xsl:with-param name="tests" select="./*" />
                    <xsl:with-param name="level" select="$level+1" />
                    <xsl:with-param name="logic" select="'not'" /> <!-- Default: All tests at first layer must be true -->
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="checker-simple">
                    <xsl:with-param name="curTest" select="." />
                    <xsl:with-param name="level" select="$level+1" />
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:for-each>
    <xsl:choose> <!-- Deal with the results of that recursive call to a deeper layer. -->
        <xsl:when test="$logic = 'and'">
            <xsl:text>    $_testResults[</xsl:text><xsl:value-of select="$level" />
            <xsl:text>] *= $_testResults[</xsl:text><xsl:value-of select="$level+1" /><xsl:text>];&#xa;</xsl:text>
        </xsl:when>
        <xsl:when test="$logic = 'or'">
            <xsl:text>    $_testResults[</xsl:text><xsl:value-of select="$level" />
            <xsl:text>] += $_testResults[</xsl:text><xsl:value-of select="$level+1" /><xsl:text>];&#xa;</xsl:text>
        </xsl:when>
        <xsl:when test="$logic = 'not'">
            <xsl:text>    $_testResults[</xsl:text><xsl:value-of select="$level" />
            <xsl:text>] = not($_testResults[</xsl:text><xsl:value-of select="$level+1" /><xsl:text>]);&#xa;</xsl:text>
        </xsl:when>
    </xsl:choose>
</xsl:template>


<!-- MultipleAnswer checker expects an array of correct solutions. -->
<!-- This create the comma-separated list that will be used. -->
<xsl:template name="de-correct-answers-comma">
    <xsl:param name="responses" />
    <xsl:variable name="length" select="count($responses)"/>
    <xsl:for-each select="$responses" >
        <xsl:text>$</xsl:text>
        <xsl:value-of select="./@correct"/>
        <xsl:if test="not(position() = $length)">
            <xsl:text>,</xsl:text>
        </xsl:if>
    </xsl:for-each>
</xsl:template>

<!-- PGML requires names escaped by brackets. -->
<xsl:template match="var[@name]">
    <xsl:text>[</xsl:text>
    <xsl:apply-templates select="." mode="webwork" />
    <xsl:text>]</xsl:text>
</xsl:template>


<!-- WeBWorK uses names prefixed by $ -->
<xsl:template match="var[@name]" mode="webwork">
    <xsl:text>$</xsl:text>
    <xsl:value-of select="@name" />
</xsl:template>


<!-- For non-PreTeXt contexts, e.g., during setup, create formulas using symbols with mustache replacement. -->
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