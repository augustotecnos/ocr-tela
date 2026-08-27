#!/usr/bin/env bash
# Remove tudo que o install.sh colocou (menos os pacotes do sistema).
set -euo pipefail

BIN="$HOME/.local/bin"
say() { printf '\033[1;34m==>\033[0m %s\n' "$1"; }

say "Desativando o pré-aquecimento"
systemctl --user disable --now ocr-warmup.service >/dev/null 2>&1 || true
rm -f "$HOME/.config/systemd/user/ocr-warmup.service"
systemctl --user daemon-reload

say "Removendo o atalho"
python3 - <<'PYEOF'
from gi.repository import Gio
BASE = "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/"
PATH = BASE + "ocr-tela/"
media = Gio.Settings.new("org.gnome.settings-daemon.plugins.media-keys")
paths = [p for p in media.get_strv("custom-keybindings") if p != PATH]
media.set_strv("custom-keybindings", paths)
Gio.Settings.sync()
PYEOF

say "Removendo os executáveis"
rm -f "$BIN/ocr-tela" "$BIN/ocr-warmup.sh"

say "Feito. Os modelos em ~/.tessdata_fast foram mantidos (apague à mão se quiser)."
