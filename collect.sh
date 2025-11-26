#!/bin/bash
set -euo pipefail

# Temp-Datei für die gesammelten Libraries
libs=$(mktemp)
#trap 'rm -f "$libs"' EXIT

echo "[+] Kopiere Executables"

# Alle übergebenen Binaries verarbeiten
for bin in "$@"; do
    # Bin durch which finden, falls kein absoluter Pfad
    if [[ "$bin" != /* ]]; then
        bin_path=$(which "$bin" 2>/dev/null || true)
        if [[ -z "$bin_path" ]]; then
            echo "ERROR: Konnte Binary '$bin' nicht finden"
            continue
        fi
    else
        bin_path="$bin"
    fi

    # Zielverzeichnis erstellen und Binary kopieren
    mkdir -p "rootfs$(dirname "$bin_path")"
    echo "'$bin_path' -> 'rootfs$bin_path'"
    cp "$bin_path" "rootfs$bin_path"

    # Libraries rekursiv sammeln
    queue=("$bin_path")
    while [[ ${#queue[@]} -gt 0 ]]; do
        current_bin="${queue[0]}"
        queue=("${queue[@]:1}")

        # ldd auf aktuelles Binary / Library
        while read -r line; do
            # Zeilen filtern, die auf Libraries verweisen
            soname=$(echo "$line" | awk '{print $1}')
            path=$(echo "$line" | awk '{print $3}')

            # Wenn path existiert und noch nicht in libs, hinzufügen
            if [[ -n "$path" && -e "$path" && ! $(grep -Fqx "$path" "$libs" 2>/dev/null) ]]; then
                echo "$path" >> "$libs"

                # Wenn path selbst dynamisch, zum Queue hinzufügen
                if file "$path" | grep -q "ELF"; then
                    queue+=("$path")
                fi
            elif [[ -n "$soname" && -z "$path" ]]; then
                echo "WARN: Konnte $soname nicht finden"
            fi
        done < <(ldd "$current_bin" 2>/dev/null || true)
    done
done

echo "[+] Gefundene libs:"
cat "$libs"

echo "[+] Kopiere Libraries"
while read -r lib; do
    mkdir -p "rootfs$(dirname "$lib")"
    echo "'$lib' -> 'rootfs$lib'"
    cp -L "$lib" "rootfs$lib"   # -L folgt Symlinks automatisch
done < "$libs"

# Kopiere Dynamischen loader
mkdir -p rootfs/lib64
cp /usr/lib/x86_64-linux-gnu/ld-linux-x86-64.so.2 rootfs/lib64/

echo "[+] Optional: strip"
#find rootfs/usr -type f -exec strip --strip-unneeded {} + 2>/dev/null || true