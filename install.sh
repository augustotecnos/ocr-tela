#!/usr/bin/env bash
# Instalador do ocr-tela. Não precisa de root, exceto para os pacotes do sistema.
set -euo pipefail

BIN="$HOME/.local/bin"
UNITS="$HOME/.config/systemd/user"
TESSDATA="$HOME/.tessdata_fast"
LANGS="${OCR_LANGS:-por eng}"
KEYBIND="${OCR_KEYBIND:-<Super><Shift>t}"
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

say() { printf '\033[1;34m==>\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$1"; }

# ---------------------------------------------------------------- checagens
[ "${XDG_SESSION_TYPE:-}" = "wayland" ] || warn "Sessão não é Wayland ($XDG_SESSION_TYPE). Feito para GNOME/Wayland."
case "${XDG_CURRENT_DESKTOP:-}" in
    *GNOME*) ;;
    *) warn "Área de trabalho '$XDG_CURRENT_DESKTOP' não é GNOME. Depende do portal de captura do GNOME." ;;
esac

# ------------------------------------------------------------- dependências
PKGS=(python3-gi gir1.2-gtk-4.0 python3-pil tesseract-ocr wl-clipboard libnotify-bin)
for l in $LANGS; do [ "$l" = "eng" ] || PKGS+=("tesseract-ocr-$l"); done

MISSING=()
for p in "${PKGS[@]}"; do
    dpkg -s "$p" >/dev/null 2>&1 || MISSING+=("$p")
done

if [ ${#MISSING[@]} -gt 0 ]; then
    if command -v apt >/dev/null 2>&1; then
        say "Instalando dependências: ${MISSING[*]}"
        sudo apt update && sudo apt install -y "${MISSING[@]}"
    else
        warn "Sem apt. Instale manualmente o equivalente a: ${MISSING[*]}"
    fi
else
    say "Dependências já satisfeitas."
fi

# ------------------------------------------------ modelos rápidos (opcional)
say "Baixando modelos tessdata_fast em $TESSDATA (OCR ~2x mais rápido)"
mkdir -p "$TESSDATA"
for l in $LANGS; do
    if [ -f "$TESSDATA/$l.traineddata" ]; then
        echo "    $l.traineddata já existe"
    else
        url="https://github.com/tesseract-ocr/tessdata_fast/raw/main/$l.traineddata"
        if curl -fsSL --retry 2 -o "$TESSDATA/$l.traineddata" "$url"; then
            echo "    $l.traineddata baixado"
        else
            rm -f "$TESSDATA/$l.traineddata"
            warn "Falha ao baixar $l.traineddata — o tesseract usará o modelo padrão do sistema."
        fi
    fi
done

# -------------------------------------------------------------- instalação
say "Instalando em $BIN"
mkdir -p "$BIN"
install -m 755 "$SRC/ocr-tela" "$BIN/ocr-tela"
install -m 755 "$SRC/ocr-warmup.sh" "$BIN/ocr-warmup.sh"

say "Ativando o pré-aquecimento dos modelos (systemd --user)"
mkdir -p "$UNITS"
install -m 644 "$SRC/ocr-warmup.service" "$UNITS/ocr-warmup.service"
systemctl --user daemon-reload
systemctl --user enable --now ocr-warmup.service >/dev/null 2>&1 || warn "Não consegui ativar ocr-warmup.service"

# ----------------------------------------------------------------- atalho
say "Configurando o atalho $KEYBIND"
python3 - "$BIN/ocr-tela" "$KEYBIND" <<'PYEOF'
import sys
from gi.repository import Gio

command, binding = sys.argv[1], sys.argv[2]
BASE = "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/"
PATH = BASE + "ocr-tela/"

media = Gio.Settings.new("org.gnome.settings-daemon.plugins.media-keys")
paths = list(media.get_strv("custom-keybindings"))
if PATH not in paths:
    paths.append(PATH)
    media.set_strv("custom-keybindings", paths)

entry = Gio.Settings.new_with_path(
    "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding", PATH)
entry.set_string("name", "OCR de área da tela")
entry.set_string("command", command)
entry.set_string("binding", binding)
Gio.Settings.sync()
print(f"    atalho {binding} -> {command}")
PYEOF

case ":$PATH:" in
    *":$BIN:"*) ;;
    *) warn "$BIN não está no PATH. Adicione ao ~/.profile e reinicie a sessão." ;;
esac

say "Pronto. Aperte $KEYBIND e arraste sobre um texto."
