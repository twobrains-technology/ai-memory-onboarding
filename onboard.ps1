#Requires -Version 5.1
<#
.SYNOPSIS
  Connects a TwoBrains developer Windows machine to the shared ai-memory server.
.DESCRIPTION
  Run from Windows PowerShell or PowerShell 7 (not inside WSL):
    powershell -ExecutionPolicy Bypass -File .\onboard.ps1
  Set $env:AI_MEMORY_AUTH_TOKEN first to skip the key prompt.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$script:PinnedVersion = '3.1.0'

function Get-ServerUrl {
    if ($env:AI_MEMORY_SERVER_URL) { return $env:AI_MEMORY_SERVER_URL }
    return 'https://memory.twobrainstechnology.com'
}

function Get-InstallerUrl {
    if ($env:AI_MEMORY_INSTALLER_URL) { return $env:AI_MEMORY_INSTALLER_URL }
    return "https://github.com/akitaonrails/ai-memory/releases/download/v$($script:PinnedVersion)/install.ps1"
}

function Read-AimKey {
    $key = $env:AI_MEMORY_AUTH_TOKEN
    if (-not $key) {
        $secure = Read-Host -Prompt 'Paste your aim_ key' -AsSecureString
        $key = [System.Net.NetworkCredential]::new('', $secure).Password
    }
    $key = $key -replace '\s', ''
    if (-not $key.StartsWith('aim_')) {
        throw 'The key must start with aim_ (ask an ai-memory admin for one).'
    }
    return $key
}

function Test-ServerIdentity {
    param([Parameter(Mandatory)][string]$Key)
    $url = "$(Get-ServerUrl)/identity"
    try {
        $identity = Invoke-RestMethod -Uri $url -Headers @{ Authorization = "Bearer $Key" }
    } catch {
        throw "Cannot reach $url with this key (check your network, or ask an admin to verify the key)."
    }
    if ($identity.level -ne 'user') {
        throw 'The server did not accept this as a developer key.'
    }
}

function Get-InstalledVersion {
    if (-not (Get-Command ai-memory -ErrorAction SilentlyContinue)) { return $null }
    $out = & ai-memory --version 2>$null
    if ("$out" -match '(\d+\.\d+\.\d+)') { return $Matches[1] }
    return $null
}

function Invoke-AiMemoryInstaller {
    param([Parameter(Mandatory)][string]$Version, [Parameter(Mandatory)][string]$Url)
    $env:AI_MEMORY_VERSION = $Version
    try {
        Invoke-Expression (Invoke-RestMethod -Uri $Url)
    } finally {
        Remove-Item Env:AI_MEMORY_VERSION -ErrorAction SilentlyContinue
    }
    $env:Path = "$env:LOCALAPPDATA\Programs\ai-memory;$env:Path"
}

function Invoke-AiMemory {
    param([Parameter(Mandatory)][string[]]$Arguments)
    & ai-memory @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "ai-memory $($Arguments -join ' ') failed with exit code $LASTEXITCODE."
    }
}

function Invoke-Onboarding {
    $key = Read-AimKey
    Test-ServerIdentity -Key $key

    $current = Get-InstalledVersion
    if ($current -eq $script:PinnedVersion) {
        Write-Host "==> ai-memory $($script:PinnedVersion) is already installed"
    } else {
        $found = if ($current) { $current } else { 'none' }
        Write-Host "==> installing ai-memory $($script:PinnedVersion) (found: $found)"
        Invoke-AiMemoryInstaller -Version $script:PinnedVersion -Url (Get-InstallerUrl)
        if ((Get-InstalledVersion) -ne $script:PinnedVersion) {
            throw "ai-memory $($script:PinnedVersion) is not on PATH after the install."
        }
    }

    $env:AI_MEMORY_SERVER_URL = Get-ServerUrl
    $env:AI_MEMORY_AUTH_TOKEN = $key
    Write-Host '==> wiring Claude Code (CLI and Claude Desktop Code tab)'
    Invoke-AiMemory -Arguments @('install-mcp', '--client', 'claude-code', '--apply')
    Invoke-AiMemory -Arguments @('install-hooks', '--agent', 'claude-code', '--capture-mode', 'allowlist', '--apply')

    Write-Host @'

Done. Next steps:
  - Restart Claude Code and Claude Desktop so they load the ai-memory hooks and MCP server.
  - Only repositories with a committed .ai-memory.toml are captured. Check one from its root with:
      @{ cwd = $PWD.Path } | ConvertTo-Json -Compress | ai-memory hook --event user-prompt-submit --agent claude-code --check-capture
'@
}

if ($MyInvocation.InvocationName -ne '.') { Invoke-Onboarding }
