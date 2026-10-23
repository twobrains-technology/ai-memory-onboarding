# TwoBrains ai-memory onboarding

Connects a developer machine to the TwoBrains shared [ai-memory](https://github.com/akitaonrails/ai-memory)
server (`https://memory.twobrainstechnology.com`). You need an API key (`aim_…`) from an ai-memory
admin. No git and no clone are needed.

There are two steps: set up your machine once, then onboard each repository you work in.

## 1. Set up your machine

### macOS

Open Terminal and run:

```bash
curl -fsSL https://raw.githubusercontent.com/twobrains-technology/ai-memory-onboarding/main/onboard.sh | bash
```

### Windows

Open PowerShell (not WSL) and run:

```powershell
irm https://raw.githubusercontent.com/twobrains-technology/ai-memory-onboarding/main/onboard.ps1 | iex
```

Paste your key when asked, then restart Claude Code, Claude Desktop, Codex and Pi.

### What the script does

1. Checks your key with the server before changing anything.
2. Installs the pinned `ai-memory` binary (official release, checksum verified).
3. Connects your agents (Claude Code, plus Codex and Pi on macOS) in **allowlist** mode: only
   repositories with a `.ai-memory.toml` file are captured.
4. Installs the `twobrains-onboard-repo` skill for Claude Code (`~/.claude/skills`) and for Codex
   and Pi (`~/.agents/skills`).

## 2. Onboard each repository

Open your agent at the root of a TwoBrains repository and ask:

> configura esse repo na memória do time

The `twobrains-onboard-repo` skill takes it from there. It asks one question at a time:

1. It confirms the repository is TwoBrains work. Repositories of other clients or employers never
   get a marker.
2. It writes `.ai-memory.toml`, with the session brief turned on.
3. It asks which other TwoBrains systems this one relates to, and finds out how from the team memory
   and the code.
4. It shows you a short **Related systems** table. Once you approve it, it saves the table on the
   server as a pinned page of this project, so every later session starts with it.
5. It checks that capture works.

Then commit `.ai-memory.toml` so your teammates are captured too. The skill never commits, and it
never edits `CLAUDE.md` or `AGENTS.md`: relations live on the server, not in the repository.

To add a related system later, ask again. The skill merges the new row with the ones already saved.

## Remove

```bash
ai-memory uninstall --mcp-url https://memory.twobrainstechnology.com/mcp --apply --yes
```

## About these files

| File | Purpose |
|---|---|
| `onboard.sh` | Machine setup for macOS |
| `onboard.ps1` | Machine setup for Windows |
| `skills/twobrains-onboard-repo/SKILL.md` | Agent skill that onboards a repository |

None of them hold secrets. They are published copies; the source and its tests live in the private
repository `twobrains-technology/ai-memory` (`twobrains/onboarding/`).
