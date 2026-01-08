sed -i -e 's/","namespace_id":/-robotshop","namespace_id":/g' $(find $(pwd)|grep xaa)

rm *-e*


gsed -i "s/,2025-/,2026-/g" *.csv

