#!/usr/bin/env bash
# Pré-carrega os modelos do tesseract no page cache, para o primeiro OCR
# da sessão não pagar o custo de leitura do disco.
TESSDATA="${OCR_TESSDATA:-$HOME/.tessdata_fast}"

for f in "$TESSDATA"/*.traineddata; do
    [ -f "$f" ] && cat "$f" > /dev/null 2>&1
done

for f in /usr/share/tesseract-ocr/*/tessdata/*.traineddata; do
    [ -f "$f" ] && cat "$f" > /dev/null 2>&1
done

echo "warmup" | tesseract stdin stdout -l "${OCR_LANG:-por}" --oem 1 --psm 6 \
    --tessdata-dir "$TESSDATA" > /dev/null 2>&1
exit 0
