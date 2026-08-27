#!/usr/bin/env bash
# Desfaz o que o install.sh colocou (não remove pacotes do sistema).
set -euo pipefail

PREFIX="${PREFIX:-$HOME/.local}"
UNITS="${SYSTEMD_USER_DIR:-$HOME/.config/systemd/user}"
say() { printf '\033[1;34m==>\033[0m %s\n' "$1"; }

say "Removendo o atalho"
if command -v "$PREFIX/bin/ocr-tela-atalho" >/dev/null 2>&1; then
    "$PREFIX/bin/ocr-tela-atalho" --remove || true
fi

say "Desativando o pré-aquecimento"
systemctl --user disable --now ocr-warmup.service >/dev/null 2>&1 || true

say "Removendo os arquivos"
make uninstall PREFIX="$PREFIX" SYSTEMD_USER_DIR="$UNITS"
systemctl --user daemon-reload || true

say "Feito."
