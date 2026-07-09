#!/bin/bash

# Directorios de fondos adaptados a tu estructura
STATIC_WALLPAPER_DIR="$HOME/Pictures/Fondos"
LIVE_WALLPAPER_DIR="$HOME/Pictures/Fondos/Live"
sddm_theme="catppuccin-mocha"

# Crear directorios clave si no existen
mkdir -p "$STATIC_WALLPAPER_DIR" "$LIVE_WALLPAPER_DIR"

# Caché de miniaturas
THUMB_DIR="$HOME/.cache/wallpaper_thumbs"
mkdir -p "$THUMB_DIR"

# Archivo de mapeo temporal persistente para esta sesión del script
MAPPING_FILE="/tmp/wallpaper_mapping_$$"
> "$MAPPING_FILE"

# Tema de Rofi
ROFI_THEME="$HOME/.config/rofi/wall-selector.rasi"

# Comprobar programas requeridos para i3/X11
for cmd in feh rofi wallust ffmpeg; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "$cmd no está instalado. Por favor instálalo."
        exit 1
    fi
done

# Check para ImageMagick
if ! command -v convert &>/dev/null && ! command -v magick &>/dev/null; then
    echo "ImageMagick es requerido para la generación de miniaturas."
    exit 1
fi

convert_cmd=$(command -v convert || command -v magick)

generate_thumbnails() {
    for dir in "$STATIC_WALLPAPER_DIR" "$LIVE_WALLPAPER_DIR"; do
        [ -d "$dir" ] || continue
        for ext in jpg jpeg png webp bmp gif mp4 mkv; do
            shopt -s nullglob
            for img in "$dir"/*."$ext"; do
                [ -f "$img" ] || continue
                filename=$(basename "$img")
                name="${filename%.*}"
                thumb_path="$THUMB_DIR/${name}_thumb.png"

                if [ ! -f "$thumb_path" ] || [ "$img" -nt "$thumb_path" ]; then
                    if [[ "$img" =~ \.(mp4|mkv)$ ]]; then
                        ffmpeg -i "$img" -vf "scale=500:500" -vframes 1 "$thumb_path" -y 2>/dev/null
                    else
                        "$convert_cmd" "$img[0]" -strip -thumbnail 500x500^ -gravity center -extent 500x500 "$thumb_path" 2>/dev/null
                    fi
                fi
            done
            shopt -u nullglob
        done
    done
}

create_rofi_entries() {
    for dir_type in static live; do
        dir_var="${dir_type^^}_WALLPAPER_DIR"
        dir="${!dir_var}"
        [ -d "$dir" ] || continue

        for ext in jpg jpeg png webp bmp gif mp4 mkv; do
            shopt -s nullglob
            for img in "$dir"/*."$ext"; do
                [ -f "$img" ] || continue
                filename=$(basename "$img")
                name="${filename%.*}"
                label="$name"
                [ "$dir_type" = "live" ] && label="[Live] $name"
                thumb="$THUMB_DIR/${name}_thumb.png"

                # Guardar mapeo real antes de que Rofi filtre
                echo "$label|$img|$dir_type" >> "$MAPPING_FILE"

                if [ -f "$thumb" ]; then
                    echo -e "$label\x00icon\x1f$thumb"
                else
                    echo "$label"
                fi
            done
            shopt -u nullglob
        done
    done
}

# Generar miniaturas antes de abrir la interfaz
generate_thumbnails

# Ejecutar Rofi y capturar la selección
if [ -f "$ROFI_THEME" ]; then
    selection=$(create_rofi_entries | rofi -dmenu -i \
        -p "󰸉 Fondo:" \
        -show-icons \
        -theme "$ROFI_THEME")
else
    selection=$(create_rofi_entries | rofi -dmenu -i \
        -p "󰸉 Fondo:" \
        -show-icons \
        -theme-str 'window { width: 250px; height: 600px; location: east; anchor: east; } listview { columns: 1; lines: 4; } element { orientation: vertical; } element-icon { size: 120px; horizontal-align: 0.5; }')
fi

# Si no se seleccionó nada, limpiar y salir
if [ -z "$selection" ]; then
    rm -f "$MAPPING_FILE"
    exit 0
fi

# Leer la ruta real desde el mapeo temporal generado
selected_line=$(grep -F "$selection" "$MAPPING_FILE" | head -n 1)
rm -f "$MAPPING_FILE"

IFS='|' read -r _ selected_path type <<< "$selected_line"

if [ -f "$selected_path" ]; then
    # Matar procesos de fondos animados anteriores si existen
    killall xwinwrap mpv &>/dev/null

    if [ "$type" = "static" ]; then
        # Aplicar fondo estático en X11 usando feh
        feh --bg-fill "$selected_path"
        cp "$selected_path" "$HOME/.cache/wall"

        # Notificar cambio
        if command -v dunstify &>/dev/null; then
            dunstify -i "$HOME/.cache/wall" -u low "Fondo Cambiado" "Fondo: $(basename "$selected_path")"
        fi

        # Procesamiento de imágenes para el entorno
        "$convert_cmd" "$selected_path"[0] -strip -thumbnail 500x500^ -gravity center -extent 500x500 "$HOME/.cache/wall.sqre" 2>/dev/null
        "$convert_cmd" "$selected_path"[0] -strip -scale 10% -blur 0x3 -resize 100% "$HOME/.cache/wall.blur" 2>/dev/null
    else
        # Fondo animado usando xwinwrap + mpv
        if command -v xwinwrap &>/dev/null && command -v mpv &>/dev/null; then
            xwinwrap -ov -g 1920x1080 -- mpv -wid WID --wid=WID --loop --no-audio --panscan=1.0 --vo=gpu "$selected_path" &
        fi

        ffmpeg -y -i "$selected_path" -ss 00:00:01.000 -vframes 1 "$HOME/.cache/wall" -y &>/dev/null
        "$convert_cmd" "$HOME/.cache/wall" -strip -thumbnail 500x500^ -gravity center -extent 500x500 "$HOME/.cache/wall.sqre" 2>/dev/null
        "$convert_cmd" "$HOME/.cache/wall" -strip -scale 10% -blur 0x3 -resize 100% "$HOME/.cache/wall.blur" 2>/dev/null
    fi

    # Generar paleta de colores mediante wallust
    wallust run "$selected_path"
    sleep 0.4

    # Recargar Polybar si está activo
    if command -v polybar-msg &>/dev/null; then
        polybar-msg cmd restart 2>/dev/null
    fi

    # Copiar al fondo de SDDM si el directorio existe
    if [ -d "/usr/share/sddm/themes/$sddm_theme/backgrounds" ]; then
        sudo cp "$HOME/.cache/wall.blur" "/usr/share/sddm/themes/$sddm_theme/backgrounds/" 2>/dev/null
    fi
else
    echo "Error: Archivo no encontrado - $selected_path"
    exit 1
fi
