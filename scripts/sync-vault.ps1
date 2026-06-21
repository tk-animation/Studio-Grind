param(
  [string]$VaultPath = "C:\Users\victo\OneDrive\Documents\Obsidian Vault\Drawing Grind",
  [string]$ContentPath = (Join-Path $PSScriptRoot "..\content")
)

$ErrorActionPreference = "Stop"

$resolvedVault = Resolve-Path -LiteralPath $VaultPath
if (-not (Test-Path -LiteralPath $ContentPath)) {
  New-Item -ItemType Directory -Path $ContentPath -Force | Out-Null
}
$resolvedContent = Resolve-Path -LiteralPath $ContentPath

Write-Host "Syncing Drawing Grind vault:"
Write-Host "  from $resolvedVault"
Write-Host "  to   $resolvedContent"

robocopy $resolvedVault $resolvedContent /MIR /XD ".obsidian" ".trash" ".git" /XF ".DS_Store" "Thumbs.db" "desktop.ini"
$robocopyExit = $LASTEXITCODE
if ($robocopyExit -gt 7) {
  throw "robocopy failed with exit code $robocopyExit"
}

function ConvertTo-Slug([string]$Value) {
  $slug = [System.IO.Path]::GetFileNameWithoutExtension($Value).ToLowerInvariant()
  $slug = $slug -replace "\s+", "-"
  return $slug -replace "[^\p{L}\p{N}.,\-]", ""
}

function Encode-Html([string]$Value) {
  return [System.Net.WebUtility]::HtmlEncode($Value)
}

function Write-Utf8NoBom([string]$Path, [string]$Value) {
  [System.IO.File]::WriteAllText($Path, $Value, [System.Text.UTF8Encoding]::new($false))
}

function Read-Utf8([string]$Path) {
  return [System.IO.File]::ReadAllText($Path, [System.Text.UTF8Encoding]::new($false))
}

function Get-Lessons([string]$Folder) {
  return @(Get-ChildItem -LiteralPath $Folder -Filter "*.md" -File |
    Where-Object { $_.Name -ne "index.md" } |
    Sort-Object Name)
}

function New-LessonCards([array]$Lessons, [string]$Track, [string]$SectionSlug) {
  $cards = foreach ($lesson in $Lessons) {
    $title = [System.IO.Path]::GetFileNameWithoutExtension($lesson.Name)
    $slug = ConvertTo-Slug $lesson.Name
    $label = if ($title -match "^(Level\s+[0-9.]+)") { $Matches[1].TrimEnd(".") } else { "Start here" }
    "<a class=`"lesson-card`" href=`"/$SectionSlug/$slug`"><span>$(Encode-Html $label)</span><strong>$(Encode-Html $title)</strong><small>$(Encode-Html $Track)</small></a>"
  }
  return $cards -join "`r`n"
}

function Add-LessonChrome(
  [System.IO.FileInfo]$Lesson,
  [string]$Track,
  [string]$SectionSlug,
  [string]$PreviousUrl,
  [string]$PreviousTitle,
  [string]$NextUrl,
  [string]$NextTitle
) {
  $title = [System.IO.Path]::GetFileNameWithoutExtension($Lesson.Name)
  $body = Read-Utf8 $Lesson.FullName
  $frontmatter = "---`r`ntitle: `"$title`"`r`ndescription: `"$Track lesson in the Studio Grind curriculum.`"`r`ncssclasses:`r`n  - studio-lesson`r`n---`r`n`r`n"
  $previous = if ($PreviousUrl) { "<a class=`"lesson-nav-link previous`" href=`"$PreviousUrl`"><span>Previous</span><strong>$(Encode-Html $PreviousTitle)</strong></a>" } else { "<span></span>" }
  $next = if ($NextUrl) { "<a class=`"lesson-nav-link next`" href=`"$NextUrl`"><span>Next</span><strong>$(Encode-Html $NextTitle)</strong></a>" } else { "<span></span>" }
  $chrome = "<p class=`"lesson-kicker`">$(Encode-Html $Track)</p>`r`n`r`n"
  $navigation = "`r`n`r`n---`r`n`r`n<nav class=`"lesson-nav`" aria-label=`"Lesson navigation`">$previous<a class=`"lesson-nav-home`" href=`"/$SectionSlug/`">All lessons</a>$next</nav>`r`n"
  Write-Utf8NoBom $Lesson.FullName ($frontmatter + $chrome + $body.Trim() + $navigation)
}

$landingPath = Join-Path $resolvedContent "0. This is a short guide.md"
$landingBody = if (Test-Path -LiteralPath $landingPath) { Read-Utf8 $landingPath } else { "" }
if (Test-Path -LiteralPath $landingPath) {
  Remove-Item -LiteralPath $landingPath -Force
}

$part1Original = Join-Path $resolvedContent "Part 1. Knowing how to draw"
$part2Original = Join-Path $resolvedContent "Part 2. Animation Grind"
$part1Path = Join-Path $resolvedContent "Part 1 Drawing Foundations"
$part2Path = Join-Path $resolvedContent "Part 2 Animation Grind"
Move-Item -LiteralPath $part1Original -Destination $part1Path
Move-Item -LiteralPath $part2Original -Destination $part2Path
$part1Lessons = Get-Lessons $part1Path
$part2Lessons = Get-Lessons $part2Path
$part1Cards = New-LessonCards $part1Lessons "Drawing foundations" "part-1-drawing-foundations"
$part2Cards = New-LessonCards $part2Lessons "Animation practice" "part-2-animation-grind"

$homePage = @"
---
title: Studio Grind
description: A practical drawing and animation curriculum built around intentional practice.
cssclasses:
  - studio-home
---

<section class="studio-hero">
  <div class="studio-hero-copy">
    <h1>Studio Grind</h1>
    <div class="studio-actions">
      <a class="studio-button primary" href="/part-1-drawing-foundations/">Start with drawing</a>
      <a class="studio-button" href="/part-2-animation-grind/">Jump to animation</a>
    </div>
  </div>
</section>

## Before you begin

$($landingBody.Trim())

<section class="curriculum-block">
  <div class="section-heading"><span>Part 1</span><h2>Knowing how to draw</h2><p>Five levels that build construction, perspective, anatomy, light, and visual storytelling.</p></div>
  <div class="lesson-grid">$part1Cards</div>
  <a class="section-link" href="/part-1-drawing-foundations/">View drawing curriculum -&gt;</a>
</section>

<section class="curriculum-block animation-block">
  <div class="section-heading"><span>Part 2</span><h2>Animation Grind</h2><p>A practical ladder from first principles to longer acting and action shots.</p></div>
  <div class="lesson-grid">$part2Cards</div>
  <a class="section-link" href="/part-2-animation-grind/">View animation curriculum -&gt;</a>
</section>

<nav class="utility-links" aria-label="Guide resources">
  <a href="/useful-links">Useful Links <span>References and study material</span></a>
  <a href="/special-thanks">Special Thanks <span>People and guides behind this project</span></a>
</nav>
"@
Write-Utf8NoBom (Join-Path $resolvedContent "index.md") $homePage

$part1Index = @"
---
title: Part 1 - Knowing how to draw
description: Build the visual and technical foundation that makes animation easier.
cssclasses:
  - studio-section
---

<p class="studio-kicker">Part 1 - Drawing foundations</p>

# Knowing how to draw

Build control from simple forms to composition. Follow the levels in order when you want structure, or jump directly to the weakness you need to train.

<div class="lesson-grid section-grid">$part1Cards</div>

<nav class="lesson-nav section-nav" aria-label="Section navigation"><a class="lesson-nav-link previous" href="/"><span>Back</span><strong>Guide home</strong></a><span></span><a class="lesson-nav-link next" href="/part-2-animation-grind/"><span>Next part</span><strong>Animation Grind</strong></a></nav>
"@
Write-Utf8NoBom (Join-Path $part1Path "index.md") $part1Index

$part2Index = @"
---
title: Part 2 - Animation Grind
description: A progressive practice ladder for animation fundamentals, acting, action, and effects.
cssclasses:
  - studio-section
---

<p class="studio-kicker">Part 2 - Animation practice</p>

# Animation Grind

Move from core principles into increasingly demanding exercises. Each level is a prompt, not a cage: repeat it, remix it, and raise the difficulty as your control improves.

<div class="lesson-grid section-grid">$part2Cards</div>

<nav class="lesson-nav section-nav" aria-label="Section navigation"><a class="lesson-nav-link previous" href="/part-1-drawing-foundations/"><span>Previous part</span><strong>Knowing how to draw</strong></a><span></span><a class="lesson-nav-link next" href="/useful-links"><span>Next</span><strong>Useful Links</strong></a></nav>
"@
Write-Utf8NoBom (Join-Path $part2Path "index.md") $part2Index

$sequence = @()
foreach ($lesson in $part1Lessons) {
  $sequence += [pscustomobject]@{ File = $lesson; Track = "Part 1 - Drawing foundations"; Section = "part-1-drawing-foundations" }
}
foreach ($lesson in $part2Lessons) {
  $sequence += [pscustomobject]@{ File = $lesson; Track = "Part 2 - Animation practice"; Section = "part-2-animation-grind" }
}

for ($i = 0; $i -lt $sequence.Count; $i++) {
  $entry = $sequence[$i]
  $previousUrl = $null
  $previousTitle = $null
  $nextUrl = $null
  $nextTitle = $null
  if ($i -gt 0) {
    $previous = $sequence[$i - 1]
    $previousUrl = "/$($previous.Section)/$(ConvertTo-Slug $previous.File.Name)"
    $previousTitle = [System.IO.Path]::GetFileNameWithoutExtension($previous.File.Name)
  }
  if ($i -lt ($sequence.Count - 1)) {
    $next = $sequence[$i + 1]
    $nextUrl = "/$($next.Section)/$(ConvertTo-Slug $next.File.Name)"
    $nextTitle = [System.IO.Path]::GetFileNameWithoutExtension($next.File.Name)
  }
  Add-LessonChrome $entry.File $entry.Track $entry.Section $previousUrl $previousTitle $nextUrl $nextTitle
}

foreach ($utility in @("Useful Links.md", "Special Thanks.md")) {
  $utilityPath = Join-Path $resolvedContent $utility
  if (Test-Path -LiteralPath $utilityPath) {
    $title = [System.IO.Path]::GetFileNameWithoutExtension($utility)
    $body = Read-Utf8 $utilityPath
    $frontmatter = "---`r`ntitle: `"$title`"`r`ncssclasses:`r`n  - studio-utility`r`n---`r`n`r`n"
    Write-Utf8NoBom $utilityPath ($frontmatter + $body.Trim())
  }
}

Write-Host "Vault sync and curriculum generation complete."
