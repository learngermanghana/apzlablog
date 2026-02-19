#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DRAFT_DIR="$ROOT_DIR/_drafts"
POST_DIR="$ROOT_DIR/_posts"
POSTS_PER_RUN="${POSTS_PER_RUN:-1}"

if ! [[ "$POSTS_PER_RUN" =~ ^[0-9]+$ ]] || [ "$POSTS_PER_RUN" -lt 1 ]; then
  echo "POSTS_PER_RUN must be a positive integer."
  exit 1
fi

mapfile -t draft_files < <(find "$DRAFT_DIR" -maxdepth 1 -type f -name '*.md' | sort)

if [ "${#draft_files[@]}" -eq 0 ]; then
  echo "No draft posts available."
  exit 0
fi

published=0
publish_date="$(date +%Y-%m-%d)"

for draft_file in "${draft_files[@]}"; do
  [ "$published" -ge "$POSTS_PER_RUN" ] && break

  base_name="$(basename "$draft_file")"
  slug="${base_name#*-}"
  target_file="$POST_DIR/${publish_date}-${slug}"

  awk -v date="$publish_date" '
    BEGIN { updated = 0 }
    /^date:[[:space:]]*TBD[[:space:]]*$/ && updated == 0 {
      print "date: " date
      updated = 1
      next
    }
    { print }
  ' "$draft_file" > "$target_file"

  rm "$draft_file"
  published=$((published + 1))
  echo "Published: $(basename "$target_file")"
done

echo "Done. Published $published post(s)."
