oc exec -n ibm-aiops -it aiops-topology-cassandra-0 -- bash


cqlsh --ssl -u ${CASSANDRA_USER} -p ${CASSANDRA_PASS} --request-timeout=3600
SELECT * FROM tararam.md_metric_resource;

copy tararam.md_metric_resource to '/tmp/tararam.md_metric_resource.csv' with header=true;

cat /tmp/tararam.md_metric_resource.csv
