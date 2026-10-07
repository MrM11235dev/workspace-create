#!/bin/sh
#
# Installer for workspace-create.
#
#   curl -fsSL https://raw.githubusercontent.com/MrM11235dev/workspace-create/main/install.sh | sh
#
# Always installs to ~/.local/bin, creating it when missing. Nothing is written
# outside your home directory, so no sudo and no system directories.
#
# Environment overrides:
#   REPO         owner/repo slug            (default: the REPO set below)
#   BRANCH       branch or tag to install   (default: main)
#   HOST         github | gitlab            (default: github)
#   SRC_URL      full URL of the script, bypassing HOST/REPO/BRANCH
#                (for self-hosted GitLab and the like)

set -eu

REPO="${REPO:-MrM11235dev/workspace-create}"
# -----------------------------------------------------------------------------
BRANCH="${BRANCH:-main}"
HOST="${HOST:-github}"
BIN_NAME="workspace-create"

if [ -z "${SRC_URL:-}" ]; then
	case "$REPO" in
		OWNER/*)
			printf 'install: REPO is still set to the placeholder "%s".\n' "$REPO" >&2
			printf '         Edit install.sh, or run: REPO=you/workspace-create sh install.sh\n' >&2
			exit 1
			;;
	esac

	case "$HOST" in
		github) SRC_URL="https://raw.githubusercontent.com/$REPO/$BRANCH/bin/$BIN_NAME" ;;
		gitlab) SRC_URL="https://gitlab.com/$REPO/-/raw/$BRANCH/bin/$BIN_NAME" ;;
		*) printf 'install: unknown HOST "%s" (expected github or gitlab)\n' "$HOST" >&2; exit 1 ;;
	esac
fi

[ -n "${HOME:-}" ] || { printf 'install: HOME is not set\n' >&2; exit 1; }
target_dir="$HOME/.local/bin"

mkdir -p "$target_dir"

# Stage inside the target directory so the final move is an atomic rename on
# the same filesystem, and so nothing is written outside the home directory.
tmp=$(mktemp "$target_dir/.$BIN_NAME.XXXXXX")
trap 'rm -f "$tmp"' EXIT INT TERM

printf 'Downloading %s...\n' "$SRC_URL"
if ! curl -fsSL "$SRC_URL" -o "$tmp"; then
	printf 'install: download failed (check REPO/BRANCH and that the repo is public)\n' >&2
	exit 1
fi

# Make sure we fetched a script and not an HTML error page.
if ! head -n 1 "$tmp" | grep -q '^#!'; then
	printf 'install: downloaded file is not a script — aborting\n' >&2
	exit 1
fi

chmod 755 "$tmp"
mv "$tmp" "$target_dir/$BIN_NAME"
trap - EXIT INT TERM

printf 'Installed %s to %s\n' "$BIN_NAME" "$target_dir/$BIN_NAME"

case ":$PATH:" in
	*":$target_dir:"*) ;;
	*)
		printf '\n%s is not on your PATH. Add it with:\n\n' "$target_dir"
		printf '  echo '\''export PATH="%s:$PATH"'\'' >> ~/.zshrc && exec zsh\n\n' "$target_dir"
		;;
esac

"$target_dir/$BIN_NAME" --version
