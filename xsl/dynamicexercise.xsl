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
    <xsl:apply-templates select="*//exercise[@dynamic]" mode="webwork"/>
</xsl:template>


<!-- Currently only designed to address #exercise elements with attribute @dynamic -->
<!-- Generate a separate .pg file for each such element. -->
<xsl:template match="exercise[@dynamic]" mode="webwork">
    <xsl:variable name="filename">
        <xsl:apply-templates select="." mode="visible-id" />
    </xsl:variable>
    <exsl:document href="{$filename}.pg" method="text">
        <!-- Common setup: define document, load macros, etc. -->
        <xsl:call-template name="webwork-pg-header" />
        <!-- Randomization and creation of expressions. -->
        <xsl:apply-templates select="setup" mode="webwork-setup" />
        <!-- Create the answer checkers and feedback (answer hints). -->
        <xsl:apply-templates select="evaluation" mode="webwork" />
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

<!-- Parse the statement using extract-pg.xsl inside the open/close calls. -->
<xsl:template match="exercise[@dynamic]//statement" mode="webwork">
    <xsl:text>################################################&#10;</xsl:text>
    <xsl:text>BEGIN_PGML&#10;</xsl:text>
    <xsl:apply-templates select="*" />
    <xsl:text>END_PGML&#10;</xsl:text>
    <xsl:text>################################################&#10;</xsl:text>
</xsl:template>

<!-- Parse the hint using extract-pg.xsl inside the open/close calls. -->
<xsl:template match="exercise[@dynamic]//hint" mode="webwork">
    <xsl:text>################################################&#10;</xsl:text>
    <xsl:text>BEGIN_PGML_HINT&#10;</xsl:text>
    <xsl:apply-templates select="*" />
    <xsl:text>END_PGML_HINT&#10;</xsl:text>
    <xsl:text>################################################&#10;</xsl:text>
</xsl:template>

<!-- Parse the solution using extract-pg.xsl inside the open/close calls. -->
<xsl:template match="exercise[@dynamic]//solution" mode="webwork">
    <xsl:text>################################################&#10;</xsl:text>
    <xsl:text>BEGIN_PGML_SOLUTION&#10;</xsl:text>
    <xsl:apply-templates select="*" />
    <xsl:template name="webwork-close-solution">
    <xsl:text>END_PGML_SOLUTION&#10;</xsl:text>
    <xsl:text>################################################&#10;</xsl:text>
</xsl:template>

<!-- Close the .pg file as needed -->
<xsl:template name="webwork-pg-footer">
    <xsl:text>ENDDOCUMENT();&#10;</xsl:text>
</xsl:template>



<!-- Part of Setup: Define a parameter -->
<!-- @random means the parameter is random -->
<!-- otherwise, defined by a constant or in terms of earlier parameters using mustache substitution -->
<xsl:template match="de-parameter" mode="webwork-setup">
    <xsl:text>$</xsl:text><xsl:value-of select="@name"/><xsl:text> = </xsl:text>
    <xsl:choose>
        <xsl:when test="@random='uniform'">
            <xsl:call-template name="random-parameter" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:call-template name="webwork-mustache-names" >
                <xsl:with-param name="mustache-string" select="."/>
            </xsl:call-template>
        </xsl:otherwise>
        <xsl:text>;&#10;</xsl:text>
    </xsl:choose>
</xsl:template>

<!-- WeBWorK: Generate a random parameter. -->
<!-- @min: lowest value -->
<!-- @max: highest value -->
<!-- @by: increment between values -->
<!-- @nonzero = 'yes': exclude value of zero from possibilities -->
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
    <xsl:text>(</xsl:text><xsl:value-of select="$param-rnd-min"/>
        <xsl:text>,</xsl:text><xsl:value-of select="$param-rnd-max"/>
        <xsl:text>,</xsl:text><xsl:value-of select="$param-rnd-by"/>
    <xsl:text>);&#10;</xsl:text>
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


<!-- Part of Setup: Define MathObject expressions/formulas -->
<xsl:template match="de-term[@context='formula']" mode="webwork-setup">
    <xsl:text>$</xsl:text><xsl:value-of select="@name"/>
    <xsl:text> = </xsl:text>
    <!-- Actual call to Compute is in separate template for general calls. -->
    <xsl:apply-templates select="." mode="webwork" />
    <xsl:text>->reduce;&#10;</xsl:text>
</xsl:template>

<!-- General creation of formula object in WeBWorK. -->
<xsl:template match="de-term[@context='formula']" mode="webwork">
    <xsl:param name="term" />
    <xsl:text>Compute("</xsl:text>
    <xsl:call-template name="webwork-mustache-names" >
        <xsl:with-param name="mustache-string" select="." />
    </xsl:call-template>
    <xsl:text>")</xsl:text>
</xsl:template>


<!-- Part of Setup: Define MathObject expressions/formulas using substitution. -->
<xsl:template match="de-term[@context='substitution']" mode="webwork-setup">
    <!-- New name of the generated term -->
    <xsl:text>$</xsl:text>
    <xsl:value-of select="@name"/>
    <xsl:text> = </xsl:text>
    <xsl:apply-templates select="." mode="webwork" />
    <xsl:text>->reduce;&#10;</xsl:text>
</xsl:template>

<!-- General creation of formula object using substitution. -->
<xsl:template match="de-term[@context='substitution']" mode="webwork">
    <xsl:choose>
        <!-- User might have provided a pre-generated term's name -->
        <xsl:when test="./start/var/@name">
            <xsl:text>$</xsl:text>
            <xsl:value-of select="./start/var/@name" />
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
    <xsl:text>-&gt;substitute(</xsl:text>
    <xsl:value-of select="./match" />
    <xsl:text disable-output-escaping="yes"> =&gt; </xsl:text>
    <xsl:choose>
        <xsl:when test="./replace/var/@name">
            <xsl:text>$</xsl:text>
            <xsl:value-of select="./replace/var/@name" />
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

<!-- Template for answer checking. Actual work done by specialized templates. -->
<xsl:template match="exercise[@dynamic]//evaluation" mode="webwork">
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

<!-- utility template to test if a problem requires MultiAnswer -->
<xsl:template name="de-requires-multianswer">
    <xsl:variable name="responseTree" select="ancestor::exercise[@dynamic]//fillin" />
    <xsl:if test="count($responseTree) > 1 and ancestor::exercise[@dynamic]//evaluation[@answers-coupled='yes']">
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
        <xsl:variable name="check" select="ancestor::exercise[@dynamic]//evaluation/evaluate[@submit = $curFillIn/@submit]" />
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
            <xsl:text>    my ( $_correct, $_student, $_ansHash ) = @_;&#10;</xsl:text>
            <xsl:text>    my @_testResults;&#10;</xsl:text>
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
            <xsl:text>    return $_testResults[0];&#10;</xsl:text>
            <xsl:text>  }&#10;</xsl:text>
        </xsl:if>
        <xsl:text>)</xsl:text>
        <!-- Feedback in post filter (custom checker possibly not required). -->
        <xsl:if test="$check/test[not(@correct='yes')]">
            <xsl:variable name="feedback-tests" select="$check/test[not(@correct='yes')]" />
            <xsl:text>-&gt;withPostFilter( sub {&#10;</xsl:text>
            <xsl:text>    my $_ansHash = shift;&#10;</xsl:text>
            <xsl:text>    my $_correct = $_ansHash->{correct_value};&#10;</xsl:text>
            <xsl:text>    my $_student = $_ansHash->{student_value};&#10;</xsl:text>
            <xsl:text>    ## Advance through the tests for additional feedback. &#10;</xsl:text>
            <xsl:for-each select="$feedback-tests">
                <xsl:text>    my @_testResults;&#10;</xsl:text>
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
                <xsl:text>" if ($_ansHash->{ans_message} == "" and $testResults[0]);&#10;</xsl:text>
            </xsl:for-each>
            <xsl:text>    return $_ansHash;&#10;</xsl:text>
            <xsl:text>  }&#10;</xsl:text>
            <xsl:text>)</xsl:text>
        </xsl:if>
        <xsl:text>;&#10;</xsl:text>
    </xsl:for-each>
</xsl:template>

<!-- Template for multiple answer checkers when evaluation requires coupling between answer blanks. -->
<!-- Feedback is part of the MultiAnswer checker. -->
<xsl:template name="de-multiple-answers">
    <xsl:param name="responseTree" />
    <xsl:variable name="checks" select="ancestor::exercise[@dynamic]//evaluation/evaluate" />
    <xsl:variable name="single-check" select="$checks[@all='yes']" />
    <xsl:text>$_mc_cmp = MultiAnswer(</xsl:text>
    <xsl:call-template name="de-correct-answers-comma">
        <xsl:with-param name="responses" select="$responseTree" />
    </xsl:call-template>
    <xsl:text>)-&gt;with(&#10;</xsl:text>
    <xsl:choose>
        <xsl:when test="$single-check">
            <xsl:text>  singleResult =&gt; 1,&#10;</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>  singleResult =&gt; 0,&#10;</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>  checker =&gt; sub {&#10;</xsl:text>
    <xsl:text>    my ( $_correct, $_student, $_ansHash ) = @_;&#10;</xsl:text>
    <xsl:text>    my @_results, @_hasFeedback;&#10;</xsl:text>
    <xsl:text>    ## Extract blanks based on names ##&#10;</xsl:text>
    <xsl:for-each select="$responseTree">
        <xsl:text>    my $</xsl:text>
        <xsl:value-of select="@submit"/>
        <xsl:text> = @{$_student}[</xsl:text>
        <xsl:value-of select="position()-1"/>
        <xsl:text>];&#10;</xsl:text>
    </xsl:for-each>
    <!-- Different pathway if *all* blanks scored at once vs each scored separately. -->
    <xsl:choose>
        <xsl:when test="$single-check">
            <xsl:variable name="single-correct-test" select="$single-check/test[@correct='yes']" />
            <xsl:text>    ## Single test for results. ##&#10;</xsl:text>
            <xsl:text>    my @_testResults;&#10;</xsl:text>
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
            <xsl:text>    $_results[0] = $_testResults[0];&#10;</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:for-each select="$responseTree">
                <xsl:variable name="curFillIn" select="." />
                <xsl:variable name="curTest" select="$checks[@submit = $curFillIn/@submit]/test[@correct='yes']" />
                <xsl:text>    ## Checker for </xsl:text><xsl:value-of select="$curFillIn/@submit"/><xsl:text>##&#10;</xsl:text>
                <xsl:text>    $_hasFeedback[</xsl:text><xsl:value-of select="position($curFillIn)"/><xsl:text>] = 0;&#10;$</xsl:text>
                <xsl:choose>
                    <!-- There is no special compare necessary unless one of the check values has @correct='yes' -->
                    <xsl:when test="$curTest">
                        <xsl:text>    my @_testResults;&#10;</xsl:text>
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
                        <xsl:text>    $_results[</xsl:text><xsl:value-of select="position($curFillIn)"/><xsl:text>] = $_testResults[0];&#10;</xsl:text>
                    </xsl:when>
                    <!-- No test with @correct='yes' means simple comparison with given answer. -->
                    <xsl:otherwise>
                        <xsl:text>    $_results[</xsl:text>
                        <xsl:value-of select="position($curFillIn)"/>
                        <xsl:text>] = ($</xsl:text>
                        <xsl:value-of select="$curFillIn/@correct"/>
                        <xsl:text> == $</xsl:text>
                        <xsl:value-of select="$curFillIn/@submit"/>
                        <xsl:text>);&#10;</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </xsl:otherwise>
    </xsl:choose>
    <!-- Now do the feedback. -->
    <xsl:for-each select="$responseTree">
        <xsl:variable name="curFillIndex" select="position()-1"/>
        <xsl:variable name="responseName" select="@submit"/>
        <xsl:variable name="feedbackTests" select="ancestor::exercise[@dynamic]//evaluation/evaluate[@submit = $responseName]/test[not(@correct='yes')]" />
        <xsl:for-each select="$feedbackTests">
            <xsl:text>    ## Feedback for </xsl:text><xsl:value-of select="$responseName"/><xsl:text> ##&#10;</xsl:text>
            <xsl:text>    my @_testResults;&#10;</xsl:text>
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
            <xsl:text>    if (not($_hasFeedback[</xsl:text><xsl:value-of select="$curFillIndex"/><xsl:text>]) and $testResults[0]) {&#10;</xsl:text>
            <xsl:text>      $_hasFeedback[</xsl:text><xsl:value-of select="$curFillIndex"/><xsl:text>] = 1;&#10;</xsl:text>
            <xsl:text>      $_ansHash->setMessage(</xsl:text><xsl:value-of select="$curFillIndex"/><xsl:text>, "</xsl:text><xsl:apply-templates select="./feedback" /><xsl:text>");&#10;</xsl:text>
            <xsl:text>    }&#10;</xsl:text>
        </xsl:for-each>
    </xsl:for-each>
    <xsl:text>    return [ @_results ];&#10;</xsl:text>
    <xsl:text>  }&#10;</xsl:text>
    <xsl:text>);&#10;</xsl:text>
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
    <xsl:text>);&#10;</xsl:text>
</xsl:template>

<!-- A test can also be composite involving a combination of logical tests -->
<!-- This template works through one layer, recursively dealing with deeper layers as needed -->
<xsl:template name="checker-layer" >
    <xsl:param name="tests" />                   <!-- The layer of tests (subtree) -->
    <xsl:param name="level" select="0" />        <!-- Level (or depth) of the layer -->
    <xsl:param name="logic" select="'and'" />    <!-- and = all must be true, or = at least one, not = negation -->
    <xsl:choose>
        <xsl:when test="$logic = 'and'">         <!-- Treat logic like multipication. A single false (0) makes product zero -->
            <xsl:text>    $_testResults[</xsl:text><xsl:value-of select="$level" /><xsl:text>] = 1;&#10;</xsl:text>
        </xsl:when>
        <xsl:when test="$logic = 'or'">         <!-- Treat logic like addition. A single true makes sum positive -->
            <xsl:text>    $_testResults[</xsl:text><xsl:value-of select="$level" /><xsl:text>] = 0;&#10;</xsl:text>
        </xsl:when>
    </xsl:choose>
    <xsl:for-each select="$tests">    <!-- Work through the layer of tests one at a time. -->
        <xsl:choose>
            <xsl:when test="name()='and'">
                <xsl:text>    $_testResults[</xsl:text><xsl:value-of select="$level+1" /><xsl:text>] = 1;&#10;</xsl:text>
                <xsl:call-template name="checker-layer">
                    <xsl:with-param name="tests" select="./*" />
                    <xsl:with-param name="level" select="$level+1" />
                    <xsl:with-param name="logic" select="'and'" /> <!-- Default: All tests at first layer must be true -->
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="name()='or'">
                <xsl:text>    $_testResults[</xsl:text><xsl:value-of select="$level+1" /><xsl:text>] = 0;&#10;</xsl:text>
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
            <xsl:text>] *= $_testResults[</xsl:text><xsl:value-of select="$level+1" /><xsl:text>];&#10;</xsl:text>
        </xsl:when>
        <xsl:when test="$logic = 'or'">
            <xsl:text>    $_testResults[</xsl:text><xsl:value-of select="$level" />
            <xsl:text>] += $_testResults[</xsl:text><xsl:value-of select="$level+1" /><xsl:text>];&#10;</xsl:text>
        </xsl:when>
        <xsl:when test="$logic = 'not'">
            <xsl:text>    $_testResults[</xsl:text><xsl:value-of select="$level" />
            <xsl:text>] = not($_testResults[</xsl:text><xsl:value-of select="$level+1" /><xsl:text>]);&#10;</xsl:text>
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