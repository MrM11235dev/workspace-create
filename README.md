# workspace-create

Create a VS Code `.code-workspace` file from a list of project directories, in one command.

```sh
workspace-create -f backend ~/code/api ~/code/worker ~/code/shared
```

```
Created /Users/you/backend.code-workspace with 3 folder(s):
  api -> /Users/you/code/api
  worker -> /Users/you/code/worker
  shared -> /Users/you/code/shared
```

```jsonc
// backend.code-workspace
{
	"folders": [
		{ "name": "api",    "path": "code/api" },
		{ "name": "worker", "path": "code/worker" },
		{ "name": "shared", "path": "code/shared" }
	],
	"settings": {}
}
```

A single bash script with no dependencies — it runs on the bash 3.2 that ships with macOS.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/OWNER/workspace-create/main/install.sh | sh
```

GitLab:

```sh
curl -fsSL https://gitlab.com/OWNER/workspace-create/-/raw/main/install.sh | HOST=gitlab sh
```

The executable goes to `~/.local/bin`, which is created if it does not exist. Nothing is
written outside your home directory — no `sudo`, no system directories. If `~/.local/bin`
is not on your `PATH`, the installer prints the line to add.

For a self-hosted GitLab, point `SRC_URL` straight at the raw file:

```sh
curl -fsSL https://git.example.com/you/workspace-create/-/raw/main/install.sh |
  SRC_URL=https://git.example.com/you/workspace-create/-/raw/main/bin/workspace-create sh
```

Prefer to read before you run? Download `install.sh`, look at it, then `sh install.sh`.

### Manual install

```sh
mkdir -p ~/.local/bin
curl -fsSL https://raw.githubusercontent.com/OWNER/workspace-create/main/bin/workspace-create \
  -o ~/.local/bin/workspace-create
chmod +x ~/.local/bin/workspace-create
```

### Uninstall

```sh
rm ~/.local/bin/workspace-create
```

## Usage

```
workspace-create [-f FILENAME] [options] DIR [DIR ...]

  -f, --file FILENAME  Workspace file to write. The .code-workspace extension
                       is appended when missing, and FILENAME may include a
                       directory part. (default: name of the current directory)
  -a, --absolute       Write absolute folder paths instead of paths relative
                       to the workspace file.
  -F, --force          Overwrite FILENAME when it already exists.
  -o, --open           Open the workspace in VS Code after writing it.
  -q, --quiet          Print errors only.
  -h, --help           Show this help.
  -V, --version        Show the version.
```

### Examples

```sh
# Three projects, workspace file written to the current directory
workspace-create -f backend ~/code/api ~/code/worker ~/code/shared

# Every project under ~/code, written to the Desktop with absolute paths
workspace-create -f ~/Desktop/everything -a ~/code/*/

# Create and open straight away
workspace-create -f client --open ../web ../mobile

# Filename defaults to the current directory's name
cd ~/code && workspace-create api worker     # -> ~/code/code.code-workspace
```

## Behaviour worth knowing

- **Relative paths by default.** Folder paths are written relative to the workspace
  file, so the workspace keeps working when the whole tree is moved or cloned
  elsewhere. Use `-a` for absolute paths.
- **Each folder gets a name**, taken from the directory name. When two directories
  share a name, the parent is included (`api/server` vs `web/server`) so they are
  distinguishable in the VS Code explorer.
- **Duplicates are dropped**, after resolving symlinks and `..`, with a note on stdout.
- **Missing directories are an error.** The file is only written once every path has
  been checked, so a typo never leaves a half-written workspace behind.
- **Existing files are never clobbered** without `--force`.

## License

MIT
