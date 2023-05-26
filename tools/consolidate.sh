cat 1000-1000-20220303-logtrain.json|grep '"instance_id":"catalogue"'>new_1000-1000-20220303-logtrain.json
cat 1000-1000-20220304-logtrain.json|grep '"instance_id":"catalogue"'>new_1000-1000-20220304-logtrain.json

cat 1000-1000-20220303-logtrain.json|grep '"instance_id":"ratings"'>ratings_1000-1000-20220303-logtrain.json
cat 1000-1000-20220304-logtrain.json|grep '"instance_id":"ratings"'>ratings_1000-1000-20220304-logtrain.json


cat 1000-1000-20220303-logtrain.json|grep '"instance_id":"web"'>web_1000-1000-20220303-logtrain.json
cat 1000-1000-20220304-logtrain.json|grep '"instance_id":"web"'>web_1000-1000-20220304-logtrain.json

cat ratings_1000-1000-20220303-logtrain.json > 1000-1000-20220303-logtrain.json
cat ratings_1000-1000-20220304-logtrain.json > 1000-1000-20220304-logtrain.json
cat web_1000-1000-20220303-logtrain.json >> 1000-1000-20220303-logtrain.json
cat web_1000-1000-20220304-logtrain.json >> 1000-1000-20220304-logtrain.json
cat new_1000-1000-20220303-logtrain.json >> 1000-1000-20220303-logtrain.json
cat new_1000-1000-20220304-logtrain.json >> 1000-1000-20220304-logtrain.json