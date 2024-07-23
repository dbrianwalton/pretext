<?xml version='1.0'?>

<!--********************************************************************
Copyright 2014-2016 Robert A. Beezer

This file is part of PreTeXt.

PreTeXt is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 2 or version 3 of the
License (at your option).

PreTeXt is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with PreTeXt.  If not, see <http://www.gnu.org/licenses/>.
*********************************************************************-->

<!-- This stylesheet locates exercise elements that have  -->
<!-- dynamic content. Create a standalone page for each.  -->
<!DOCTYPE xsl:stylesheet [
    <!ENTITY % entities SYSTEM "entities.ent">
    %entities;
]>


<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:exsl="http://exslt.org/common"
    xmlns:str="http://exslt.org/strings"
    extension-element-prefixes="exsl str"
>


<!-- Get a "subtree" xml:id value   -->
<!-- Then walk the XML source tree  -->
<!-- applying specializations below -->
<xsl:import href="./pretext-common.xsl" />
<xsl:import href="./extract-pg.xsl" />
<xsl:import href="./extract-identity.xsl" />
<xsl:param name="format" value="webwork"/>

<xsl:variable name="b-dynamics-static-seed" select="false()"/>
<xsl:variable name="exercise-style" select="'dynamic'"/>

<xsl:output method="text" encoding="UTF-8"/>

<xsl:template match="eval">
    <xsl:text>[</xsl:text>
    <xsl:apply-templates select="." mode="ww-evaluate"/>
    <xsl:text>]</xsl:text>
</xsl:template>

<xsl:template match="exercise|&PROJECT-LIKE;|task[@exercise-interactive='fillin']" mode="extraction">
    <xsl:choose>
        <xsl:when test="setup[de-object and not(setupScript)]">
            <xsl:choose>
                <xsl:when test="$format='webwork'">
                    <xsl:apply-templates select="." mode="convert-to-webwork"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="." mode="visible-id" />
                    <xsl:text> not converted.&#xa;</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
    </xsl:choose>
</xsl:template>

<xsl:template match="exercise|&PROJECT-LIKE;|task[@exercise-interactive='fillin']" mode="convert-to-webwork">
    <!-- Lead off by listing the file that is being produced.    -->
    <!-- This will be used to know what files need to be copied. -->
    <xsl:variable name="filename">
        <xsl:apply-templates select="." mode="visible-id" />
        <xsl:text>.pg</xsl:text>
    </xsl:variable>
    <xsl:value-of select="$filename"/>
    <xsl:text>&#xa;</xsl:text>
    <!-- Now generate the actual file. -->
    <exsl:document href="{$filename}" method="text">
        <!-- Common setup: define document, load macros, etc. -->
        <xsl:call-template name="dynamic-webwork-pg-header" />
        <!-- Randomization and creation of expressions. -->
        <xsl:apply-templates select="setup" mode="dynamic-webwork-setup" />
        <!-- Create the answer checkers and feedback (answer hints). -->
        <xsl:apply-templates select="evaluation" mode="dynamic-webwork" />
        <!-- Generate the content of the exercise. -->
        <xsl:apply-templates select="statement" mode="dynamic-webwork" />
        <xsl:apply-templates select="hint" mode="dynamic-webwork" />
        <xsl:apply-templates select="solution" mode="dynamic-webwork" />
        <!-- Close the .pg file as needed -->
        <xsl:call-template name="dynamic-webwork-pg-footer" />
    </exsl:document>
</xsl:template>

<!-- Common setup: define document, load macros, etc. -->
<xsl:template name="dynamic-webwork-pg-header">
<xsl:text>DOCUMENT();&#xa;</xsl:text>
<xsl:text>loadMacros(&#xa;</xsl:text>
<xsl:text>  "PGstandard.pl",&#xa;</xsl:text>
<xsl:text>  "PGML.pl",&#xa;</xsl:text>
<xsl:text>  "MathObjects.pl",&#xa;</xsl:text>
<xsl:text>  "PGcourse.pl",&#xa;</xsl:text>
<xsl:text>  "parserNumberWithUnits.pl",&#xa;</xsl:text>
<xsl:text>  "parserMultiAnswer.pl",&#xa;</xsl:text>
<xsl:text>  "contextArbitraryString.pl",&#xa;</xsl:text>
<xsl:text>  "contextInequalities.pl",&#xa;</xsl:text>
<xsl:text>  "PGgraphmacros.pl",&#xa;</xsl:text>
<xsl:text>);&#xa;</xsl:text>
<xsl:text>TEXT(beginproblem());&#xa;</xsl:text>
<xsl:text>$showPartialCorrectAnswers = 1;&#xa;</xsl:text>
<xsl:text>Context("Numeric");&#xa;</xsl:text>
</xsl:template>

<!-- Parse the statement using extract-pg.xsl inside the open/close calls. -->
<xsl:template match="statement" mode="dynamic-webwork">
<xsl:text>################################################&#xa;</xsl:text>
<xsl:text>BEGIN_PGML&#xa;</xsl:text>
<xsl:apply-templates select="*" />
<xsl:text>END_PGML&#xa;</xsl:text>
<xsl:text>################################################&#xa;</xsl:text>
</xsl:template>

<!-- Parse the hint using extract-pg.xsl inside the open/close calls. -->
<xsl:template match="hint" mode="dynamic-webwork">
<xsl:text>################################################&#xa;</xsl:text>
<xsl:text>BEGIN_PGML_HINT&#xa;</xsl:text>
<xsl:apply-templates select="*" />
<xsl:text>END_PGML_HINT&#xa;</xsl:text>
<xsl:text>################################################&#xa;</xsl:text>
</xsl:template>

<!-- Parse the solution using extract-pg.xsl inside the open/close calls. -->
<xsl:template match="solution" mode="dynamic-webwork">
<xsl:text>################################################&#xa;</xsl:text>
<xsl:text>BEGIN_PGML_SOLUTION&#xa;</xsl:text>
<xsl:apply-templates select="*" />
<xsl:text>END_PGML_SOLUTION&#xa;</xsl:text>
<xsl:text>################################################&#xa;</xsl:text>
</xsl:template>

<!-- Close the .pg file as needed -->
<xsl:template name="dynamic-webwork-pg-footer">
<xsl:text>ENDDOCUMENT();&#xa;</xsl:text>
</xsl:template>


<!-- Part of Setup: Define a parameter -->
<!-- @random means the parameter is random -->
<!-- otherwise, defined by a constant or in terms of earlier parameters using mustache substitution -->
<xsl:template match="de-object" mode="dynamic-webwork-setup">
<xsl:text>$</xsl:text><xsl:value-of select="@name"/><xsl:text> = </xsl:text>
<xsl:apply-templates select="*" mode="ww-evaluate"/>
<xsl:text>;&#xa;</xsl:text>
</xsl:template>

<xsl:template match="de-number" mode="ww-evaluate">
    <xsl:text>Real("</xsl:text>
    <xsl:apply-templates select="."/>
    <xsl:text>")</xsl:text>
</xsl:template>

<xsl:template match="de-random" mode="ww-evaluate">
    <xsl:choose>
        <xsl:when test="@distribution='discrete' or @distribution='integer'">
            <xsl:variable name="rnd_function">
                <xsl:choose>
                    <xsl:when test="@nonzero='yes'">
                        <xsl:text>non_zero_random</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>random</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:variable name="by">
                <xsl:choose>
                    <xsl:when test="@by">
                        <xsl:value-of select="@by"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>1</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:value-of select="$rnd_function"/>
            <xsl:text>(</xsl:text>
            <xsl:value-of select="@min"/><xsl:text>,</xsl:text>
            <xsl:value-of select="@max"/><xsl:text>,</xsl:text>
            <xsl:value-of select="$by"/><xsl:text>)</xsl:text>
        </xsl:when>
        <xsl:when test="@distribution='sign'">
            <xsl:text>non_zero_random(-1,1)</xsl:text>
        </xsl:when>
        <xsl:when test="@distribution='uniform'">
            <xsl:value-of select="@min"/>
            <xsl:text>+rand(</xsl:text>
            <xsl:value-of select="@max"/>
            <xsl:text>-</xsl:text>
            <xsl:value-of select="@min"/>
            <xsl:text>)</xsl:text>
        </xsl:when>
    </xsl:choose>
</xsl:template>

<xsl:template match="de-evaluate" mode="ww-evaluate">
    <xsl:apply-templates select="formula/*" mode="ww-evaluate"/>
    <xsl:text>.evaluate({</xsl:text>
    <xsl:apply-templates select="variable" mode="ww-mappings"/>
    <xsl:text>})</xsl:text>
</xsl:template>

<xsl:template match="de-expression[@mode='formula']" mode="ww-evaluate">
    <xsl:text>Compute("</xsl:text>
    <xsl:apply-templates select="." mode="ww-parse"/>
    <xsl:text>")</xsl:text>
</xsl:template>

<xsl:template match="de-expression[@mode='substitution']" mode="ww-evaluate">
    <xsl:apply-templates select="formula/*" mode="ww-evaluate"/>
    <xsl:text>-&gt;substitute({</xsl:text>
    <xsl:apply-templates select="variable" mode="ww-mappings"/>
    <xsl:text>})</xsl:text>
</xsl:template>

<xsl:template match="de-expression[@mode='derivative']" mode="ww-evaluate">
    <xsl:apply-templates select="formula/*" mode="ww-evaluate"/>
    <xsl:text>-&gt;D('</xsl:text>
    <xsl:value-of select="variable/@name"/>
    <xsl:text>')</xsl:text>
</xsl:template>

<xsl:template match="variable" mode="ww-mappings">
    <xsl:if test="position()>1"><xsl:text>,</xsl:text></xsl:if>
    <xsl:value-of select="@name"/>
    <xsl:text> =&gt; </xsl:text>
    <xsl:choose>
        <xsl:when test="eval|de-number|de-evaluate|de-expression">
            <xsl:apply-templates select="*" mode="ww-evaluate"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="."/>
        </xsl:otherwise>
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

<!-- When new objects are created or evaluated, switch to more complicated multianswer -->
<!-- which enables ability for those evaluations to include other blanks' responses.   -->
<xsl:template match="evaluation" mode="de-requires-multianswer">
    <xsl:if test="evaluate[@all='yes' or .//eval or .//de-expression]">
        <xsl:text>yes</xsl:text>
    </xsl:if>
</xsl:template>

<xsl:template match="fillin" mode="de-requires-multianswer">
    <xsl:apply-templates select="ancestor::statement/../evaluation" mode="de-requires-multianswer"/>
</xsl:template>

<!-- MathObject answer blanks. Pass correct answer as well as size of answer blank. -->
<!-- Copied from extract.pg with variant for MathObjects like Matrix, Vector, ColumnVector      -->
<!-- where the shape of the MathObject guides the array of answer blanks -->
<xsl:template match="fillin" mode="field">
    <xsl:param name="b-human-readable" />
    <xsl:variable name="multiAns">
        <xsl:apply-templates select="." mode="de-requires-multianswer" />
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
            <xsl:text>{$_</xsl:text><xsl:value-of select="@ansobj" /><xsl:text>_cmp}</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>{</xsl:text><xsl:value-of select="$width"/><xsl:text>}</xsl:text>
</xsl:template>


<!-- Part of Setup: Define MathObject expressions/formulas -->
<xsl:template match="de-expression[@mode='formula']" mode="ww-evaluate">
<xsl:param name="term" />
<xsl:text>Compute("</xsl:text>
<xsl:call-template name="isolate-names">
    <xsl:with-param name="text" select="."/>
</xsl:call-template>
<xsl:call-template name="mustache-names-webwork" >
    <xsl:with-param name="mustache-string" select="." />
</xsl:call-template>
<xsl:text>")</xsl:text>
</xsl:template>


<!-- Reference a previously defined object -->
<xsl:template match="eval" mode="ww-evaluate">
    <xsl:text>$</xsl:text>
    <xsl:value-of select="@obj"/>
</xsl:template>


<xsl:template match="*" mode="ww-evaluate">
    <xsl:text>WARNING: Unmatched type in ww-evalute </xsl:text>
    <xsl:value-of select="name()"/>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- Template for answer checking. Actual work done by specialized templates. -->
<xsl:template match="evaluation" mode="dynamic-webwork">
    <xsl:variable name="responseTree" select="../statement//fillin"/>
    <xsl:variable name="numberAnswers" select="count($responseTree)"/>
    <xsl:variable name="multiAns">
        <xsl:apply-templates select="." mode="de-requires-multianswer" />
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

<!-- Template for simple answer checkers: no interaction between different fillins. -->
<!-- Add a post-filter to deal with additional feedback, similar to AnswerHints but allowing more complex logic. -->
<xsl:template name="de-single-answers">
    <xsl:param name="responseTree" />
    <!-- Generate the correct answer evaluateers, looping through the fillins. -->
    <xsl:for-each select="$responseTree">
        <xsl:variable name="curFillIn" select="." />
        <xsl:variable name="check" select="ancestor::statement/../evaluation/evaluate[@name = $curFillIn/@name]" />
        <xsl:text>$_</xsl:text>
        <xsl:value-of select="@ansobj" />
        <xsl:text>_cmp = ${</xsl:text>
        <xsl:value-of select="@ansobj" />
        <xsl:text>}->cmp(</xsl:text>
        <!-- There is no special compare necessary unless one of the check values has @correct='yes' -->
        <xsl:if test="$check/test[@correct='yes']">
            <xsl:variable name="curTest" select="$check/test[@correct='yes']" />

            <!-- Create a checker function. -->
             <!--Initialize a stack of flag variables to track results. -->
            <xsl:text>&#xa;</xsl:text>
            <xsl:text>  checker => sub {&#xa;</xsl:text>
            <xsl:text>    my ( $_correct, $_student, $_ansHash ) = @_;&#xa;</xsl:text>
            <xsl:text>    my @_testResults;&#xa;</xsl:text>
            <xsl:choose>
                <xsl:when test="count($curTest/*[name() != 'feedback']) = 1">
                    <xsl:call-template name="checker-simple">
                        <xsl:with-param name="response-fillin" select="$curFillIn"/>
                        <xsl:with-param name="response-name" select="@name"/>
                        <xsl:with-param name="curTest" select="$curTest/*" />
                        <xsl:with-param name="level" select="0" />
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="checker-layer">
                        <xsl:with-param name="response-fillin" select="$curFillIn"/>
                        <xsl:with-param name="response-name" select="@name"/>
                        <xsl:with-param name="tests" select="$curTest/*" />
                        <xsl:with-param name="level" select="0" />
                        <xsl:with-param name="logic" select="'and'" /> <!-- All tests at first layer must be true -->
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:text>    return $_testResults[0];&#xa;</xsl:text>
            <xsl:text>  }&#xa;</xsl:text>
        </xsl:if>
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
                            <xsl:with-param name="response-fillin" select="$curFillIn"/>
                            <xsl:with-param name="response-name" select="@name"/>
                            <xsl:with-param name="curTest" select="./*" />
                            <xsl:with-param name="level" select="0" />
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="checker-layer">
                            <xsl:with-param name="response-fillin" select="$curFillIn"/>
                            <xsl:with-param name="response-name" select="@name"/>
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

<!-- Template for multiple answer checkers when evaluation -->
<!-- might require coupling between answer blanks.         -->
<!-- Feedback is part of the MultiAnswer checker.          -->
<xsl:template name="de-multiple-answers">
    <xsl:param name="responseTree" />
    <xsl:variable name="checks" select="$responseTree[1]/ancestor::statement/../evaluation/evaluate" />
    <!-- May be one evaluate to determine correctness of all blanks -->
    <xsl:variable name="single-check" select="$checks[@all='yes']" />
    <xsl:text>$_mc_cmp = MultiAnswer(</xsl:text>
    <xsl:call-template name="de-correct-answers-comma">
        <xsl:with-param name="responses" select="$responseTree" />
    </xsl:call-template>
    <xsl:text>)-&gt;with(&#xa;</xsl:text>
    <!-- Specify whether there is a single true/false for all -->
    <!-- or an array of values, one for each blank checked    -->
    <xsl:choose>
        <xsl:when test="$single-check">
            <xsl:text>  singleResult =&gt; 1,&#xa;</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>  singleResult =&gt; 0,&#xa;</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>  allowBlankAnswers =&gt; 1,&#xa;</xsl:text>
    <xsl:text>  checker =&gt; sub {&#xa;</xsl:text>
    <xsl:text>    my ( $_correct, $_student, $_ansHash ) = @_;&#xa;</xsl:text>
    <xsl:text>    my @_results, @_hasFeedback;&#xa;</xsl:text>
    <xsl:text>    ## Extract blanks based on names ##&#xa;</xsl:text>
    <xsl:for-each select="$responseTree">
        <xsl:text>    my $</xsl:text>
        <xsl:choose>
            <xsl:when test="@name">
                <xsl:value-of select="@name"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>_blank_</xsl:text>
                <xsl:value-of select="position()"/>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:text> = @{$_student}[</xsl:text>
        <xsl:value-of select="position()-1"/>
        <xsl:text>];&#xa;</xsl:text>
    </xsl:for-each>
    <!-- Different pathway if *all* blanks scored at once vs each scored separately. -->
    <xsl:choose>
        <xsl:when test="$single-check">
            <xsl:variable name="single-correct-test" select="$single-check/test[@correct='yes']" />
            <xsl:variable name="actual-tests" select="$single-correct-test/*[name() != 'feedback']"/>
            <xsl:text>    ## Single test for results. ##&#xa;</xsl:text>
            <xsl:text>    my @_testResults;&#xa;</xsl:text>
            <xsl:choose>
                <xsl:when test="count($actual-tests) = 1">
                    <xsl:call-template name="checker-simple">
                        <xsl:with-param name="curTest" select="$actual-tests" />
                        <xsl:with-param name="level" select="0" />
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="checker-layer">
                        <xsl:with-param name="tests" select="$actual-tests" />
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
                <xsl:variable name="curFillInName">
                    <xsl:choose>
                        <xsl:when test="@name">
                            <xsl:value-of select="@name"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:text>_blank_</xsl:text>
                            <xsl:value-of select="position()"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="curTest" select="$checks[@name = $curFillInName]/test[@correct='yes']" />
                <xsl:text>    ## Checker for </xsl:text>
                <xsl:value-of select="$curFillInName"/>
                <xsl:text> ##&#xa;</xsl:text>
                <xsl:text>    $_hasFeedback[</xsl:text>
                <xsl:value-of select="position()-1"/>
                <xsl:text>] = 0;&#xa;</xsl:text>
                <xsl:choose>
                    <!-- There is no special compare necessary unless one of the check values has @correct='yes' -->
                    <xsl:when test="$curTest">
                        <xsl:text>    my @_testResults;&#xa;</xsl:text>
                        <xsl:choose>
                            <xsl:when test="count($curTest/*[name() != 'feedback']) = 1">
                                <xsl:call-template name="checker-simple">
                                    <xsl:with-param name="response-fillin" select="$curFillIn"/>
                                    <xsl:with-param name="response-name" select="$curFillInName"/>
                                    <xsl:with-param name="curTest" select="$curTest/*" />
                                    <xsl:with-param name="level" select="0" />
                                </xsl:call-template>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:call-template name="checker-layer">
                                    <xsl:with-param name="response-fillin" select="$curFillIn"/>
                                    <xsl:with-param name="response-name" select="$curFillInName"/>
                                    <xsl:with-param name="tests" select="$curTest/*" />
                                    <xsl:with-param name="level" select="0" />
                                    <xsl:with-param name="logic" select="'and'" /> <!-- All tests at first layer must be true -->
                                </xsl:call-template>
                            </xsl:otherwise>
                        </xsl:choose>
                        <xsl:text>    $_results[</xsl:text><xsl:value-of select="position()-1"/><xsl:text>] = $_testResults[0];&#xa;</xsl:text>
                    </xsl:when>
                    <!-- No test with @correct='yes' means simple comparison with given answer. -->
                    <xsl:otherwise>
                        <xsl:text>    $_results[</xsl:text>
                        <xsl:value-of select="position()-1"/>
                        <xsl:text>] = ($</xsl:text>
                        <xsl:value-of select="$curFillIn/@ansobj"/>
                        <xsl:text> == $</xsl:text>
                        <xsl:value-of select="$curFillInName"/>
                        <xsl:text>);&#xa;</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </xsl:otherwise>
    </xsl:choose>
    <!-- Now do the feedback. -->
    <xsl:for-each select="$responseTree">
        <xsl:variable name="curFillIn" select="." />
        <xsl:variable name="curFillIndex" select="position()-1"/>
        <xsl:variable name="responseName">
            <xsl:choose>
                <xsl:when test="@name">
                    <xsl:value-of select="@name"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>_blank_</xsl:text>
                    <xsl:value-of select="position()"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="feedback-by-name" select= "$checks[@name=$responseName]/test[not(@correct='yes')]"/>
        <xsl:variable name="feedbackTests" select="$feedback-by-name"/>
        <xsl:for-each select="$feedbackTests">
            <xsl:text>    ## Feedback for </xsl:text><xsl:value-of select="$responseName"/><xsl:text> ##&#xa;</xsl:text>
            <xsl:text>    my @_testResults;&#xa;</xsl:text>
            <xsl:choose>
                <xsl:when test="count(./*[name() != 'feedback']) = 1">
                    <xsl:call-template name="checker-simple">
                        <xsl:with-param name="response-fillin" select="$curFillIn"/>
                        <xsl:with-param name="response-name" select="$responseName"/>
                        <xsl:with-param name="curTest" select="./*" />
                        <xsl:with-param name="level" select="0" />
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="checker-layer">
                        <xsl:with-param name="response-fillin" select="$curFillIn"/>
                        <xsl:with-param name="response-name" select="$responseName"/>
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
    <xsl:param name="response-fillin" />
    <xsl:param name="response-name" />
    <xsl:param name="curTest" />
    <xsl:param name="level" select="0" />
    <xsl:text>    $_testResults[</xsl:text>
    <xsl:value-of select="$level" />
    <xsl:text>] = (</xsl:text>
    <!-- A test can have an implied equal or an explicit equal -->
    <!-- At root level, the test might also have a feedback. Skip that. -->
    <xsl:variable name="actualTest" select="$curTest[name() != 'feedback']"/>
    <xsl:choose>
        <!-- A mathcmp element might compare submission to answer object. -->
        <xsl:when test="name($actualTest) = 'mathcmp' and $actualTest/@use-answer='yes'">
            <xsl:text>${</xsl:text>
            <xsl:value-of select="$response-fillin/@ansobj" />
            <xsl:text>} == ${</xsl:text>
            <xsl:value-of select="$response-name" />
            <xsl:text>}</xsl:text>
        </xsl:when>
        <!-- A mathcmp element might compare submission to a named object. -->
        <xsl:when test="name($actualTest) = 'mathcmp' and $actualTest/@obj">
            <xsl:text>${</xsl:text>
            <xsl:value-of select="$actualTest/@obj" />
            <xsl:text>} == ${</xsl:text>
            <xsl:value-of select="$response-fillin/@name" />
            <xsl:text>}</xsl:text>
        </xsl:when>
        <!-- Otherwise, mathcmp element must have two expression children. -->
        <xsl:when test="name($actualTest) = 'mathcmp'">
            <xsl:apply-templates select="$actualTest/*[1]" mode="ww-evaluate" />
            <xsl:text> == </xsl:text>
            <xsl:apply-templates select="$actualTest/*[2]" mode="ww-evaluate" />
        </xsl:when>
        <!-- An implied equal compares the submitted answer to the given expression. -->
        <xsl:when test="$response-fillin">   <!-- Must be expression: #eval or #de-expression -->
            <xsl:apply-templates select="$actualTest" mode="ww-evaluate" />
            <xsl:text> == ${</xsl:text>
            <xsl:value-of select="$response-name" />
            <xsl:text>}</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>## ERROR: No response-fillin &#xa;</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>);&#xa;</xsl:text>
</xsl:template>

<!-- A test can also be composite involving a combination of logical tests -->
<!-- This template works through one layer, recursively dealing with deeper layers as needed -->
<xsl:template name="checker-layer" >
    <xsl:param name="response-fillin" />
    <xsl:param name="response-name" />
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
            <xsl:when test="name()='logic' and @op='and'">
                <xsl:text>    $_testResults[</xsl:text><xsl:value-of select="$level+1" /><xsl:text>] = 1;&#xa;</xsl:text>
                <xsl:call-template name="checker-layer">
                    <xsl:with-param name="response-fillin" select="$response-fillin"/>
                    <xsl:with-param name="response-name" select="$response-name"/>
                    <xsl:with-param name="tests" select="./*" />
                    <xsl:with-param name="level" select="$level+1" />
                    <xsl:with-param name="logic" select="'and'" /> <!-- Default: All tests at first layer must be true -->
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="name()='logic' and @op='or'">
                <xsl:text>    $_testResults[</xsl:text><xsl:value-of select="$level+1" /><xsl:text>] = 0;&#xa;</xsl:text>
                <xsl:call-template name="checker-layer">
                    <xsl:with-param name="response-fillin" select="$response-fillin"/>
                    <xsl:with-param name="response-name" select="$response-name"/>
                    <xsl:with-param name="tests" select="./*" />
                    <xsl:with-param name="level" select="$level+1" />
                    <xsl:with-param name="logic" select="'or'" /> <!-- Default: All tests at first layer must be true -->
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="name()='logic' and @op='not'">
                <xsl:call-template name="checker-layer">
                    <xsl:with-param name="response-fillin" select="$response-fillin"/>
                    <xsl:with-param name="response-name" select="$response-name"/>
                    <xsl:with-param name="tests" select="./*" />
                    <xsl:with-param name="level" select="$level+1" />
                    <xsl:with-param name="logic" select="'not'" /> <!-- Default: All tests at first layer must be true -->
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="checker-simple">
                    <xsl:with-param name="response-fillin" select="$response-fillin"/>
                    <xsl:with-param name="response-name" select="$response-name"/>
                    <xsl:with-param name="curTest" select="." />
                    <xsl:with-param name="level" select="$level+1" />
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
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
    </xsl:for-each>
</xsl:template>


<!-- MultipleAnswer checker expects an array of correct solutions. -->
<!-- This create the comma-separated list that will be used. -->
<xsl:template name="de-correct-answers-comma">
    <xsl:param name="responses" />
    <xsl:variable name="length" select="count($responses)"/>
    <xsl:for-each select="$responses" >
        <xsl:text>$</xsl:text>
        <xsl:value-of select="./@ansobj"/>
        <xsl:if test="not(position() = $length)">
            <xsl:text>,</xsl:text>
        </xsl:if>
    </xsl:for-each>
</xsl:template>

<xsl:template match="setup" mode="collect-object-names">
    <xsl:for-each select="de-object">
        <xsl:if test="position()=1">
            <xsl:text> </xsl:text>
        </xsl:if>
        <xsl:value-of select="@name"/>
    </xsl:for-each>
</xsl:template>

<xsl:template name="isolate-names">
    <xsl:param name="text"/>
    <xsl:param name="obj-names"/>
    <xsl:variable name="fixed-string"  
                  select="str:replace($text, '[ab]', '${a}')"/>
    <xsl:value-of select="$fixed-string"/>
</xsl:template>

<!-- For non-PreTeXt contexts, e.g., during setup, create formulas using symbols with mustache replacement. -->
<xsl:template name="mustache-names-webwork">
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
                    <xsl:call-template name="mustache-names-webwork">
                        <xsl:with-param name="mustache-string" select="substring-after($start-subst, '}}')"/>
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

</xsl:stylesheet>