#!/usr/bin/env bash
set -euo pipefail

input_dir="${1:-.}"
output_dir="${2:-reordered_csv}"
days_ahead="${DAYS_AHEAD:-24}"

today="$(date +%Y-%m-%d)"
if cutoff="$(date -v+"${days_ahead}"d +%Y-%m-%d 2>/dev/null)"; then
  :
elif cutoff="$(date -d "+${days_ahead} days" +%Y-%m-%d 2>/dev/null)"; then
  :
else
  echo "Could not calculate cutoff date with date(1)" >&2
  exit 1
fi

mkdir -p "$output_dir"

shopt -s nullglob
csv_files=("$input_dir"/*.csv)

if [ "${#csv_files[@]}" -eq 0 ]; then
  echo "No CSV files found in: $input_dir" >&2
  exit 1
fi

for csv_file in "${csv_files[@]}"; do
  output_file="$output_dir/$(basename "$csv_file")"

  awk -F',' -v today="$today" -v cutoff="$cutoff" '
    BEGIN { OFS = "," }
    {
      sub(/\r$/, "", $8)
      sub(/^2024-/, "2026-", $3)
      sub(/\.000\+0000$/, "+00", $3)
      row_date = substr($3, 1, 10)
      if (row_date >= today && row_date <= cutoff) {
        print $1, $2, $3, $8, $7, $6, $5, $4
      }
    }
  ' "$csv_file" > "$output_file"
done

echo "Reordered ${#csv_files[@]} CSV file(s) into: $output_dir"
echo "Kept rows from $today through $cutoff"
