# 🚀 Zrok Installer for Windows

[![Powershell](https://img.shields.io/badge/PowerShell-5.1+-blue.svg?style=for-the-badge&logo=powershell)](https://microsoft.com/powershell)
[![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011-lightgrey.svg?style=for-the-badge&logo=windows)](https://www.microsoft.com/windows)
[![License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

Un script de automatización potente y elegante para descargar, instalar y configurar **zrok** en sistemas Windows x64. Olvídate de configuraciones manuales de variables de entorno o extracciones tediosas.

---

## ✨ Características Principales

*   **🔍 Detección Inteligente:** Verifica instalaciones previas y arquitecturas de sistema automáticamente.
*   **🌐 Descarga Automatizada:** Obtiene la última versión directamente desde los releases oficiales de GitHub.
*   **🛠️ Configuración de PATH:** Agrega `zrok` al PATH del usuario de forma persistente.
*   **📦 Manejo de Dependencias:** Utiliza la herramienta nativa `tar` de Windows para extracciones limpias.
*   **🧹 Auto-Limpieza:** Elimina archivos temporales después de una instalación exitosa.

---

## 🚀 Uso Rápido

Para una instalación estándar con descarga automática, ejecuta el siguiente comando en una terminal de PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File zrok.ps1
```

> [!TIP]
> Si deseas forzar una reinstalación aunque ya exista una versión válida, usa el flag `-Force`.

---

## ⚙️ Parámetros Avanzados

El script soporta varios parámetros para personalizar la instalación:

| Parámetro | Descripción | Valor por Defecto |
| :--- | :--- | :--- |
| `-InstallPath` | Ruta donde se instalará zrok. | `C:\zrok` |
| `-Force` | Fuerza la reinstalación y sobreescritura. | `$false` |
| `-TarFile` | Ruta a un archivo `.tar.gz` descargado manualmente. | `""` |

---

## 🛠️ Solución de Problemas (Modo Offline)

Si te encuentras en una red con restricciones que bloquean el acceso a GitHub:

1.  Descarga manualmente el archivo `zrok_X.X.X_windows_amd64.tar.gz` desde los [Releases de zrok](https://github.com/openziti/zrok/releases/latest).
2.  Coloca el archivo en la misma carpeta que el script o dentro de `C:\zrok`.
3.  Vuelve a ejecutar el script; este detectará el archivo local y procederá con la instalación sin necesidad de internet.

---

## 👨‍💻 Créditos

Este script fue desarrollado con pasión y atención al detalle por:

**Richard Campos - PMO**

---

> [!IMPORTANT]
> **Nota:** Después de la instalación, asegúrate de abrir una **nueva ventana de terminal** para que los cambios en el PATH surtan efecto y puedas empezar a usar `zrok` inmediatamente.