# ================================================================
#  install-zrok.ps1
#  Descarga, instala y configura zrok en Windows 10/11 (x64)
#  Compatible con PowerShell 5.1 (Windows 10/11 por defecto)
#  Uso: powershell -ExecutionPolicy Bypass -File install-zrok.ps1
# ================================================================

#Requires -Version 5.1

[CmdletBinding()]
param(
    [string]$InstallPath = "C:\zrok",
    [switch]$Force
)

# ----------------------------------------------------------------
# Helpers de salida
# ----------------------------------------------------------------
function Write-Step { param($msg) Write-Host "`n[>] $msg" -ForegroundColor Cyan }
function Write-OK   { param($msg) Write-Host "    [OK] $msg" -ForegroundColor Green }
function Write-Warn { param($msg) Write-Host "    [!]  $msg" -ForegroundColor Yellow }
function Write-Fail {
    param($msg)
    Write-Host "`n[ERROR] $msg" -ForegroundColor Red
    exit 1
}

# ----------------------------------------------------------------
# TLS 1.2 (requerido en Windows 10 versiones anteriores)
# ----------------------------------------------------------------
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# ----------------------------------------------------------------
# 1. Verificar instalacion previa
# ----------------------------------------------------------------
Write-Step "Comprobando instalacion previa..."

$existingExe = Join-Path $InstallPath "zrok.exe"

if ((Test-Path $existingExe) -and (-not $Force)) {
    # Intentar ejecutar, pero NO abortar si falla (puede estar corrupto)
    $ver = $null
    try {
        $ver = & $existingExe version 2>&1
    } catch {
        $ver = $null
    }

    if ($LASTEXITCODE -eq 0 -and $ver) {
        Write-Warn "zrok ya esta instalado: $ver"
        Write-Warn "Usa -Force para reinstalar."
        exit 0
    } else {
        Write-Warn "Se encontro zrok.exe pero no es valido o esta corrupto. Reinstalando..."
        Remove-Item $existingExe -Force -ErrorAction SilentlyContinue
    }
}

# ----------------------------------------------------------------
# 2. Detectar arquitectura
# ----------------------------------------------------------------
Write-Step "Detectando arquitectura del sistema..."

$arch = $env:PROCESSOR_ARCHITECTURE
if ($arch -ne "AMD64" -and $arch -ne "EM64T") {
    Write-Fail "Arquitectura no soportada: $arch. Solo se soporta x64 (AMD64)."
}
Write-OK "Arquitectura: $arch"

# ----------------------------------------------------------------
# 3. Obtener la ultima release de GitHub
# ----------------------------------------------------------------
Write-Step "Consultando la ultima version en GitHub..."

try {
    $release = Invoke-RestMethod `
        -Uri "https://api.github.com/repos/openziti/zrok/releases/latest" `
        -Headers @{ "User-Agent" = "zrok-installer-ps1" } `
        -ErrorAction Stop
} catch {
    Write-Fail "No se pudo consultar GitHub: $_"
}

$version = $release.tag_name
Write-OK "Ultima version: $version"

# ----------------------------------------------------------------
# 4. Buscar el asset correcto (.tar.gz para Windows amd64)
# ----------------------------------------------------------------
Write-Step "Buscando binario Windows x64..."

$asset = $release.assets | Where-Object {
    $_.name -like "*windows*" -and
    $_.name -like "*amd64*" -and
    $_.name -like "*.tar.gz"
} | Select-Object -First 1

if (-not $asset) {
    Write-Warn "Assets disponibles en esta release:"
    $release.assets | ForEach-Object { Write-Host "    - $($_.name)" }
    Write-Fail "No se encontro un binario Windows .tar.gz para amd64."
}
Write-OK "Asset encontrado: $($asset.name)"

# ----------------------------------------------------------------
# 5. Preparar directorio de instalacion
# ----------------------------------------------------------------
Write-Step "Preparando directorio $InstallPath..."

try {
    if (-not (Test-Path $InstallPath)) {
        New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
        Write-OK "Directorio creado."
    } else {
        Write-OK "Directorio ya existe."
    }
} catch {
    Write-Fail "No se pudo crear el directorio $InstallPath : $_"
}

# ----------------------------------------------------------------
# 6. Descargar el archivo
# ----------------------------------------------------------------
$tarPath = Join-Path $InstallPath $asset.name
$sizeMB  = [math]::Round($asset.size / 1MB, 1)

Write-Step "Descargando $($asset.name) ($sizeMB MB)..."

try {
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $tarPath -ErrorAction Stop
    $ProgressPreference = 'Continue'
} catch {
    Write-Fail "Error al descargar: $_"
}
Write-OK "Descarga completada."

# ----------------------------------------------------------------
# 7. Verificar que tar este disponible (Win10 v1803+)
# ----------------------------------------------------------------
Write-Step "Verificando herramienta tar..."

$tarCmd = Get-Command tar -ErrorAction SilentlyContinue
if (-not $tarCmd) {
    Write-Fail "El comando 'tar' no esta disponible. Requiere Windows 10 v1803 o superior."
}
Write-OK "tar encontrado: $($tarCmd.Source)"

# ----------------------------------------------------------------
# 8. Extraer el archivo
# ----------------------------------------------------------------
Write-Step "Extrayendo $($asset.name)..."

$tarOutput = tar -xzf $tarPath -C $InstallPath 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Fail "tar fallo (codigo $LASTEXITCODE): $tarOutput"
}
Write-OK "Extraccion completada."

# ----------------------------------------------------------------
# 9. Localizar zrok.exe y moverlo a la raiz si es necesario
# ----------------------------------------------------------------
Write-Step "Localizando zrok.exe..."

$exe = Get-ChildItem -Path $InstallPath -Recurse -Filter "zrok.exe" | Select-Object -First 1

if (-not $exe) {
    Write-Fail "No se encontro zrok.exe tras la extraccion."
}

if ($exe.FullName -ne $existingExe) {
    Move-Item -Path $exe.FullName -Destination $existingExe -Force
    Write-OK "zrok.exe movido a $existingExe"
} else {
    Write-OK "zrok.exe ya estaba en la ruta correcta."
}

# ----------------------------------------------------------------
# 10. Limpiar archivos temporales
# ----------------------------------------------------------------
Write-Step "Limpiando archivos temporales..."

if (Test-Path $tarPath) {
    Remove-Item $tarPath -Force -ErrorAction SilentlyContinue
}

Get-ChildItem -Path $InstallPath -Directory |
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

Write-OK "Limpieza completada."

# ----------------------------------------------------------------
# 11. Agregar al PATH del usuario (persistente, compatible PS 5.1)
# ----------------------------------------------------------------
Write-Step "Configurando PATH del usuario..."

$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($null -eq $userPath) {
    $userPath = ""
}

if ($userPath -notlike "*$InstallPath*") {
    $trimmed = $userPath.TrimEnd(";")
    if ($trimmed -eq "") {
        $newPath = $InstallPath
    } else {
        $newPath = "$trimmed;$InstallPath"
    }
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    Write-OK "$InstallPath agregado al PATH del usuario."
} else {
    Write-OK "$InstallPath ya estaba en el PATH."
}

# Actualizar PATH de la sesion actual
if ($env:Path -notlike "*$InstallPath*") {
    $env:Path = "$env:Path;$InstallPath"
}

# ----------------------------------------------------------------
# 12. Validar instalacion
# ----------------------------------------------------------------
Write-Step "Validando instalacion..."

if (Test-Path $existingExe) {
    $verOutput = $null
    try {
        $verOutput = & $existingExe version 2>&1
    } catch {
        $verOutput = $null
    }
    if ($LASTEXITCODE -eq 0 -and $verOutput) {
        Write-OK "$verOutput"
    } else {
        Write-Warn "zrok.exe no respondio correctamente. Puede requerir reinicar la terminal."
    }
} else {
    Write-Warn "No se encontro $existingExe para validar."
}

# ----------------------------------------------------------------
# 13. Resumen final
# ----------------------------------------------------------------
Write-Host ""
Write-Host "================================================" -ForegroundColor Green
Write-Host "  zrok $version instalado correctamente"         -ForegroundColor Green
Write-Host "  Ruta     : $existingExe"                       -ForegroundColor Green
Write-Host "  PATH     : actualizado para el usuario actual" -ForegroundColor Green
Write-Host "  NOTA     : Abre una nueva terminal para usar zrok" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Host ""