# CSV Reorder Script Implementation

This document contains the instructions needed to recreate `reorder_csv_columns.sh`.

## Goal

Create a shell script that reads every `.csv` file from an input folder, transforms each row, and writes files with the same names into an output folder.

The CSV files do not contain headers.

Source column meaning:

```text
t_uid,mr_id,tstamp,value,min,max,expected,anomalous
```

Destination column meaning:

```text
t_uid,mr_id,tstamp,anomalous,expected,max,min,value
```

Therefore, each output row must use this positional mapping:

```text
$1,$2,$3,$8,$7,$6,$5,$4
```

## Transformations

For each row:

1. Remove a trailing carriage return from column 8, so Windows-style line endings do not pollute the reordered output.
2. In column 3 only, replace a leading `2024-` with `2026-`.
3. In column 3 only, replace a trailing `.000+0000` with `+00`.
4. Validate the date portion of column 3 after the year replacement.
5. Skip rows with invalid calendar dates, such as `2026-06-31` or `2026-02-30`.
6. Keep only rows where the date portion of column 3 is between today and `DAYS_AHEAD` days in the future, inclusive.
7. Write the reordered row to the matching output file.

The default value for `DAYS_AHEAD` must be `24`.

## Script

Create a file named `reorder_csv_columns.sh` with this exact content:

```bash
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
```

Make the script executable:

```bash
chmod +x reorder_csv_columns.sh
```

## Usage

Run against the current folder and write output to `reordered_csv`:

```bash
./reorder_csv_columns.sh
```

Run with explicit input and output folders:

```bash
./reorder_csv_columns.sh . reordered_csv
```

Override the date window:

```bash
DAYS_AHEAD=10 ./reorder_csv_columns.sh . reordered_csv
```

## Expected Output

The script creates the output folder if it does not exist.

Each output CSV has the same filename as the source CSV.

Example source row:

```csv
cfd95b7e-3bc7-4006-a4a8-a73a79c71255,46b764cb-9ad6-326d-971b-c15b7423e49a,2024-10-01 00:05:00.000+0000,False,1.519528475299,2.179167442024,0.8569829016924,1.5068
```

Example transformed row:

```csv
cfd95b7e-3bc7-4006-a4a8-a73a79c71255,46b764cb-9ad6-326d-971b-c15b7423e49a,2026-10-01 00:05:00+00,1.5068,0.8569829016924,2.179167442024,1.519528475299,False
```

That example row is only written if its transformed date is within the configured date window and is a valid calendar date.
