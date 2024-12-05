sed -i -e 's/2023-01-/2024-01-/g' $(find $(pwd)|grep .csv)
sed -i -e 's/2023-02-/2024-02-/g' $(find $(pwd)|grep .csv)
sed -i -e 's/2023-03-/2024-03-/g' $(find $(pwd)|grep .csv)
sed -i -e 's/2023-04-/2024-04-/g' $(find $(pwd)|grep .csv)

rm *csv-e*