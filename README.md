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

The installer also sets up four shell helpers that ship alongside it:

| Command | What it does |
|---|---|
| [`aes_crypt`](#aes_crypt) | AES-256-CBC encrypt/decrypt for files and strings. |
| [`venv_activate`](#venv_activate) | Activate a Python virtualenv by name. **Source-only.** |
| [`custom_dbt_run`](#custom_dbt_run) | Turn dbt model paths into bare model names. |
| [`linting_dbt_models`](#linting_dbt_models) | List your uncommitted `.sql` files for a linter. |

Each one is a single self-contained script that can be run as a command *or*
sourced to define it as a shell function.

## Requirements

| | |
|---|---|
| **Running the tools** | `bash` 3.2 or newer — the version preinstalled on macOS is enough. No `jq`, no `realpath`, no package manager. |
| **Installing** | `curl`, plus a writable `$HOME`. |
| **`--open`** | The `code` command on your `PATH` (VS Code → *Shell Command: Install 'code' command in PATH*). Without `code`, the tool falls back to `open -a "Visual Studio Code"`, which only exists on macOS. |
| **`aes_crypt`** | `openssl`, preinstalled on macOS and on most Linux distributions. |
| **`venv_activate`** | Virtualenvs living under `/Volumes/manoj_ssd/Python_envs`, and a shell that can `source` — so it must be sourced, not run. |
| **`linting_dbt_models`** | `git`, and a working tree to run in. |

Linux and WSL work too, with one caveat: the `--open` fallback has no platform check. On
Linux without `code` on your `PATH`, the workspace file is still written, but the command
then fails with `open: command not found` and exits non-zero.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/MrM11235dev/workspace-create/main/install.sh | sh
```

That installs five commands — `workspace-create`, `aes_crypt`, `venv_activate`,
`custom_dbt_run` and `linting_dbt_models`. They all go to `~/.local/bin`, which is created
if it does not exist. Nothing is written outside your home directory — no `sudo`, no
system directories. If `~/.local/bin` is not on your `PATH`, the installer prints a
ready-to-paste command that appends the export to `~/.zshrc` and runs `exec zsh`. That
line assumes zsh, the macOS default — on bash or fish, point it at your own rc file
instead.

To install only some of them, set `BINS`:

```sh
curl -fsSL https://raw.githubusercontent.com/MrM11235dev/workspace-create/main/install.sh |
  BINS="workspace-create aes_crypt" sh
```

Prefer to read before you run? Download `install.sh`, look at it, then `sh install.sh`.

### Verify

```sh
workspace-create --version      # workspace-create 1.0.0
aes_crypt --version             # aes_crypt 1.0.0
venv_activate --version         # venv_activate 1.0.0
custom_dbt_run --version        # custom_dbt_run 1.1.0
linting_dbt_models --version    # linting_dbt_models 1.0.0
```

Every command also takes `--help`. The installer runs `--version` on each installed
command as its last step, so a successful install ends by printing all five versions.

### Manual install

No installer, one `curl` per command:

```sh
mkdir -p ~/.local/bin
for cmd in workspace-create aes_crypt venv_activate custom_dbt_run linting_dbt_models; do
  curl -fsSL "https://raw.githubusercontent.com/MrM11235dev/workspace-create/main/bin/$cmd" \
    -o "$HOME/.local/bin/$cmd"
  chmod +x "$HOME/.local/bin/$cmd"
done
```

Cloning works as well — every script is self-contained, so symlinking them onto your
`PATH` is enough:

```sh
mkdir -p ~/.local/bin
git clone https://github.com/MrM11235dev/workspace-create.git ~/src/workspace-create
for cmd in workspace-create aes_crypt venv_activate custom_dbt_run linting_dbt_models; do
  ln -sf ~/src/workspace-create/bin/$cmd ~/.local/bin/$cmd
done
```

`git pull` in the clone then updates the commands. Moving the clone breaks the symlinks.

### Use the helpers as shell functions

`aes_crypt`, `venv_activate`, `custom_dbt_run` and `linting_dbt_models` are each written
so that sourcing the file defines the function without running anything. If you would
rather have them in every shell than on your `PATH`:

```sh
for cmd in aes_crypt venv_activate custom_dbt_run linting_dbt_models; do
  echo "source ~/.local/bin/$cmd" >> ~/.zshrc
done
exec zsh
```

For `aes_crypt`, `custom_dbt_run` and `linting_dbt_models`, running them as a command and
sourcing them both work; pick one. **`venv_activate` is the exception — it has to be
sourced.** Activating a virtualenv changes the current shell, so as a command it would
activate inside a subshell that exits immediately. Run that way it refuses and tells you
so rather than appearing to work:

```sh
$ venv_activate myenv
venv_activate: run as a command, this activates a virtualenv in a subshell that exits straight away.
venv_activate: source this file instead, then call it:

  source /Users/you/.local/bin/venv_activate
  venv_activate myenv
```

### Installer options

Set these as environment variables in front of `sh`:

| Variable | Default | Purpose |
|---|---|---|
| `REPO` | `MrM11235dev/workspace-create` | `owner/repo` slug to install from — point it at your own fork. |
| `BRANCH` | `main` | Branch or tag to install. |
| `HOST` | `github` | `github` or `gitlab`. |
| `BINS` | `workspace-create aes_crypt venv_activate custom_dbt_run linting_dbt_models` | Space-separated commands to install. |
| `BASE_URL` | *(derived)* | Raw base URL of the repo at `BRANCH`, bypassing `HOST`/`REPO`/`BRANCH`. Each command is fetched from `$BASE_URL/bin/<name>`. |

Install a tagged release from a fork:

```sh
curl -fsSL https://raw.githubusercontent.com/MrM11235dev/workspace-create/main/install.sh |
  REPO=you/workspace-create BRANCH=v1.0.0 sh
```

GitLab — replace `you` with your namespace in both places:

```sh
curl -fsSL https://gitlab.com/you/workspace-create/-/raw/main/install.sh |
  REPO=you/workspace-create HOST=gitlab sh
```

`HOST` only selects the shape of the URL, so `REPO` has to be set as well. With `HOST`
alone the installer keeps the default slug and tries to download it from GitLab, which
404s.

For a self-hosted GitLab, point `BASE_URL` at the directory the `bin/` folder sits under:

```sh
curl -fsSL https://git.example.com/you/workspace-create/-/raw/main/install.sh |
  BASE_URL=https://git.example.com/you/workspace-create/-/raw/main sh
```

### Update

Re-run the install command. It overwrites each command in `~/.local/bin` in place, via an
atomic rename, so there is nothing to clean up first.

### Uninstall

```sh
cd ~/.local/bin && rm -f workspace-create aes_crypt venv_activate custom_dbt_run linting_dbt_models
```

If you added any `source ~/.local/bin/<command>` lines to your `~/.zshrc`, remove those
too.

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

Every `DIR` must be an existing directory; the workspace is written with one folder entry
per directory, in the order you list them.

`--file=FILENAME` is accepted alongside `-f FILENAME`. For a directory whose name begins
with a dash, prefix it with `./`. A bare `--` is not enough: it ends option parsing, but
the path is then handed to `cd`, which reads the leading dash as its own flags.

```sh
workspace-create -f odd ./-weird-dir ./another
```

The directory part of `-f` must already exist — it is not created for you.

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

# Regenerate an existing workspace after adding a project
workspace-create -F -f backend ~/code/api ~/code/worker ~/code/billing

# Scripted use: say nothing unless something goes wrong
workspace-create -q -f ci ~/code/api ~/code/worker
```

The `~/code/*/` form is a shell glob, not a feature of the tool — the trailing slash makes
your shell expand it to directories only.

### Exit codes

| Code | Meaning |
|---|---|
| `0` | Workspace written. |
| `1` | Error — unknown option, missing directory, non-directory argument, or the output file exists without `--force`. The message goes to stderr. |
| `2` | No directories given. Usage is printed to stderr. |
| other | `--open` was requested and launching VS Code failed — `127` when neither `code` nor `open` is available. The workspace file had already been written at that point. |

## Behaviour worth knowing

- **Relative paths by default.** Folder paths are written relative to the workspace
  file, so the workspace keeps working when the whole tree is moved or cloned
  elsewhere. Use `-a` for absolute paths.
- **Each folder gets a name**, taken from the directory name. When two directories
  share a name, the parent is included (`api/server` vs `web/server`) so they are
  distinguishable in the VS Code explorer.
- **Symlinks are resolved.** Every input is reduced to its physical path, so a path
  through a symlinked directory is recorded as its real location.
- **Duplicates are dropped**, after resolving symlinks and `..`, with a note on stdout.
- **Missing directories are an error.** The file is only written once every path has
  been checked, so a typo never leaves a half-written workspace behind.
- **Existing files are never clobbered** without `--force`.
- **`settings` is left empty.** The tool writes `"settings": {}` and never touches an
  existing file, so any workspace settings you want are yours to add afterwards — but
  remember that regenerating with `--force` replaces the whole file, settings included.

## Troubleshooting

**`workspace-create: command not found` after installing.** `~/.local/bin` is not on your
`PATH`. Add it and reload the shell — zsh, the macOS default:

```sh
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc && exec zsh
```

bash, on most Linux distributions:

```sh
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc && exec bash
```

**`install: downloaded file is not a script — aborting`.** The raw URL returned an HTML
page, usually a 404 — check `REPO` and `BRANCH`, and that the repository is public.

**`already exists (use --force to overwrite)`.** Intentional. Pass `-F` to replace the
file, or `-f` with a different name.

**`--open` fails or exits non-zero.** The `code` command is not on your `PATH` and the
`open -a "Visual Studio Code"` fallback failed — it is macOS-only, and even there it needs
VS Code installed. The workspace file was still written; only the launch failed. Install
the shell command from VS Code's command palette, or drop `-o` and open the file yourself.

## aes_crypt

AES-256-CBC encryption for a file or a string, wrapping `openssl enc` with PBKDF2 key
derivation and a random salt.

```sh
aes_crypt {encrypt|decrypt} [-f <file>] [-t <text>] [-p <password>]
```

| Option | Purpose |
|---|---|
| `-f FILE` | Encrypt `FILE` to `FILE.enc`, or decrypt `FILE` to `FILE.dec`. |
| `-t TEXT` | Encrypt or decrypt `TEXT`, base64, printed to stdout. |
| `-p PASSWORD` | Password to use. Omit it and `openssl` prompts instead. |

Strings:

```sh
$ aes_crypt encrypt -t "hello world"
enter aes-256-cbc encryption password:
U2FsdGVkX19X462I1FAUv71kWAXeP2YXLMt+b0cSTuE=

$ aes_crypt decrypt -t "U2FsdGVkX19X462I1FAUv71kWAXeP2YXLMt+b0cSTuE="
hello world
```

Files — the original is left alone, and the output is a new file alongside it:

```sh
$ aes_crypt encrypt -f notes.txt
Encrypted file written to: notes.txt.enc

$ aes_crypt decrypt -f notes.txt.enc
Decrypted file written to: notes.txt.dec
```

Worth knowing:

- **`-p` leaks the password.** It lands in your shell history and is visible in `ps` to
  anyone else on the machine while `openssl` runs. Leave `-p` off for interactive use and
  let `openssl` prompt; reach for it only in scripts, and ideally from a variable you
  sourced from somewhere safer.
- **A wrong password is not reported as a failure.** `openssl` prints `bad decrypt` to
  stderr, but `aes_crypt` does not check its exit status: with `-f` it still prints
  `Decrypted file written to: ...`, leaves a garbage `.dec` file behind, and exits `0`.
  Read the stderr output rather than the exit code, and check the `.dec` file before
  trusting it.
- **Existing output files are overwritten** without asking.
- **`-f` and `-t` together**: `-f` wins, `-t` is ignored.
- **Round-tripping a file** gives you `notes.txt.dec`, not `notes.txt` — rename it
  yourself if you want the original name back.

## venv_activate

Activate a Python virtualenv by name, from `/Volumes/manoj_ssd/Python_envs`.

```sh
source ~/.local/bin/venv_activate  # once, or from ~/.zshrc
venv_activate myproject            # -> /Volumes/manoj_ssd/Python_envs/myproject/bin/activate
deactivate                         # as usual
```

Worth knowing:

- **It must be sourced**, as [described above](#use-the-helpers-as-shell-functions). Put
  the `source` line in your `~/.zshrc` and it is there in every shell.
- **The envs directory is hardcoded** to `/Volumes/manoj_ssd/Python_envs`. Edit the one
  line in `bin/venv_activate` to point it somewhere else.
- **A name that does not exist** produces the shell's own `no such file or directory` for
  the `activate` script, and leaves the current environment untouched.

## custom_dbt_run

Turn dbt model paths into bare model names — directory and extension stripped — on one
space-separated line, ready to paste into a `--select`.

```sh
$ custom_dbt_run models/marts/orders.sql
orders

$ custom_dbt_run models/marts/orders.sql models/customers.sql
orders customers

$ dbt run --select $(custom_dbt_run models/marts/*.sql)
```

Worth knowing:

- **Names come back in the order you give them**, with no sorting and no de-duplication.
- **Any extension is stripped**, not just `.sql` — `models/schema.yml` gives `schema`, and
  a path with no extension is passed through as-is.
- **It is pure string handling.** Paths are never checked against the filesystem, so a
  typo comes back as a name rather than an error.
- **With no arguments** it prints its usage to stderr and exits `1`.

## linting_dbt_models

List the `.sql` files you have changed but not yet committed, space separated, ready to
hand to a linter.

```sh
$ linting_dbt_models
models/customers.sql models/marts/orders.sql

$ sqlfluff lint $(linting_dbt_models)
$ sqlfluff fix $(linting_dbt_models)
```

Worth knowing:

- **Repo-relative paths**, sorted — unlike `custom_dbt_run`, this one gives you paths, not
  model names. Feed one into the other if you want names:
  `custom_dbt_run $(linting_dbt_models)`.
- **Tracked, unstaged changes only.** It runs `git diff --name-only`, so new untracked
  models are not listed, and neither is anything you have already `git add`ed. Add
  `--cached` or `HEAD` to the `git diff` in `bin/linting_dbt_models` if you want those.
- **A clean tree prints an empty line** and exits `0`.

## License

MIT
