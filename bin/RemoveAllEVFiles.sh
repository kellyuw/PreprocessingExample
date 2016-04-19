#!/bin/bash -X

Task=$1
Run=$2
Subject=$3
TaskDir=`echo "${Task}" | tr '[:upper:]' '[:lower:]'`

PROJECT_DIR="/Users/kelly89/Projects/PreprocessingExample"
FSF="${PROJECT_DIR}/${Subject}/${TaskDir}/${Task}${Run}.fsf"

if [[ ${Task} == "ExtinctionRecall" ]]; then
	OnsetFiles="CSPlus_ImageResponse_R CSMinus_ImageResponse_R Simpson CSPlus_ImageResponse_NR CSMinus_ImageResponse_NR"
elif [[ ${Task} == "ThreatReactivity" ]]; then
	OnsetFiles="F C S Simpson"
elif [[ ${Task} == "WMShapes" ]]; then
	OnsetFiles="low high Simpson"
elif [[ ${Task} == "WMFaces" ]]; then
	OnsetFiles="calm angry Simpson"
elif [[ ${Task} == "GNG" ]]; then
	OnsetFiles="Two_NoGo_Correct Three_NoGo_Correct Four_NoGo_Correct Two_Go_Correct Three_Go_Correct Four_Go_Correct Two_NoGo_Incorrect Three_NoGo_Incorrect Four_NoGo_Incorrect ALL_Go_Incorrect"
fi


for f in `ls ${PROJECT_DIR}/${Subject}/${TaskDir}/${Task}${Run}_${f}*.txt`; do
	echo ${f}
done
