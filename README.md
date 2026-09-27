# ticket-workflow-skills

Skills for taking a tracker ticket (Linear, Jira) from assigned to PR open, built so the planning
and the implementation can happen in different sessions, or using different agents, without losing
context.

| Skill               | Does                                                                                                                |
| ------------------- | ------------------------------------------------------------------------------------------------------------------- |
| **plan-ticket**     | Researches the ticket with read-only subagents, gates on blockers and missing spec, writes a milestone-grouped plan |
| **build-ticket**    | Executes that plan, one milestone at a time, suggesting commits and a PR                                            |
| **add-ticket-refs** | TODO hygiene: every deferral in committed code owns a real ticket                                                   |

Works in **Claude Code** and **Cursor**, with **any tracker** exposing `PREFIX-number` ids over MCP.
Linear and Jira both qualify.

## The idea

Planning agents usually research two places: the tracker and the current repo. Real teams have more.
Specs in Notion, contracts in a sibling repo, etc.

These skills do not hardcode where to look. Each repo declares its research places in
`.agents/research-sources.md`: what each source holds, when it is worth consulting, how to reach it,
and what a scout must bring back. The planner batches those into parallel read-only subagents and
holds each to its contract. The parent model never browses. It judges briefs, asks you about the
gaps, and writes the plan.

## Install

### Claude Code

Add this repo as a plugin marketplace, then install `ticket-workflow` from it.

### Cursor

```bash
git clone https://github.com/heyJonBray/ticket-workflow-skills
cd ticket-workflow-skills
./install.sh cursor                    # into ~/.cursor/skills
./install.sh repo /path/to/your/repo   # or pin a copy in one repo
```

Cursor will prefer a global skill over a repo-level one, so a stale global can silently win. Use
`repo` when a project should see its own pinned copy.

## Set up a repo

In the repo you want to plan work for:

```bash
/plan-ticket --setup
```

or just ask, "set up plan-ticket for this repo". It asks which tracker MCP to use, confirms the
ticket prefix against a real issue, reads your conventions files, walks through what other places
your team researches, and writes `.agents/research-sources.md`.

Commit that file. It should describe the team's research surface, not one person's setup. To write
it by hand instead, see
[sources-reference.md](plugins/ticket-workflow/skills/plan-ticket/sources-reference.md).

## Use it

```bash
/plan-ticket TEAM-420
/plan-ticket --auto TEAM-420
/build-ticket TEAM-420
```

Paste the issue along with the invocation and the skill uses your paste instead of re-fetching it.

### Guided and auto

`guided` (the default) pauses after each milestone for review. `auto` runs straight through.

Auto drops the **approval** checkpoint only. Validation still runs after every milestone, a failing
validation is still a stop, commits still need an explicit ask, scope still does not expand, and a
fact the plan does not specify still stops the build. Any milestone tagged `**Pause:** required`
stops regardless of mode, so `--auto` stays usable on a ticket with one destructive step in it.

Set a repo default with `default_mode` in the sidecar; an explicit flag always wins. The resolved
mode is written into the plan as a `Mode:` line, which is how `build-ticket` knows how to pace
itself in a later session.

## Layout

```txt
.claude-plugin/marketplace.json     this repo as a plugin marketplace
plugins/ticket-workflow/
  .claude-plugin/plugin.json        the plugin
  skills/
    plan-ticket/
      SKILL.md                      workflow
      scouts.md                     scout contract: dispatch, prompts, return schemas
      template.md                   plan body and the implementing-agent cadence
      sources-reference.md          .agents/research-sources.md field reference
    build-ticket/SKILL.md
    add-ticket-refs/SKILL.md
install.sh                          copy skills into a host or a repo
```

The three skills cross-reference each other with relative paths, so they must stay siblings.

## License

MIT
