# Studio Grind

Quartz site generated from the Obsidian vault at:

```text
C:\Users\victo\OneDrive\Documents\Obsidian Vault\Drawing Grind
```

## Preview

```powershell
.\scripts\sync-vault.ps1
npx quartz build --serve
```

## Publish

```powershell
.\scripts\publish-static-pages.ps1
```

The publisher syncs the vault, regenerates the curriculum pages, builds Quartz, and pushes the static site to `gh-pages`.

Set GitHub Pages to **Deploy from a branch**, branch `gh-pages`, folder `/ (root)`.

## Obsidian hotkey

Use the Shell Commands community plugin with:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Users\victo\Documents\TK-Disk\studio-grind-quartz\scripts\publish-static-pages.ps1"
```

Suggested hotkey: `Ctrl+Alt+G`.
