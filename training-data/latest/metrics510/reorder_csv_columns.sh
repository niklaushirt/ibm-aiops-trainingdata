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
    function is_leap_year(year) {
      return (year % 4 == 0 && year % 100 != 0) || year % 400 == 0
    }
    function days_in_month(year, month) {
      if (month == 2) {
        return is_leap_year(year) ? 29 : 28
      }
      if (month == 4 || month == 6 || month == 9 || month == 11) {
        return 30
      }
      return 31
    }
    function valid_date(date_value, parts, year, month, day) {
      if (date_value !~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/) {
        return 0
      }
      split(date_value, parts, "-")
      year = parts[1] + 0
      month = parts[2] + 0
      day = parts[3] + 0
      return month >= 1 && month <= 12 && day >= 1 && day <= days_in_month(year, month)
    }
    {
      sub(/\r$/, "", $8)
      sub(/^2024-/, "2026-", $3)
      sub(/\.000\+0000$/, "+00", $3)
      row_date = substr($3, 1, 10)
      if (valid_date(row_date) && row_date >= today && row_date <= cutoff) {
        print $1, $2, $3, $8, $7, $6, $5, $4
      }
    }
  ' "$csv_file" > "$output_file"
done

echo "Reordered ${#csv_files[@]} CSV file(s) into: $output_dir"
echo "Kept rows from $today through $cutoff"
