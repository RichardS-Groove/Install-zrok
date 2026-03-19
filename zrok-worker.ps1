#Requires -Version 5.1
param([string]$Action = "4")

# Configuración Global
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$INSTALL_V1 = 'C:\zrok'

# --- Utilidades de Salida ---
function ln   { param($t,$c='White') Write-Host $t -ForegroundColor $c }
function ok   { Write-Host '  [OK] ' -ForegroundColor Green  -NoNewline; Write-Host $args[0] }
function warn { Write-Host '  [!]  ' -ForegroundColor Yellow -NoNewline; Write-Host $args[0] }
function err  { Write-Host '  [X]  ' -ForegroundColor Red    -NoNewline; Write-Host $args[0] }
function info { Write-Host '  [>]  ' -ForegroundColor Cyan   -NoNewline; Write-Host $args[0] }
function sep  { Write-Host ('=' * 64) -ForegroundColor DarkCyan }

# --- Funciones de Lógica ---
function Get-VerLine {
    param($exe)
    if (-not (Test-Path $exe)) { return $null }
    $raw = $null
    try { $raw = & $exe version 2>&1 } catch { return $null }
    return ($raw | Where-Object { $_ -match 'v\d+\.\d+' } | Select-Object -First 1)
}

function Find-LocalTar {
    param($pattern, $searchPath)
    $locs = @(
        $searchPath,
        (Join-Path $env:USERPROFILE 'Downloads'),
        (Join-Path $env:USERPROFILE 'Desktop'),
        $env:TEMP
    )
    foreach ($loc in $locs) {
        if (-not (Test-Path $loc)) { continue }
        $f = Get-ChildItem -Path $loc -Filter $pattern -ErrorAction SilentlyContinue |
             Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($f) { return $f.FullName }
    }
    return $null
}

function Add-ToPath {
    param($dir)
    $dirNormal = $dir.TrimEnd('\')
    $up = [Environment]::GetEnvironmentVariable('Path', 'User')
    if ($null -eq $up) { $up = '' }
    
    $exists = $up.Split(';') | Where-Object { $_.TrimEnd('\') -eq $dirNormal }
    if (-not $exists) {
        $tr = $up.TrimEnd(';')
        $np = if ($tr -eq '') { $dirNormal } else { $tr + ';' + $dirNormal }
        [Environment]::SetEnvironmentVariable('Path', $np, 'User')
        ok ($dirNormal + ' agregado al PATH del usuario.')
    } else {
        ok 'PATH ya configurado correctamente.'
    }
    
    if ($env:Path -notlike ('*' + $dirNormal + '*')) {
        $env:Path += ';' + $dirNormal
    }
}

function Remove-FromPath {
    param($dir)
    $dirNormal = $dir.TrimEnd('\')
    $up = [Environment]::GetEnvironmentVariable('Path', 'User')
    if ($null -eq $up) { return }
    $found = $false
    $remainingParts = @()
    foreach ($p in $up.Split(';')) {
        if ($p.TrimEnd('\') -eq $dirNormal) {
            $found = $true
        } elseif ($p.Trim() -ne '') {
            $remainingParts += $p.Trim()
        }
    }
    if ($found) {
        [Environment]::SetEnvironmentVariable('Path', ($remainingParts -join ';'), 'User')
        ok ($dirNormal + ' removido del PATH del usuario.')
    }
}

function Install-Zrok {
    param($pattern, $exeName, $installPath, $label, $forceUpdate=$false, $offlineMode=$false)
    sep
    $title = if($offlineMode){'INSTALACION OFFLINE'} elseif($forceUpdate){'ACTUALIZANDO'} else {'INSTALANDO'}
    ln ('  ' + $title + '  ' + $label) 'Cyan'
    sep
    ln ''
    
    if (-not (Test-Path $installPath)) {
        New-Item -ItemType Directory -Path $installPath -Force | Out-Null
        ok ('Directorio creado: ' + $installPath)
    }
    
    $exePath = Join-Path $installPath $exeName
    $existingExe = Get-ChildItem -Path $installPath -Filter 'zrok*.exe' | Sort-Object Length | Select-Object -First 1
    $curVer = ''
    if ($existingExe) {
        $exePath = $existingExe.FullName
        $cv = Get-VerLine $exePath
        if ($cv) {
            $curVer = $cv.Trim()
            info ('Version actual instalada: ' + $curVer + ' (' + $existingExe.Name + ')')
        } else {
            info ('Sin version previa instalada (o ilegible en ' + $existingExe.Name + ').')
        }
    } else {
        info 'Sin version previa instalada.'
    }
    ln ''
    
    $tarPath = $null
    $version = 'desconocida'
    $release = $null
    
    if (-not $offlineMode) {
        info 'Consultando version en GitHub...'
        try {
            $releases = Invoke-RestMethod -Uri 'https://api.github.com/repos/openziti/zrok/releases' -Headers @{'User-Agent'='zrok-manager'} -ErrorAction Stop
            $release = $releases | Select-Object -First 1
        } catch { 
            warn ('GitHub no accesible: ' + $_.Exception.Message)
            warn 'Sugerencia: Usa la opcion [0] para instalar desde un archivo local.'
        }
    } else {
        info 'Modo OFFLINE activado. Saltando consulta a GitHub.'
    }
    
    if ($release) {
        $version = $release.tag_name
        ok ('Ultima version disponible: ' + $version)
        if ($curVer -and $forceUpdate -and ($curVer -like ('*' + $version.TrimStart('v') + '*'))) {
            warn 'Ya tienes la ultima version instalada.'
            ln ''
            return
        }
        $asset = $release.assets | Where-Object { $_.name -like $pattern } | Select-Object -First 1
        if ($asset) {
            $tarPath = Join-Path $installPath $asset.name
            $mb = [math]::Round($asset.size / 1MB, 1)
            info ('Asset detectado: ' + $asset.name + ' (' + $mb + ' MB)')
            info 'Descargando desde GitHub...'
            try {
                $ProgressPreference = 'SilentlyContinue'
                Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $tarPath -ErrorAction Stop
                $ProgressPreference = 'Continue'
                ok 'Descarga completada.'
            } catch {
                warn ('Descarga fallida: ' + $_.Exception.Message)
                $tarPath = $null
            }
        } else {
            warn 'No se encontro asset compatible en la release de GitHub.'
        }
    }
    
    if (-not $tarPath) {
        info 'Buscando archivo descargado manualmente...'
        $tarPath = Find-LocalTar -pattern $pattern -searchPath $installPath
        if ($tarPath) {
            ok ('Archivo local encontrado: ' + $tarPath)
        }
    }
    
    if (-not $tarPath) {
        $dlFolder = Join-Path $env:USERPROFILE 'Downloads'
        ln ''
        err 'No se encontro el archivo descargado localmente.'
        ln ''
        ln '  === PASOS PARA INSTALAR OFFLINE ===' 'Yellow'
        ln '  1. Descarga el archivo manualmente desde GitHub:' 'White'
        ln '     https://github.com/openziti/zrok/releases' 'Cyan'
        ln ('     -> Busca el archivo que termine en: ' + $pattern) 'DarkGray'
        ln '     -> Nota: zrok2 (v2) suele estar bajo la etiqueta "Pre-release".' 'DarkGray'
        ln ''
        ln '  2. Deja el archivo descargado en tu carpeta de DESCARGAS:' 'White'
        ln ('     ' + $dlFolder) 'Cyan'
        ln ''
        ln '  3. Vuelve a ejecutar esta Opcion [0] en el menu.' 'White'
        ln '     (El sistema detectara el archivo, lo descomprimira y lo movera a C:\zrok)' 'DarkGray'
        ln ''
        try { 
            Start-Process 'https://github.com/openziti/zrok/releases' -ErrorAction SilentlyContinue
            Start-Process $dlFolder -ErrorAction SilentlyContinue 
        } catch {}
        return
    }
    
    if (-not (Get-Command tar -ErrorAction SilentlyContinue)) {
        err 'tar no disponible. Requiere Windows 10 v1803+.'
        return
    }
    
    info ('Extrayendo ' + (Split-Path $tarPath -Leaf) + '...')
    $tmpExt = Join-Path $env:TEMP ('zrok_ext_' + [guid]::NewGuid().ToString().Substring(0,8))
    New-Item -ItemType Directory -Path $tmpExt -Force | Out-Null
    
    $out = tar -xzf $tarPath -C $tmpExt 2>&1
    if ($LASTEXITCODE -ne 0) {
        err ('Error en tar (codigo ' + $LASTEXITCODE + '): ' + $out)
        return
    }
    
    $found = Get-ChildItem -Path $tmpExt -Recurse -Filter 'zrok*.exe' |
             Where-Object { $_.Name -notlike '*uninst*' } |
             Sort-Object { $_.Name.Length } | Select-Object -First 1
    
    if (-not $found) {
        err 'No se encontro ejecutable tras la extraccion.'
        return
    }
    
    $finalExePath = Join-Path $installPath $found.Name
    if (Test-Path $finalExePath) {
        Remove-Item $finalExePath -Force
    }
    if ($existingExe -and $existingExe.Name -ne $found.Name) {
        Remove-Item $existingExe.FullName -Force -ErrorAction SilentlyContinue
    }
    
    Move-Item $found.FullName $finalExePath -Force
    ok ('Binario instalado correctamente en ' + $finalExePath)
    
    if ($tarPath -like ($installPath + '\*')) {
        Remove-Item $tarPath -Force -ErrorAction SilentlyContinue
    }
    Remove-Item -Path $tmpExt -Recurse -Force -ErrorAction SilentlyContinue
    
    Add-ToPath $installPath
    $newVer = Get-VerLine $finalExePath
    
    ln ''
    sep
    if ($newVer) {
        $msg = '  ' + $label + $(if($forceUpdate){' actualizado'} else {' instalado'}) + ' correctamente!'
        ln $msg 'Green'
        ln ('  Version  : ' + $newVer.Trim()) 'Green'
    } else {
        ln ('  ' + $label + ' instalado (abre nueva terminal para validar).') 'Yellow'
    }
    ln ('  Ruta     : ' + $finalExePath) 'Green'
    ln '  PATH     : actualizado para el usuario actual' 'Green'
    ln '  NOTA     : Abre una NUEVA terminal para usar el comando' 'Cyan'
    sep
    ln ''
}

function Uninstall-Zrok {
    param($installPath, $label)
    sep
    ln ('  DESINSTALAR  ' + $label) 'Cyan'
    sep
    ln ''
    if (-not (Test-Path $installPath)) {
        warn ($label + ' no parece estar instalado.')
        return
    }
    
    info 'Cerrando procesos de zrok abiertos...'
    Get-Process -Name "zrok","zrok2" -ErrorAction SilentlyContinue | Stop-Process -Force
    
    Write-Host '  ¿Confirmar desinstalacion completa de ' -NoNewline
    Write-Host $label -ForegroundColor Yellow -NoNewline
    Write-Host '? [S/N]: ' -NoNewline
    $input = Read-Host
    if ($input -notmatch '^[sSyY]') {
        warn 'Operacion cancelada.'
        return
    }
    
    Remove-FromPath $installPath
    try {
        Remove-Item -Path $installPath -Recurse -Force -ErrorAction Stop
        ok ($label + ' desinstalado correctamente.')
    } catch {
        err ('Error al eliminar: ' + $_.Exception.Message)
    }
    ln ''
}

function Show-Status {
    sep
    ln '  COMPROBAR VERSION Y ESTADO' 'Cyan'
    sep
    ln ''
    Write-Host '  zrok local' -ForegroundColor White
    $v = $null
    $existingExe = Get-ChildItem -Path $INSTALL_V1 -Filter 'zrok*.exe' | Sort-Object Length | Select-Object -First 1
    
    if ($existingExe) {
        Write-Host '    Ruta      : ' -NoNewline; Write-Host $existingExe.FullName
        Write-Host '    Estado    : ' -NoNewline
        $vRegex = Get-VerLine $existingExe.FullName
        if ($vRegex) {
            $v = $vRegex.Trim()
            Write-Host ('Instalado  ' + $v) -ForegroundColor Green
        } else {
            Write-Host 'Existe pero no responde' -ForegroundColor Yellow
        }
    } else { 
        Write-Host '    Ruta      : Ninguna'
        Write-Host '    Estado    : ' -NoNewline
        Write-Host 'No instalado' -ForegroundColor DarkGray 
    }
    
    $up = [Environment]::GetEnvironmentVariable('Path', 'User')
    if ($null -eq $up) { $up = '' }
    Write-Host '    PATH      : ' -NoNewline
    if ($up.Split(';') | Where-Object { $_.TrimEnd('\') -eq $INSTALL_V1.TrimEnd('\') }) {
        Write-Host 'Configurado' -ForegroundColor Green
    } else {
        Write-Host 'NO configurado' -ForegroundColor Yellow 
    }
    
    ln ''
    Write-Host '  Buscando actualizaciones...' -ForegroundColor Cyan
    Write-Host '  Ultima release oficial: ' -NoNewline
    $repVer = $null
    try {
        $rels = Invoke-RestMethod -Uri 'https://api.github.com/repos/openziti/zrok/releases' -Headers @{'User-Agent'='zrok-manager'} -ErrorAction Stop
        $repVer = ($rels | Select-Object -First 1).tag_name
        Write-Host $repVer -ForegroundColor White
    } catch {
        Write-Host 'No accesible' -ForegroundColor Yellow
    }
    
    ln ''
    if ($v -and $repVer) {
        if ($v -like ('*' + $repVer.TrimStart('v') + '*')) {
            ln '    -> Sistema al dia.' 'Green'
        } else {
            ln '    -> Actualizacion disponible (Usa opcion 2).' 'Yellow'
        }
    } elseif (-not $v) {
        ln '    -> Zrok no instalado.' 'Yellow'
    }
    ln ''
    sep
}

function Verify-PathSetup {
    sep
    ln '  VERIFICACION INTEGRAL DEL SISTEMA' 'Cyan'
    sep
    ln ''
    
    $okCount = 0
    Write-Host '  1. Carpeta (C:\zrok) : ' -NoNewline
    if (Test-Path $INSTALL_V1) { ln 'OK' 'Green'; $okCount++ } else { ln 'FALTA' 'Red' }
    
    Write-Host '  2. Ejecutable (EXE)  : ' -NoNewline
    $exe = Get-ChildItem -Path $INSTALL_V1 -Filter 'zrok*.exe' -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($exe) { ln ('OK (' + $exe.Name + ')') 'Green'; $okCount++ } else { ln 'FALTA' 'Red' }
    
    Write-Host '  3. PATH (User)       : ' -NoNewline
    $up = [Environment]::GetEnvironmentVariable('Path', 'User')
    if ($up.Split(';') | Where-Object { $_.TrimEnd('\') -eq $INSTALL_V1.TrimEnd('\') }) {
        ln 'OK' 'Green'; $okCount++
    } else {
        ln 'PENDIENTE' 'Yellow'
    }
    
    Write-Host '  4. Sesion actual     : ' -NoNewline
    if ($env:Path.Split(';') | Where-Object { $_.TrimEnd('\') -eq $INSTALL_V1.TrimEnd('\') }) {
        ln 'ACTIVA' 'Green'
    } else {
        ln 'INACTIVA' 'Yellow'
    }
    
    ln ''
    if ($okCount -eq 3) {
        ok 'Sincronizacion correcta.'
    } else {
        err 'Integracion incompleta.'
    }
    ln ''
    sep
}

# --- Punto de Entrada ---
switch ($Action) {
    '1' { Install-Zrok '*windows*amd64*.tar.gz' 'zrok.exe'  $INSTALL_V1 'zrok'          $false $false }
    '2' { Install-Zrok '*windows*amd64*.tar.gz' 'zrok.exe'  $INSTALL_V1 'zrok'          $true  $false }
    'O' { Install-Zrok '*windows*amd64*.tar.gz' 'zrok.exe'  $INSTALL_V1 'zrok'          $false $true  }
    '0' { Install-Zrok '*windows*amd64*.tar.gz' 'zrok.exe'  $INSTALL_V1 'zrok'          $false $true  }
    '3' { Uninstall-Zrok $INSTALL_V1 'zrok' }
    '4' { Show-Status }
    'P' { Verify-PathSetup }
    default { warn ('Accion desconocida: ' + $Action) }
}
