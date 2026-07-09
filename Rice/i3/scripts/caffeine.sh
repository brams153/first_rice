#!/bin/bash

STATUS_FILE="/tmp/caffeine_status"

# Inicializar si no existe
if [ ! -f "$STATUS_FILE" ]; then
    echo "OFF" > "$STATUS_FILE"
fi

toggle() {
    if grep -q "OFF" "$STATUS_FILE"; then
        xset s off
        xset -dpms
        echo "ON" > "$STATUS_FILE"
    else
        xset s 600 600
        xset dpms 600 600 600
        echo "OFF" > "$STATUS_FILE"
    fi
    # Forzar la actualización visual inmediata si usas Polybar
    # Si tienes instalado 'polybar-msg', esto hará que el cambio sea instantáneo
    command -v polybar-msg >/dev/null 2>&1 && polybar-msg cmd restart
}
if [[ "$1" == "--toggle" ]]; then
    toggle
else
    # Lectura para la barra
    if grep -q "ON" "$STATUS_FILE"; then
        #echo "☕ ON"
        echo " ON"
    else
        #echo "☕ OFF"
        echo " OFF"

    fi
fi
