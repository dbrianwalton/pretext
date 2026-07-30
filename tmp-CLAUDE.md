# FITB review-remediation work (`fitb-extensions-work` → reconciled onto `fitb-extension-work`) — handoff notes

Separate task from everything below this section, which is about the blank-ordering work.
This section is about PR #3054's review remediation (JS library imports, `config-json`, custom
`@parser`) — originally developed on `fitb-extensions-work` (plural), now reconciled onto and
committed to `fitb-extension-work` (singular, this branch), per explicit instruction this
session: "I need these reconciled... ALL reflected in *my* branch `fitb-extension-work`."

**Status: applied and committed. Next step (not started): consolidate the 8 new commits below
into the branch's pre-existing 8 "extensions" commits via interactive rebase, and clean up
subjects.**

## What happened, in order

1. **Diagnosis.** `fitb-extensions-work` branches from `d03bcc2d` — `fitb-extension-work`'s tip
   on 2026-07-29, before both the blank-ordering work (§1–15 below, dated 7/30) and the
   2026-07-31 rebase onto `upstream/master`. All 8 of `fitb-extensions-work`'s own commits
   already exist, rebased, inside `fitb-extension-work` (mapping table below) — nothing was
   lost, but `fitb-extensions-work` itself is stale relative to where the real work lives.

2. **Patch reconciliation.** `fitb-extensions-work-review-fixes.patch` (13 files, 341+/195-)
   was applied to `fitb-extension-work`'s working tree, not to `fitb-extensions-work`. 10 of 13
   files applied cleanly with `git apply`. 3 conflicted because the blank-ordering/rebase work
   had already touched the same regions — `xsl/pretext-runestone-fitb.xsl`,
   `xsl/extract-dynamic.xsl`, `script/dynsub/dynamic_extract.mjs` — and were reconciled by hand:
   in each, the patch's `@visible-id`→`@unique-id` hunks were already satisfied by the rebase's
   visible-id sweep, and only the unrelated parts (jslibrary-template indentation,
   `quote-string`→`escape-quote-string` renames, the `.mjs`'s `realpathSync`/`SCHEME`/timeout
   fixes) still needed applying.

3. **`topics.xml` correction.** The patch's own rewording of the `fillin` `@mode`/`@parser`
   paragraph (line 2445) was itself imprecise. Verified against the actual XSL: `@parser` only
   supersedes `@mode` for building the `v.types` parser array (`setup-parsers` mode in
   `pretext-runestone-fitb.xsl`). `@mode` is independently load-bearing elsewhere — the HTML
   `<input>` type, whether an `@ansobj` answer's automatic solution is typeset as math, and
   (absent an explicit `test`) the default comparison synthesized for `@ansobj`/`@answer`
   answers — with a `PTX:ERROR`/`PTX:WARNING` in `pretext-runestone-fitb.xsl` /
   `pretext-assembly.xsl` if `@mode` is missing, regardless of `@parser`. Corrected, then the
   user simplified the wording further by hand.

4. **Two maintainer-review-style questions raised and resolved, no further changes needed:**
   - `common.py`'s new `log_relayed_message` — confirmed it is *not* only used by the new
     `dynamic_substitutions()` code; `xsltproc()`'s own pre-existing severity-token loop was
     refactored to call it too (replacing its inline duplicate), which is exactly what the
     maintainer's "re-implements machinery already in common.py" comment was asking for. No
     other subprocess call site in `pretext.py` (sage, latex-image, css builder, ...) relays
     `PTX:TOKEN` messages, so there's no other established pattern being missed.
   - `pretext.py`'s hard-coded `"external/"` prefix — confirmed consistent with existing
     convention; `"external"` is a bare string literal throughout `common.py`/`pretext.py`
     already, no constant exists anywhere in the codebase for it.

5. **Committed and pushed** — branch even with `origin/fitb-extension-work` as of this session.
   8 new commits, newest last:

   ```
   aaf32adb  Guide: Updating the guide
   e3a8304c  Example: Sample article minor change to fix ordering and white spacing.
   3a8737ee  Dynamic substitutions for sample-article white space cleanup
   b719c45a  Schema: Fix schema and comments relating to @url vs @source
   7d906a1c  Changes associated with extracting substitutions
   b9f35101  Fix on text utilties
   950fbc4b  FITB: parsing fitb clean-up of spacing
   fed7bc82  Claude: personal only.
   ```

## Next step: consolidate via interactive rebase — NOT STARTED

Fold the 7 content commits above into the pre-existing "extensions" commits that originally
introduced each piece, then clean up subjects. Mapping (current hashes, post blank-ordering-rebase):

| New commit | Folds into |
|---|---|
| `950fbc4b` FITB: parsing fitb clean-up of spacing | `d3665213` FITB: Allow inclusion of libraries and config data... |
| `aaf32adb` Guide: Updating the guide | `43cdc0a0` GUIDE: Add explanation for authoring FITB... |
| `b719c45a` Schema: Fix schema and comments relating to @url vs @source | `864b89f7` FITB: Update schema to include js-imports and custom parsers |
| `7d906a1c` Changes associated with extracting substitutions | `85c38de0` FITB: Dynamic substitution process updated (v1)... |
| `e3a8304c` Example: Sample article minor change... | `cdb9e6f7` FITB: sample-article addition of example fitb exercise... |
| `3a8737ee` Dynamic substitutions for sample-article white space cleanup | `096e8cdd` Update dynamic substitutions for sample article and sample book... |
| `b9f35101` Fix on text utilties | `92650151` Improve escape-json-string template... |
| `fed7bc82` Claude: personal only. | **nowhere** — working-notes only (commit-plan.md, the .patch, design doc, tmp-CLAUDE.md); stays a standalone trailing commit per branch hygiene, never folds into a PR-bound commit |

`70f3e9e4` (the original `visible-id`→`unique-id` commit) gets nothing folded into it —
everything the patch wanted there was already satisfied by the blank-ordering rebase's
visible-id sweep.

After the fixups: rename the 7 target commits' subjects per `doc/guide/developer/git.xml`
(capitalize only the first letter, no trailing period, real-acronym prefixes in caps —
`FITB`/`XSL`, not `SCHEMA`/`GUIDE` spelled in full caps), and append `(PR #3054)` to each once
finalized. `fitb-extensions-work-commit-plan.md`'s rename-suggestion table was drafted against
the *original* pre-reconciliation 8-commit sequence — re-derive it against the actual final
content rather than reusing verbatim.

**Not decided yet:** `git commit --fixup=<target>` + `git rebase -i --autosquash` (fast, review
the result before pushing) vs. walking the `git rebase -i` todo list interactively
commit-by-commit — the user was asked and hadn't chosen when this session ended. Branch is
currently even with `origin/fitb-extension-work`, so either approach ends in a force-push.

**Open question, not raised with the user yet:** does PR #3054 (backed by `fitb-extensions` /
`fitb-extensions-work` on GitHub) still need this fix delivered there separately, now that the
authoritative copy lives on `fitb-extension-work`? Or does the PR's source branch change? Don't
assume either way — ask.

**Still outstanding, unrelated to the above:** the stale nested worktree from an earlier
session — `git worktree list` still shows `.worktrees/fitb-extensions-work` pointing at
`/sessions/elegant-eloquent-thompson/mnt/pretext/...`, a path from a since-gone sandbox. Clean
up with `git worktree remove --force .worktrees/fitb-extensions-work` (or `rm -rf .worktrees`
then `git worktree prune`).

---

# FITB blank-ordering work — handoff notes

Branch: `fitb-extension-work`, rebased onto `upstream/master` (2026-07-31) and force-pushed.

**Working tree is clean.** Everything described below is committed.

**Next up:** maintainer feedback on the PR is coming in the next session — a list of additional
issues, some already fixed independently. Read the rebase section below first; it's the current
state of the branch that feedback will be layered onto.

| commit | | §  |
|---|---|---|
| `42f550cf`, `28349cb7` | early work in progress | 1–6 |
| `df5aec4d` | schema: interleave, `FITBTest*`, validation-plus counts | 8–9 |
| `051d7e5f` | assembly: `$eval-position` excludes `@all='yes'` | 7 |
| `65679c5c` | fitb: name-mismatch guards | 10 |
| `3047e52b` | notes | — |
| `cbef17fa` | static solution pairing | 11 |
| `2b8cb219` | `TMP:` fixture, `examples/fillin/` | 13 |
| `20858e80` | `fillin-in-mathematics` validation-plus check | 15 |
| `c1a3873e` | well-formed JSON on the error branches | 14 |
| `7c2fe2e2` | notes | — |

## Rebase onto `upstream/master` (2026-07-31)

Rebased from the old base (`d03bcc2d`) onto `upstream/master` at `ade44af0` — 261 upstream commits,
21 of ours replayed. One textual conflict; everything else merged cleanly. Force-pushed afterward
(history rewritten, so a plain `push` would have been rejected).

**The retired `visible-id` alias.** Upstream `92284606` deleted `mode="visible-id"` — it was a bare
alias for `mode="unique-id"` (`<xsl:value-of select="@pi:unique-id"/>`, nothing more), and the alias
template was removed outright, not renamed with a compatibility shim. Every call site using
`mode="visible-id"` merged cleanly (no textual conflict) and then silently fell through to XSLT's
default template rule for that mode — this is the dangerous kind of break, invisible in the diff.
Swept the whole repo (`git grep 'mode="visible-id"'`) and fixed every hit:

- `xsl/pretext-runestone-fitb.xsl` — ~12 message call sites, mechanical swap to `mode="unique-id"`.
- `xsl/extract-dynamic.xsl` / `script/dynsub/dynamic_extract.mjs` — `exercise_visible_id` field
  renamed to `exercise_unique_id`; the `quote-string` call site was also fixed to route through
  `apply-templates mode="unique-id"` rather than a bare attribute select (the original bug: passing
  the `apply-templates` instruction directly as `xsl:call-template` content, outside any
  `xsl:with-param`, which is invalid — `xsl:call-template` may only contain `xsl:with-param`
  children).
- `xsl/pretext-assembly.xsl:1731` — two distinct bugs, not one. First, the mechanical swap alone
  (`@visible-id` → `@unique-id`) was still wrong: it needs the `pi:` namespace prefix, since the
  stamped attribute is `@pi:unique-id` and an unprefixed `@unique-id` in XPath always means
  "no namespace" — a different, nonexistent attribute. Second, and this survives the prefix fix
  too: this message lives inside `mode="exercise"` (template at ~line 1678), which runs on `$exercise`
  at line 636 — *before* `@pi:assembly-id` (stamped line 643) or `@pi:unique-id` (stamped line 704)
  exist on the tree at all. Fixed to `@pi:original-id`, the one id-attribute guaranteed present at
  this pipeline stage (stamped at line 615, well before `$assembly`/`$exercise`). Swept the rest of
  `mode="exercise"` for the same class of bug (any `@pi:assembly-id`/`@pi:unique-id` reference inside
  an `id-attribute` pass that runs too early) — none found elsewhere.

**Schema regeneration.** Ran `schema/build.sh` translated for this checkout (it hardcodes RAB's own
`PTX=${HOME}/mathbook/mathbook`, documented as "make a copy and adjust paths"). Only diff:
whitespace on two blank lines in `publication-schema.rnc`. Traced to unrelated upstream `4047cff3`
("Litprog: trim trailing whitespace from a 'code' fragment") — it changed `pretext-litprog.xsl`
itself and regenerated four other `.rnc` files in the same commit; `publication-schema.rnc` just
hadn't been regenerated since, so this run is the first to pick up that cleanup. Confirms the FITB
grammar itself (`exercise-dev` fragment, `pretext.xml:2358` on) was untouched by any of the 261
upstream commits — no schema-side conflict with the FITB feature.

**Verification re-run.** Re-ran the full `examples/fillin/` recipe (§12/§13 below) against the
rebased tree: `main.ptx` still builds silent end to end — HTML/JSON, LaTeX, jing, and
validation-plus all clean, every exercise's `blankNames`/`feedbackArray`/LaTeX `FB-…` sequence
matches the README tables exactly, all JSON parses. `diagnostics.ptx` still noisy with the exact
expected severities and counts, both from the FITB stylesheets and from validation-plus. No
regression from the rebase.

**New, unrelated finding — not yet acted on.** `examples/fillin/publication.xml` (and likely other
publication files in the repo) now trigger a new upstream deprecation warning: `directories/@external`
moved from the publisher file into `docinfo` (upstream `26dbe8eb`). Harmless — the old location is
still honored — but worth relocating. Out of scope for the FITB branch, flagging for whoever owns
publication-file hygiene.

**Mechanism learned, worth keeping**: `@pi:original-id`, `@pi:assembly-id`, `@pi:unique-id` are not
a fallback chain. One template, `match="*" mode="id-attribute"` (`pretext-assembly.xsl:1022`), is
applied three times at three pipeline points with a different `attr-name` param each time, same
label→xml:id→position algorithm every time — `original-id` (pass 3, after `version`), `assembly-id`
(pass 6, after `exercise` tagging), `unique-id` (pass 12, after `labels`, final form). They can
disagree only because the `labels` pass, which runs between the assembly-id and unique-id stampings,
can promote an `@xml:id` to `@label` in between; `id-coherence-check` (line 1087) flags a mismatch
as `PTX:DEBUG` when `$assembly.debug` is set. Separately, `dynamic_extract.mjs`'s
`exercise_id`/`exercise_unique_id` split is intentional: `exercise_id` (assembly-id) is the required
round-trip key for the `dynamic-substitution` file, because the real build's lookup happens at
`$assembly-label` (line 663) — *before* `labels`/`unique-id` exist on that build's tree — so
assembly-id is the only id available there; `exercise_unique_id` is purely a display string for
`reportError`/`reportWarning` messages. And: direct `@pi:*` access always needs the namespace prefix
regardless of whether you're on a real tree or an `exsl:node-set()`-converted result-tree-fragment —
that's a property of the node, not the tree shape. Consumer stylesheets mostly never see this because
they go through the `mode="unique-id"`/`mode="assembly-id"` accessor templates; `pretext-assembly.xsl`
touches `@pi:*` directly and constantly (146 instances) because it's the one file that owns and
stamps the namespace.

**Environment note, not a code issue.** Hit a stale `.git/index.lock` again during this round (same
class of problem as Outstanding §6 below, already resolved once before) — recurring nuisance, not a
repo defect.

## Branch hygiene

`fitb-extension-work` is a **working branch, synced across machines** — not the branch behind
the open pull request. So two kinds of thing live here:

| kind | files | destination |
|---|---|---|
| PR-bound | `xsl/`, `schema/pretext.xml`, `schema/pretext-*.rnc`/`.rng`, `schema/pretext-validation-plus.xsl` | upstream |
| working-branch only | `examples/fillin/`, `tmp-CLAUDE.md`, `tmp_git_log`, `fitb-external-libraries-design.md` | never upstream |

Everything must be **committed** to travel between machines, including the working-branch-only
files — that is what the branch is for. The care is needed at the moment work moves to the PR
branch, not here.

**So keep the two kinds in separate commits.** Never mix a stylesheet change and a notes or
fixture change in one commit, or the PR branch cannot take one without the other.

The message prefixes carry this: `FITB:` and `SCHEMA:` are PR-bound, **`TMP:` is not**
(`2b8cb219`, the fixture), and the bare `Update Claude context` commits are notes. So

```
git log --oneline | grep -v '^[0-9a-f]* \(TMP:\|Update Claude\)'
```

is the set that may travel upstream.

`examples/README.md` is deliberately left unmodified for the same reason: an entry there would
be a PR-bound change advertising a directory that never leaves this branch.

Primary file: `xsl/pretext-runestone-fitb.xsl`. Secondary: `xsl/pretext-assembly.xsl`,
`xsl/pretext-runestone-static.xsl`, `schema/pretext.xml`,
`schema/pretext-validation-plus.xsl`.

## The problem

`xsl/pretext-runestone-fitb.xsl` used `position()` throughout to determine the sequential
order of `fillin` elements within a `statement`. `position()` is the index in the *current
node list*, not document order, so it is only correct when the caller happened to build the
list with a single `select="statement//fillin"`.

Two distinct failure modes existed:

1. **Silently always 1.** Where `position()` appeared in a template body reached via
   `<xsl:apply-templates select="."/>`, the node list has one member, so `position()` is
   always `1`. This affected `mode="blank-name"`, meaning *every* unnamed `fillin` was named
   `blank1` — duplicate DOM ids on the generated `<input>` elements, and
   `evaluate[@name='blank1']` matching every blank.
2. **Fragile-but-currently-correct.** Where `position()` was used for comma separators inside
   item templates, it worked only because callers passed the full node list.

Test structure that motivated the fix (blanks must number 1..8):

```xml
<statement>
<p>text <fillin/> text <fillin/>
<ul><li><p>text <fillin/></p></li><li><p>text <fillin/></p></li></ul>
</p>
<p>text <fillin/> text <fillin/>
<ul><li><p>text <fillin/></p></li><li><p>text <fillin/></p></li></ul>
</p>
</statement>
```

## Completed

### 1. `mode="blank-number"` — robust document-order index

```xml
<xsl:template match="fillin" mode="blank-number">
    <xsl:variable name="the-fillin" select="."/>
    <xsl:for-each select="ancestor::statement[1]//fillin">
        <xsl:if test="generate-id() = generate-id($the-fillin)">
            <xsl:value-of select="position()"/>
        </xsl:if>
    </xsl:for-each>
</xsl:template>
```

`xsl:for-each` always iterates in document order, so `position()` inside it *is* the index.
`$the-fillin` is required because `xsl:for-each` rebinds the context node — `generate-id(.)`
inside the loop would compare a node to itself and match on every iteration. `current()` does
not help either, since `xsl:for-each` changes the current node too.

Replaces `position()` in `blank-name`, `declare-blank`, and `fillin`/`dynamic-feedback`.
Verified 1..8 on the structure above, via both `statement//fillin` and recursive descent.

### 2. Separators hoisted out of item templates

General rule adopted: **`position()` is trustworthy where the node list is built, not where it
is consumed.** The delimiter belongs to the loop, not the item — the XSLT equivalent of
`", ".join(...)`. Item templates are now context-free and reusable.

```xml
<xsl:for-each select="statement//fillin">
    <xsl:if test="position() > 1"><xsl:text>, </xsl:text></xsl:if>
    <xsl:apply-templates select="." mode="setup-parsers"/>
</xsl:for-each>
```

Applied at five call sites: `declare-blank`, `fillin`/`dynamic-feedback`, `setup-parsers`, and
both `evaluation-binding` callers (~1101, ~1197). Internal separators removed from all of them.

### 3. Dead code removed

- `mode="get-index"` template and the `$evaluate-index` variable (never referenced).
- `$curFillIn` in `fillin`/`dynamic-feedback`.

### 4. Correctness cleanups

- `ancestor::statement` → `ancestor::statement[1]`. With multiple context nodes a positional
  predicate is re-evaluated per context node and can return several `evaluate` elements.
- RTF-to-number comparisons wrapped in `number(...)`. Variables built with
  `<xsl:variable><xsl:apply-templates/></xsl:variable>` are result tree fragments; comparing
  an RTF to a number is not strictly legal XSLT 1.0, though libxslt coerces via string value.
- `declare-blanks` renamed to `declare-blank` (singular, since it now handles one blank).

### 5. `fillin`/`dynamic-feedback` restructured

Match resolution now happens once into a node-set variable, then a single `apply-templates`
consumes it. XSLT 1.0 cannot assign a node-set from inside `xsl:choose` (you get an RTF), so
the union idiom is used:

```xml
<xsl:variable name="the-evaluation" select="ancestor::statement[1]/../evaluation"/>
<xsl:variable name="ordered-evaluates" select="$the-evaluation/evaluate[not(@all='yes')]"/>
<xsl:variable name="named-match" select="$the-evaluation/evaluate[@name = $fillinName]"/>
<xsl:variable name="ordered-match" select="$ordered-evaluates[position() = number($blankNum)]"/>
<xsl:variable name="the-evaluate" select="$named-match | $ordered-match[count($named-match) = 0]"/>
```

Semantics settled on:

- Only `evaluate[@all='yes']` is excluded from the numbering. **Named `evaluate` elements DO
  occupy a positional slot** — pairing with blanks is one-to-one.
- Name match wins; otherwise positional.
- Guard on a positionally-matched `evaluate` carrying a name — see §10, which reworked it.
- Guard: `count($the-evaluate) > 1` catches an author reusing one `@name`, which would
  otherwise emit two feedback arrays and break the JSON.

Selecting `$ordered-evaluates[position() = N]` from a *variable* gives document order across
the whole set, unlike the old inline `evaluation/evaluate[position() = N]`.

Verified against 4 blanks (blank 2 named `beta`) and an `evaluation` of `@all='yes'` + E1..E4
where E2 is `beta`, E4 is `delta`:

```
blank 1 ("blank1") -> E1
blank 2 ("beta")   -> E2
blank 3 ("blank3") -> E3
blank 4 ("blank4") -> E4   [WARN: evaluate named "delta"]
```

### 6. Count check

Added in the caller (line ~156) so it fires once per exercise rather than once per blank:

```xml
<xsl:if test="count(evaluation/evaluate[not(@all='yes')]) != count(statement//fillin)">
```

Justified by research, not assumption:

- Guide, `doc/guide/author/topics.xml:2435`: "The `evaluation` block will have a sequence of
  `evaluate` elements, one associated with each of the corresponding `fillin` elements
  appearing in the `statement`. By default, the association is by order."
- `pretext-assembly.xsl:1621` requires an `evaluation` sibling before an exercise is treated
  as `exercise-interactive='fillin'` at all.

So an `evaluate` **cannot** be omitted in favour of a bare `@answer`/`@ansobj` on the `fillin`.
What is implicit is the *correct test*, not the `evaluate`: assembly (1659-1723) injects
`<test correct="yes"><numcmp|strcmp use-answer="yes"/></test>` when an `evaluate` lacks a
`test[@correct='yes']` and the paired `fillin` has `@answer`; `@ansobj` cases are built at
render time in the `otherwise` branch of `evaluate`/`dynamic-feedback`. The shell must exist.
As of §8 the schema now permits that shell to be empty of `test` elements.

### 7. `pretext-assembly.xsl:1672` — `$eval-position` excludes `@all='yes'`

```xml
<xsl:variable name="eval-position" select="count(preceding-sibling::evaluate[not(@all='yes')]) + 1"/>
```

Earlier notes called this the highest-priority wrong-output case, on the theory that assembly
and the Runestone pass would disagree whenever an author led with `<evaluate all="yes">`.
**That was overstated.** The template's own match pattern excludes

```
not( count(../../statement//fillin) > 1 and ../evaluate[@all='yes']/test )
```

so in any multi-blank document with an `@all='yes'` evaluate the template never fires and the
numbering is never consulted. Verified with libxslt over eight constructed cases.

The reachable defect was narrow: **one blank, `<evaluate all="yes">` written first**. The
`count(...) > 1` gate fails, the exclusion lapses, the template fires, `$eval-position` is 2,
`(fillin)[2]` is empty and no test is synthesized — silently. Two exercises differing only in
where the `all='yes'` element sat produced different output.

Dropping `count(fillin) > 1` was considered and rejected: `pretext-runestone-fitb.xsl:462`
carries the same gate, so at one blank the Runestone pass ignores the `all='yes'` test too.
Removing assembly's gate would leave neither pass supplying a correct test, landing on
`PTX:ERROR: No method provided to identify a correct answer` (line ~533).

The fix is now load-bearing rather than defensive. Under the old `FITBTest+` a bare
`<evaluate all="yes">` was schema-invalid, which is what made `../evaluate[@all='yes']/test`
a reliable proxy for "an `all='yes'` evaluate exists". With `FITBTest*` (§8) an author can
write one, the exclusion lapses, and the template fires on a position that would have been
wrong without this change.

### 8. Schema: interleave, and `FITBTest*`

**Edits go in `schema/pretext.xml` only.** It is a literate program and the master source;
`README.md` says "Submit pull requests against this version only, all the others are derived
copies." `build.sh` runs `pretext-litprog.xsl` to emit **both** `pretext.rnc` *and*
`pretext-dev.rnc` (fragment at `pretext.xml:3960`), then `trang` for the `.rng` files. The
FITB grammar lives in the `exercise-dev` fragment, `pretext.xml:2358` onward.

`FillInBlank` (`pretext.xml:~2542`) now reads:

```
(
Setup? &
Evaluation &
( StatementExercise, (Hint* & Answer* & Solution*) )
)
```

`setup` and `evaluation` are data, not content — neither renders where it sits — so their
placement is left to the author. Nesting the ordered part *inside* the interleave is what
keeps `statement` ahead of every `hint`, `answer` and `solution`. Two flat alternatives were
tried and rejected:

- Full interleave of all six: loses `statement`-before-`solution`, and silently breaks
  `pretext-common.xsl:4094`, which reaches back with `../preceding-sibling::statement[1]//ol[1]`
  to recover list-marker formatting from inside a solution.
- `(Setup? & Evaluation & StatementExercise), (Hint* & Answer* & Solution*)`: rejects four
  existing spots in `sample-article.xml` (10149, 10184, 10215, 10247) where `setup` and
  `evaluation` legitimately trail a `solution`.

`Evaluate` now takes `FITBTest*` rather than `FITBTest+`, so a bare `<evaluate/>` is valid.
The element is still required one-per-blank; only the test inside it is optional.

No RELAX-NG grammar can express the one-to-one count, since it relates children of one element
to descendants at arbitrary depth in mixed content of a *sibling*, and RELAX-NG has no
assertion mechanism (no XSD 1.1 `assert`, no Schematron — `build.sh` runs only trang).

### 9. `schema/pretext-validation-plus.xsl` — two new checks

One template on `evaluation`, three messages:

- `evaluation-too-few-evaluate` (`error`) — blanks left with no feedback path.
- `evaluation-too-many-evaluate` (`warn`) — surplus merely unused.
- `evaluation-all-single-blank` (`warn`) — `@all='yes'` with one blank; the Runestone pass
  discards it (`pretext-runestone-fitb.xsl:462` gates on `count > 1`).

**Why these can live here.** Both jing and validation-plus run against the assembled
**`version`** tree — pass 2 of 14 (`pretext.py:5078`, `assembly(..., "version")`;
`$b-version-only` short-circuits at `pretext-assembly.xsl:582`). No pass creates or removes an
`evaluate` or a `fillin`; the `exercise` pass (5) only adds a `test` inside an `evaluate` that
already exists. So the counts are invariant and the checks are safe at pass 2.

**What cannot live here:** any check on the *presence* of `test[@correct='yes']`. Synthesis has
not happened at pass 2, so such a check would be all false positives. It must stay in the
Runestone pass.

`pretext-validation-plus.xsl` is **not** generated — edit it directly. It merely lives in
`schema/`. `pretext.xml` mentions it only in prose (lines 460, 1828).

### 10. Name-mismatch guards consolidated

The old guard at the top of `evaluate`/`dynamic-feedback` (~475) is gone, replaced by a comment
explaining where the check moved. It was subsumed exactly: that template has a single entry
point (line ~597, inside `fillin`/`dynamic-feedback`), and since `$fillinName` is never empty —
`blank-name` falls back to the synthetic `blankN` — its condition strictly implied the newer
one. Its message, "Dynamic content missing label", also described a name *mismatch* as a
*missing* label.

Deleting it outright would have downgraded a genuine error to a warning, so the severity was
folded into the surviving guard instead. Both branches report the same finding — **a name on an
`evaluate` is a request for name-based pairing, and reaching the positional path means that
request went unmet** — and differ in what the author must do:

- **Both named, disagreeing** → `PTX:ERROR`. Two conflicting intentions; only the author knows
  which name is the mistake.
- **Only the `evaluate` named** → `PTX:WARNING`, every time. One edit fixes it, and position may
  have landed on the intended blank anyway. The message names both exits: name the blank, or
  drop the name from the `evaluate`.

This closes the old "warning noise" question. The noise was never the point — a name that does
nothing is worth saying out loud. Inside the guard the context node is the `fillin`, so a bare
`@name` is the blank's *authored* name, which is what the split turns on.

An `evaluate` named `blank3` that pairs with an unnamed third blank matches **by name**, since
`$fillinName` has already collapsed authored and synthetic names into one string before the
comparison. Presumed intentional; no message, and no way to distinguish at that point anyway.

### 11. `pretext-runestone-static.xsl` — static pairing fixed (Outstanding §2)

All three defects in `statement`/`mode="fillin-solution"` are repaired. The template is now
lines 1161-1190. **Uncommitted** at time of writing; one file.

```xml
<xsl:variable name="exercise" select=".."/>
<xsl:variable name="ordered-evaluates" select="$exercise/evaluation/evaluate[not(@all = 'yes')]"/>
...
<xsl:for-each select=".//fillin">
    <xsl:variable name="fillin-name" select="@name"/>
    <xsl:variable name="fillin-pos" select="position()"/>
    <xsl:variable name="named-evaluate" select="$exercise/evaluation/evaluate[@name = $fillin-name]"/>
    <xsl:variable name="ordered-evaluate" select="$ordered-evaluates[position() = $fillin-pos]"/>
```

- **(a)** `evaluate[@name='$fillin-name']` → `evaluate[@name = $fillin-name]`. An unnamed blank
  gives `$fillin-name` = `''`, and `@name = ''` is false against a *missing* attribute (empty
  node-set vs. string), so unnamed blanks still fall through to the positional branch. No
  synthetic `blankN` collapse is needed here, unlike the interactive path in §5/§10.
- **(b)** the positional branch now indexes `$ordered-evaluates`, which excludes `@all='yes'`.
- **(c)** the loop is `.//fillin`, not `.//fillin[@answer]`, so `@ansobj` blanks occupy their
  slot. The §1 `generate-id()` walk is **not** required: `position()` here sits directly in the
  `xsl:for-each` that *builds* the list, which is the trustworthy case under the §2 rule.

`$ordered-evaluates` is hoisted above `<solution>` since it is loop-invariant, and both matches
are bound to variables so the RTF-free node-set selection of §5 applies — indexing a variable
gives document order across the whole set, and the positional predicate is not re-evaluated
per `evaluation`.

Behaviour is now identical to the interactive path on the pairing rules, but the two
stylesheets still solve the problem separately; the factoring suggested in old §2 is untaken.

`../evaluation[@answers-coupled='yes']` (line 1186) and the `setup/var/condition[1]/feedback`
loop are untouched.

Verified by harness, old vs. new, importing the real stylesheet rather than a copied template
body (`xsl:import` + a root template applying `mode="fillin-solution"`, so the actual
`fillin`/`var` fillin-solution templates run too):

| case | old | new |
|---|---|---|
| blanks `alpha`,`beta`; evaluates named `beta`,`alpha` | FB-BETA, FB-ALPHA | FB-ALPHA, FB-BETA |
| 2 blanks, `all='yes'` first | FB-ALL, FB-ONE | FB-ONE, FB-TWO |
| blank1 `@ansobj`, blank2 `@answer` | FB-ONE only | FB-ONE, FB-TWO |
| 4 blanks across nested `ul`/`li`, blank 2's evaluate named | 1,2,3,4 | 1,2,3,4 (unchanged) |
| 1 blank + `@answers-coupled='yes'` | FB-ONE, FB-ALL | unchanged |
| legacy `fillin`, no `evaluation` | no feedback | unchanged |
| `fillin-basic` `var` + `setup` feedback | FB-VAR | unchanged |
| 3 blanks, only 2 evaluates | FB-ONE, FB-TWO | unchanged |
| bare `<evaluate/>` first (no correct test) | FB-TWO | unchanged |

The last five are the regression set: the widened `.//fillin` loop could in principle have
started emitting feedback in `fillin-basic` documents, and does not.

### 12. Verification build — recipe and first pass (Outstanding §1)

A real build **does** run in a sandbox with no LaTeX and no network. Recipe, then results.

**What is actually required**

- Python 3.10+ and **`lxml` only**. `common.xsltproc` (`pretext/lib/common.py:198`) is lxml, not
  the `xsltproc` binary — nothing to install there. The rest of `pretext/requirements.txt`
  (`qrcode`, `nbformat`, `pyMuPDF`, `PyPDF2`, `playwright`, `coloraide`) is unused by
  `-f html` and `-f latex`; `coloraide` only downgrades a contrast check to a warning.
- **Node** for `-c dynamic` (`setup` blocks, `@ansobj`, `jsimports`). Nothing else needs it.
- `-f pdf` needs xelatex and is **not** required — the static path under test terminates in the
  LaTeX source, so `-f latex` is the right target and stops before the parts that need a TeX
  installation.

**Two blockers on `-f html`, both cleared with string parameters**

- `_place_runestone_services` fetches `runestone.academy/cdn/runestone/latest/…` and treats
  failure as fatal (`pretext.py:3515`). `debug.rs.dev yes` returns stock values and skips the
  fetch. The resulting HTML cannot *run* the component (no `_static`), but the embedded
  Runestone JSON — the thing under test — is generated in full.
- `build_or_copy_theme` (`pretext.py:3824`) uses the prebuilt CSS only if `node_modules` is
  absent under `script/cssbuilder`. This checkout has it, so the build shells out to esbuild.
  `debug.html.theme-name default-legacy` takes the `"-legacy" in theme_name` branch instead.
  Note this is the **string parameter**, not `<html><theme name="…"/>` in the publication file,
  which did not take.

**`-x` does not accumulate.** A second `-x` replaces the first — `nargs="+"`, no `append`. All
pairs go after one `-x`. This silently reintroduced the CDN failure once.

Also: the `-d` output directory and the `external`/`generated` directories named in the
publication file must all exist beforehand; the script raises rather than creating them.

```
mkdir -p out external generated
python3 pretext/pretext -v -c doc -f html \
  -x debug.rs.dev yes debug.html.theme-name default-legacy \
  -p pub.ptx -d out fitb.ptx
python3 pretext/pretext -c doc -f latex -p pub.ptx -o fitb.tex fitb.ptx
```

with a minimal publication file of

```xml
<publication><source><directories external="external" generated="generated"/></source></publication>
```

**`sample-article` is not a sufficient test.** Its LaTeX output is **byte-identical** before and
after §11 (only the generated timestamp differs) — good as a regression check, useless as a
demonstration, because none of its FITB exercises reverse names, lead with `@all='yes'` over
several blanks, or mix `@ansobj` ahead of `@answer`. A purpose-built document is required.

**Results of the first pass**

*HTML / Runestone JSON* — three exercises: eight unnamed blanks across two paragraphs and two
nested `ul`s, two named blanks with the `evaluate` elements written in reverse, and a
two-blank exercise leading with `<evaluate all="yes">`.

- `blankNames` is `{blank1…blank8}` and the `<input>` ids are
  `ex-nested-unnamed-blank1 … -blank8`, all distinct. This is §1 confirmed end-to-end; before
  that fix every one of them was `blank1`.
- Named pairing survives reversal: `alpha`→FB-ALPHA, `beta`→FB-BETA.
- Every `feedbackArray` parses as JSON — no doubled `, ,` from §2.
- All four §10/§6 guards fire, with the right severity, on a document built to trip them:
  `evaluate` named but blank not (WARNING), names disagreeing (ERROR), count mismatch (ERROR,
  once per exercise, plus the per-blank "No matching #evaluate"), and one `@name` reused
  (ERROR).

*Not a defect, but worth recording:* in the `all='yes'` exercise the feedback array carries
FB-ALL in **both** slots and FB-ONE/FB-TWO never appear. That is by design — `$multiAns`
(line 480) *replaces* each blank's correct-test when `count(fillin) > 1` and
`evaluate[@all='yes']/test` exists. So an author's per-blank *correct* feedback is silently
unreachable in that configuration, while their per-blank *incorrect* feedback still shows.
This is the interactive half of the asymmetry in Outstanding §3 and should be settled there.

*LaTeX / static solutions* — the same document, exercising §11:

```
FB-1 … FB-8          (eight blanks, document order across nested lists)
FB-ALPHA, FB-BETA    (was FB-BETA, FB-ALPHA)
FB-ONE, FB-TWO, FB-ALL   (was FB-ALL, FB-ONE; FB-ALL now only via @answers-coupled)
```

*Node path* — `-c dynamic` on `sample-article` reproduces the committed
`gen/dynamic_subs/dynamic_substitutions.xml` **byte-identically**, so `setup`, `@ansobj` and the
`jsimports` external-library exercise all still round-trip.

**Still not covered:** PDF, EPUB and braille (no TeX/liblouis available); the HTML was never
loaded in a browser against real Runestone Services, so this checks the generated JSON, not the
component's behaviour on it.

### 13. `examples/fillin/` — the fixture, kept

The §12 test document is now in the repository, modelled on `examples/numbering/` (same
"machine-made, machine-oriented" framing, same `ext/`+`gen/` `.gitkeep` layout). Split in two:

- `main.ptx` — all valid. Builds **silently** in HTML and LaTeX, validates with no jing and no
  validation-plus messages. Any message is a regression.
- `diagnostics.ptx` — all broken, one exercise per diagnostic. Noisy by design; silence is the
  failure.

`README.md` carries the build recipe from §12 and tables of the expected output per exercise:
`blankNames`, the `<input>` ids, the feedback order in the JSON, the full `FB-…` sequence from
the LaTeX, and the expected message and severity for each diagnostics exercise.

**Local only — do not push upstream.** `examples/README.md` is deliberately left untouched: an
entry there would advertise a directory the upstream repository is not going to have. If this
fixture is ever offered upstream, that entry is the thing to add back (a paragraph alongside the
numbering stress test, same framing).

Build into `output/`, which the repository's `.gitignore` already covers. Validation deposits the
assembled source next to `-o`, so point that inside `output/` too.

Both documents were built through all three paths after being written, and match the tables.

**Finding, from writing the fixture.** An answerable blank inside `<m>` is not schema-valid —
`Fillin` inside mathematics permits `@characters` and `@fill` only. So the "blank in math"
case does not exist and was dropped. But the *decorative* blank that is legal there is counted
as answerable by the fill-in machinery, which is a real bug — see Outstanding §7.

### 14. An authoring error can no longer break the JSON

`pretext-runestone-fitb.xsl`, `fillin`/`dynamic-feedback`. Both error branches of the `xsl:choose`
emitted a message and no output, while the caller at :163 had already written the `, ` separator
that precedes the blank. One bad blank therefore left `, ,` and cost the *whole exercise* its
JSON. Each branch now emits a well-formed one-element array:

```xml
<xsl:text>[{"feedback": "[Error: No evaluate to match this blank]"}]</xsl:text>
<xsl:text>[{"feedback": "[Error: Several evaluate elements share this blank's name]"}]</xsl:text>
```

The shape matches the default entry the normal path already ends with (:548) — a single object
with only a `feedback` key, which Runestone treats as always-true, so the reader sees the error
text rather than a silently dead blank. The messages are unchanged; this only adds output.

**The duplicate-name branch was fixed too**, though only the unpaired case was asked for. It is
the identical defect three lines up and leaving it would have kept the hole open; say the word
and it comes out.

Verified across `diagnostics.ptx`: all eight exercises' JSON now parses, where
`ex-decorative-blank-counted` previously did not. `main.ptx` unchanged, nine blocks, still
silent.

### 15. `fillin-in-mathematics` — new validation-plus check (Outstanding §9)

An error, per the decision that a blank inside mathematics cannot work in an interactive
fill-in exercise: the schema allows it only `@fill`/`@characters`, and PreTeXt has no mechanism
for placing an `<input>` inside MathJax-rendered mathematics. (MathJax itself may support it;
PreTeXt does not implement it.) Such a blank is counted, consumes an `evaluate`, and renders as
nothing.

```xml
<xsl:template match="fillin[ancestor::m or ancestor::md]">
    <xsl:if test="ancestor::statement[1]/../evaluation and not(ancestor::statement[1]//var)">
```

Three things about that test:

- `ancestor::md` covers `mrow`, which occurs only inside `md`. There is no `me`/`men` in this
  schema — display math is `md` with `@number`.
- The interactive-fill-in test mirrors `pretext-assembly.xsl:1616-1622`: an `evaluation` beside
  the statement, and no `var` in it, since a `var` makes the exercise `fillin-basic` instead,
  where a decorative blank in mathematics is unremarkable. `@exercise-interactive` **cannot** be
  used — it is not set until a later pass than the one this stylesheet runs against.
- Blanks in a `hint`, `answer` or `solution` have no `statement` ancestor, so they never reach
  the test. Decorative blanks there stay legal.

The template ends with `<xsl:apply-templates select="@*|node()"/>` to preserve the traversal it
overrides.

Verified: fires twice on `ex-decorative-blank-counted`; **zero** hits on `sample-article` (205
pre-existing validation-plus messages, none of them this) and on `sample-book` (35); `main.ptx`
still validates with no messages from jing or validation-plus.

## Verification performed

All by harness, not by a full build (see Outstanding §1).

- **`$eval-position`** — eight constructed exercises through libxslt, exercising the real match
  pattern: `all='yes'` first/middle/last, one blank vs several, with and without a `test`.
- **Schema** — eleven orderings through jing against the regenerated `pretext-dev.rng`. `setup`
  and `evaluation` validate before the statement, after the solution, and first of all;
  `statement` after `solution` still fails; bare `<evaluate/>` and feedback-only `<evaluate>`
  now validate. Against `sample-article.xml` the diff versus the pre-change schema removes
  exactly the two `find-row-echelon` errors (10309, 10321) and adds none.
- **validation-plus** — eight cases covering matched counts, too few, too many, `all='yes'`
  excluded from the count, single-blank `all='yes'`, and bare evaluates. All as expected. The
  new checks fire zero times on `sample-article.xml`.
- **`pretext-runestone-fitb.xsl`** compiles after the guard rework.

Regeneration: `pretext.rnc`, `pretext.rng`, `pf-adapter.rng` came back byte-identical — the
change is dev-schema only.

## Outstanding

1. ~~**Verification build not yet run.**~~ **First pass done — see §12** for the recipe, the
   two string parameters that make it work offline, and the results. HTML/JSON and LaTeX both
   check out; `sample-article` is unchanged. Remaining: PDF/EPUB/braille targets, and loading
   the HTML in a browser against real Runestone Services. Also fold the §12 test document into
   the repo somewhere if it is worth keeping.

2. ~~**`xsl/pretext-runestone-static.xsl`, `statement`/`mode="fillin-solution"`.**~~ **FIXED —
   see §11.** Original description retained below for the record.

   **`xsl/pretext-runestone-static.xsl:1161-1187`, `statement`/`mode="fillin-solution"` — three
   bugs of the same family this branch has been fixing, all confirmed to produce wrong
   output.** Found while tracing `@answers-coupled`; not yet touched.

   This template builds the **automatically generated static solution**, so the damage is wrong
   or missing solution text in print/PDF/braille rather than broken interactivity — likely why
   it went unnoticed. It is *not* dead code for the new markup: it is applied from **both**
   `fillin-basic` (line 1115) and the new `fillin` type (line 1230).

   **(a) The name-matching branch can never fire.**

   ```xml
   <xsl:when test="$exercise/evaluation/evaluate[@name='$fillin-name']/test[@correct='yes']">
   ```

   `'$fillin-name'` is quoted *inside* the XPath, so it is a **string literal**, not the
   variable declared on the line above. The predicate compares `@name` against the twelve
   characters `$fillin-name`, which no author will ever write. Every blank therefore falls
   through to the positional branch, and named pairing is silently unavailable in static
   output — even though the interactive path honours it. Same expression repeated at 1175.

   **(b) The positional branch does not exclude `@all='yes'`.**

   ```xml
   <xsl:when test="$exercise/evaluation/evaluate[$fillin-pos]/test[@correct='yes']">
   ```

   The bug fixed in assembly at §7, still present here. A leading `<evaluate all="yes">` shifts
   every blank by one.

   **(c) `$fillin-pos` counts only blanks that have `@answer`.**

   It is `position()` within `for-each select=".//fillin[@answer]"`, so any blank using
   `@ansobj` is skipped *and* shifts the numbering of every blank after it.

   Verified with libxslt against the exact template body:

   | case | current output | should be |
   |---|---|---|
   | blanks `alpha`, `beta`; evaluates named `beta`, `alpha` (reversed) | `alpha`→FB-BETA, `beta`→FB-ALPHA | `alpha`→FB-ALPHA, `beta`→FB-BETA |
   | 2 blanks; `all='yes'` written first | blank1→**FB-ALL**, blank2→FB-ONE, FB-TWO dropped | blank1→FB-ONE, blank2→FB-TWO |
   | blank1 `@ansobj`, blank2 `@answer` | blank1→nothing, blank2→FB-ONE | blank1→FB-ONE, blank2→FB-TWO |

   Note the second row: the *global* all-blanks feedback is emitted as if it were the solution
   for blank 1.

   The fixes are the ones already applied elsewhere on this branch — unquote the variable, add
   `[not(@all='yes')]`, and index blanks by the `generate-id()` walk from §1 rather than by
   `position()` over a filtered list. Consider factoring the pairing out of both stylesheets;
   the static and interactive paths are now solving the same problem twice, differently.

   Line 1183's `../evaluation[@answers-coupled='yes']` is correct as written — `..` from the
   `statement` context is the exercise.

3. **`@answers-coupled` is live but undocumented.** Declared at `pretext.xml:2660`, read in
   exactly one place — `pretext-runestone-static.xsl:1183` — where it gates whether the
   `evaluate[@all='yes']` correct-test feedback is appended to the generated static solution.
   Authored in `sample-article.xml:10247` and `sample-book/rune.xml:4479`. It appears nowhere in
   `doc/`. Note the asymmetry: the dynamic path (`get-multianswer-check`, line 460) ignores the
   attribute entirely and gates only on `count($responseTree) > 1`. So `@all='yes'` reaches the
   interactive output regardless, and `@answers-coupled` decides only the static rendering.
   Either document it or reconcile the two paths.

4. **Same treatment for other exercise types?** Only `FillInBlank` references `Setup` and
   `Evaluation`, so the interleave was FITB-only. The other eight `StatementExercise,` sites in
   the dev grammar have no data-like children and need nothing — but worth a look if new
   Runestone types acquire a `setup`.

5. ~~**Commit the working tree.**~~ Done — `df5aec4d`, `051d7e5f`, `65679c5c`. The only
   uncommitted file now is `xsl/pretext-runestone-static.xsl` (§11).

6. ~~**Stale `.git/index.lock`.**~~ Removed.

7. **Decorative attributes on a fill-in blank are discarded by the static build.**

   **Settled doctrine first**, since an earlier draft of this section had it backwards. Inside
   the `statement` of a fill-in exercise there is **no such thing as a decorative blank**. Every
   `fillin` is answerable and must pair with an `evaluate`. The decorative *attributes* —
   `@characters`, `@rows`, `@cols`, `@fill` — are welcome on an answerable blank and should
   carry through to the static build; what is unwanted is a `fillin` that is decorative *only*,
   with no `evaluate` behind it.

   Two consequences, both of which reverse earlier notes:

   - **`statement//fillin`, unfiltered, is correct** at all five sites (`…fitb.xsl:156`, `:162`,
     `mode="blank-number"`, validation-plus, and the `.//fillin` loop of §11). No "is this
     answerable" predicate is wanted anywhere. The predicate hunt in the earlier draft of this
     item was a wrong turn.
   - The messages from `ex-decorative-blank-counted` in the §13 fixture were **right**. A blank
     with no `evaluate` is exactly the error the count check exists to report. That exercise is
     a correctly-diagnosed authoring mistake, not a false positive.

   **The real defect** is that the decorative attributes are silently dropped.
   `pretext-runestone-static.xsl:1240`, `mode="fillin-statement"`, discards the authored
   attributes and rebuilds the element from `@width` alone:

   ```xml
   <fillin>
       <xsl:attribute name="characters">
           <xsl:choose>
               <xsl:when test="@width"><xsl:value-of select="@width"/></xsl:when>
               <xsl:otherwise><xsl:text>5</xsl:text></xsl:otherwise>
           </xsl:choose>
       </xsl:attribute>
   </fillin>
   ```

   Verified through a LaTeX build of four blanks:

   | authored | LaTeX | wanted |
   |---|---|---|
   | `characters="40"` | `\ptxfillintext{5}` | 40 |
   | `width="30"` | `\ptxfillintext{30}` | 30 (only one that works) |
   | `rows="3" cols="20"` | `\ptxfillintext{5}` | a multi-line box |
   | none | `\ptxfillintext{5}` | 5 |

   `mode="fillin-solution"` (line 1257) is the same story, emitting `<fillin characters="1"/>`
   around every answer regardless. And the interactive side has the mirror-image gap:
   `pretext-runestone-fitb.xsl:50` reads `@width` only, so `characters="40"` yields an `<input>`
   with no `size` at all. The attribute is inert in **both** directions.

   Note the ordinary, non-interactive `fillin` honours all of `@characters`, `@rows` and `@cols`
   (`sample-article.xml:1747`). So the fill-in path is strictly losing information that the
   plain path keeps, for the same attributes on the same element name.

   **What the guide says**, which is more decisive than the code. `topics.xml:784-789` documents
   the *generic* `fillin` — `@characters` (default 10 in text), `@fill` (math, default `XXX`),
   and `@rows`/`@cols`, where the latter pair means "an indication that the expected content to
   fill in the blank is a `rows` × `cols` array", i.e. semantics and not a width hint.
   `topics.xml:2433` documents the *interactive* `fillin` and names exactly one sizing
   attribute: "may have a `width` attribute specifying the number of characters for the
   static-version blank." It never mentions `@characters`, `@rows` or `@cols` on an interactive
   blank, and `topics.xml:2598` gives `var` the same `@width`, so `@width` is the
   Runestone-family spelling throughout.

   So the guide describes **two disjoint vocabularies** and never promised the old attributes
   work on the new element. The dev schema widened `FillInText` to accept all of them and the
   prose was never reconciled. This is a schema/guide divergence, not a contradiction of
   documented behaviour.

   **Decided.** `@rows`/`@cols` are **ignored** on an interactive blank: interactive fill-ins do
   not support tables yet, so there is nothing for a `rows` × `cols` array to mean. Where to say
   so — a schema restriction that refuses them on an interactive blank, or a validation-plus
   warning — is not yet settled, and either way it waits on someone deciding whether the
   restriction belongs in the grammar.

   **For the maintainer.** `@characters` on an interactive `fillin` needs a decision before any
   code moves. Today it is accepted by the schema, documented for the generic element only, and
   discarded by both paths. The options are to honour it as a synonym for `@width` (a pure
   widening — nothing reads it now, so no existing output could change), to forbid it on an
   interactive blank and keep the two vocabularies apart, or to settle which of the two spellings
   is canonical and deprecate the other. That choice decides whether `topics.xml:2433` gains a
   sentence or the section gets restructured, so it is not a change to make unilaterally.

   Deliberately **not** implemented pending that decision.

8. ~~**Malformed JSON when a blank has no `evaluate`.**~~ **FIXED — see §14.**

9. ~~**`fillin` inside `<m>` in a fill-in statement.**~~ **FIXED — see §15.**

10. **`examples/fillin/publication.xml` uses the deprecated `directories/@external` location.**
    Surfaced by the 2026-07-31 rebase (upstream `26dbe8eb`): the attribute now belongs on
    `docinfo`, not the publisher file. Still honored, so not a build failure, just noise in the
    log. Low priority, unrelated to the FITB feature; relocate whenever someone is next in this
    file.

## Notes for whoever picks this up

- The stylesheet declares `version="1.0"`. No `string-join`, no dynamic modes, no
  higher-order functions. The union idiom and `generate-id()` comparisons are the XSLT 1.0
  workarounds for those gaps, not stylistic choices.
- `xsltproc` is not required to test; `python3` with `lxml` runs XSLT 1.0 fine:
  `etree.XSLT(etree.parse('sheet.xsl'))(etree.parse('input.xml'))`. Small standalone harnesses
  reproducing just the templates under test were how each fix above was verified.
  For a stylesheet with a DOCTYPE entity reference, parse with
  `etree.XMLParser(load_dtd=True, resolve_entities=True)`.
- **libxml2 cannot load PreTeXt's RELAX-NG** ("Internal found no define for ref Group"), so
  `lxml.etree.RelaxNG` and `xmllint` are useless here. Use jing. `pip install jingtrang` puts
  both `jing.jar` and `trang.jar` in `site-packages/jingtrang/`, which is enough to regenerate
  and validate without system packages.
- Schema edits go in `schema/pretext.xml`, never in the `.rnc` or `.rng`. Both compact grammars
  are generated from it. `build.sh` has `PTX=${HOME}/mathbook/mathbook` hard-coded and is
  documented as "Copy and edit local paths, or consult as documentation".
- The interleave operator is written `&amp;` in `pretext.xml` — it is XML character data there.
- If a template must be reachable from a single-node `apply-templates select="."`, it must not
  contain a bare `position()`. That is the invariant this whole change enforces.
- `<xsl:apply-templates mode="..."/>` without `select` defaults to `select="node()"` — the
  *children*. Since `fillin` is empty that silently emits nothing. Always write `select="."`.
- The FITB grammar lives only in the dev schema. `pretext.rnc` has `fillin` but no
  `evaluation`/`evaluate`, so none of this is frozen contract yet.
