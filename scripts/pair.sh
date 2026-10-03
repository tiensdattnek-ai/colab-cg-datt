#!/usr/bin/env bash
# Pair Moonlight voi Sunshine bang PIN (khong can mo web UI)
pin="${1:-}"; [ -z "$pin" ] && read -rp "Nhap PIN tu Moonlight: " pin
[ -z "$pin" ] && { echo "Thieu PIN"; exit 1; }
RES=$(curl -s -u admin:admin -k -X POST https://localhost:47990/api/pin \
  -H 'Content-Type: application/json' -d "{\"pin\":\"$pin\",\"name\":\"moonlight\"}")
echo "$RES"
echo "$RES" | grep -q '"status":true' \
  && echo "✅ Pair thanh cong! Quay lai Moonlight va bam vao host." \
  || echo "❌ That bai. Kiem tra PIN con han (60s) va Sunshine dang chay."
