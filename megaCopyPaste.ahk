#Requires AutoHotkey v2.0

clips := Map()
global pre_clip := ""

; Le decimos a AHK que vigile el portapapeles todo el tiempo
OnClipboardChange ClipChanged

; Esta función salta sola cada vez que el portapapeles cambia
ClipChanged(DataType) {
    global clips
    
    ; DataType 2 significa que el nuevo contenido es una imagen
    if (DataType == 2) {
        
        ; Aviso visual
        ToolTip("Captura detectada. Pulsa una tecla...")
        
        ih := InputHook("T1")
        ih.Start()
        ih.Wait()
        
        ToolTip() ; Quitamos el aviso
        
        key := ih.Input
        if (key != "") {
            clips[key] := ClipboardAll()
        }
        
        ; Borra la imagen del buffer como querías
        A_Clipboard := ""
    }
}

^c::
{
    global clips, pre_clip

    ; Desactivamos temporalmente el listener de arriba para que no haya 
    ; conflicto si haces Ctrl+C sobre una imagen en un documento
    OnClipboardChange ClipChanged, 0

    ; Guarda todo lo que esté en el portapapeles ahora (texto o imágenes)
    pre_clip := ClipboardAll() 
    A_Clipboard := "" ; Vaciamos para que ClipWait funcione correctamente

    Hotkey("^c", "Off")     ; desactiva la hotkey temporalmente

    Send "^c"               ; ejecuta el copiar real
    ClipWait(0.1)          ; Espera hasta 0.1s por cualquier tipo de dato

    Hotkey("^c", "On")      ; la vuelve a activar

    ih := InputHook("T1") 
    ih.Start()
    ih.Wait()
    
    key := ih.Input
    
    if (key != "")
        clips[key] := ClipboardAll() ; Usamos ClipboardAll() para soportar todo
    
    ; Restauramos el portapapeles a su estado original
    A_Clipboard := pre_clip
    
    ; Volvemos a activar el listener automático
    OnClipboardChange ClipChanged, 1
}

^v::
{
    global clips, pre_clip

    ; 1. APAGAMOS el vigilante para que no detecte nuestros propios cambios
    OnClipboardChange ClipChanged, 0

    ; Guarda TODO lo que está en el portapapeles
    pre_clip := ClipboardAll()

    ; Espera una combinacion de letras como key y la usa para buscar en el map
    ih := InputHook("T1") 
    ih.Start()
    ih.Wait()
    
    key := ih.Input

    ; Buscamos en el map y pasamos al portapapeles
    if (key != "" && clips.Has(key))
    {
        A_Clipboard := clips[key]
        ClipWait(0.1) ; Espera a que el sistema reconozca los nuevos datos binarios
    }

    Hotkey("^v", "Off")     ; desactiva la hotkey temporalmente

    Send "^v"               ; ejecuta el pegar real
    
    ; CRÍTICO: Windows necesita tiempo. 100ms es seguro para imágenes.
    Sleep 100 

    Hotkey("^v", "On")      ; la vuelve a activar

    ; reestablecemos el portapapeles
    A_Clipboard := pre_clip

    ; 2. ENCENDEMOS el vigilante de nuevo una vez que hemos terminado
    OnClipboardChange ClipChanged, 1
}