#!/bin/bash
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# LOAD EVENTS DIRECTLY INTO CASSANDRA
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


# Get Namespace from Cluster 
echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "    🔬 Getting Installation Namespace"
echo "   ------------------------------------------------------------------------------------------------------------------------------"

export AIOPS_NAMESPACE=$(oc get po -A|grep aiops-orchestrator-controller |awk '{print$1}')
echo "       ✅ OK - IBMAIOps:    $AIOPS_NAMESPACE"

oc project $AIOPS_NAMESPACE  >/tmp/demo.log


echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "   🔎  Get Cassandra Authentication"	
echo "   ------------------------------------------------------------------------------------------------------------------------------"
export CASSANDRA_PASS=$(oc get secret aiops-topology-cassandra-auth-secret -n $AIOPS_NAMESPACE -o jsonpath='{.data.password}' | base64 -d)
export CASSANDRA_USER=$(oc get secret aiops-topology-cassandra-auth-secret -n $AIOPS_NAMESPACE -o jsonpath='{.data.username}' | base64 -d)

echo "CASSANDRA_USER:$CASSANDRA_USER"
echo "CASSANDRA_PASS:$CASSANDRA_PASS"



echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "   🔎  Get REST Authentication"	
echo "   ------------------------------------------------------------------------------------------------------------------------------"
export USER_PASS="$(oc get secret aiops-ir-core-ncodl-api-secret -o jsonpath='{.data.username}' | base64 --decode):$(oc get secret -n $AIOPS_NAMESPACE aiops-ir-core-ncodl-api-secret -o jsonpath='{.data.password}' | base64 --decode)"
sleep 2
export DATALAYER_ROUTE=$(oc get route  -n $AIOPS_NAMESPACE datalayer-api  -o jsonpath='{.status.ingress[0].host}')

echo "USER_PASS:$USER_PASS"
echo "DATALAYER_ROUTE:$DATALAYER_ROUTE"


echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "   🧻 Empty Cassandra tables"
echo "   ------------------------------------------------------------------------------------------------------------------------------"
    oc exec -ti -n $AIOPS_NAMESPACE aiops-topology-cassandra-0 -- bash -c "/opt/ibm/cassandra/bin/cqlsh --ssl -u $CASSANDRA_USER -p $CASSANDRA_PASS -e \"TRUNCATE aiops.alerts;\""
echo "  "
echo "  "




echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "   🚀 Update Training Data Today"
echo "   ------------------------------------------------------------------------------------------------------------------------------"
cp ./training-data/latest/events-rest/events-training-rest.json /tmp/events-training-rest.json
export current_date=$(date --date='-1 day' +'%Y-%m-%d')
sed -i "s/2026-01-01/$current_date/g" /tmp/events-training-rest.json
head -n 3 /tmp/events-training-rest.json

while IFS= read -r line
do      
      #echo "              line:$"
      line=${line//\"/\\\"}

      export c_string=$(echo "curl \"https://$DATALAYER_ROUTE/irdatalayer.aiops.io/active/v1/events\" --insecure -s  -X POST -u \"${USER_PASS}\" -H 'Content-Type: application/json' -H 'x-username:admin' -H 'x-subscription-id:cfd95b7e-3bc7-4006-a4a8-a73a79c71255' -d \"${line}\"")
      #echo "       Q:$c_string"
      #echo ""
      export result=$(eval $c_string)
      #export result=$(curl "https://$DATALAYER_ROUTE/irdatalayer.aiops.io/active/v1/events" --insecure --silent -X POST -u "${USER_PASS}" -H 'Content-Type: application/json' -H "x-username:admin" -H "x-subscription-id:cfd95b7e-3bc7-4006-a4a8-a73a79c71255" -d "${line}")
      #echo $result
      myId=$(echo $result|jq ".deduplicationKey")
      echo "              DONE:$myId"

done < "/tmp/events-training-rest.json"
echo "              ✅ OK"
echo " "



echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "   🚀 Update Training Data 1 Month ago"
echo "   ------------------------------------------------------------------------------------------------------------------------------"
cp ./training-data/latest/events-rest/events-training-rest.json /tmp/events-training-rest.json
export current_date=$(date --date='-1 month' +'%Y-%m-%d')
sed -i "s/2026-01-01/$current_date/g" /tmp/events-training-rest.json
head -n 3 /tmp/events-training-rest.json


while IFS= read -r line
do      
      #echo "              line:$"
      line=${line//\"/\\\"}

      export c_string=$(echo "curl \"https://$DATALAYER_ROUTE/irdatalayer.aiops.io/active/v1/events\" --insecure -s  -X POST -u \"${USER_PASS}\" -H 'Content-Type: application/json' -H 'x-username:admin' -H 'x-subscription-id:cfd95b7e-3bc7-4006-a4a8-a73a79c71255' -d \"${line}\"")
      #echo "       Q:$c_string"
      #echo ""
      export result=$(eval $c_string)
      #export result=$(curl "https://$DATALAYER_ROUTE/irdatalayer.aiops.io/active/v1/events" --insecure --silent -X POST -u "${USER_PASS}" -H 'Content-Type: application/json' -H "x-username:admin" -H "x-subscription-id:cfd95b7e-3bc7-4006-a4a8-a73a79c71255" -d "${line}")
      #echo $result
      myId=$(echo $result|jq ".deduplicationKey")
      echo "              DONE:$myId"

done < "/tmp/events-training-rest.json"
echo "              ✅ OK"
echo " "



echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "   🚀 Update Training Data 2 Month ago"
echo "   ------------------------------------------------------------------------------------------------------------------------------"
cp ./training-data/latest/events-rest/events-training-rest.json /tmp/events-training-rest.json
export current_date=$(date --date='-2 month' +'%Y-%m-%d')
sed -i "s/2026-01-01/$current_date/g" /tmp/events-training-rest.json
head -n 3 /tmp/events-training-rest.json


while IFS= read -r line
do      
      #echo "              line:$"
      line=${line//\"/\\\"}

      export c_string=$(echo "curl \"https://$DATALAYER_ROUTE/irdatalayer.aiops.io/active/v1/events\" --insecure -s  -X POST -u \"${USER_PASS}\" -H 'Content-Type: application/json' -H 'x-username:admin' -H 'x-subscription-id:cfd95b7e-3bc7-4006-a4a8-a73a79c71255' -d \"${line}\"")
      #echo "       Q:$c_string"
      #echo ""
      export result=$(eval $c_string)
      #export result=$(curl "https://$DATALAYER_ROUTE/irdatalayer.aiops.io/active/v1/events" --insecure --silent -X POST -u "${USER_PASS}" -H 'Content-Type: application/json' -H "x-username:admin" -H "x-subscription-id:cfd95b7e-3bc7-4006-a4a8-a73a79c71255" -d "${line}")
      #echo $result
      myId=$(echo $result|jq ".deduplicationKey")
      echo "              DONE:$myId"

done < "/tmp/events-training-rest.json"
echo "              ✅ OK"
echo " "



echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "   🚀 Update Training Data 3 Month ago"
echo "   ------------------------------------------------------------------------------------------------------------------------------"
cp ./training-data/latest/events-rest/events-training-rest.json /tmp/events-training-rest.json
export current_date=$(date --date='-3 month' +'%Y-%m-%d')
sed -i "s/2026-01-01/$current_date/g" /tmp/events-training-rest.json
head -n 3 /tmp/events-training-rest.json


while IFS= read -r line
do      
      #echo "              line:$"
      line=${line//\"/\\\"}

      export c_string=$(echo "curl \"https://$DATALAYER_ROUTE/irdatalayer.aiops.io/active/v1/events\" --insecure -s  -X POST -u \"${USER_PASS}\" -H 'Content-Type: application/json' -H 'x-username:admin' -H 'x-subscription-id:cfd95b7e-3bc7-4006-a4a8-a73a79c71255' -d \"${line}\"")
      #echo "       Q:$c_string"
      #echo ""
      export result=$(eval $c_string)
      #export result=$(curl "https://$DATALAYER_ROUTE/irdatalayer.aiops.io/active/v1/events" --insecure --silent -X POST -u "${USER_PASS}" -H 'Content-Type: application/json' -H "x-username:admin" -H "x-subscription-id:cfd95b7e-3bc7-4006-a4a8-a73a79c71255" -d "${line}")
      #echo $result
      myId=$(echo $result|jq ".deduplicationKey")
      echo "              DONE:$myId"

done < "/tmp/events-training-rest.json"
echo "              ✅ OK"
echo " "




echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "   🚀 Update Training Data 4 Month ago"
echo "   ------------------------------------------------------------------------------------------------------------------------------"
cp ./training-data/latest/events-rest/events-training-rest.json /tmp/events-training-rest.json
export current_date=$(date --date='-4 month' +'%Y-%m-%d')
sed -i "s/2026-01-01/$current_date/g" /tmp/events-training-rest.json
head -n 3 /tmp/events-training-rest.json


while IFS= read -r line
do      
      #echo "              line:$"
      line=${line//\"/\\\"}

      export c_string=$(echo "curl \"https://$DATALAYER_ROUTE/irdatalayer.aiops.io/active/v1/events\" --insecure -s  -X POST -u \"${USER_PASS}\" -H 'Content-Type: application/json' -H 'x-username:admin' -H 'x-subscription-id:cfd95b7e-3bc7-4006-a4a8-a73a79c71255' -d \"${line}\"")
      #echo "       Q:$c_string"
      #echo ""
      export result=$(eval $c_string)
      #export result=$(curl "https://$DATALAYER_ROUTE/irdatalayer.aiops.io/active/v1/events" --insecure --silent -X POST -u "${USER_PASS}" -H 'Content-Type: application/json' -H "x-username:admin" -H "x-subscription-id:cfd95b7e-3bc7-4006-a4a8-a73a79c71255" -d "${line}")
      #echo $result
      myId=$(echo $result|jq ".deduplicationKey")
      echo "              DONE:$myId"

done < "/tmp/events-training-rest.json"
echo "              ✅ OK"
echo " "



echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "   🔎 Check Cassandra tables"
echo "   ------------------------------------------------------------------------------------------------------------------------------"
    oc exec -ti -n $AIOPS_NAMESPACE aiops-topology-cassandra-0 -- bash -c "/opt/ibm/cassandra/bin/cqlsh --ssl -u $CASSANDRA_USER -p $CASSANDRA_PASS -e \"SELECT COUNT(*) FROM aiops.alerts;\""



echo "*****************************************************************************************************************************"
echo " ✅ DONE"
echo "*****************************************************************************************************************************"
