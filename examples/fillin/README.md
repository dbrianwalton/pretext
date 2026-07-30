# `examples/fillin` — a fill-in-the-blank pairing fixture

Two synthetic documents that exercise how the blanks of a fill-in exercise are
numbered and how each one is paired with an `<evaluate>`:

- **`main.ptx`** — every exercise is valid. A clean build emits **no**
  `PTX:ERROR`, `PTX:WARNING` or `PTX:FALLBACK`, and validates against the
  development schema with no messages from either jing or `validation-plus`.
  A message here is a regression.
- **`diagnostics.ptx`** — every exercise is deliberately broken. A build
  *should* be noisy; silence is the failure. The expected messages are listed
  below.

Both use `publication.xml`.

## Heads-up: machine-made, and machine-oriented

Written by Claude (Anthropic's AI assistant) alongside the blank-ordering work
on the `fitb-extension-work` branch, and grown to fit the cases that testing
turned up. Like `examples/numbering`, it is a test fixture and **not** an
example of good PreTeXt authoring:

- The prose is throwaway ("Enter 1 here") so the answers are trivially
  predictable and the output easy to grep.
- All feedback is the literal string `FB-…`, so a build can be checked by
  `grep -o "FB-[A-Z0-9]*"` and compared against the tables below.
- It crowds together constructs no real exercise would.

## Building

Neither document needs LaTeX, Node, or a network connection.

```
cd examples/fillin
mkdir -p output/html output/latex

# HTML, carrying the Runestone JSON that the interactive path generates
python3 ../../pretext/pretext -v -c doc -f html \
    -x debug.rs.dev yes debug.html.theme-name default-legacy \
    -p publication.xml -d output/html main.ptx

# LaTeX, carrying the automatically generated static solutions
python3 ../../pretext/pretext -c doc -f latex \
    -p publication.xml -o output/latex/main.tex main.ptx

# schema and validation-plus
python3 ../../pretext/pretext -V -M local-dev \
    -p publication.xml -o output/report.txt main.ptx
```

`output/` is already covered by the repository's `.gitignore`; build elsewhere
and you will have to sweep up after yourself.  Validation also deposits the
assembled source next to `-o`, so point that inside `output/` too.

Three things about that invocation:

- `debug.rs.dev` skips the fetch of Runestone Services, which is otherwise a
  fatal network dependency. The HTML will not *run* the component — there is no
  `_static` — but the embedded JSON is generated in full, and that JSON is what
  this fixture is about.
- `debug.html.theme-name default-legacy` selects a prebuilt stylesheet instead
  of shelling out to esbuild. Drop it if your `script/cssbuilder` is working.
- **`-x` does not accumulate.** A second `-x` replaces the first, so all pairs
  go after one flag.

`ext/` and `gen/` are named in the publication file and must exist; they are
kept in the repository, empty, for that reason.

## What `main.ptx` should produce

Interactive path, from the `application/json` script block of each exercise.
Every `feedbackArray` must parse as JSON — a missing array element leaves `, ,`
and it will not.

| exercise | `blankNames` | correct-response feedback, in order |
|---|---|---|
| `ex-nested-unnamed` | `blank1`…`blank8` | `FB-1`…`FB-8` |
| `ex-blank-edges` | `blank1`…`blank3` | `FB-M1`, `FB-M2`, `FB-M3` |
| `ex-names-reversed` | `alpha`, `beta` | `FB-ALPHA`, `FB-BETA` |
| `ex-mixed-names` | `blank1`, `middle`, `blank3` | `FB-X1`, `FB-X2`, `FB-X3` |
| `ex-all-first` | `blank1`, `blank2` | `FB-ALL`, `FB-ALL` |
| `ex-all-last` | `blank1`, `blank2` | `FB-ALL`, `FB-ALL` |
| `ex-evaluation-first` | `blank1` | `FB-P1` |
| `ex-evaluation-last` | `blank1` | `FB-P2` |
| `ex-implicit-tests` | `blank1`…`blank3` | none; `FB-T1` and `FB-T3` are wrong-response feedback |

The `<input>` ids are the exercise id joined to the blank name, so
`ex-nested-unnamed` must yield eight *distinct* ids, `-blank1` through
`-blank8`. Before the blank-ordering fix every one of them was `blank1`, which
is duplicate DOM ids on eight elements.

`ex-all-first` and `ex-all-last` are worth reading twice. `FB-ALL` fills both
slots and `FB-ONE`/`FB-TWO` never reach the interactive output at all: an
`<evaluate all="yes">` carrying a test *replaces* each blank's correct-test
whenever the exercise has more than one blank. That is the current design, not
a fault of the pairing. The two exercises differ only in where the `all="yes"`
element is written, and must agree — the author's placement of it is not
supposed to matter.

Static path, from the LaTeX. The whole document in one pass should be:

```
FB-1 FB-2 FB-3 FB-4 FB-5 FB-6 FB-7 FB-8 FB-M1 FB-M2 FB-M3 FB-ALPHA FB-BETA
FB-X1 FB-X2 FB-X3 FB-ONE FB-TWO FB-ALL FB-ONE FB-TWO FB-ALL FB-P1 FB-P2
```

Here `FB-ONE` and `FB-TWO` *do* appear, ahead of `FB-ALL`, which arrives only
because the `<evaluation>` carries `@answers-coupled`. That asymmetry between
the static and interactive readings of `@all="yes"` is longstanding and
unresolved; the fixture records it rather than asserting it is right.

## What `diagnostics.ptx` should produce

From the HTML build:

| exercise | severity | finding |
|---|---|---|
| `ex-evaluate-named-blank-not` | WARNING | `evaluate` named `delta`, matched to blank 2 by position |
| `ex-names-disagree` | ERROR | blank `aa` matched by position to an `evaluate` named `zz` |
| `ex-too-few-evaluate` | ERROR ×2 | count mismatch, then blank 3 with nothing to pair to |
| `ex-too-many-evaluate` | ERROR | count mismatch |
| `ex-duplicate-name` | ERROR + WARNING | one `@name` on two `evaluate` elements |
| `ex-decorative-blank-counted` | FALLBACK ×2, ERROR ×3 | two blanks inside `<m>`, neither answerable nor paired |

From `validation-plus`, which runs on the assembled tree before any test is
synthesized and so can only count:

| check | severity |
|---|---|
| `evaluation-too-few-evaluate` | ERROR |
| `evaluation-too-many-evaluate` | WARNING |
| `evaluation-all-single-blank` | WARNING |
| `fillin-in-mathematics` | ERROR, twice |

The last exercise, `ex-decorative-blank-counted`, covers blanks inside
mathematics. Inside the statement of a fill-in exercise there is no such thing
as a decorative blank: every `<fillin>` is answerable and must pair with an
`<evaluate>`. A blank inside `<m>` can never satisfy that — the schema permits
only `@fill` and `@characters` there, and PreTeXt has no way to place an
`<input>` inside mathematics rendered by MathJax — so `validation-plus` raises
`fillin-in-mathematics`, once per blank. The count error and the two "No
matching #evaluate" errors that follow are correct too, and the `@mode`
fallbacks are a knock-on, those blanks having no `@mode` because the schema
does not allow one.

**Every `feedbackArray` in this file must still parse as JSON**, errors and
all. An unpaired blank emits a placeholder entry reading `[Error: No evaluate
to match this blank]`, and a blank whose name is claimed by several
`<evaluate>` elements gets the parallel `[Error: Several evaluate elements
share this blank's name]`. An authoring mistake should cost the exercise its
feedback, never its JSON. Checking that both documents parse is the single most
useful automated assertion here.
