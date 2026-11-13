# My Tiny Mess - petit serveur local pour la version web (Windows).
# Aucune installation : PowerShell est fourni avec Windows.
# Sert le dossier « app » sur http://localhost:8095 et ouvre le navigateur.
param([int]$Port = 8095)

$ErrorActionPreference = 'Stop'
$racine = [IO.Path]::GetFullPath((Join-Path (Split-Path -Parent $PSScriptRoot) 'app'))
$adresse = "http://localhost:$Port/"
$types = @{
  '.html' = 'text/html; charset=utf-8'; '.js' = 'text/javascript'; '.mjs' = 'text/javascript'
  '.json' = 'application/json'; '.wasm' = 'application/wasm'; '.css' = 'text/css'
  '.png' = 'image/png'; '.jpg' = 'image/jpeg'; '.ico' = 'image/x-icon'; '.svg' = 'image/svg+xml'
  '.otf' = 'font/otf'; '.ttf' = 'font/ttf'; '.woff2' = 'font/woff2'; '.txt' = 'text/plain'
}

$ecoute = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $Port)
try {
  $ecoute.Start()
} catch {
  Write-Host "Le port $Port est deja utilise : My Tiny Mess est sans doute deja ouvert."
  Start-Process $adresse
  Start-Sleep -Seconds 3
  exit
}

Write-Host ''
Write-Host '  === My Tiny Mess ==='
Write-Host "  Application ouverte dans le navigateur : $adresse"
Write-Host '  Laissez cette fenetre ouverte pendant l''utilisation.'
Write-Host '  Fermez-la pour arreter l''application.'
Write-Host ''
Start-Process $adresse

while ($true) {
  $client = $ecoute.AcceptTcpClient()
  try {
    $flux = $client.GetStream()
    $lecteur = [System.IO.StreamReader]::new($flux, [Text.Encoding]::ASCII, $false, 8192, $true)
    $requete = $lecteur.ReadLine()
    # On lit (et ignore) les en-tetes jusqu'a la ligne vide.
    while ($true) {
      $ligne = $lecteur.ReadLine()
      if ($null -eq $ligne -or $ligne -eq '') { break }
    }
    if (-not $requete) { continue }
    $chemin = [Uri]::UnescapeDataString((($requete -split ' ')[1] -split '\?')[0])
    if ($chemin -eq '/') { $chemin = '/index.html' }
    $fichier = [IO.Path]::GetFullPath((Join-Path $racine $chemin.TrimStart('/')))
    if (-not $fichier.StartsWith($racine) -or -not (Test-Path -LiteralPath $fichier -PathType Leaf)) {
      $fichier = Join-Path $racine 'index.html'
    }
    $octets = [IO.File]::ReadAllBytes($fichier)
    $type = $types[[IO.Path]::GetExtension($fichier).ToLower()]
    if (-not $type) { $type = 'application/octet-stream' }
    $entete = "HTTP/1.1 200 OK`r`nContent-Type: $type`r`nContent-Length: $($octets.Length)`r`n" +
      "Cache-Control: no-cache`r`nConnection: close`r`n`r`n"
    $e = [Text.Encoding]::ASCII.GetBytes($entete)
    $flux.Write($e, 0, $e.Length)
    $flux.Write($octets, 0, $octets.Length)
    $flux.Flush()
  } catch {
    # Requete interrompue par le navigateur : on passe a la suivante.
  } finally {
    $client.Close()
  }
}
