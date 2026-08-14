#!/bin/bash
# ~/Downloads にある Gemini 生成画像を、工務店デモ用に取り込む
#
# 使い方:
#   ./add-images.sh 04-doma 05-laundry 06-nook 07-workspace
#   （古い順に並んでいる画像へ、指定した名前を順に割り当てます）
#
#   引数なしで実行すると、~/Downloads にある候補を一覧表示するだけです。

set -u
IMG_DIR="$(cd "$(dirname "$0")" && pwd)/demo/koumuten/img"
DL="$HOME/Downloads"

# Gemini の生成画像を古い順に集める
# ★macOS標準のbashは3.2で mapfile が無い。while read で読む
FILES=()
while IFS= read -r line; do
  [ -n "$line" ] && FILES+=("$line")
done < <(ls -tr "$DL"/Gemini_Generated_Image_*.jpeg "$DL"/Gemini_Generated_Image_*.png 2>/dev/null)

if [ "${#FILES[@]}" -eq 0 ]; then
  echo "~/Downloads に Gemini の生成画像が見つかりません。"
  echo "画像をダウンロードしてから、もう一度実行してください。"
  exit 1
fi

if [ "$#" -eq 0 ]; then
  echo "取り込める画像（古い順）:"
  i=1
  for f in "${FILES[@]}"; do
    printf "  %d. %s  (%s)\n" "$i" "$(basename "$f")" "$(du -h "$f" | cut -f1)"
    i=$((i+1))
  done
  echo
  echo "名前を指定して実行してください。例:"
  echo "  ./add-images.sh 04-doma 05-laundry"
  exit 0
fi

mkdir -p "$IMG_DIR"
i=0
for name in "$@"; do
  src="${FILES[$i]:-}"
  if [ -z "$src" ]; then
    echo "★ $name に割り当てる画像がありません（画像は ${#FILES[@]} 枚）"
    break
  fi
  dst="$IMG_DIR/${name}.jpg"
  cp "$src" "$dst"

  before=$(stat -f%z "$dst")
  # 幅1600pxに縮小し、JPEG品質72で保存（表示品質を保ったまま10分の1程度になる）
  sips -Z 1600 "$dst" --out "$dst.tmp" >/dev/null 2>&1
  sips -s format jpeg -s formatOptions 72 "$dst.tmp" --out "$dst" >/dev/null 2>&1
  rm -f "$dst.tmp"
  after=$(stat -f%z "$dst")

  printf "  %-18s %5.1fMB → %4.0fKB  %s\n" "${name}.jpg" \
    "$(echo "$before/1048576" | bc -l)" "$(echo "$after/1024" | bc -l)" \
    "$(sips -g pixelWidth -g pixelHeight "$dst" 2>/dev/null | awk '/pixel/{printf "%s ", $2}')"

  rm -f "$src"   # 取り込んだ元ファイルは片付ける
  i=$((i+1))
done

echo
echo "取り込み完了。$IMG_DIR に保存しました。"
echo "HTMLへの組み込みはClaudeに伝えてください。"
