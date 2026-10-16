# TwoBrains ai-memory onboarding

Connects a developer machine to the TwoBrains shared [ai-memory](https://github.com/akitaonrails/ai-memory)
server (`https://memory.twobrainstechnology.com`). You need an API key (`aim_…`) from an ai-memory
admin. No git and no clone are needed.

## macOS

Open Terminal and run:

```bash
curl -fsSL https://raw.githubusercontent.com/twobrains-technology/ai-memory-onboarding/main/onboard.sh | bash
```

## Windows

Open PowerShell (not WSL) and run:

```powershell
irm https://raw.githubusercontent.com/twobrains-technology/ai-memory-onboarding/main/onboard.ps1 | iex
```

Paste your key when asked, then restart Claude Code, Claude Desktop, Codex and Pi.

## What the script does

1. Checks your key with the server before changing anything.
2. Installs the pinned `ai-memory` binary (official release, checksum verified).
3. Connects your agents (Claude Code, plus Codex and Pi on macOS) in **allowlist** mode: only
   repositories with a `.ai-memory.toml` file are captured.

The scripts hold no secrets. They are published copies; the source and its tests live in the
private repository `twobrains-technology/ai-memory` (`twobrains/onboarding/`).

## Remove

```bash
ai-memory uninstall --mcp-url https://memory.twobrainstechnology.com/mcp --apply --yes
```
