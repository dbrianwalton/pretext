# Commit restructuring plan for `fitb-extensions-work`

Not executed — no git commit/rebase was run this session per instruction. This is the
mapping to apply by hand (interactive rebase, `fixup!`, or however you prefer) once
`fitb-extensions-work-review-fixes.patch` is applied and reviewed.

Starting point: `fitb-extensions` at `40cbce09`. Current 8-commit sequence, oldest first:

```
a80b2046  FITB: Allow inclusion of libraries and config data as part of setup and custom specification of parsers.
06b57319  GUIDE: Add explanation for authoring FITB that include external libraries, config objects, or custom parsers.
2900cadc  FITB: Update schema to include js-imports and custom parsers
7ba91690  FITB: Dynamic substitution process updated (v1) to record plain and latex substitutions.
d6469653  FITB: sample-article addition of example fitb exercise (rref of matrix) calling external JS library and using config-json
f2071dbb  Update dynamic substitutions for sample article and sample book to new format (v1)
0443e018  Improve escape-json-string template by adding potential escape pairs.
40cbce09  FITB: Revision of error message to use template for id instead of attribute for visible-id.
```

## Where each patch hunk belongs

| File in the patch | Fold into | Why |
|---|---|---|
| `xsl/pretext-runestone-fitb.xsl` — 2-space → 4-space indentation on the two new `jslibrary` templates | `a80b2046` | That commit introduced both templates. |
| `xsl/pretext-runestone-fitb.xsl` — `mode="visible-id"` → `mode="unique-id"` (8 sites) | `40cbce09` | That commit introduced these exact call sites; this corrects the mode name it should have used. |
| `doc/guide/author/topics.xml` — wording (Javascript casing, "a config-json", "should have" instead of overstating "required", external-directory terminology, cross-link to the new publisher reference entry) | `06b57319` | Same file, same topic. |
| `doc/guide/publisher/publication-file.xml` — new "Dynamic Exercise Options" reference section | `06b57319`, or split into its own `Guide:` commit if you'd rather keep author-guide and publisher-guide changes apart | New content, no prior commit to fold into either way. |
| `schema/pretext-validation-plus.xsl` — removed `jslibrary-no-location`/`jslibrary-both-locations`, comment `-->` alignment, "assets" → "external" wording, `jslibrary-insecure-url` rewrap/clarity/HTML casing | `2900cadc` | That commit introduced this template. |
| `xsl/extract-dynamic.xsl` — `escape-quote-string` swap, `exercise_visible_id` → `exercise_unique_id` rename + comment realignment | `7ba91690` | That commit introduced this file's content. |
| `xsl/pretext-assembly.xsl` — `dynamic-representation` fallback fix (per-mode, not joint) | `7ba91690` | Same. |
| `xsl/pretext-text-utilities.xsl` — comment realignment, "control character" (singular) | `0443e018` | That commit touches exactly this template. |
| `script/dynsub/dynamic_extract.mjs` — `exercise_unique_id` rename, `SCHEME` regex (RFC 3986 single-char scheme), `withinProject` symlink resolution via `realpathSync`, `fetchRemoteModule` timeout, garbled module-cache comment, "assets" → "external" wording | `7ba91690` | That commit introduced this file. |
| `pretext/lib/common.py` — new `log_relayed_message`, `xsltproc()`'s loop calls it; new `copy_managed_resources()` sibling of `copy_managed_directories()` | `7ba91690` | Fixing this commit's own new severity-routing code, and narrowing its own whole-tree copy, so it never existed either way, per "make it look like it never happened." |
| `pretext/lib/pretext.py` — `dynamic_substitutions()` calls `common.log_relayed_message`, dead `PTX:ADVICE` branch removed, literal `PTX:ERROR:` dropped from the one `log.error()` call that had it (kept on the `raise ValueError`, which bypasses the logger's own prefix); `dynamic_substitutions()` now derives the local-library resource list from the extraction JSON and calls `copy_managed_resources()` instead of `copy_managed_directories()` | `7ba91690` | Same. |
| `examples/sample-article/media/code/fitb/btm-matrix-library.js` — `toTeX()` join separator drops trailing space before the newline | `d6469653` | That commit added this file. |
| `examples/sample-article/sample-article.xml` — `find-row-echelon`: statement-before-setup reorder (the blocker), 4-space indentation | `d6469653` | That commit added this exercise. |
| `examples/sample-article/gen/dynamic_subs/dynamic_substitutions.xml` — trailing-whitespace cleanup (now stays clean on regeneration, since the library fix is the root cause) | `f2071dbb` | That commit last regenerated this file. |

## Commit subject renames

Per `doc/guide/developer/git.xml`: capitalize only the first letter, no trailing period, topic
prefix is a real acronym in caps (`FITB`, `XSL`) or a title-cased word (`Guide`, `Script`), not
`SCHEMA`/`GUIDE` in full caps since those aren't acronyms.

| Current | Suggested |
|---|---|
| `GUIDE: Add explanation for authoring FITB that include external libraries, config objects, or custom parsers.` | `Guide: explain authoring FITB with external libraries, config objects, custom parsers` |
| `FITB: Dynamic substitution process updated (v1) to record plain and latex substitutions.` | `FITB: dynamic substitutions record both "plain" and "latex" representations` |
| `Update dynamic substitutions for sample article and sample book to new format (v1)` | `FITB: regenerate sample-article and sample-book dynamic substitutions` |
| `Improve escape-json-string template by adding potential escape pairs.` | `XSL: "escape-json-string" also handles U+2028/U+2029` |
| `FITB: Revision of error message to use template for id instead of attribute for visible-id.` | `FITB: route id-bearing messages through "mode=unique-id", not a raw attribute` |
| `FITB: Allow inclusion of libraries and config data as part of setup and custom specification of parsers.` | (drop the trailing period; otherwise fine) |
| `FITB: Update schema to include js-imports and custom parsers` | (fine as-is) |
| `FITB: sample-article addition of example fitb exercise (rref of matrix) calling external JS library and using config-json` | (drop trailing period if any; consider tightening, it's long) |

All should get ` (PR #3054)` appended once finalized, per the same chapter.

## `copy_managed_directories` narrowing — now implemented

After discussion, `dynamic_substitutions()` no longer calls `copy_managed_directories()` (whole
`external` tree). It now derives the set of project-local library paths from the extraction JSON
(already produced, once per document, before the copy) and calls a new sibling,
`copy_managed_resources()`, added to `common.py` right after `copy_managed_directories()`.

- Signature is flat, parallel to `copy_managed_directories(build_dir, external_abs=None,
  generated_abs=None, data_abs=None)`: `copy_managed_resources(build_dir, external_abs=None,
  external_resources=None, generated_abs=None, generated_resources=None, data_abs=None,
  data_resources=None)`. Chose flat over a grouped-object shape since nothing else in `common.py`
  groups arguments that way and three pairs isn't enough to justify introducing a new shape.
- Copies the *directory* immediately containing each requested resource (not the individual file),
  de-duplicated with a set, so a multi-file library with relative imports between its own files
  still has its siblings available. A resource sitting at the root of its managed directory copies
  that whole root — verified this behavior directly; flagging as a known coarseness, not fixed
  further since it wasn't asked for.
- Raises if a `*_resources` list is given without its matching `*_abs` path, rather than silently
  copying nothing.
- Verified against a real fixture: unrelated files/folders elsewhere in `external/` are excluded;
  a file sharing the needed library's folder is still pulled in (expected); the full `-c dynamic`
  then `-f latex` pipeline still runs silently and produces correct output.

Separately (discussion only, nothing implemented): `withinProject()` in `dynamic_extract.mjs`
checks containment against the whole `--basedir` (the build's temp directory), not specifically
against the copied `external/` subdirectory. Today that's harmless, since `dynamic_substitutions()`
puts nothing else in that temp directory. But `generated/` and `_static/` are populated alongside
`external/` for other conversions like `html()`, where a browser really can reach any of them from
any other via relative paths -- and if `dynamic_substitutions()` is ever changed to also copy
`generated/` in (say, to give a setup script access to a generated image), a `"../generated/..."`
specifier would start resolving successfully with no matching change to any approval/allowlist
logic, since nothing today distinguishes "the directory this feature means to expose" from
"whatever the build's temp directory happens to contain." If that's ever wanted, the fix is narrow
(scope `withinProject`'s comparison to `external_dir` specifically), but there's nothing to fix
yet since nothing else exists in that temp directory to reach.
