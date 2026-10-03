#!/usr/bin/env bash
# Backup/restore thu muc game ra Google Drive de lan sau khong phai tai lai
# Usage: backup.sh save|load [duong_dan_drive]
MODE="${1:-save}"; DRIVE="${2:-/content/drive/MyDrive/ccg-backup.tar.zst}"
SRC="/home/${CCG_USER:-gamer}"
command -v zstd >/dev/null || apt-get install -y -qq zstd
case "$MODE" in
  save) echo "Nen $SRC -> $DRIVE ..."
        tar --zstd -cf "$DRIVE" -C "$(dirname "$SRC")" "$(basename "$SRC")" \
            --exclude='*/.cache/*' --exclude='*/Trash/*' && echo "✅ Xong: $(du -h "$DRIVE" | cut -f1)" ;;
  load) echo "Giai nen $DRIVE -> $SRC ..."
        tar --zstd -xf "$DRIVE" -C "$(dirname "$SRC")" && chown -R "${CCG_USER:-gamer}:${CCG_USER:-gamer}" "$SRC" && echo "✅ Xong" ;;
  *) echo "Usage: backup.sh save|load [path]" ;;
esac
