# Plan body template

Copy this structure into the plan. **Always include** Branch, Ticket, Mode, Cadence, Milestones,
Final PR, Rules. Include **Contract** when the implementer must not invent a spec.

Omit **Context used** and **Unresolved spec** unless the rules under those headings apply. Do not
recap scout research the implementer will not use; fold paths, symbols, copy-from patterns, and
locked decisions into Ticket, Contract, and milestone steps.

Replace `TEAM-n` with this ticket's id. Fill branch/commit/PR shapes from the repo brief's
conventions excerpts, not from memory of another project.

---

## Branch

Stay on `<current-branch>` **or** switch to the conventions-shaped branch for this ticket if the
current branch is wrong (say so first).

Use the commands the repo brief reported. If the checkout held other in-progress work, state which
base this branch comes from and whether it runs in a linked worktree, per what the user chose.

```bash
<exact commands from the repo brief>
```

Note stack parent / PR base if this branch is stacked. Do not rename unless the user asked.

## Ticket

**Goal:** one sentence.

**In scope:** …

**Out of scope:** …

**Acceptance:** …

## Context used

**Omit unless** the implementing agent may need the material in a later discussion with the user: a
related PR URL, a decision-log id the user asked to cite, a parked scout contradiction. Do **not**
list docs, files, or tickets already cited in Contract or milestones. Pointers only.

## Unresolved spec

**Omit unless** (a) the user may still decide something in this chat, or (b) a follow-up ticket owns
a deferral the implementer must know about. Do **not** list resolved locks. Each item: path or
ticket quote, one-line leftover, disposition, owning `TEAM-n` if any.

## Mode: guided

> One of `guided` or `auto`, resolved by the planner. The implementing agent reads this line to know
> how to pace itself.

## Implementing-agent cadence

Approved plan. Do not re-plan unless asked.

1. Work the milestones in order, one at a time.
2. **Pacing: read the `Mode:` line above.**
   - **guided:** after each milestone, validate, summarize, and **pause for review**. Do not start
     the next until the user says continue.
   - **auto:** validate after each milestone and continue. Do not pause for approval.
   - **Both:** a milestone tagged `**Pause:** required` always stops for review. A failing
     validation is a stop, not a note.
3. **No commits unless asked.** Suggest a commit message per this repo's conventions, not a generic
   conventional-commit guess. Guided: after each milestone. Auto: all of them, in order, at the end.
4. Do not expand scope.
5. A fact you need that this plan does not specify → **stop and ask**. Auto mode removes the
   approval checkpoint, not this one.
6. After the last milestone, suggest a PR title and body per this repo's conventions and any PR
   template. Use the closing phrase when this PR completes the ticket (including docs-, scaffold-,
   or hygiene-scoped tickets); otherwise the link-only phrase. Auto mode: give one summary covering
   every milestone, the validation output, the ordered commit messages, and the PR draft.
7. Plain domain language in comments. Deferrals: `TODO(TEAM-n): …` on the next line with a real
   tracker owner. No bare `TODO`/`FIXME`/`HACK`, no vague `planned`/`TBD`. Follow the
   `add-ticket-refs` skill.
8. New follow-ups need a tracker ticket first. Never invent an id. Spec gaps found during the build:
   create the issue, then add the matching `TODO(TEAM-n):`.
9. When this PR completes `TEAM-n`, remove stale refs to that ticket from committed docs: narrative
   prose, header TODOs for behavior this PR ships. Keep refs for still-open work only, per the
   repo's documentation rules.

## Contract

**Include when** there is a locked surface the implementer must not invent (schema, API, enum
constraints, copy-from table). **Omit** if every fact fits in milestone steps without repetition.

Put scout citations here: files, symbols, constraints, indexes, copy-from paths, files not to touch.
This is the implementer's spec.

## Milestones

Commit-sized; one concern each; independently committable. Prefer tests/docs with the behavior they
cover.

### Milestone N: `<title>`

**Goal:** …

**In scope / out of scope:** …

**Files:** to change / not to change.

**Steps:** numbered; patterns, types, tests, edge cases.

**Validation:** commands and cases, **plus a diff review, always**:

- Read the full diff for this milestone before reporting it. Confirm you changed only the files and
  only the lines you intended. **An unrelated hunk is a stop, not a footnote**: revert it and say
  so.
- When a step inserts into structured content (a markdown table, a list, frontmatter, a config
  block), re-read the whole structure afterward, not just your insertion. A markdown table split by
  a stray paragraph still looks fine in a diff and renders as broken prose.
- Content checks ("read the new section", "grep for the header") confirm you wrote the right thing.
  They cannot tell you what else you touched. Do both.

**Pause:** omit for an ordinary milestone. Add `**Pause:** required - <why>` when this must stop for
review **even in auto mode**: destructive migration, a change to a risk limit or spend cap, an
awkward-to-undo deletion, anything touching credentials or production data.

**Suggested commit:** `<commit message per this repo's conventions, see the repo brief excerpt>`

Replace that slot with a real message in the repo's own format. Never carry the placeholder into the
plan, and do not reach for `type(scope): summary` unless the repo actually uses it.

## Final PR

**Title:** `<PR title per this repo's conventions, see the repo brief excerpt>`

**Body:** section headings from the conventions files; where those are silent, the PR template's
headings and order (the repo brief should have cited its path).

```markdown
<the repo's own PR body sections, in the repo's own order>
```

Use the repo's closing phrase when this PR completes the ticket, including when its scope is docs,
scaffolding, or hygiene. Use the link-only phrase when the ticket stays open after merge.

## Rules (implementing agent)

- Cadence items 7–9.
- Repo rules that apply (migrations, deps, money/safety, logging): one line each from the scout.
- Expected `TODO(TEAM-n)` ids, if any.
