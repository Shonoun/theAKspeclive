# fix-assets.ps1
# Normalizes asset references so nested pages still load shared CSS/JS/images.

$root = $PSScriptRoot
Set-Location $root

$files = Get-ChildItem -Recurse -File -Filter *.html |
  Where-Object { $_.FullName -notmatch '\\\.git\\' }

foreach ($f in $files) {
  $c = Get-Content -Raw $f.FullName
  $o = $c

  # Rootify core CSS/JS (handles ../ prefixes too)
  $c = $c -replace 'href\s*=\s*"(?:\.\./)*nicepage\.css"', 'href="/nicepage.css"'
  $c = $c -replace 'src\s*=\s*"(?:\.\./)*nicepage\.js"', 'src="/nicepage.js"'
  $c = $c -replace 'src\s*=\s*"(?:\.\./)*jquery\.js"',   'src="/jquery.js"'

  # Rootify page-specific CSS (About.css, Team.css, *-Template.css, *-fonts.css)
  $c = $c -replace 'href\s*=\s*"(?:\.\./)*([A-Za-z0-9\-]+(?:-Template)?(?:-fonts)?\.css)"', 'href="/$1"'

  # Favicon & images/assets to absolute
  $c = $c -replace 'href\s*=\s*"(?:\.\./)*images/([^"]+)"',  'href="/images/$1"'
  $c = $c -replace 'src\s*=\s*"(?:\.\./)*(images|img|assets)/([^"]+)"', 'src="/$1/$2"'

  # Fix Nicepage desktop scheme leftovers
  $c = $c -replace 'np://user\.desktop\.nicepage\.com/[^"]*nicepage\.css', '/nicepage.css'

  # Fix intl-tel-input CDN meta path when nested
  $c = $c -replace 'data-intl-tel-input-cdn-path="(?:\.\./)*intlTelInput/?"', 'data-intl-tel-input-cdn-path="/intlTelInput/"'

  if ($c -ne $o) {
# Strip characters that often get mis-decoded as â€‹
$content = $content -replace '[\u200B\u00E2\u20AC\u2039]', ''
    Set-Content -Path $f.FullName -Value $c -Encoding UTF8 -Force
    Write-Host "Assets fixed: $($f.FullName)"
  }
}

Write-Host "fix-assets: done."
