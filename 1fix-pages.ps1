# fix-pages.ps1
# Moves every *.html (except existing index.html) into a same-named subfolder as index.html
# Example: /About.html -> /About/index.html, /blog/post-1.html -> /blog/post-1/index.html

$root = $PSScriptRoot
Set-Location $root

$pages = Get-ChildItem -Recurse -File -Filter *.html |
  Where-Object {
    $_.Name -ne 'index.html' -and
    $_.FullName -notmatch '\\\.git\\'
  }

foreach ($p in $pages) {
  $destDir = Join-Path $p.DirectoryName $($p.BaseName)
  if (-not (Test-Path $destDir)) {
    New-Item -ItemType Directory -Path $destDir | Out-Null
  }
  $dest = Join-Path $destDir 'index.html'
  Write-Host "Move: $($p.FullName) -> $dest"
  Move-Item -Force $p.FullName $dest
}

Write-Host "fix-pages: done."
