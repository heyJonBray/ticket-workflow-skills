# Plan Ticket: scouts

Parent workflow stays in `SKILL.md`. This file is the scout contract: how sources become scouts, how
to launch, what to return, when to retry.

## Sources to scouts

From `.agents/research-sources.md`, after dropping `never` and evaluating each `conditional`
trigger:

The parent already holds the primary ticket (`SKILL.md` step 3). A `tracker` scout exists only to
fetch **related** issues; it must never re-fetch the primary. If nothing related needs fetching, no
tracker scout runs.

- **One scout per `group`**, not per source. Sources sharing a group share a prompt and return one
  brief.
- Cap at `scout_budget` (default 3). Over budget, merge the lowest-priority groups; merge `repo`
  last.
- **Never put a `repo` source in the same scout as a `tracker` or `external` source.** A scout that
  both browses the filesystem and makes remote calls does neither thoroughly, and its brief cannot
  be attributed. This split has no exceptions.
- Launch every scout in the **same** parent message.

## Launch wiring (mandatory)

| Field         | Value                                                                                       |
| ------------- | ------------------------------------------------------------------------------------------- |
| Subagent type | this host's read-only exploration subagent                                                  |
| Model         | `scout_model` from the sidecar, resolved for this host                                      |
| Fallback type | this host's general-purpose subagent, when there is no read-only type or an MCP call failed |
| Background    | off                                                                                         |

**Always pin the model.** Omitting it inherits the parent, which is the expensive default on every
host. Scouts do bulk search, so `scout_model` should name a fast tier, not a reasoning tier. Never
pin a variant the host treats as degraded.

If the host has no read-only subagent type, use its general-purpose one and state the read-only
constraint in the prompt. If `scout_model` is missing from the sidecar, ask the user once and offer
to record it.

Thoroughness in the prompt: **very thorough**. Read-only: no edits, no commits, no tracker writes.

Scouts start with empty history. Every prompt must carry: workspace path, ticket id, the **full
pasted issue text** when the user pasted one, each assigned source's `return` text, and the matching
schema below.

If a scout reports it cannot reach an MCP server, retry **that scout only** as the host's
general-purpose type with the same prompt. The parent still does not fetch anything itself.

## Prompt shape

One prompt per group. Fill the brackets.

```text
Read-only scout. Do not edit files, commit, or write to any tracker.

Workspace: [absolute repo path]
Ticket: [TEAM-n]
Thoroughness: very thorough

Ticket body (the parent already has this; do NOT re-fetch it):
[full ticket text: description, acceptance criteria, relations]

What this ticket needs built:
[2-4 lines the parent distils from the body, so the scout knows what to look for]

Your job is to find what is needed to BUILD the above. Do not go looking for
mentions of [TEAM-n] in the repo as your main task; existing references are a
footnote, not the assignment.

Sources assigned to you:
[for each source in this group:]
- [id]: [blurb]
  Access: [access]
  Bring back: [return]
  If unreachable: [on_failure]

Return in this schema:
[paste the matching schema below]

Return evidence with paths, symbol names, and verbatim quotes. Do not write an
implementation plan. Do not invent an API, enum, or payload shape. If you cannot
find something, say what you searched.
```

Restate in every prompt: a **tracker** scout never re-fetches the primary issue; a **repo** scout
never calls the tracker.

### Repo scouts: always ask for these

1. `git branch --show-current` and `git status -sb`. Quote the repo's branch pattern. Say whether
   the current branch matches it for this ticket (not main/master; contains the ticket id). If not,
   suggest one. **Working directory:** quote whatever the conventions files say, including any
   worktree workflow they document. Then report the state of this checkout: clean and on the base
   branch, or holding other in-progress work (dirty tree, or a feature branch for a different
   ticket). If it holds other work, say so plainly and flag it as a question for the parent, not
   something you resolve: should this ticket stack on that work or start from the base branch, and
   should it run in a linked worktree or in this checkout.
2. Map the implementation surface **for the requirements above**: the files, symbols, tests, and
   fixtures this work would change or copy, the existing pattern to follow, and what to leave alone.
   Start from the behavior the ticket asks for, not from its id. Separately, and as a footnote, note
   any existing `TEAM-n` references already in the tree.
3. Quote the repo rules an implementing agent must follow for the areas this ticket touches
   (`.cursor/rules`, `CLAUDE.md`, `AGENTS.md`: logging, migrations, security, docs, money, git,
   deps).
4. Excerpt the conventions files enough to draft: branch name, commit messages (types, scopes,
   body/refs rules), PR title, PR body sections, and any PR template
   (`.github/pull_request_template.md`, `.github/PULL_REQUEST_TEMPLATE.md`,
   `.github/PULL_REQUEST_TEMPLATE/`, quote path and headings). Include the team prefix.
5. In-repo spec gaps: read the docs and code this ticket touches: indexes, decision logs, design
   docs, domain docs, findings. Report facts the implementer would otherwise guess: payload shape,
   enums, auth, sequencing, retry/idempotency, policy/UX branches. Verbatim excerpt for each. **List
   paths searched even when nothing was found**: unmeasured is not "no gaps." Anything a doc marks
   unverified or assumed is a gap, not a fact.
6. If the ticket touches comments or committed docs, note existing `TODO(TEAM-n)` patterns in that
   area.

## Return schemas

### Tracker brief (related issues only)

The parent supplies the primary ticket itself, so this brief covers only the related issues it asked
for.

```markdown
## Related issues

For each id the parent asked for:

- id, title, state
- relation to the primary (blocker, related, duplicate, parent)
- condensed requirements that change scope or sequencing for the primary
- whether a blocker is actually done, so the parent knows if it is a real wait
- ambiguities, quoted verbatim, never resolved

## Access

- [tool failures, missing issue]
```

### Repo brief

```markdown
## Git

- current branch, dirty?
- correct for TEAM-n per the conventions? yes/no
- suggested branch if no
- team prefix this repo uses
- working directory: this checkout or a linked worktree, with exact branch commands, and whether
  other in-progress work was found here

## Surface

- files/symbols to change
- pattern to copy (path + name)
- files not to touch
- tests to add/update
- validation commands
- existing TEAM-n refs in repo

## Conventions (excerpts)

- branch / commit rules / PR title+body, quoted, with the file each came from
- PR template path and section headings, if any

## Rules that apply

- [relevant repo rules] one line each

## Spec gaps

For each gap that could change implementation:

- path + heading or symbol
- verbatim excerpt
- why it matters for this ticket (one sentence)

## Paths searched

- [every path/heading checked, including empty ones]

## Gaps

- [what you could not find]
```

### External brief

```markdown
## [source id]

- what was asked, what was found
- verbatim excerpts with URL, path, or call
- primary-source citation for every factual claim
- what remains unverified, stated as unverified rather than omitted

## Access

- [tool failures]
```

## Follow-up scouts

Launch another when:

- A required schema section is missing
- A spec gap lacks a verbatim excerpt
- The plan would need a file/symbol the brief did not name
- Two briefs conflict on a fact (ask for both sources quoted; take the conflict to the user)

Follow-up prompt: quote the exact path, heading, or comment and return the verbatim excerpt only.

A `required: true` source still failing after one retry is a **gate**: ask the user, using that
source's `on_failure` text. Do not plan around the hole.

## Quality bar

The parent can plan without opening files when the briefs include:

- Ticket requirements and blockers (from the paste, or the tracker brief)
- Branch recommendation with evidence from **this** repo's conventions
- Copy-from pattern + test location
- Every in-repo spec gap in full, **or** an explicit search list showing none
- Conventions enough to draft milestone commits and the **Final PR**

A one-line "see the docs" without a path is a failed scout; follow up.
