# Implementation Guide: Auto-Log CLI Prompts to a File

> **Purpose:** Drop this file into any project. Tell Claude Code: *"Read `PROMPT_LOGGING_HOOK.md` and implement it."*
> The CLI will configure a hook that appends every prompt you submit — with a timestamp — to a log file in the project root. Fully automatic; no manual action per prompt.

---

## What this does

Uses Claude Code's **`UserPromptSubmit`** hook event, which fires every time the user submits a prompt in the CLI. The hook reads the prompt from stdin (JSON), prepends a timestamp, and appends a line to `prompts.log` in the project root.

Result format, one line per prompt:

```
[2026-06-17 08:49:13] the exact text of the prompt the user submitted
```

**Requirements:** `jq` must be installed (`jq --version` to check; `brew install jq` / `apt install jq` if missing).

---

## Implementation steps (for the CLI to perform)

### Step 1 — Locate or create the settings file

- **Project-scoped (logs only this project):** `.claude/settings.json` in the project root.
- **Global (logs prompts in every project):** `~/.claude/settings.json`.

Create the `.claude/` directory and file if they don't exist. If the file already exists, **merge** the `hooks` key below into it — do not overwrite other settings (`model`, `theme`, `mcpServers`, existing hooks, etc.).

### Step 2 — Add the hook

Add this `hooks` block to the settings JSON:

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "jq -r '\"[\\(now | strftime(\"%Y-%m-%d %H:%M:%S\"))] \\(.prompt)\"' >> \"$CLAUDE_PROJECT_DIR/prompts.log\" 2>/dev/null || true"
          }
        ]
      }
    ]
  }
}
```

Notes on the command:
- `$CLAUDE_PROJECT_DIR` is injected by Claude Code and resolves to the project root — the log always lands there regardless of the current working directory.
- `now | strftime(...)` builds the timestamp in **local time**. For UTC, use `(now | strftime(...))` after `gmtime`: replace `now |` with `now | gmtime |`... — actually use `(now - (now % 1) | strflocaltime("%Y-%m-%d %H:%M:%S"))` is unnecessary; the default above is local time and fine for most uses.
- `2>/dev/null || true` ensures the hook never blocks or fails your prompt, even if `jq` is missing.

### Step 3 — Ignore the log in git

Append `prompts.log` to the project's `.gitignore` (create `.gitignore` if absent) so the log is never committed:

```
prompts.log
```

### Step 4 — Tell the user to reload

Hook config changes take effect on the **next session** (or after re-approving hooks). Instruct the user to restart Claude Code once if logging doesn't start immediately.

---

## Verification

After setup, the user submits any prompt, then runs:

```bash
cat prompts.log
```

The submitted prompt should appear as a timestamped line. To watch live in a second terminal:

```bash
tail -f prompts.log
```

---

## Customization options

| Want | Change |
|------|--------|
| Different log location | Change `$CLAUDE_PROJECT_DIR/prompts.log` to any path, e.g. `$CLAUDE_PROJECT_DIR/logs/prompts.log` (ensure the dir exists). |
| Different filename | Replace `prompts.log` throughout. |
| Log across all projects | Put the `hooks` block in `~/.claude/settings.json` instead of project `.claude/settings.json`. |
| JSON-lines format | Replace the `jq` filter with: `jq -c '{ts: now, prompt: .prompt}' >> "$CLAUDE_PROJECT_DIR/prompts.jsonl"` |
| Include session id | The stdin JSON also has `.session_id` and `.cwd` — add them to the `jq` template. |
| UTC timestamps | Use `strflocaltime` → `strftime` with `(now \| gmtime \| strftime("%Y-%m-%d %H:%M:%S"))`. |

---

## Reference: hook input schema

`UserPromptSubmit` hooks receive this JSON on stdin:

```json
{
  "session_id": "abc123",
  "transcript_path": "/path/to/transcript.jsonl",
  "cwd": "/path/to/project",
  "hook_event_name": "UserPromptSubmit",
  "prompt": "the user's submitted text"
}
```

Anything the hook writes to **stdout** is added to the model's context; writing to a file (as above) keeps it out of context. Exit code `0` = allow the prompt through.

---

## Make the log tamper-resistant (append-only)

Goal: the hook can keep appending, but the user who enters prompts cannot edit, truncate, save-over, or delete the log.

> **Reality check:** Unix permissions have no "append-only" *permission bit* — append behavior comes from how the writer opens the file (`>>`), not the file's mode. So `chmod` cannot do this. Use the macOS file flag `chflags`. And note: on a single machine, anyone with the sudo password can ultimately undo any local protection — true tamper-proofing requires shipping logs off-machine.

### Recommended: system append-only flag (`sappnd`) — requires sudo

Set **after** the file exists (submit one prompt first, or `touch prompts.log`):

```bash
sudo chflags sappnd prompts.log
```

- The hook's `>>` appends keep working (append is permitted).
- Editing, truncating, renaming, and deleting are blocked.
- The flag can only be removed with sudo: `sudo chflags nosappnd prompts.log`.
- This is the strongest local option: a user without the sudo password cannot alter or remove the log.

### Lighter alternative: user append-only flag (`uappnd`) — no sudo

```bash
chflags uappnd prompts.log
```

Blocks casual/accidental edits, but the same user can remove it (`chflags nouappnd`). Use only when sudo isn't available.

### Verify the flag is set

```bash
ls -lO prompts.log    # look for "sappnd" (or "uappnd") in the flags column
```

### Strongest: off-machine

For protection even against a local root user, have the hook also append to a remote/append-only store the prompt-enterer cannot reach (logging service, server-side file). Heavier; needs infrastructure.

---

## Uninstall

1. If a file flag was set, remove it first: `sudo chflags nosappnd prompts.log` (or `chflags nouappnd prompts.log`).
2. Remove the `UserPromptSubmit` block from the settings file.
3. Delete `prompts.log`.
