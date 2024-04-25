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



export LOG_TYPE=lags   # humio, elk, splunk, ...
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

#------------------------------------------------------------------------------------------------------------------------------------
#  Get the cert for kafkacat
#------------------------------------------------------------------------------------------------------------------------------------
echo "     🥇 Getting Kafka Cert"
oc extract secret/kafka-secrets -n $AIOPS_NAMESPACE --keys=ca.crt --confirm| sed 's/^/            /'
echo ""
echo ""


export my_date=$(date "+%Y-%m-%dT")

#------------------------------------------------------------------------------------------------------------------------------------
#  Get Kafkacat executable
#------------------------------------------------------------------------------------------------------------------------------------
echo "     📥  Getting Kafkacat executable"
if [ -x "$(command -v kafkacat)" ]; then
      export KAFKACAT_EXE=kafkacat
else
      if [ -x "$(command -v kcat)" ]; then
            export KAFKACAT_EXE=kcat
      else
            echo "     ❗ ERROR: kafkacat is not installed."
            echo "     ❌ Aborting..."
            exit 1
      fi
fi
echo " "



echo "     🔐 Get Kafka Password"
export KAFKA_SECRET=$(oc get secret -n $AIOPS_NAMESPACE |grep 'aiops-kafka-secret'|awk '{print$1}')
export SASL_USER=$(oc get secret $KAFKA_SECRET -n $AIOPS_NAMESPACE --template={{.data.username}} | base64 --decode)
export SASL_PASSWORD=$(oc get secret $KAFKA_SECRET -n $AIOPS_NAMESPACE --template={{.data.password}} | base64 --decode)
export KAFKA_BROKER=$(oc get routes iaf-system-kafka-0 -n $AIOPS_NAMESPACE -o=jsonpath='{.status.ingress[0].host}{"\n"}'):443



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
            echo "          Injecting file ($ACT_COUNT/$(($NUM_FILES-1))) - $FILE"
            #echo "                 ${KAFKACAT_EXE} -v -X security.protocol=SASL_SSL -X ssl.ca.location=./ca.crt -X sasl.mechanisms=SCRAM-SHA-512  -X sasl.username=token -X sasl.password=$KAFKA_PASSWORD -b $KAFKA_BROKER -P -t $KAFKA_TOPIC_LOGS -l $FILE   "
            ${KAFKACAT_EXE} -v -X security.protocol=SASL_SSL -X ssl.ca.location=./ca.crt -X sasl.mechanisms=SCRAM-SHA-512  -X sasl.username=$SASL_USER -X sasl.password=$SASL_PASSWORD -b $KAFKA_BROKER -P -t $KAFKA_TOPIC_LOGS -l $FILE
            echo "          ✅ OK"
            echo " "
    fi
done




