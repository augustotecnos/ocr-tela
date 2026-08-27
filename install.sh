#!/usr/bin/env bash
# Instalação a partir do fonte, na pasta do usuário (~/.local).
# Para empacotar, não use este script: use "make install" com DESTDIR/PREFIX.
set -euo pipefail

PREFIX="${PREFIX:-$HOME/.local}"
UNITS="${SYSTEMD_USER_DIR:-$HOME/.config/systemd/user}"
LANGS="${OCR_LANGS:-por}"
KEYBIND="${OCR_KEYBIND:-<Super><Shift>t}"
SHORTCUT=1
WARMUP=1

for arg in "$@"; do
    case "$arg" in
        --no-shortcut) SHORTCUT=0 ;;
        --no-warmup)   WARMUP=0 ;;
        -h|--help)
            echo "Uso: ./install.sh [--no-shortcut] [--no-warmup]"
            echo "Variáveis: PREFIX, OCR_LANGS (ex.: \"por eng\"), OCR_KEYBIND"
            exit 0 ;;
        *) echo "Opção desconhecida: $arg" >&2; exit 1 ;;
    esac
done

say()  { printf '\033[1;34m==>\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$1"; }

[ "${XDG_SESSION_TYPE:-}" = "wayland" ] || warn "Sessão não é Wayland (${XDG_SESSION_TYPE:-?}). Feito para GNOME/Wayland."
case "${XDG_CURRENT_DESKTOP:-}" in
    *GNOME*) ;;
    *) warn "Área de trabalho '${XDG_CURRENT_DESKTOP:-?}' não é GNOME; depende do portal de captura do GNOME." ;;
esac

# ---------------------------------------------------------------- dependências
PKGS=(python3-gi gir1.2-gtk-4.0 python3-pil tesseract-ocr wl-clipboard libnotify-bin)
for l in $LANGS; do PKGS+=("tesseract-ocr-$l"); done

MISSING=()
for p in "${PKGS[@]}"; do
    dpkg -s "$p" >/dev/null 2>&1 || MISSING+=("$p")
done

if [ ${#MISSING[@]} -gt 0 ]; then
    if command -v apt >/dev/null 2>&1; then
        say "Instalando dependências: ${MISSING[*]}"
        sudo apt update && sudo apt install -y "${MISSING[@]}"
    else
        warn "Sem apt. Instale o equivalente a: ${MISSING[*]}"
    fi
else
    say "Dependências já satisfeitas."
fi

# ------------------------------------------------------------------ instalação
say "Instalando em $PREFIX"
make install PREFIX="$PREFIX" SYSTEMD_USER_DIR="$UNITS"

case ":$PATH:" in
    *":$PREFIX/bin:"*) ;;
    *) warn "$PREFIX/bin não está no PATH. Adicione ao ~/.profile e reinicie a sessão." ;;
esac

# --------------------------------------------------------------------- extras
if [ "$WARMUP" = 1 ]; then
    say "Ativando o pré-aquecimento dos modelos (opcional, acelera o primeiro uso)"
    systemctl --user daemon-reload
    systemctl --user enable --now ocr-warmup.service >/dev/null 2>&1 \
        || warn "Não consegui ativar ocr-warmup.service"
fi

if [ "$SHORTCUT" = 1 ]; then
    say "Registrando o atalho $KEYBIND"
    "$PREFIX/bin/ocr-tela-atalho" --binding "$KEYBIND" --command "$PREFIX/bin/ocr-tela"
else
    say "Atalho não registrado. Para criar depois: ocr-tela-atalho"
fi

say "Pronto."
