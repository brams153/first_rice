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

# --- Arrays paralelos: la fuente de verdad, indexados 0..N-1 ---
# ENTRY_LABEL[i]  -> texto mostrado en rofi
# ENTRY_PATH[i]   -> ruta real del archivo
# ENTRY_TYPE[i]   -> "static" o "live"
ENTRY_LABEL=()
ENTRY_PATH=()
ENTRY_TYPE=()

generate_thumbnails() {
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
                # Namespaced por tipo para que no choquen miniaturas
                # de un mismo nombre en carpetas distintas (static/live)
                thumb_path="$THUMB_DIR/${dir_type}_${name}_thumb.png"

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

# Puebla los arrays ENTRY_* recorriendo static y live.
# El orden de inserción aquí ES el índice que rofi devolverá con -format "i",
# así que no debe reordenarse entre esta función y la lectura de la selección.
build_entries() {
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

                ENTRY_LABEL+=("$label")
                ENTRY_PATH+=("$img")
                ENTRY_TYPE+=("$dir_type")
            done
            shopt -u nullglob
        done
    done
}

# Imprime las líneas para rofi -dmenu (icono opcional por entrada),
# en el MISMO orden que los arrays ENTRY_*.
print_rofi_entries() {
    local i
    for i in "${!ENTRY_LABEL[@]}"; do
        local label="${ENTRY_LABEL[$i]}"
        local dir_type="${ENTRY_TYPE[$i]}"
        local img="${ENTRY_PATH[$i]}"
        local filename name thumb
        filename=$(basename "$img")
        name="${filename%.*}"
        thumb="$THUMB_DIR/${dir_type}_${name}_thumb.png"

        if [ -f "$thumb" ]; then
            echo -e "$label\x00icon\x1f$thumb"
        else
            echo "$label"
        fi
    done
}

# Generar miniaturas y poblar los arrays antes de abrir la interfaz
generate_thumbnails
build_entries

if [ "${#ENTRY_LABEL[@]}" -eq 0 ]; then
    if command -v dunstify &>/dev/null; then
        dunstify -u critical "Fondos" "No se encontraron wallpapers en $STATIC_WALLPAPER_DIR ni $LIVE_WALLPAPER_DIR"
    else
        echo "No se encontraron wallpapers."
    fi
    exit 0
fi

# Ejecutar Rofi pidiendo el ÍNDICE de la selección (-format "i"),
# no el texto. Esto elimina cualquier ambigüedad por labels repetidos
# o coincidencias parciales, ya que el índice es exacto y no depende
# de cómo se vea el texto en pantalla.
if [ -f "$ROFI_THEME" ]; then
    selected_index=$(print_rofi_entries | rofi -dmenu -i \
        -p "󰸉 Fondo:" \
        -show-icons \
        -format "i" \
        -theme "$ROFI_THEME")
else
    selected_index=$(print_rofi_entries | rofi -dmenu -i \
        -p "󰸉 Fondo:" \
        -show-icons \
        -format "i" \
        -theme-str 'window { width: 250px; height: 600px; location: east; anchor: east; } listview { columns: 1; lines: 4; } element { orientation: vertical; } element-icon { size: 120px; horizontal-align: 0.5; }')
fi

# Si no se seleccionó nada (Esc o cierre), rofi con -format "i" no imprime nada
if [ -z "$selected_index" ]; then
    exit 0
fi

selected_path="${ENTRY_PATH[$selected_index]}"
type="${ENTRY_TYPE[$selected_index]}"

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
