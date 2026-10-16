#!/usr/bin/env bash
# Connects a TwoBrains developer Mac to the shared ai-memory server.
# Usage: ./onboard.sh                          (prompts for your aim_ key)
#        AI_MEMORY_AUTH_TOKEN=aim_... ./onboard.sh
set -euo pipefail

readonly PINNED_VERSION="3.1.0"
readonly SERVER_URL="${AI_MEMORY_SERVER_URL:-https://memory.twobrainstechnology.com}"
readonly INSTALLER_URL="${AI_MEMORY_INSTALLER_URL:-https://github.com/akitaonrails/ai-memory/releases/download/v${PINNED_VERSION}/install.sh}"

die() { printf 'error: %s\n' "$1" >&2; exit 1; }
info() { printf '==> %s\n' "$1"; }

# Reads from the terminal device, not stdin: in `curl ... | bash` stdin is the script itself.
read_key() {
  local key="${AI_MEMORY_AUTH_TOKEN:-}" tty="${ONBOARD_TTY:-/dev/tty}"
  if [[ -z "$key" ]]; then
    { exec 3<"$tty"; } 2>/dev/null || die "no key: set AI_MEMORY_AUTH_TOKEN or run this script in a terminal"
    printf 'Paste your aim_ key: ' >&2
    IFS= read -rs key <&3 || true
    exec 3<&-
    printf '\n' >&2
  fi
  key="${key//[[:space:]]/}"
  [[ "$key" == aim_* ]] || die "the key must start with aim_ (ask an ai-memory admin for one)"
  printf '%s' "$key"
}

# The key goes to curl through --config on stdin, so it never appears in the process list.
check_identity() {
  local key="$1" body re='"level"[[:space:]]*:[[:space:]]*"user"'
  body="$(printf 'header = "Authorization: Bearer %s"\n' "$key" | curl -fsS --config - "$SERVER_URL/identity")" \
    || die "cannot reach $SERVER_URL/identity with this key (check your network, or ask an admin to verify the key)"
  [[ "$body" =~ $re ]] || die "the server did not accept this as a developer key"
}

installed_version() {
  command -v ai-memory >/dev/null 2>&1 || return 0
  ai-memory --version 2>/dev/null | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' | head -n 1 || true
}

ensure_binary() {
  local current
  current="$(installed_version)"
  if [[ "$current" == "$PINNED_VERSION" ]]; then
    info "ai-memory $PINNED_VERSION is already installed"
    return 0
  fi
  info "installing ai-memory $PINNED_VERSION (found: ${current:-none})"
  curl -fsSL "$INSTALLER_URL" | AI_MEMORY_VERSION="$PINNED_VERSION" sh
  export PATH="$HOME/.local/bin:$PATH"
  hash -r
  [[ "$(installed_version)" == "$PINNED_VERSION" ]] || die "ai-memory $PINNED_VERSION is not on PATH after the install"
}

wire_agents() {
  export AI_MEMORY_SERVER_URL="$SERVER_URL" AI_MEMORY_AUTH_TOKEN="$1"
  info "wiring Claude Code (CLI and Claude Desktop Code tab)"
  ai-memory install-mcp --client claude-code --apply
  ai-memory install-hooks --agent claude-code --capture-mode allowlist --apply
  if command -v codex >/dev/null 2>&1; then
    info "wiring Codex"
    ai-memory install-mcp --client codex --apply
    ai-memory install-hooks --agent codex --capture-mode allowlist --apply
    WIRED_CODEX=1
  fi
  if command -v pi >/dev/null 2>&1; then
    info "wiring Pi"
    ai-memory install-hooks --agent pi --capture-mode allowlist --apply
    WIRED_PI=1
  fi
}

print_next_steps() {
  printf '\nDone. Next steps:\n'
  printf '  - Restart Claude Code and Claude Desktop so they load the ai-memory hooks and MCP server.\n'
  if [[ -n "${WIRED_CODEX:-}" ]]; then
    printf '  - Codex: open Codex, run /hooks and trust the ai-memory hooks.\n'
  fi
  if [[ -n "${WIRED_PI:-}" ]]; then
    printf '  - Pi: restart Pi to load the ai-memory extension.\n'
  fi
  cat <<'EOF'
  - Only repositories with a committed .ai-memory.toml are captured. Check one from its root with:
      printf '{"cwd":"%s"}' "$PWD" | ai-memory hook --event user-prompt-submit --agent claude-code --check-capture
EOF
}

main() {
  [[ "$(uname -s)" == "Darwin" ]] || die "this script is for macOS; on Windows run onboard.ps1"
  local key
  key="$(read_key)"
  check_identity "$key"
  ensure_binary
  wire_agents "$key"
  print_next_steps
}

main "$@"
