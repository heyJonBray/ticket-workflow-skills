#!/usr/bin/env bash
# Install the ticket-workflow skills.
#
#   ./install.sh                  # both global host dirs, whichever exist
#   ./install.sh cursor           # ~/.cursor/skills only
#   ./install.sh claude           # ~/.claude/skills only
#   ./install.sh repo <path>      # <path>/.cursor/skills only, no global install
#
# Use `repo` when a project should see its own pinned copy and you do not want
# a global copy shadowing it: Cursor prefers a global skill over the repo one,
# so a stale global silently wins.
#
# Skills are copied as siblings so their relative links keep resolving.
# Cursor users: this also keeps `sync-skill <name> <repo>` working, since it
# reads from ~/.cursor/skills.

set -euo pipefail

src="$(cd "$(dirname "${BASH_SOURCE[0]}")/plugins/ticket-workflow/skills" && pwd)"
targets=()

case "${1:-both}" in
	cursor) targets=("$HOME/.cursor/skills") ;;
	claude) targets=("$HOME/.claude/skills") ;;
	both) targets=("$HOME/.cursor/skills" "$HOME/.claude/skills") ;;
	repo)
		repo_raw="${2:-}"
		[[ -n "$repo_raw" ]] || {
			echo "usage: install.sh repo <path-to-repo>" >&2
			exit 1
		}
		repo_root="${repo_raw/#\~/$HOME}"
		repo_root="$(cd "$repo_root" 2>/dev/null && pwd)" || {
			echo "install.sh: not a directory: $repo_raw" >&2
			exit 1
		}
		targets=("$repo_root/.cursor/skills")
		;;
	*)
		echo "usage: install.sh [cursor|claude|both] | install.sh repo <path>" >&2
		exit 1
		;;
esac

installed=0
for dest in "${targets[@]}"; do
	parent="$(dirname "$dest")"
	if [[ ! -d "$parent" && "${1:-both}" != "repo" ]]; then
		echo "skip: $parent does not exist (host not installed?)"
		continue
	fi
	mkdir -p "$dest"
	for skill in "$src"/*/; do
		name="$(basename "$skill")"
		if command -v rsync >/dev/null 2>&1; then
			rsync -a --delete "$skill" "$dest/$name/"
		else
			rm -rf "${dest:?}/$name"
			cp -R "$skill" "$dest/$name"
		fi
		echo "installed $name -> $dest/$name"
	done
	installed=1
done

[[ $installed -eq 1 ]] || {
	echo "nothing installed" >&2
	exit 1
}
