# FITB external Javascript libraries in static builds

Working notes for the `fitb-extensions` branch. Written to be pasted into a
fresh session as context.

## Problem

A fill-in-the-blank exercise with a `setup` block generates its content in
Javascript. HTML is fine: the Runestone component runs the setup in the
reader's browser. Static formats (LaTeX, PDF, EPUB) have no browser, so the
setup must be run once at build time and the resulting values substituted into
the source.

That build-time evaluation is:

```
xsl/extract-dynamic.xsl  ->  JSON  ->  script/dynsub/dynamic_extract.mjs  ->  XML
                                                                             |
                                              xsl/pretext-assembly.xsl  <----+
```

driven by `dynamic_substitutions()` in `pretext/lib/pretext.py`.

The branch adds `setup/jsimports/jslibrary`, letting an exercise import a
library by `@source` (project-local, under the external directory) or `@url`
(remote). Runestone handles this in HTML. The build-time path did not: the
extraction JSON recorded nothing about imports, so the Node script had no way
to load them.

## Fidelity is the governing constraint

A value produced at build time must equal the value the browser would produce
for the same seed. Where the two paths could drift, change the Node script to
match the component. The component's code:

```js
// imports
case "BTM": import_promises.push(import("btm-expressions/src/BTM_root.js")); break;
default:    import_promises.push(import(/* webpackIgnore: true */ import_)); break;
// merged
this.dyn_imports = Object.assign({}, ...module_namespace_arr);
// scope
window.Function("v", "rand", ...Object.keys(dyn_imports),
                `"use strict";\n${dyn_vars};\nreturn v;`)
```

Consequences adopted verbatim: `"BTM"` is matched as a literal string and
resolved to the npm package; namespaces merge with `Object.assign`, so a name
exported twice resolves to the later import, silently; the setup runs inside a
function taking `v`, `rand`, then the merged names, with `"use strict"`.

## Design decisions

**Imports are recorded per exercise, mirroring `dyn_imports` exactly**,
including the leading `"BTM"`. Keeping the arrays identical means an exercise
that loads in a browser loads the same way under Node. No Runestone change.

**`@obj` is an expression, not a variable name.** HTML drops the same string
into a template as `[%= ... %]`, so `_config.date` has to evaluate. The old
script did a property lookup, which returned `undefined` and threw, taking the
entire run with it. The script now evaluates each `@obj` in the scope the setup
left behind.

**Every substitution is recorded in two forms.** The file is keyed only by
`@obj`, but one object is routinely referenced more than once and not always
the same way — as a `fillin/@ansobj` answer and again inside `<m>` in the
solution. Those need different strings from one key. Rather than guess, record
both and let the consumer, which knows its own context, choose:

```xml
<eval-subst obj="baseMatrix"><latex>\begin{bmatrix}...</latex><plain>[[1, 3], [2, 4]]</plain></eval-subst>
```

Files written before this distinction hold text and no children; that text is
accepted for either request, so existing generated files keep working.

**Remote libraries are gated by a per-URL publisher allowlist.** A static build
runs the library under Node as whoever is building, unsandboxed — a different
proposition from the same code in a reader's browser. HTML is not gated.
Approval is per-library, not a blanket switch, so approving one library cannot
extend to a different one an exercise imports later. The check is a plain
string match on the specifier as written, and runs across the whole document
before anything is imported or evaluated, so the author sees every approval to
add at once. Unapproved URL means exit 1, no output file.

```xml
<publication>
  <dynamics>
    <remote-libraries>
      <library url="https://example.org/matrix.mjs"/>
    </remote-libraries>
  </dynamics>
</publication>
```

**Remote source is fetched to a temp file with an `.mjs` extension**, not
imported as a `data:` URL. A `data:` URL has no position in a filesystem, so a
library that imports anything of its own cannot resolve it. The `.mjs`
extension forces ESM parsing, so a bundle that is not an ES module fails here
exactly as it would in a browser rather than loading quietly as CommonJS with
no named exports. No caching between runs; within a run, a shared library is
fetched once.

**Project-local paths reuse the HTML path scheme.** `@source` is recorded as
`external/...`, the same relative form HTML uses. `dynamic_substitutions()`
copies the external tree into the temp dir and passes `--basedir`, so one path
convention serves both.

**Failures are isolated and reported, not fatal.** A per-exercise failure emits
`PTX:ERROR` naming the exercise's `@unique-id` and records its substitutions
present but empty, so `document()` lookups in assembly still resolve and the
rest of the document keeps its content. Exit code is nonzero only when nothing
usable could be produced. `pretext.py` now keys failure on the exit code —
previously any stderr output was treated as total failure, which would have
turned a partial success into a dead build.

**`@mode` stays optional in the schema.** Making it required is not reachable:
`FillInText |= element fillin { ... }` combines into the global pattern shared
with the ordinary prose fill-in blank (126 such uses in `examples/` and `doc/`
alone), and `FillInBlank` reaches its blanks through the generic
`StatementExercise` content model, so scoping the requirement to FITB would
mean cloning the whole inline content model. Instead a missing `@mode` produces
`PTX:FALLBACK` from `mode="declare-blanks"` and defaults to `string`, which is
already the implicit behavior downstream.

## Bugs fixed along the way

- **No XML escaping.** The script concatenated values into the output raw. A
  matrix `toTeX()` joins with `" & "`, so the new sample exercise produced a
  malformed substitutions file, and `document()` then failed, taking the whole
  static build down.
- **`md` missing from the math-context test.** `ancestor::m|ancestor::mrow`
  missed `md`, whose single-line form holds text directly with no `mrow` to
  find. Harmless while everything got TeX unconditionally; wrong as soon as
  math mode is honored. Fixed in both `pretext-runestone-fitb.xsl` and the new
  assembly consumer, which must agree.
- **Duplicate parameter names.** `v.rrefMatrix = rrefMatrix(...)` put one name
  in both the `v` list and the imports list; duplicate parameters are a
  `SyntaxError` under strict mode. `v` now wins, matching the browser, where
  the template evaluates against `v` and shadowing is natural.
- **`btm-matrix-library.js` did not load at all** — `export { rrefMatrix }`
  named a function since renamed to `getRREF`; `testRowEquivalent` called the
  old name; `_choosePivotCols` took a parameter `col` while its body used
  `cols`, and its caller passed an undefined `col`.

## Files changed

| File | Change |
|---|---|
| `script/dynsub/dynamic_extract.mjs` | Rewritten. Async imports, BTM literal match, `--basedir`, allowlisted remote fetch, `default`-export filtering, two-stage evaluation, latex/plain output, XML escaping, per-exercise isolation |
| `xsl/extract-dynamic.xsl` | Emits `allowed_remote`, `exercise_imports`, `exercise_visible_id`; top level is now an object, not a bare array |
| `xsl/pretext-runestone-fitb.xsl` | `mode="js-import-path"` factored out for sharing; `md` added to math test; `PTX:FALLBACK` for missing `@mode` |
| `xsl/pretext-assembly.xsl` | `mode="dynamic-representation"` picks latex or plain with legacy fallback; both consumers updated |
| `xsl/publisher-variables.xsl` | `$remote-library-allowlist` |
| `pretext/lib/pretext.py` | Copies external tree, passes `--basedir`, keys failure on exit code |
| `schema/pretext-dev.{rnc,rng}` | `jsimports` and `config-json` moved to head of `setup` |
| `schema/publication-schema.{rnc,rng}` | New `Dynamics` pattern |
| `examples/sample-article/sample-article.xml` | `mode="math" parser="parseMatrix" ansobj="rrefMatrix"`; solution with `<m>` reference; renamed library calls |
| `examples/sample-article/media/code/fitb/btm-matrix-library.js` | Load-blocking reference errors fixed |
| `doc/guide/author/topics.xml`, `script/dynsub/README.md` | Documentation |

## Verified

Extractor run end to end against the real library: `_config.date` resolves,
`&` escapes to well-formed XML, latex and plain genuinely differ, duplicate
`@obj` entries collapse. Unapproved URL exits 1 with no output. Approved URL
fetches and imports (tested against a local server, with a `default` export
present to confirm filtering). Failing exercise yields empty substitutions and
continues. Legacy bare-array JSON still loads. Assembly's representation
template tested standalone on new, legacy, and empty entries. Publication
schema accepts `dynamics` and rejects `library` without `@url`. Sample `setup`
validates against the reordered pattern; the old ordering is rejected.

Not verified: a full `pretext build` of the sample article. `pretext.rng` has a
pre-existing `Group` define that libxml2 cannot resolve, so whole-document
RELAX NG validation needs `jing`.

## Open

- `PTX:FALLBACK` for missing `@mode` fires from `declare-blanks`, on the HTML
  generation path. A LaTeX-only build will not show it. Covering static builds
  would mean a second copy of the message in `pretext-runestone-static.xsl`.
- The `default`-export hazard is filtered here but remains live in the
  Runestone component: `Object.assign` copies `default` into
  `Object.keys(dyn_imports)`, and `window.Function(..., "default", ...)`
  throws.
- `@parser` and `@mode` are independent in the schema but `@parser` wins for
  parser selection, so there is no way to say "custom parser, typeset the
  answer as math" other than setting both, which the sample now does.
- Regenerate `examples/*/gen/dynamic_subs/dynamic_substitutions.xml`; they
  predate the latex/plain form (and still work via the legacy fallback).
- `.rnc` and `.rng` schema files were edited by hand in parallel; a `trang`
  regeneration would confirm they agree.
