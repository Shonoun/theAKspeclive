# fix-links.ps1
# Run from the root of your Nicepage export folder.
# Rewrites internal href/action links to /path/ form, rewrites data-* attributes to path/, and patches sitemap.xml.

Set-Location $PSScriptRoot
Write-Host "Starting fix-links.ps1 in $PSScriptRoot"

# 1) Replace href/action attributes -> absolute /path/
$hrefRegex = [regex] '(?i)(\b(?:href|action)\s*=\s*")(?!(?:https?:\/\/|\/\/|mailto:|tel:))([^"#?"]+?)\.html(?<tail>[#?][^"]*)?"'
Get-ChildItem -Recurse -Filter *.html |
  Where-Object { $_.FullName -notmatch '\\\.git\\' } |
  ForEach-Object {
    $path = $_.FullName
    $content = Get-Content -Raw $path

    $content = $hrefRegex.Replace($content, { param($m)
      $attr = $m.Groups[1].Value
      $p = $m.Groups[2].Value
      $tail = $m.Groups['tail'].Value
      # Normalize away ./ ../
      $p = $p -replace '^(?:\./)+','' -replace '^(?:\.\./)+',''
      if ($p.Length -gt 0 -and $p[0] -ne '/') { $p = '/' + $p }
      return ($attr + $p + '/' + $tail + '"')
    })

    # 2) Replace data-* attributes -> path/ (no leading slash)
    $dataRegex = [regex] '(?i)(\bdata-[a-zA-Z0-9_-]+\s*=\s*")([^"#?"]+?)\.html(?<tail>[#?][^"]*)?"'
    $content = $dataRegex.Replace($content, { param($m)
      $attr = $m.Groups[1].Value
      $p = $m.Groups[2].Value
      $tail = $m.Groups['tail'].Value
      $p = $p -replace '^(?:\./)+','' -replace '^(?:\.\./)+',''
      $p = $p.TrimStart('/')  # data-* should stay without leading slash
      return ($attr + $p + '/' + $tail + '"')
    })

    # 3) Fix product fragment cases like products.html#... -> /products/#...
    $content = $content -replace '(?i)(products)\.html#', '$1/#'

    if ($content -ne (Get-Content -Raw $path)) {
# After all regex replacements
$content = $content -replace "`u200B", ""
Set-Content -Path $path -Value $content -Encoding UTF8 -Force
      Write-Host "Patched: $path"
    }
  }

# 4) Patch sitemap.xml (if present)
$sitemap = Join-Path $PSScriptRoot 'sitemap.xml'
if (Test-Path $sitemap) {
  $s = Get-Content -Raw $sitemap
  # index.html -> root '/'
  $s = $s -replace '(<loc>https?://[^<]*/)index\.html(</loc>)', '$1$2'
  # any other *.html -> /dir/
  $s = $s -replace '(<loc>https?://[^<]*/)([^<"]*?)\.html(</loc>)', '$1$2/$3'
  Set-Content -Path $sitemap -Value $s -Encoding UTF8 -Force
  Write-Host "Patched sitemap.xml"
} else {
  Write-Host "No sitemap.xml found; skipping sitemap patch."
}

Write-Host "fix-links.ps1 complete."
Pause
