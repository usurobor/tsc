# example.repo-legibility — authored intent

**The authoritative executable artifact for this CM is
`ir/repo-legibility.ir.json`** — a hand-authored `#NormalizedCMIR` (`0.2`) that
validates against `../../contracts/cm-ir.cue`. This file is a **prose note
recording author intent**. It is not source, nothing compiles it, and nothing
reads it at run time.

## Governing question

> Does the repository present an entry document with enough substance to read,
> under a declared licence?

## Why this CM exists

It is the second methodology, and it exists to make one claim checkable: that
adding a methodology to `coh-min` is **data alone**. The commit that introduced
this directory touches no `.ml` file, no `Makefile` rule and no CUE contract —
it is a JSON IR, four subject fixtures, two TSV tables and this note. It then
runs end to end through the same parser, linker, scheduler, result evaluator and
receipt writer as `example.readme-present`, which is structurally nothing like
it.

So it is deliberately built from the shapes the first CM does not have:

| Property | `readme-present` | `repo-legibility` |
|---|---|---|
| steps | 1 | 3 |
| independent steps | — | 2 (`readme_locate`, `license_locate`) |
| dependent steps | — | 1 (`readme_depth` binds `readme_locate.path`) |
| capabilities used | `fs.file-exists` | `fs.file-exists` **and** `fs.text-metrics` |
| optional output ports | none | `readme_locate.path` |
| principled skip reachable | no | yes |
| result classes | 3 | 4 |
| algebra used | `eq`, `not`, `step_status` | `eq`, `ge`, `and`, `not`, `step_status` |
| warrant obligations | 1 | 2, on a strong class |

## The graph

```text
  repository ──┬──► readme_locate   (fs.file-exists  "README.md")
               │        present : boolean            required
               │        path    : relative-path      OPTIONAL
               │           │
               ├──► license_locate  (fs.file-exists  "LICENSE")
               │        present : boolean            required
               │           │
               └──►     readme_depth  (fs.text-metrics)
                        root   ◄── repository
                        target ◄── readme_locate.path      ← the dependency
                        line_count : integer     required
                        non_empty  : boolean     required
```

`readme_locate` and `license_locate` are **independent**: neither reads the
other, so nothing about the result may depend on which runs first. `make gate`
and the test suite both check that by permuting the step order and comparing the
derived class and the published fact set.

## The optional port, and the branch it opens

`fs.file-exists` publishes `present` always, and `path` **only when the file
exists** — there is no path to name when it does not. The capability therefore
declares `path` withholdable, and this CM declares it `"required": false`.

That single bit is what makes conditional progress expressible without any
conditional node:

- **subject has a README** — `readme_locate` succeeds and publishes both ports;
  `readme_depth` becomes ready and measures the file.
- **subject has no README** — `readme_locate` still **succeeds** (the absence is
  the measurement, not a failure) and publishes `present: false` while lawfully
  withholding `path`. `readme_depth` can never become ready, so it is a
  **principled skip** whose trace entry names the unpublished port:

  ```
  required input "target" of step "readme_depth" binds readme_locate.path,
  which step "readme_locate" did not publish (step "readme_locate" ended success)
  ```

  No value is fabricated, nothing crashes, and the receipt's `reports` record
  `readme_depth.line_count` as `"available": false` rather than as a zero.

Note that the methodology could NOT have declared `path` as `"required": true`:
the capability does not promise it, so the linker refuses that as a contract
mismatch (`refusals/required-withholdable-port.json`). Withholding a *required*
output is not available as a control mechanism — it is a rejected outcome.

## The decision, as a sketch

Illustrative pseudo-code — **not** a program in any implemented grammar:

```text
decide  NO_ENTRY_DOC  when readme_locate.present = false
        INCOMPLETE    when readme_depth did not succeed
        LEGIBLE       when readme_depth.line_count >= 5
                       and license_locate.present = true
        SHALLOW       otherwise
```

Rule ORDER is load-bearing and is exercised by the fixtures. On the `bare`
subject both the first and the second rule would match — no README means no
depth — and `NO_ENTRY_DOC` wins because it is declared first. That is a more
useful answer than `INCOMPLETE`: the run concluded something, it just concluded
that the entry document is missing.

`LEGIBLE` is the strong class, so it carries warrant obligations: it is
claimable only if `readme_depth` and `license_locate` both retained evidence in
this run. An unknown obligation is never treated as discharged, so a class
cannot be strengthened by inventing a requirement nobody can check.

## Fixtures

| Subject | README | LICENSE | Expected | Route |
|---|---|---|---|---|
| `rich` | 8 lines | yes | `LEGIBLE` | all three steps succeed |
| `thin` | 2 lines | yes | `SHALLOW` | depth measured, below threshold |
| `unlicensed` | 8 lines | no | `SHALLOW` | depth met, licence conjunct fails |
| `bare` | none | no | `NO_ENTRY_DOC` | lawful withholding → principled skip |
| `rich` under `ir/repo-legibility.tight.ir.json` | 8 lines | yes | `INCOMPLETE` | `max_bytes: 32` makes the dependent checker **refuse** |

The last row reaches `INCOMPLETE` by a different route than a skip: the checker
ran, a declared bound lawfully prevented it from establishing its fact, and its
`failure_policy` maps `refused` to `fact_unavailable`. The rule table sees
`step_status(readme_depth) ≠ success` either way, which is the point — the
methodology reasons about availability, not about why the provider stopped.

`cases.tsv` and `refusals.tsv` carry these rows in machine-readable form;
`make gate` discovers and runs every one.

## Provenance

The IR's `cm.source_digest` is the SHA-256 of **this file**:

```
$ sha256sum repo-legibility.intent.md
```
