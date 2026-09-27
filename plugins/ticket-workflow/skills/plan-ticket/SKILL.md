---
name: plan-ticket
description:
  Plans a tracker ticket for a later implementing agent. Scouts the sources listed in
  .agents/research-sources.md, gates on blockers and missing spec, writes a milestone-grouped plan
  in guided or auto mode. Works with any issue tracker reachable over MCP (Linear, Jira, and
  similar). Use when the user invokes /plan-ticket, pastes an issue prompt such as Linear's `<issue
  identifier="TEAM-n">` XML, asks to plan implementation for a ticket, or asks to set up or
  configure plan-ticket.
disable-model-invocation: true
---

# Plan Ticket

Planning-only skill. Do not implement, edit repo files, or create commits.

The parent (planning) model **does not scout**. It parses the invocation, treats a pasted ticket
body as the source for **this** issue, launches scouts, judges briefs, asks the user, and writes the
plan. See [scouts.md](scouts.md) for launch wiring and return schemas. See
[template.md](template.md) for the plan section list and cadence block.

`TEAM-n` means the **current repo's** ticket identifier (team or project prefix plus number).
Discover it from the pasted issue, a tracker scout, or the repo's conventions files. Never hardcode
a prefix from another project.

**Host:** this skill names no models and no host-specific tools beyond the few marked inline as
`Cursor:` / `Claude:`. Subagent types come from what this host exposes; models come from
`scout_model` in the sidecar. Use what you actually have.

## Setup

If the invocation is `--setup`, or asks in words to set up or configure this skill, **run setup and
nothing else**: no plan mode, no scouts, no ticket.

1. If `.agents/research-sources.md` exists, this is an edit: read it, show what is configured, ask
   what to change. Never overwrite a filled sidecar.
2. Tracker: list the issue-tracker MCP namespaces available in this session, ask which one this repo
   uses, and confirm `team_prefix` against a **real issue**, not the repo name.
3. Conventions: read whichever of `CONTRIBUTING.md`, `AGENTS.md`, `CLAUDE.md`, `README.md` exist.
   Propose the `conventions` precedence list and say what each supplied.
4. Other sources: ask **by category**, not open-ended: product specs, design, sibling repos,
   external sources of truth, anything else the team reaches for before writing code. For each: a
   one-line blurb, when it is worth consulting, how to reach it, what a scout brings back, what to
   do if it is unreachable.
5. Scout model: ask which model subagents should use for bulk search. A fast tier, not the reasoning
   tier. Record it as `scout_model`; use a per-host map when the answer differs by host.
6. Mode: `guided` or `auto` as this repo's default.
7. Write `.agents/research-sources.md`, show it, offer a pointer to it from `AGENTS.md`. Keep it in
   version control; use relative paths, never machine-specific absolute ones.

Field reference and a worked example: [sources-reference.md](sources-reference.md).

## Mode

Resolve **before** writing the plan:

1. `--auto` / `--guided` in the invocation, or the same intent in words
2. `default_mode` in the sidecar
3. `guided`

`guided` pauses between milestones. `auto` runs straight through. Auto drops the **approval**
checkpoint only: validation, no-commits-without-asking, no scope expansion, and stop-on-missing-fact
hold in both, and a milestone tagged `**Pause:** required` stops regardless.

Record it as the `Mode:` line in the plan and write the matching cadence from
[template.md](template.md). That line is how `build-ticket` paces itself in a later session; an
unrecorded mode does not exist.

## Canonical request

The user's standing request. Operational details below must not weaken it:

```
Plan issue TEAM-n. Verify the current branch; if we're not on a correct new branch for this
ticket, suggest one at the start of the plan. Assume a less capable AI agent may be implementing it,
so be thorough. Break the plan into discrete, commit-sized milestones. Instruct the implementing
agent to not make any commits unless the user asks, but to suggest a commit message after each
milestone. Once all milestones are done, the implementing agent should suggest a PR title/body that
adheres to this repo's contributing guidelines. If implementing this ticket requires any context not
100% outlined in the ticket or existing docs, prompt the user for it; do not assume.
```

Plus one mode-dependent clause:

- **guided:** work one milestone at a time, pausing for user review before continuing to the next.
- **auto:** work the milestones in order without pausing between them, except where one is tagged
  `**Pause:** required`.

## Parent vs scout

| Parent (this conversation)                               | Scouts                                                |
| -------------------------------------------------------- | ----------------------------------------------------- |
| Enter plan mode                                          | **tracker:** _related_ issues only, never the primary |
| Acquire the primary ticket: paste, else read it directly | **repo:** branch, code, tests, rules, in-repo docs    |
| Read the sidecar; select sources                         | conventions + PR-template excerpts                    |
| Launch scouts; follow up                                 | **external:** whatever the sidecar defines            |
| Judge briefs; ask the user                               | spec gaps quoted from real paths                      |
| Write the plan from briefs + answers                     |                                                       |

**Parent must not** grep, glob, shell out, or fetch the web to gather **repo** facts, and must not
research any source the sidecar lists. Thin brief or failed tool → **re-launch a scout** with a
tighter prompt. Do not go looking yourself.

**Parent must** acquire the primary ticket itself (step 3). That is one bounded read, the parent
needs it verbatim to evaluate triggers and write gates, and a subagent would only hand back a
summary of it.

**Parent may** read `.agents/research-sources.md` and this skill's own files, and write the plan
file.

## Workflow

Copy this checklist and track it:

```
Plan Ticket:
- [ ] 1. Enter plan mode
- [ ] 2. Parse the invocation; resolve the mode
- [ ] 3. Acquire the primary ticket (paste, else read it directly)
- [ ] 4. Read the sidecar; select sources
- [ ] 5. Launch research scouts
- [ ] 6. Judge briefs; follow up on gaps
- [ ] 7. Blockers + spec gate (GATE)
- [ ] 8. Missing-context gate (GATE)
- [ ] 9. Write the plan
```

### 1. Enter plan mode

Switch immediately if not already there. `Cursor:` `SwitchMode` → `plan`. `Claude:` `EnterPlanMode`.
Stay there.

### 2. Parse the invocation; resolve the mode

Parse `TEAM-n` from `<issue identifier="TEAM-n">` XML or the invocation text. Missing → ask. Do not
guess, do not reuse another repo's prefix.

Resolve the mode per **Mode** above.

### 3. Acquire the primary ticket

**Nothing else happens until you have the ticket body.** Source selection and every scout prompt
depend on knowing what this ticket asks for.

- **User pasted it** → that paste is the source for this `TEAM-n`. Do not re-read it, do not refresh
  it for staleness.
- **No paste** → read the issue **yourself**, one call, using the `tracker` value from the sidecar
  for this host. Include its relations. Do **not** launch a subagent to do this: it is a single
  bounded read, you need the text verbatim, and a scout would only return a summary of it.

Then read it before going further. From it you need: the requirements, the acceptance criteria, the
relation list, and whatever the ticket leaves unspecified.

**Related tickets are different.** If the ticket names blockers, related, duplicate, or "see TEAM-m"
issues whose content would change scope or sequencing, those are research and belong to a scout in
step 5. Fetching several issues and condensing how each bears on this one is real work; fetching one
issue you already have the id for is not.

### 4. Read the sidecar; select sources

Read `.agents/research-sources.md`. **Missing → run Setup**, then continue. Do not invent a source
list.

Drop `never` sources. Keep `always`. Evaluate each `conditional` source's `trigger` against **the
ticket text you just read**. **Report every skipped source in one line with its reason**: a silent
skip is indistinguishable from a source nobody configured.

### 5. Launch research scouts

One scout per `group`, capped at `scout_budget`, all in **one** parent message. Never mix a `repo`
source with a `tracker` or `external` source.

Every scout prompt carries the **full ticket body**. A scout's job is to find what is needed to
_build_ this ticket, never to hunt the repo for mentions of its id. Launch fields and prompts:
[scouts.md](scouts.md).

### 6. Judge briefs; follow up on gaps

Required sections are in [scouts.md](scouts.md). Missing section, spec gap with no verbatim excerpt,
or "not found" with no search list → re-launch a tightened scout.

Do not invent contracts, enums, payloads, owners, or product policy. If two briefs disagree, that is
a question for the user, not something to resolve by reading the files yourself.

### 7. Blockers + spec gate (before the plan)

From the pasted ticket (or the tracker brief):

- Required blockers not Done → ask whether to wait, split, or proceed anyway.
- Ambiguities **in the ticket text** → ask the user; do not fill in.
- Repo brief flags other in-progress work in the checkout → ask whether to stack this ticket on it
  or branch from the base, and whether to use a linked worktree. Do not choose for them.

From the repo and external briefs:

1. Keep gaps that **change how this ticket would be implemented**: payload shape, ids, auth, status
   mapping, sequencing, policy, retry/idempotency. Drop unrelated items.
2. **Excerpts are evidence.** A doc that says unverified/assumed stays unresolved until the user
   confirms.
3. "No gaps" is acceptable only when the search list covers the ticket's domain.
4. A `required: true` source that could not be reached is a gate. Use its `on_failure` text.

If any impacting gap is unresolved: ask for the decision or missing artifact. Offer to wait, split
scope, or do fixture-only work **only if the user opts in** with named assumptions. **Do not begin
the plan** until they answer or say to proceed with named assumptions.

Unresolved spec must never be silently filled in.

If scouting reveals follow-up work the tracker does not already have, the plan must **create a
ticket** (or ask the user to) before the implementer leaves `TODO(TEAM-n)` in the repo.

### 8. Missing-context gate (before the plan)

If anything needed to implement is not **100% specified** by the ticket or the briefs, ask.
Examples: which status maps to which lifecycle event, whether this PR should `Fixes` the ticket,
product copy, feature flags, rollout, error UX.

Do not assume. Do not write the plan around a guessed default.

### 9. Write the plan

Audience: a **less capable AI agent** implementing later. Be concrete using **scout citations**:
paths, symbols, commands. Missing a path or pattern → follow-up scout, do not browse.

Follow [template.md](template.md) for section order, the `Mode:` line, and the cadence block. Copy
the cadence as written; do not expand it. Fill `TEAM-n`, branch shape, commit format, and PR layout
from the **repo brief's conventions excerpts**, not from memory of another project.

**Wrap scout facts into the plan** (Ticket, Contract, milestone steps). Do **not** add a **Context
used** or **Unresolved spec** recap unless the template's include rules apply. Locked decisions and
copy-from patterns belong in Contract / milestones so the implementer does not second-guess or
re-research.

Each milestone must include:

- Goal, in scope, out of scope
- Files / symbols to change (and files not to change)
- Step-by-step notes: patterns, types, tests, edge cases
- Validation: commands and cases, **plus a diff review** (confirm only the intended files and lines
  changed; re-read any table, list, or config block you inserted into)
- Suggested commit message in this repo's own format, from the scout excerpts
- `**Pause:** required - <why>` if it must stop for review even in auto mode
- Stop instruction per the cadence

Keep milestones independently committable. Prefer tests/docs with the behavior they cover, not a
trailing "write tests" dump, unless a test-only milestone is the right split.

## Conventions

Branch, commit, and PR rules come from the repo, never from memory. The sidecar's `conventions:`
list is the precedence order; first file that answers wins. Unset → try `CONTRIBUTING.md`,
`AGENTS.md`, `CLAUDE.md`, `README.md`. None exist → ask the user once and offer to record it in the
sidecar. **Do not default to `type(scope): summary`** unless a file in the repo says so.

The repo scout also reports any PR template (`.github/pull_request_template.md`,
`.github/PULL_REQUEST_TEMPLATE.md`, `.github/PULL_REQUEST_TEMPLATE/`). The plan's **Final PR** uses
those headings where the conventions files are silent; if they disagree, conventions win and the
plan says so.

Linking words: use the repo's own. Typically `Fixes`/`Closes`/`Resolves` when the PR completes the
ticket, `Related to`/`Refs`/`Part of` when it does not. Default to link-only unless the user said
this PR completes the ticket.

## TODO hygiene

Stated once, in [template.md](template.md)'s cadence. Details:
[add-ticket-refs](../add-ticket-refs/SKILL.md).

Deferrals in committed code or docs use `TODO(TEAM-n): <concrete follow-up>` on the next line, where
`TEAM-n` is a real tracker issue owning that work. No bare `TODO`/`FIXME`/`HACK`, no vague
`planned`/`TBD`. New follow-ups need the ticket created first; never invent an id. Some repos forbid
ticket ids in committed prose entirely; their rules win.

Plans that **finish** the issue must include a step to remove stale references to that ticket from
committed docs. Keep refs for still-open work only.

## Failure modes to avoid

- Parent grep/shell/tracker "just to double-check"
- Scouts launched without pinning `scout_model` (omitting the model inherits an expensive parent)
- A scout that both browses the repo and makes remote calls
- Re-fetching a ticket the user already pasted
- Skipping a `conditional` source without saying so
- Proceeding past an unreachable `required: true` source
- Implementing during the planning turn
- Launching a scout to fetch the primary ticket instead of reading it directly
- A scout prompt with no ticket body, which can only make it grep for the ticket id
- Selecting sources before the ticket body is in hand, so `conditional` triggers cannot be judged
- Starting the plan before the blocker / missing-context gates
- Encoding an unverified vendor or product fact
- Trusting "no spec gaps" with no search list
- One giant milestone for a multi-change ticket; vague steps ("update the service as needed")
- Committing, or telling the implementing agent to commit automatically
- Commit or PR text that ignores this repo's conventions or PR template
- `Fixes TEAM-n` when the PR does not complete the ticket
- Bare `planned` / `TBD` / `TODO` without `TODO(TEAM-n): …` and a real owner
- Deferred work with no owning ticket when implementation would leave a repo `TODO`
- Shipping a completing PR while docs still cite the ticket as pending
- A **Context used** / **Unresolved spec** recap the implementer will not use
- Another repo's prefix, branch pattern, or doc map
- A plan with no `Mode:` line
- Planning work on top of an in-progress branch without confirming with the user that it should be
  stacked there
