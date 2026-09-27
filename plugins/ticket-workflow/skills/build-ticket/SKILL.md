---
name: build-ticket
description:
  Implements a ticket from an approved plan-ticket plan file. Resolves the plan, verifies the
  branch, follows milestones at the pace the plan's Mode line sets; suggests commits and PR
  title/body per the repo's conventions and PR template; creates tracker tickets and TODO(TEAM-n)
  for new open questions; scrubs stale doc refs when the ticket completes. Use when the user invokes
  /build-ticket, links a `.plan.md`, or asks to build or implement TEAM-n from an existing plan.
disable-model-invocation: true
---

# Build Ticket

Implementation skill. Execute an approved plan from [plan-ticket](../plan-ticket/SKILL.md). Do not
re-plan unless the user asks.

`TEAM-n` means this repo's ticket identifier. Take it from the plan and the live issue. Do not reuse
another project's prefix.

**Host:** any subagents you launch use this host's read-only exploration type, pinned to
`scout_model` from `.agents/research-sources.md`. Never leave the model unpinned. Plans live in
`~/.cursor/plans/` on Cursor, under `~/.claude/plans/` on Claude Code.

## Resolve the plan

1. **User linked a plan file** (`.plan.md` path or attachment) → that file is the plan.
2. **User gave only a ticket** (`TEAM-n`, issue XML, or URL) → search for a plan whose filename
   contains the id, or whose frontmatter `name` or a body heading names it. Look in this order:
   1. The host's user-level plan directory, where both Cursor and Claude Code write plans by default
      (`~/.cursor/plans/`, `~/.claude/plans/`).
   2. The repo-level equivalent: `<repo>/.cursor/plans/`, `<repo>/.claude/plans/`,
      `<repo>/docs/plans/`. Plans get moved here by hand so a team can see them.
   - **Multiple matches** → ask which plan to use.
   - **No match** → ask whether to run `/plan-ticket` first. Do not implement without a plan.

## Read the config

Read `.agents/research-sources.md` if the repo has one, the same sidecar the planner used. Take
`team_prefix` and the `conventions` precedence list from it rather than re-deriving them, so plan
and build cannot disagree about where the house style lives. No sidecar → `CONTRIBUTING.md`, then
`AGENTS.md`, then `CLAUDE.md`.

**The plan's Rules section is a snapshot of the repo when the plan was written, not a live list.**
Rules get added between planning and building, and one added since still applies. Re-read the repo's
own rules (`.cursor/rules/`, `CLAUDE.md`, `AGENTS.md`) for the areas this ticket touches, and treat
anything you find there as authoritative over the plan's copy.

## Before coding

```
Build Ticket:
- [ ] Plan file resolved and read in full
- [ ] Mode noted from the plan's `Mode:` line
- [ ] Branch matches plan (or switched)
- [ ] Milestone 1 in progress (only one at a time)
```

1. **Read the entire plan** before editing anything (Branch, Ticket, Contract, cadence, every
   milestone, Final PR, Rules).
2. **Note the mode** from the `Mode:` line. No line → `guided`.
3. **Branch:** `git branch --show-current`. Compare to the plan's **Branch** section. Already
   correct → continue. Otherwise check out the branch the plan names, creating it only if the plan
   says to. Work in the directory the plan's Branch section specifies. If this checkout holds other
   in-progress work the plan did not account for, stop and ask whether to stack on it, branch from
   the base, or move to a linked worktree.

## Pacing

The plan's `Mode:` line sets this. Follow its cadence block exactly.

**`guided`**: one milestone at a time. After each: validate, summarize, suggest a commit message,
**stop for review**. Do not start the next until the user says continue.

**`auto`**: work the milestones in order without pausing. At the end, one summary: every milestone,
the validation output, the ordered commit messages, and the PR title and body.

**Both modes:**

- A milestone tagged `**Pause:** required` **always** stops for review. Auto does not override it.
- Validate after every milestone. A failing validation is a stop, not a footnote.
- **No commits unless the user asks.**
- Do not expand scope.
- A fact you need that the plan does not specify → **stop and ask**. Auto removes the approval
  checkpoint, not this one.
- **Run the milestone check below before reporting**, in both modes. Auto does not skip it.

## Diff check

After every milestone, before summarizing, actually run these. Reading your own edits is not the
same as reading the diff.

```bash
git diff --stat            # which files changed
git diff -U0 | grep '^@@'  # every hunk, including ones you did not make
git diff                   # the changes themselves
```

- **Account for every hunk.** A hunk outside the milestone's **Files** list, or in a region you
  never visited, is a stop. Revert it and say what it was. Editors reformat on save, so a file you
  opened can carry changes you did not type.
- **Re-read any structured block you inserted into** end to end: a markdown table, a list,
  frontmatter, a config block. A table split by a stray paragraph still looks correct in a diff and
  renders as broken prose.
- **Check your added lines against the repo's rules**, not the file around them. Surrounding text
  predates the rule; yours does not get to inherit its habits.

Mention only what you found. A clean check needs no block of its own.

## Commit and PR suggestions

- **Commits:** format per this repo's conventions (type, scopes, subject, body/refs, whatever they
  require). Prefer the milestone's **Suggested commit** when it matches; if the plan's example looks
  stale, re-read the conventions file; it wins over the plan. Do not default to a generic
  `type(scope): summary` unless the repo uses that shape.
- **PR title and body:** follow the plan's **Final PR** section, then verify against the conventions
  files and any PR template (`.github/pull_request_template.md`, `.github/PULL_REQUEST_TEMPLATE.md`,
  `.github/PULL_REQUEST_TEMPLATE/`). Use the template's headings and order where the conventions are
  silent.

Do not open a PR unless the user asks.

## Open questions during the build

When implementation hits something the plan and docs do not specify (vendor field, policy,
sequencing, env):

1. **Stop** if it changes behavior you cannot safely guess; ask the user.
2. Otherwise **create a tracker issue** (or ask the user to) with concrete scope; link it from the
   PR description if relevant.
3. Add `TODO(TEAM-n): <concrete follow-up>` on the **next line** in code. Never invent an id. See
   [add-ticket-refs](../add-ticket-refs/SKILL.md).
4. Do not add open-question tables to markdown or cite ids from some other system in source; the
   owner is the new ticket.

## Doc references when the ticket completes

When a milestone or the full plan **closes** the issue:

- Search the repo for that ticket id. Remove or rewrite hits in committed docs and reference samples
  that still describe the work as future: narrative prose, workflow comments, header `TODO(TEAM-n)`
  for behavior you just shipped.
- Replace with plain domain language for shipped behavior, or retarget remaining work to **other
  still-open** tickets, per the repo's documentation rules.
- Keep `TODO(TEAM-n)` for **other** open tickets. Do not edit plan files or the conventions files'
  own examples unless the plan says to.

Some repos are stricter; a rule may forbid ticket ids in committed prose entirely, leaving
`TODO(TEAM-n):` as the only permitted form. The repo's rules win.

If the plan already lists a doc-hygiene step, execute it in the milestone that finishes the ticket.

## Implement

Start the **earliest** milestone not yet done. For that milestone only: stay within its goal, scope,
files, and steps. Then run the **Diff check** above, summarize, and suggest the commit message. Then
pace yourself per **Pacing**.

When all milestones are done, suggest the PR title and body per the plan and the repo's conventions.
Use the closing phrase when the PR completes the ticket (including docs-, scaffold-, or
hygiene-scoped tickets), the link-only phrase when it stays open. Unsure → ask.

## Failure modes

- Implementing without reading the full plan
- Ignoring the `Mode:` line, or pausing through an auto-mode plan
- Blowing past a `**Pause:** required` milestone because the mode is auto
- Continuing after a failed validation
- Asserting the diff was checked instead of running the commands
- Treating the plan's Rules section as the full rule list when the repo has gained one since
- Letting a formatter's reflow of an untouched line ride along because the content you wrote was
  correct
- Matching the surrounding file's style where it conflicts with a repo rule
- Committing without an explicit user request
- Re-scouting or rewriting the plan instead of executing it
- Wrong branch or working directory, or rebasing when the plan forbids it
- Starting work in a checkout that holds unrelated in-progress changes without asking
- Subagents launched without the host's model pin
- New deferrals left as bare `TODO` / `TBD` without creating the ticket first
- Commit or PR suggestions that ignore the repo's conventions or PR template
- Suggesting a completing PR while docs still cite the closed ticket as pending work
