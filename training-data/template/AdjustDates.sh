sed -i -e 's/2023-01-/2023-08-/g' $(find $(pwd)|grep .csv)
sed -i -e 's/2023-02-/2023-09-/g' $(find $(pwd)|grep .csv)
sed -i -e 's/2023-03-/2023-10-/g' $(find $(pwd)|grep .csv)
sed -i -e 's/2023-04-/2023-11-/g' $(find $(pwd)|grep .csv)

rm *csv-e*

