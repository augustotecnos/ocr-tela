#!/usr/bin/env bash
# Pré-carrega os modelos do tesseract no page cache, para o primeiro OCR da
# sessão não pagar a leitura do disco. Opcional: só acelera o primeiro uso.
LANG_CODE="${OCR_LANG:-por}"

preload() {
    for f in "$@"; do
        [ -f "$f" ] && cat "$f" > /dev/null 2>&1
    done
}

preload /usr/share/tesseract-ocr/*/tessdata/*.traineddata
preload /usr/share/tessdata/*.traineddata

# Pasta alternativa de modelos, se o usuário tiver configurado uma.
if [ -n "${OCR_TESSDATA:-}" ] && [ -d "$OCR_TESSDATA" ]; then
    preload "$OCR_TESSDATA"/*.traineddata
    export TESSDATA_PREFIX="$OCR_TESSDATA"
fi

echo warmup | tesseract stdin stdout -l "$LANG_CODE" --oem 1 --psm 6 >/dev/null 2>&1
exit 0
