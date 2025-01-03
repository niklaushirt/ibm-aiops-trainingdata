#!/bin/bash
echo "***************************************************************************************************************************************************"
echo "***************************************************************************************************************************************************"
echo ""
echo ""
echo ""
echo "         ________  __  ___     ___    ________       "     
echo "        /  _/ __ )/  |/  /    /   |  /  _/ __ \____  _____"
echo "        / // __  / /|_/ /    / /| |  / // / / / __ \/ ___/"
echo "      _/ // /_/ / /  / /    / ___ |_/ // /_/ / /_/ (__  ) "
echo "     /___/_____/_/  /_/    /_/  |_/___/\____/ .___/____/  "
echo "                                           /_/            "
echo ""
echo ""
echo ""
echo "***************************************************************************************************************************************************"
echo "***************************************************************************************************************************************************"
echo ""
echo " 🚀  IBMAIOPS Inject Logs through Kafka"
echo ""
echo "***************************************************************************************************************************************************"
echo "***************************************************************************************************************************************************"



export LOG_TYPE=lags   
export INDEX_TYPE=lags

cd /ibm-aiops-trainingdata

echo "   "
echo "   "

if [[  $VERSION == "" ]]; then
    echo "   ------------------------------------------------------------------------------------------------------------------------------"
    echo "   🔬 Setting Version to default latest"
    echo "   ------------------------------------------------------------------------------------------------------------------------------"
    export VERSION=latest
fi


echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "    🔬 Getting Installation Namespace"
echo "   ------------------------------------------------------------------------------------------------------------------------------"

export AIOPS_NAMESPACE=$(oc get po -A|grep aiops-orchestrator-controller |awk '{print$1}')
echo "       ✅ OK - IBMAIOps:    $AIOPS_NAMESPACE"

echo " "
echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "   🚀  Initializing..."
echo "   ------------------------------------------------------------------------------------------------------------------------------"

echo "     📥 Get Working Directories"
export WORKING_DIR_LOGS="./training-data/$VERSION/$INDEX_TYPE/"
echo $WORKING_DIR_LOGS

echo "     📥 Get Kafka Topics"
export KAFKA_TOPIC_LOGS=$(oc get kafkatopics -n $AIOPS_NAMESPACE | grep cp4waiops-cartridge-logs-elk| awk '{print $1;}')

if [[ "${KAFKA_TOPIC_LOGS}" == "" ]]; then
    echo "          ❗ Please define a Kafka connection in IBMAIOps of type $LOG_TYPE."
    echo "          ❗ Existing Log Topics are:"
    oc get kafkatopics -n $AIOPS_NAMESPACE | grep cp4waiops-cartridge-logs-| awk '{print $1;}'| sed 's/^/                /'
    echo ""
    echo "          ❌ Exiting....."
    #exit 1 

else
    echo "        🟢 OK"
fi


echo "     🔐 Get Kafka Password"
export KAFKA_SECRET=$(oc get secret -n $AIOPS_NAMESPACE |grep 'aiops-kafka-secret'|awk '{print$1}')
export SASL_USER=$(oc get secret $KAFKA_SECRET -n $AIOPS_NAMESPACE --template={{.data.username}} | base64 --decode)
export SASL_PASSWORD=$(oc get secret $KAFKA_SECRET -n $AIOPS_NAMESPACE --template={{.data.password}} | base64 --decode)
export KAFKA_BROKER=$(oc get routes iaf-system-kafka-0 -n $AIOPS_NAMESPACE -o=jsonpath='{.status.ingress[0].host}{"\n"}'):443


#------------------------------------------------------------------------------------------------------------------------------------
#  Get the cert for kafkacat
#------------------------------------------------------------------------------------------------------------------------------------
echo "     🥇 Getting Kafka Cert"
oc extract secret/kafka-secrets -n $AIOPS_NAMESPACE --keys=ca.crt --confirm| sed 's/^/            /'
echo ""
echo ""


export my_date=$(date "+%Y-%m-%dT")


OS=$(uname -s | tr '[:upper:]' '[:lower:]')
if [ "${OS}" == "darwin" ]; then
      # Suppose we're on Mac
      export my_date1=$(date -v-6d "+%Y-%m-%d")
      export my_date2=$(date -v-5d "+%Y-%m-%d")
      export my_date3=$(date -v-4d "+%Y-%m-%d")
      export my_date4=$(date -v-3d "+%Y-%m-%d")
      export my_date5=$(date -v-2d "+%Y-%m-%d")
      export my_date6=$(date -v-1d "+%Y-%m-%d")
      export my_date7=$(date "+%Y-%m-%d")
else
      export my_date1=$(date -d '6 days ago' "+%Y-%m-%d")
      export my_date2=$(date -d '5 days ago' "+%Y-%m-%d")
      export my_date3=$(date -d '4 days ago' "+%Y-%m-%d")
      export my_date4=$(date -d '3 days ago' "+%Y-%m-%d")
      export my_date5=$(date -d '2 days ago' "+%Y-%m-%d")
      export my_date6=$(date -d '1 days ago' "+%Y-%m-%d")
      export my_date7=$(date "+%Y-%m-%d")
fi




echo "   ----------------------------------------------------------------------------------------------------------------------------------------"
echo "     🔎  Parameters for Incident Simulation for $APP_NAME"
echo "   ----------------------------------------------------------------------------------------------------------------------------------------"
echo "     "
echo "       🗂  Log Topic                   : $KAFKA_TOPIC_LOGS"
echo "       🌏 Kafka Broker URL            : $KAFKA_BROKER"
echo "       🔐 Kafka User                  : $SASL_USER"
echo "       🔐 Kafka Password              : $SASL_PASSWORD"
echo "       🖥️  Kafka Executable            : $KAFKACAT_EXE"
echo "     "
echo "       📝 Log Type                    : $LOG_TYPE"
echo "     "
echo "       📂 Directory for Logs          : $WORKING_DIR_LOGS"
echo "   ----------------------------------------------------------------------------------------------------------------------------------------"
echo "   "
echo "       📝 Date                        : $my_date1"
echo "       📝 Date                        : $my_date2"
echo "       📝 Date                        : $my_date3"
echo "       📝 Date                        : $my_date4"
echo "       📝 Date                        : $my_date5"
echo "       📝 Date                        : $my_date6"
echo "       📝 Date                        : $my_date7"

echo "   "
echo "   ----------------------------------------------------------------------------------------------------------------------------------------"
echo "     🗄️  Log Files to be loaded"
echo "   ----------------------------------------------------------------------------------------------------------------------------------------"
ls -1 $WORKING_DIR_LOGS | grep "zip"| sed 's/^/          /'
echo "     "


echo "   "
echo "   "
echo "   ----------------------------------------------------------------------------------------------------------------------------------------"
echo "     🚀  Preparing Log Data"
echo "   ----------------------------------------------------------------------------------------------------------------------------------------"

mkdir /tmp/training-files-logs/  >/tmp/demo.log 2>&1 
rm -f -r /tmp/training-files-logs/* 


for actFile in $(ls -1 $WORKING_DIR_LOGS | grep "zip"); 
do 

#------------------------------------------------------------------------------------------------------------------------------------
#  Prepare the Data
#------------------------------------------------------------------------------------------------------------------------------------
    echo "   "
    echo "   "
    echo "   "
    echo "   "
    echo "      -------------------------------------------------------------------------------------------------------------------------------------"
    echo "        🛠️   Preparing Data for file $actFile"
    echo "      -------------------------------------------------------------------------------------------------------------------------------------"

    #------------------------------------------------------------------------------------------------------------------------------------
    #  Create file and structure in /tmp
    #------------------------------------------------------------------------------------------------------------------------------------
    echo "      -------------------------------------------------------------------------------------------------------------------------------------"
    echo "        🛠️   Copy $actFile to /tmp/training-files-logs/"

    cp $WORKING_DIR_LOGS/$actFile /tmp/training-files-logs/$actFile

    cd /tmp/training-files-logs/

    unzip /tmp/training-files-logs/$actFile




    export NUM_FILES=$(ls | wc -l)
    ls -1 /tmp/training-files-logs/x*| sed 's/^/             /'
    #cat xaa
    cd -  >/tmp/demo.log 2>&1 
    echo " "
    echo "          ✅ OK - File Count: $NUM_FILES"

done

rm -f -r /tmp/training-files-logs/*.zip 
rm -f -r /tmp/training-files-logs/__MACOSX



echo "   "
echo "      ----------------------------------------------------------------------------------------------------------------------------------------"
echo "       🚀  Inject Log Files"
echo "      ----------------------------------------------------------------------------------------------------------------------------------------"

#------------------------------------------------------------------------------------------------------------------------------------
#  Inject the Data
#------------------------------------------------------------------------------------------------------------------------------------
echo "         -------------------------------------------------------------------------------------------------------------------------------------"
echo "          🌏  Injecting Log Data" 
echo "              Quit with Ctrl-Z"
echo "         -------------------------------------------------------------------------------------------------------------------------------------"
ACT_COUNT=0
for FILE in /tmp/training-files-logs/*; do 
    if [[ $FILE =~ "x"  ]]; then
            ACT_COUNT=`expr $ACT_COUNT + 1`

            sed -i -e "s/2024-03-15/$my_date7/g" $FILE
            sed -i -e "s/2024-03-14/$my_date6/g" $FILE
            sed -i -e "s/2024-03-13/$my_date5/g" $FILE
            sed -i -e "s/2024-03-12/$my_date4/g" $FILE
            sed -i -e "s/2024-03-11/$my_date3/g" $FILE
            sed -i -e "s/2024-03-10/$my_date2/g" $FILE
            sed -i -e "s/2024-03-09/$my_date1/g" $FILE


            tail $FILE

            echo "          Injecting file ($ACT_COUNT/$(($NUM_FILES-1))) - $FILE"
            #echo "                 ${KAFKACAT_EXE} -v -X security.protocol=SASL_SSL -X ssl.ca.location=./ca.crt -X sasl.mechanisms=SCRAM-SHA-512  -X sasl.username=token -X sasl.password=$KAFKA_PASSWORD -b $KAFKA_BROKER -P -t $KAFKA_TOPIC_LOGS -l $FILE   "
            kafkacat -v -X security.protocol=SASL_SSL -X ssl.ca.location=./ca.crt -X sasl.mechanisms=SCRAM-SHA-512  -X sasl.username=$SASL_USER -X sasl.password=$SASL_PASSWORD -b $KAFKA_BROKER -P -t $KAFKA_TOPIC_LOGS -l $FILE
            echo "          ✅ OK"
            echo " "
    fi
done




