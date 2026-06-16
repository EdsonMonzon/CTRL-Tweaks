#Requires AutoHotkey v2.0
#SingleInstance Force

; ==========================================================
; AUTO-INICIO DE WINDOWS
; ==========================================================
nombre_script := StrReplace(A_ScriptName, ".ahk", "")
ruta_inicio := A_Startup "\" nombre_script ".lnk" ; Ruta de auto-inicio de windows
archivo_ignorar := A_ScriptDir "\.no_inicio_" nombre_script ; Archivo invisible para no volver a preguntar

; Cuando se ejecuta por primera vez
if !FileExist(ruta_inicio) && !FileExist(archivo_ignorar) {
    MostrarVentanaInicio()
}

; Ventana de inicio
MostrarVentanaInicio() {
    global ruta_inicio, archivo_ignorar, nombre_script
    
    ; Creamos la ventana
    vent := Gui("-MinimizeBox -MaximizeBox +AlwaysOnTop", "Configuración de " nombre_script)
    
    ; Añadimos el texto, la casilla y los botones
    vent.Add("Text", "w280", "¿Quieres que el programa se inicie automáticamente en segundo plano cada vez que enciendas tu PC?")

    chk := vent.Add("Checkbox", "y+15", "No volver a preguntar")
    
    btnSi := vent.Add("Button", "w80 x60 y+15 Default", "Sí, claro")
    btnSi.OnEvent("Click", (*) => Procesar(vent, "Yes", chk.Value))
    
    btnNo := vent.Add("Button", "w80 x+10", "No, gracias")
    btnNo.OnEvent("Click", (*) => Procesar(vent, "No", chk.Value))
    
    ; Mostramos la ventana
    vent.Show("AutoSize Center")
}

Procesar(vent, respuesta, no_preguntar) {
    global ruta_inicio, archivo_ignorar
    vent.Destroy() ; Cerramos la ventana
    
    ; Si "si" creamos el acceso directo en la carpeta de auto-inicio de windows
    if (respuesta == "Yes") {
        FileCreateShortcut(A_ScriptFullPath, ruta_inicio)
        MsgBox("¡Configurado! Se iniciará con Windows.", "Éxito", "Iconi T2")
    } 
    
    ; Si "si" o "no volver a preguntar" crea el archivo invisible para no volver a aparecer
    if (no_preguntar == 1 || respuesta == "Yes") {
        if !FileExist(archivo_ignorar) {
            FileAppend("", archivo_ignorar)
            FileSetAttrib("+H", archivo_ignorar)
        }
    }
}

; ==========================================================
; CONFIGURACIÓN INICIAL Y CARGA DE DATOS
; ==========================================================
; Se crea la carpeta para almacenar los datos guardados
global clips := Map()
global carpeta_datos := A_ScriptDir "\DataClips"

if !DirExist(carpeta_datos)
    DirCreate(carpeta_datos)

Loop Files, carpeta_datos "\*.bin" {
    nombre_codigo := StrReplace(A_LoopFileName, ".bin", "")
    datos_binarios := ClipboardAll(FileRead(A_LoopFileFullPath, "RAW")) 
    clips[nombre_codigo] := datos_binarios
}

; ==========================================================
; PRESETS DINÁMICOS
; ==========================================================
; Claves con resultados especificos por defecto
ObtenerPreset(codigo) {
    ; Pegar Ipv4 local
    if (codigo == "ipv4") {
        ips := SysGetIPAddresses()
        return ips.Has(1) ? ips[1] : "No hay red local"
    }
    
    ; Pegar Ipv4 publica
    if (codigo == "pubip") {
        try {
            req := ComObject("WinHttp.WinHttpRequest.5.1")
            req.Open("GET", "https://api.ipify.org", true)
            req.Send()
            req.WaitForResponse(2000)
            return req.ResponseText
        } catch {
            return "[Error de red al obtener IPv4]"
        }
    }

    ; Pegar Ipv6 publica
    if (codigo == "ipv6") {
        try {
            req := ComObject("WinHttp.WinHttpRequest.5.1")
            req.Open("GET", "https://api64.ipify.org", true)
            req.Send()
            req.WaitForResponse(2000)
            return req.ResponseText
        } catch {
            return "[Error de red o no tienes IPv6 asignada]"
        }
    }

    ; Pegar fecha de hoy
    if (codigo == "hoy")
        return FormatTime(, "dd/MM/yyyy")

    ; Pegar hora
    if (codigo == "hora")
        return FormatTime(, "HH:mm")

    ; Si no es un codigo preset
    return "" 
}

; ==========================================================
; ATAJO: CAPTURA DE PANTALLA CON CODIGO (CTRL + ALT + S)
; ==========================================================
^!s::
{
    ; Guardamos lo que estaba en el portapapeles para hacer la nueva captura
    global clips, carpeta_datos
    pre_clip := ClipboardAll()
    A_Clipboard := ""

    ; Lanza la herramienta de captura de pantalla
    Send "#+s"
    if !ClipWait(15, 1) {
        A_Clipboard := pre_clip
        return
    }

    ; Espera la clave para guardar la captura
    ToolTip("Captura: Esperando clave...") 
    ih := InputHook("", "{Space}{Enter}{Esc}{Tab}")
    ih.OnChar := (hook, char) => ToolTip("Captura: " hook.Input) 
    ih.KeyOpt("{Backspace}", "N")
    ih.OnKeyDown := (hook, vk, sc) => (vk = 8) ? SetTimer(() => ToolTip("Captura: " hook.Input), -10) : ""
    ih.Start()
    ih.Wait()
    ToolTip() 
    
    ; Si el codigo no esta vacio
    codigo := ih.Input
    if (codigo != "") {
        datos := ClipboardAll()
        clips[codigo] := datos
        FileOpen(carpeta_datos "\" codigo ".bin", "w").RawWrite(datos)
    }

    ; Devolvemos lo que estaba en el portapapeles
    A_Clipboard := pre_clip
}

; ==========================================================
; ATAJO: COPIAR CON CODIGO (CTRL + ALT + C)
; ==========================================================
^!c::
{
    global clips, carpeta_datos
    pre_clip := ClipboardAll()
    A_Clipboard := ""

    Send "^c"
    if !ClipWait(0.5, 1) {
        return
    }

    ToolTip("Copia Especial: Esperando clave...") 
    ih := InputHook("", "{Space}{Enter}{Esc}{Tab}")
    ih.OnChar := (hook, char) => ToolTip("Copia Especial: " hook.Input) 
    ih.KeyOpt("{Backspace}", "N")
    ih.OnKeyDown := (hook, vk, sc) => (vk = 8) ? SetTimer(() => ToolTip("Copia Especial: " hook.Input), -10) : ""
    ih.Start()
    ih.Wait()
    ToolTip() 
    
    codigo := ih.Input
    if (codigo != "") {
        datos := ClipboardAll()
        clips[codigo] := datos
        FileOpen(carpeta_datos "\" codigo ".bin", "w").RawWrite(datos)
    }
    A_Clipboard := pre_clip 
}

; ==========================================================
; ATAJO: PEGAR CON CODIGO (CTRL + ALT + V)
; ==========================================================
^!v::
{
    global clips
    
    ToolTip("Pegar Especial: Escribe clave...") 
    ih := InputHook("", "{Space}{Enter}{Esc}{Tab}")
    ih.OnChar := (hook, char) => ToolTip("Pegar Especial: " hook.Input) 
    ih.KeyOpt("{Backspace}", "N")
    ih.OnKeyDown := (hook, vk, sc) => (vk = 8) ? SetTimer(() => ToolTip("Pegar Especial: " hook.Input), -10) : ""
    ih.Start()
    ih.Wait()
    ToolTip() 
    
    codigo := ih.Input
    
    ; Comprueba los presets
    texto_preset := ObtenerPreset(codigo)
    
    if (texto_preset != "") {
        pre_clip := ClipboardAll()
        A_Clipboard := texto_preset
        Sleep 50
        Send "^v"
        Sleep 100
        A_Clipboard := pre_clip
    }
    ; Comprueba que exista el codigo
    else if (codigo != "" && clips.Has(codigo)) {
        pre_clip := ClipboardAll()
        A_Clipboard := ClipboardAll(clips[codigo])
        Sleep 50
        Send "^v"
        Sleep 100
        A_Clipboard := pre_clip
    } 
    ; Si no esta vacio
    else if (codigo != "") {
        ToolTip("Clave no encontrada")
        SetTimer () => ToolTip(), -1500
    }
}

; Boton de panico
^Esc::ExitApp