# 🚀 Zrok Manager for Windows (v2.3)

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue.svg?style=for-the-badge&logo=powershell)](https://microsoft.com/powershell)
[![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011-lightgrey.svg?style=for-the-badge&logo=windows)](https://www.microsoft.com/windows)
[![Zrok](https://img.shields.io/badge/Zrok-v1%20%7C%20v2-orange.svg?style=for-the-badge)](https://zrok.io)

Un gestor robusto y profesional para automatizar la instalación, actualización y gestión de **zrok** (v1) y **zrok2** (v2) en entornos Windows, diseñado para ser resiliente incluso en redes corporativas restringidas.

---

## ✨ Características Principales

*   **🔄 Soporte v1 y v2 Dinámico:** Detecta e instala automáticamente la última versión desde GitHub, soportando plenamente **zrok2** (v2).
*   **🌐 Gestión de Red Inteligente:** Capacidad de detectar bloqueos de red (como en empresas) y ofrecer alternativas de descarga.
*   **📦 Instalación Offline:** Opción dedicada para instalar desde archivos locales si GitHub no es accesible.
*   **🛡️ Arquitectura Segura:** Usa un **VBS Proxy** para ejecutar PowerShell de forma transparente y evitar falsos positivos de antivirus.
*   **🔍 Diagnóstico del "Patch" (PATH):** Herramienta integrada para verificar la correcta integración de zrok en las variables de entorno de Windows.
*   **🛠️ Consola Unificada:** Todo ocurre en una única ventana de comandos, sin aperturas externas molestas.

---

## 🚀 Guía de Opciones del Menú

### `[1] INSTALAR`
Descarga e instala la última versión disponible (v1 o v2) directamente desde GitHub. Configura automáticamente el directorio `C:\zrok` y las variables de entorno.

### `[2] ACTUALIZAR`
Consulta la versión instalada localmente y la compara con la última release oficial. Si existe una actualización, realiza una migración segura preservando tu configuración.

### `[0] OFFLINE (Instalación Manual)`
**Diseñada para entornos con restricciones.** Si GitHub está bloqueado, el script automatiza el proceso:
1.  **Apertura Automática:** Al no hallar el archivo, el script abrirá tu navegador en las releases de GitHub y también tu carpeta de `Descargas`.
2.  **Descarga:** Baja el archivo `*windows*amd64*.tar.gz` (elige la etiqueta "Pre-release" para zrok v2).
3.  **Ubicación:** Deja el archivo en tu carpeta de `Descargas`.
4.  **Procesamiento:** Vuelve a elegir la opción `[0]` y el sistema detectará, extraerá y migrará todo a `C:\zrok` automáticamente.

### `[3] DESINSTALAR`
Realiza un borrado total y limpio:
- Cierra procesos activos para evitar errores de "archivo en uso".
- Elimina el directorio `C:\zrok`.
- **Limpia el PATH** del usuario de forma permanente.

### `[4] COMPROBAR (Estado)`
Muestra un resumen rápido: versión instalada, ubicación del ejecutable y si existe alguna actualización pendiente en GitHub.

### `[P] VERIFICAR PATH`
Realiza un diagnóstico de 4 puntos del sistema:
- Verifica la existencia de la carpeta de instalación.
- Confirma la presencia del binario (`zrok` o `zrok2`).
- Valida la variable de entorno **PATH** del usuario.
- Verifica si la sesión actual reconoce el comando.

### `[R] REPARAR PATH`
**Herramienta de autorecuperación.** Si por accidente borraste tu variable de entorno o `zrok` dejó de ser reconocido, esta opción vuelve a inyectar la ruta `C:\zrok` de forma segura en el PATH de tu usuario sin afectar otras instalaciones.

### `[C] ABRIR CMD`
Abre una nueva ventana de comandos (`cmd.exe`) ubicada en la carpeta del proyecto, lista para ejecutar comandos de zrok.

---

## 🛠️ Estructura del Proyecto

1.  **`zrok-manager.bat`**: Interfaz visual y selector de opciones.
2.  **`zrok-worker.vbs`**: Proxy ligero para una ejecución de PowerShell silenciosa y robusta.
3.  **`zrok-worker.ps1`**: El motor principal que gestiona descargas, extracciones y lógica de sistema.

> [!TIP]
> **Recordatorio:** Al instalar por primera vez, es necesario abrir una **NUEVA terminal** para que Windows reconozca los comandos `zrok` o `zrok2`.

---

## 👨‍💻 Créditos y Autoría

Rediseñado y optimizado para máxima robustez por:

**Richard Campos - PMO**

---

*Desarrollado con ❤️ para la comunidad de zrok.*