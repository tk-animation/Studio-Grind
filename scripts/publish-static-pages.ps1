param(
  [string]$VaultPath = "C:\Users\victo\OneDrive\Documents\Obsidian Vault\Drawing Grind",
  [string]$CommitMessage = "Deploy Studio Grind"
)

$ErrorActionPreference = "Stop"
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$Parent = Split-Path $RepoRoot
$PagesWorktree = Join-Path $Parent "studio-grind-quartz-gh-pages"

function Invoke-SafeGit {
  param(
    [string]$SafeDirectory,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$GitArgs
  )

  & git -c "safe.directory=$SafeDirectory" @GitArgs
  if ($LASTEXITCODE -ne 0) {
    throw "git $($GitArgs -join ' ') failed with exit code $LASTEXITCODE"
  }
}

Push-Location $RepoRoot
try {
  & (Join-Path $PSScriptRoot "sync-vault.ps1") -VaultPath $VaultPath

  Invoke-SafeGit -SafeDirectory $RepoRoot -GitArgs @("add", "content")
  $sourceChanges = Invoke-SafeGit -SafeDirectory $RepoRoot -GitArgs @("status", "--porcelain", "content")
  if ($sourceChanges) {
    Invoke-SafeGit -SafeDirectory $RepoRoot -GitArgs @("commit", "-m", "Sync Drawing Grind vault")
    Invoke-SafeGit -SafeDirectory $RepoRoot -GitArgs @("push", "origin", "v5")
  }

  node --import tsx -e "import('./quartz/plugins/loader/gitLoader.ts').then(m => m.regeneratePluginIndex({ verbose: true }))"
  node quartz/bootstrap-cli.mjs build

  if (-not (Test-Path -LiteralPath $PagesWorktree)) {
    Invoke-SafeGit -SafeDirectory $RepoRoot -GitArgs @("worktree", "add", "-B", "gh-pages", $PagesWorktree)
  }

  $resolvedWorktree = (Resolve-Path -LiteralPath $PagesWorktree).Path
  if (-not ($resolvedWorktree.StartsWith($Parent, [System.StringComparison]::OrdinalIgnoreCase))) {
    throw "Refusing to clean unexpected worktree path: $resolvedWorktree"
  }

  Get-ChildItem -LiteralPath $resolvedWorktree -Force |
    Where-Object { $_.Name -ne ".git" } |
    Remove-Item -Recurse -Force

  robocopy (Join-Path $RepoRoot "public") $resolvedWorktree /E /XD ".git"
  $robocopyExit = $LASTEXITCODE
  if ($robocopyExit -gt 7) {
    throw "robocopy failed with exit code $robocopyExit"
  }

  New-Item -ItemType File -Path (Join-Path $resolvedWorktree ".nojekyll") -Force | Out-Null

  Invoke-SafeGit -SafeDirectory $resolvedWorktree -GitArgs @("-C", $resolvedWorktree, "add", "-A")
  $changes = Invoke-SafeGit -SafeDirectory $resolvedWorktree -GitArgs @("-C", $resolvedWorktree, "status", "--porcelain")
  if (-not $changes) {
    Write-Host "No static site changes to publish."
    exit 0
  }

  Invoke-SafeGit -SafeDirectory $resolvedWorktree -GitArgs @("-C", $resolvedWorktree, "commit", "-m", $CommitMessage)
  Invoke-SafeGit -SafeDirectory $resolvedWorktree -GitArgs @("-C", $resolvedWorktree, "push", "-u", "origin", "gh-pages")
} finally {
  Pop-Location
}
