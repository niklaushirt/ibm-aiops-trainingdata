#!/bin/bash
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# LOAD LOGS DIRECTLY INTO ELASTICSEARCH
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# ADAPT VALUES
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

echo " ------------------------------------------------------------------------------------------------------------------------------"
echo " 🚀 Starting Load (>=4.1)"
echo " ------------------------------------------------------------------------------------------------------------------------------"
echo "  "
echo "  "

export INDEX_TYPE=metrics


#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# DO NOT EDIT BELOW
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


if [[  $VERSION == "" ]]; then
    echo "   ------------------------------------------------------------------------------------------------------------------------------"
    echo "   🔬 Setting Version to default latest"
    echo "   ------------------------------------------------------------------------------------------------------------------------------"
    export VERSION=latest
fi





if [[  $WAIOPS_NAMESPACE == "" ]]; then
    # Get Namespace from Cluster 
    echo "   ------------------------------------------------------------------------------------------------------------------------------"
    echo "   🔬 Getting Installation Namespace"
    echo "   ------------------------------------------------------------------------------------------------------------------------------"
    export WAIOPS_NAMESPACE=$(oc get po -A|grep aimanager-operator |awk '{print$1}')
    echo "       ✅ OK - AI Manager:               $WAIOPS_NAMESPACE"
fi

if [ ! -x "$(command -v unzip)" ]; then
      echo "❌ Unzip not installed."

      echo "❌ Aborting...."
      exit 1
fi


echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "   🔎  Get Cassandra Authentication"	
echo "   ------------------------------------------------------------------------------------------------------------------------------"
export CASSANDRA_PASS=$(oc get secret aiops-topology-cassandra-auth-secret -n $WAIOPS_NAMESPACE -o jsonpath='{.data.password}' | base64 -d)
export CASSANDRA_USER=$(oc get secret aiops-topology-cassandra-auth-secret -n $WAIOPS_NAMESPACE -o jsonpath='{.data.username}' | base64 -d)

echo "CASSANDRA_USER:$CASSANDRA_USER"
echo "CASSANDRA_PASS:$CASSANDRA_PASS"


echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "   🔎  Check for Training Files in ./training-data/$VERSION/$INDEX_TYPE/"	
echo "   ------------------------------------------------------------------------------------------------------------------------------"
export MERIC_FILES=$(ls -1 ./training-data/$VERSION/$INDEX_TYPE/ | grep "dt_metric_value")	
if [[ $MERIC_FILES == "" ]] ;	
then	
      echo "           ❗ No Metric Dump files found"	
      echo "           ❗    No Metric Dump files found to ingest in path ./training-data/$VERSION/$INDEX_TYPE/"	
      echo "           ❗    Please place them in the directory."	
      echo "           ❌ Aborting..."	
      exit 1	
else	
      echo "     ✅ Dump Files:                 OK"	
fi	
echo "     "	


#--------------------------------------------------------------------------------------------------------------------------------------------	
#  Check Credentials	
#--------------------------------------------------------------------------------------------------------------------------------------------	

echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "   🗄️  Indexes to be loaded from ./training-data/$VERSION/$INDEX_TYPE/"	
echo "   ------------------------------------------------------------------------------------------------------------------------------"
ls -1 ./training-data/$VERSION/$INDEX_TYPE/ | grep "dt_metric_value"	 | sed 's/^/          /'
echo "       "	
echo "       "	



echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "   💾 Copy Files into Pod"
echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "      👉 Version    : $VERSION"
echo "  "
echo "  "
    oc rsync -n $WAIOPS_NAMESPACE ./training-data/$VERSION/$INDEX_TYPE/ aiops-topology-cassandra-0:/tmp/
echo "  "
echo "  "


echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "   🧻 Empty Cassandra tables"
echo "   ------------------------------------------------------------------------------------------------------------------------------"
    oc exec -ti -n $WAIOPS_NAMESPACE aiops-topology-cassandra-0 -- bash -c "/opt/ibm/cassandra/bin/cqlsh --ssl -u $CASSANDRA_USER -p $CASSANDRA_PASS -e \"TRUNCATE  tararam.dt_metric_value;\""
    oc exec -ti -n $WAIOPS_NAMESPACE aiops-topology-cassandra-0 -- bash -c "/opt/ibm/cassandra/bin/cqlsh --ssl -u $CASSANDRA_USER -p $CASSANDRA_PASS -e \"TRUNCATE  tararam.md_metric_resource;\""
    oc exec -ti -n $WAIOPS_NAMESPACE aiops-topology-cassandra-0 -- bash -c "/opt/ibm/cassandra/bin/cqlsh --ssl -u $CASSANDRA_USER -p $CASSANDRA_PASS -e \"TRUNCATE  tararam.md_resource;\""
    oc exec -ti -n $WAIOPS_NAMESPACE aiops-topology-cassandra-0 -- bash -c "/opt/ibm/cassandra/bin/cqlsh --ssl -u $CASSANDRA_USER -p $CASSANDRA_PASS -e \"TRUNCATE  tararam.md_group;\""
echo "  "
echo "  "

echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "   🔎 Check Cassandra tables"
echo "   ------------------------------------------------------------------------------------------------------------------------------"
    oc exec -ti -n $WAIOPS_NAMESPACE aiops-topology-cassandra-0 -- bash -c "/opt/ibm/cassandra/bin/cqlsh --ssl -u $CASSANDRA_USER -p $CASSANDRA_PASS -e \"SELECT COUNT(*) FROM tararam.dt_metric_value;\""
    oc exec -ti -n $WAIOPS_NAMESPACE aiops-topology-cassandra-0 -- bash -c "/opt/ibm/cassandra/bin/cqlsh --ssl -u $CASSANDRA_USER -p $CASSANDRA_PASS -e \"SELECT * FROM tararam.md_metric_resource;\""
    oc exec -ti -n $WAIOPS_NAMESPACE aiops-topology-cassandra-0 -- bash -c "/opt/ibm/cassandra/bin/cqlsh --ssl -u $CASSANDRA_USER -p $CASSANDRA_PASS -e \"SELECT * FROM tararam.md_resource;\""
    oc exec -ti -n $WAIOPS_NAMESPACE aiops-topology-cassandra-0 -- bash -c "/opt/ibm/cassandra/bin/cqlsh --ssl -u $CASSANDRA_USER -p $CASSANDRA_PASS -e \"SELECT * FROM tararam.md_group;\""

echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "   🚚 Load data structure dump into Cassandra tables"
echo "   ------------------------------------------------------------------------------------------------------------------------------"
    oc exec -ti -n $WAIOPS_NAMESPACE aiops-topology-cassandra-0 -- bash -c "/opt/ibm/cassandra/bin/cqlsh --ssl -u $CASSANDRA_USER -p $CASSANDRA_PASS -e \"copy tararam.md_metric_resource from '/tmp/tararam.md_metric_resource.csv' with header=true;\""
    oc exec -ti -n $WAIOPS_NAMESPACE aiops-topology-cassandra-0 -- bash -c "/opt/ibm/cassandra/bin/cqlsh --ssl -u $CASSANDRA_USER -p $CASSANDRA_PASS -e \"copy tararam.md_resource from '/tmp/tararam.md_resource.csv' with header=true;\""
    oc exec -ti -n $WAIOPS_NAMESPACE aiops-topology-cassandra-0 -- bash -c "/opt/ibm/cassandra/bin/cqlsh --ssl -u $CASSANDRA_USER -p $CASSANDRA_PASS -e \"copy tararam.md_group from '/tmp/tararam.md_group.csv' with header=true;\""
echo "  "
echo "  "


for actFile in $(ls -1 ./training-data/$VERSION/$INDEX_TYPE/ | grep "dt_metric_value");
do
    echo "   ------------------------------------------------------------------------------------------------------------------------------"
    echo "   🚚 Load data values dump into Cassandra table tararam.dt_metric_value from $actFile"
    echo "   ------------------------------------------------------------------------------------------------------------------------------"
        oc exec -ti -n $WAIOPS_NAMESPACE aiops-topology-cassandra-0 -- bash -c "/opt/ibm/cassandra/bin/cqlsh --ssl -u $CASSANDRA_USER -p $CASSANDRA_PASS -e \"copy tararam.dt_metric_value from '/tmp/"$actFile"' with header=true;\""
    echo "  "
    echo "  "

done

echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "   🔎 Check Cassandra tables"
echo "   ------------------------------------------------------------------------------------------------------------------------------"
    oc exec -ti -n $WAIOPS_NAMESPACE aiops-topology-cassandra-0 -- bash -c "/opt/ibm/cassandra/bin/cqlsh --ssl -u $CASSANDRA_USER -p $CASSANDRA_PASS -e \"SELECT COUNT(*) FROM tararam.dt_metric_value;\""
    oc exec -ti -n $WAIOPS_NAMESPACE aiops-topology-cassandra-0 -- bash -c "/opt/ibm/cassandra/bin/cqlsh --ssl -u $CASSANDRA_USER -p $CASSANDRA_PASS -e \"SELECT * FROM tararam.md_metric_resource;\""
    oc exec -ti -n $WAIOPS_NAMESPACE aiops-topology-cassandra-0 -- bash -c "/opt/ibm/cassandra/bin/cqlsh --ssl -u $CASSANDRA_USER -p $CASSANDRA_PASS -e \"SELECT * FROM tararam.md_resource;\""
    oc exec -ti -n $WAIOPS_NAMESPACE aiops-topology-cassandra-0 -- bash -c "/opt/ibm/cassandra/bin/cqlsh --ssl -u $CASSANDRA_USER -p $CASSANDRA_PASS -e \"SELECT * FROM tararam.md_group;\""


echo "*****************************************************************************************************************************"
echo " ✅ DONE"
echo "*****************************************************************************************************************************"


