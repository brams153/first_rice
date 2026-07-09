#!/bin/bash

# Detectar la ruta de la batería
if [ -d /sys/class/power_supply/BAT0 ]; then
    BAT_PATH="/sys/class/power_supply/BAT0"
else
    BAT_PATH="/sys/class/power_supply/BAT1"
fi

CAPACITY=$(cat "$BAT_PATH/capacity")
STATUS=$(cat "$BAT_PATH/status")

# Iconos compatibles con Font Awesome estándar
if [ "$STATUS" = "Charging" ]; then
    ICON="" # Icono de un enchufe (Plug) para carga
else
    if [ "$CAPACITY" -ge 80 ]; then ICON="";
    elif [ "$CAPACITY" -ge 60 ]; then ICON="";
    elif [ "$CAPACITY" -ge 40 ]; then ICON="";
    elif [ "$CAPACITY" -ge 20 ]; then ICON="";
    else ICON=""; fi
fi

# Salida para i3blocks
echo "$ICON $CAPACITY%"
echo "$CAPACITY%"

# Color dinámico
if [ "$CAPACITY" -le 20 ]; then
    echo "#FF0000"
else
    echo "#00FF7F"
fi
