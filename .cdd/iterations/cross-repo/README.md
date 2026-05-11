# Cross-Repo Iteration Bundles

Per `cdd/post-release/SKILL.md` Step 5.6b. This directory holds tsc-side artifacts produced for cross-repo cycles (typically cnos cycles where tsc is the consumer/courier side).

Layout (one subdir per cross-repo cycle):

```
cross-repo/
  <upstream-repo>-<cycle-N>/
    <artifacts produced on the tsc side for that cycle>
```

Empty at initialization (cycle #32). Future cross-repo bundles will populate here; the top-level `../INDEX.md` cross-references them by row.
