---
name: add-ticket-refs
description: >-
  Cites leftover work in code as tracker-backed TODOs (`TODO(TEAM-n):`) and creates follow-up
  tickets when no owner exists. Use when implementing a ticket, leaving TODO/FIXME/HACK, deferring
  work, or putting ticket ids in comments, JSDoc, or committed docs.
---

# Add Ticket Refs

When leaving follow-up in code, use `TODO(TEAM-n): <what must change>`. `TEAM-n` is the **current
repo's** ticket identifier (team prefix + number). Discover the prefix from `CONTRIBUTING.md`,
existing `TODO(` comments, or the live issue in the tracker; never from another project. JSDoc is
fine.

The id must already exist in the tracker. Never invent ids. Never `TODO` the ticket currently being
implemented; finish that work or split a new ticket.

If nothing covers the leftover, create a ticket first (the tracker's MCP if available, otherwise ask
the user). Set `blockedBy` / `blocks` correctly. Cite the file and symbol in the ticket body. Then
add the `TODO`.

## Form

```ts
// TODO(TEAM-n): Exchange the authorization code when live credentials exist.

/**
 * TODO(TEAM-n): Switch to `disabled` | `live`. Omit secrets when disabled.
 */
```

- One id, then a concrete change. Not a status, not a question.
- Line comments and JSDoc both OK.
- No bare `TODO`, `FIXME`, `HACK`, `planned`, or `TBD`.
- Do not use row ids from other systems (vendor Q&A rows, spreadsheet cells, wiki prefixes that are
  not tracker issues) as the TODO identifier. Those belong in those systems, not as the ticket the
  code waits on.

## Which ticket to cite

Cite the **implementation** ticket that will actually do this leftover, not the current ticket, not
a vendor Q&A / research ticket.

| Kind of leftover                                 | Cite                                                    |
| ------------------------------------------------ | ------------------------------------------------------- |
| In-scope for this ticket                         | Do not TODO. Implement it.                              |
| Later engineering work with an existing ticket   | That ticket                                             |
| Later engineering work with no ticket            | Create one, then cite it                                |
| Vendor Q&A, research, ops, hostname registration | Do not TODO in code. Those tickets are not code owners. |

When creating a follow-up, block it on the current ticket (and any other real prerequisites).
Example: current callback work + vendor answers → token-exchange ticket → live HTTP ticket.

## Docs

Do not put ticket ids in committed docs or prose comments. The only in-repo form is
`TODO(TEAM-n): <what must change>` (code, JSDoc, or a markdown leftover line). Row ids from other
systems, for open questions documented elsewhere, are fine **in those systems**, not as the ticket
the code waits on.

Branch names, commit `Refs`, and PR `Fixes` / `Related to` are not comments or docs; those stay per
the repo's CONTRIBUTING.

## Do not

- Invent or guess a ticket number
- Reuse another repo's tracker prefix
- `TODO(current-ticket)` for work this PR is supposed to finish
- Point code TODOs at Q&A tickets
- Leave vault values, empty-string "placeholders", or infra wiring as unowned comments
- Log secrets, auth codes, or tokens in the TODO text
