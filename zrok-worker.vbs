' ================================================================
'  zrok-worker.vbs
'  Worker Proxy - llamado por zrok-manager.bat
'  (Modificado para evitar falsos positivos del Antivirus)
' ================================================================
Option Explicit

Dim oShell, sAction, ps1Path
Set oShell = CreateObject("WScript.Shell")

sAction = "4"
If WScript.Arguments.Count > 0 Then
    sAction = WScript.Arguments(0)
End If

' Construir la ruta al archivo .ps1 que se encuentra en la misma carpeta
ps1Path = Replace(WScript.ScriptFullName, WScript.ScriptName, "") & "zrok-worker.ps1"

' Ejecutar el script PowerShell real
oShell.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -File """ & ps1Path & """ -Action " & sAction, 1, True

WScript.Echo ""
WScript.Echo " [NOTA] Tarea completada. Presiona cualquier tecla para continuar si se te solicita."
