sed -i -e 's/2023-01-/2024-06-/g' $(find $(pwd)|grep .csv)
sed -i -e 's/2023-02-/2024-07-/g' $(find $(pwd)|grep .csv)
sed -i -e 's/2023-03-/2024-08-/g' $(find $(pwd)|grep .csv)
sed -i -e 's/2023-04-/2024-09-/g' $(find $(pwd)|grep .csv)

rm *csv-e*