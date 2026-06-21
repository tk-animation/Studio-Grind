param(
  [string]$VaultPath = "C:\Users\victo\OneDrive\Documents\Obsidian Vault\Japanese-Blog",
  [string]$CommitMessage = "Update Obsidian vault content"
)

$ErrorActionPreference = "Stop"
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")

Push-Location $RepoRoot
try {
  & (Join-Path $PSScriptRoot "sync-vault.ps1") -VaultPath $VaultPath

  node --import tsx -e "import('./quartz/plugins/loader/gitLoader.ts').then(m => m.regeneratePluginIndex({ verbose: true }))"
  npx quartz build

  git add content quartz.config.yaml quartz.lock.json package-lock.json package.json .github scripts README.md

  $changes = git status --porcelain
  if (-not $changes) {
    Write-Host "No site changes to publish."
    exit 0
  }

  git commit -m $CommitMessage
  git push
} finally {
  Pop-Location
}
