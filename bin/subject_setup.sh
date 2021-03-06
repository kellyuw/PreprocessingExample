#!/bin/bash
#
# Setup Subject directories as new data is collected
#

# Takes 1 input (Subject number))
# Usage: Subject_setup.sh <sub_id>

if [ $# -lt 1 ]; then
	echo
	echo   "bash Subject_setup.sh <Subject_id>"
	echo
	exit
fi

Subject=$1

PROJECT_DIR=/Users/kelly89/Projects/PreprocessingExample
TEMPLATES=${PROJECT_DIR}/templates

cd ${PROJECT_DIR}
echo ${PROJECT_DIR}

#Make dirctory structure
for fname in dti threatreactivity extinctionrecall wmshapes wmfaces gng mprage rest session_info behavior QA/Images QA/Reports parrecs nifti; do
	mkdir -p ${PROJECT_DIR}/${Subject}/${fname}
done

#copying the zipfolder
#find the zip file
Zipfile=`find ${PROJECT_DIR}/incoming -iname "*${Subject}*.zip"`
cp ${Zipfile} ${PROJECT_DIR}/${Subject}/
cp ${PROJECT_DIR}/incoming/*${Subject}*.txt ${PROJECT_DIR}/${Subject}/behavior/fMRI_COMBINED_TASKS_${Subject}.txt
cp ${PROJECT_DIR}/incoming/*${Subject}*.edat2 ${PROJECT_DIR}/${Subject}/behavior/fMRI_COMBINED_TASKS_${Subject}.edat2

cd ${PROJECT_DIR}/${Subject}
echo ${PROJECT_DIR}/${Subject}

find . -iname *.zip | wc -l

while [ `find . -iname *.zip | wc -l` -gt 0 ]; do
	echo unzipping files
	for i in `find . -iname *.zip`; do
		echo unzipping $i
		unzip $i
		rm $i
	done
done

find -iname "*PAR" -exec mv -t ./ {} \+
find -iname "*REC" -exec mv -t ./ {} \+

mv ${PROJECT_DIR}/${Subject}/*.PAR parrecs/
mv ${PROJECT_DIR}/${Subject}/*.REC parrecs/
rm -r *${Subject}*

#Rename PARREC files
for i in `ls ${PROJECT_DIR}/${Subject}/parrecs/*.PAR` ; do
    initialname=`basename ${i} .PAR`
    cleanname=`echo ${initialname} | awk -F "DT${Subject}_WIP_" '{print $2}' | sed -e 's/_SENSE_.*_.*//g' | sed 's/_//g'`
    echo ${cleanname}

    #A few of the scans are named differently from the rest :)
    if [[ ${cleanname} == *RS* ]]; then
	cleanname="Rest"
    elif [[ ${cleanname} == *FACE* ]]; then
	cleanname=`echo ${cleanname} | sed 's/WMFACE/WMFace/g'`
    elif [[ ${cleanname} == *Survey* ]]; then
	cleannname="Survey"
    fi

    #Rename PAR, REC, and nii files to clean names
    echo "Renaming PARREC files: ${initialname} to ${cleanname} ..."
    mv ${PROJECT_DIR}/${Subject}/parrecs/${initialname}.PAR ${PROJECT_DIR}/${Subject}/parrecs/${cleanname}.PAR
    mv ${PROJECT_DIR}/${Subject}/parrecs/${initialname}.REC ${PROJECT_DIR}/${Subject}/parrecs/${cleanname}.REC

    #Copy PARs to QA for inclusion in QA reports
    cp ${PROJECT_DIR}/${Subject}/parrecs/${cleanname}.PAR ${PROJECT_DIR}/${Subject}/QA/${cleanname}.PAR

done


#### Converting all the PAR/REC to Nifti
cp /mnt/home/ibic/bin/run_ConvertR2A.sh ${PROJECT_DIR}/${Subject}
cp /mnt/home/ibic/bin/ConvertR2A ${PROJECT_DIR}/${Subject}
bash run_ConvertR2A.sh /usr/local/MATLAB/MATLAB_Compiler_Runtime/v81 ${PROJECT_DIR}/${Subject}/parrecs/
rm ${PROJECT_DIR}/${Subject}/run_ConvertR2A.sh
rm -r ${PROJECT_DIR}/${Subject}/ConvertR2A
mv ${PROJECT_DIR}/${Subject}/parrecs/*.nii ${PROJECT_DIR}/${Subject}/nifti
gzip ${PROJECT_DIR}/${Subject}/nifti/*.nii

#Rename NIFTI files
for i in `ls ${PROJECT_DIR}/${Subject}/nifti/*-*.nii.gz` ; do
    initialname=`basename ${i} .nii.gz`
    cleanname=`echo ${initialname} | awk -F "-" '{print $1}'`

    if [[ ${cleanname} == *DTI* ]]; then
	   rm ${PROJECT_DIR}/${Subject}/nifti/${initialname}.nii.gz
    else
	   echo "Renaming NIFTI files: ${initialname} to ${cleanname} ..."
	   mv ${PROJECT_DIR}/${Subject}/nifti/${initialname}.nii.gz ${PROJECT_DIR}/${Subject}/nifti/${cleanname}.nii.gz
    fi
done

#Finish renaming NIFTI (to match behavioral file)
rename 's|ExtRecall|ExtinctionRecall|g' ${PROJECT_DIR}/${Subject}/nifti/ExtRecall?.nii.gz
rename 's|FaceReactivity|ThreatReactivity|g' ${PROJECT_DIR}/${Subject}/nifti/FaceReactivity?.nii.gz
rename 's|WMFace|WMFaces|g' ls ${PROJECT_DIR}/${Subject}/nifti/WMFace?.nii.gz
rename 's|WMShape|WMShapes|g' ${PROJECT_DIR}/${Subject}/nifti/WMShape?.nii.gz

for i in PAR REC; do
    if [ -f ${PROJECT_DIR}/${Subject}/parrecs/*DTI32*.${i} ]; then
	mv ${PROJECT_DIR}/${Subject}/parrecs/*DTI32*.${i} ${PROJECT_DIR}/${Subject}/parrecs/DTI32.${i}
    fi

    if [ -f ${PROJECT_DIR}/${Subject}/parrecs/*B0_DTI*.${i} ]; then
	mv ${PROJECT_DIR}/${Subject}/parrecs/*B0_DTI*.${i} ${PROJECT_DIR}/${Subject}/parrecs/B0_DTI.${i}
    fi
done


#Make relative symbolic links to Makefiles
cd ${PROJECT_DIR}/${Subject}
if [ ! -f ${PROJECT_DIR}/${Subject}/Makefile ] ; then ln -s ../templates/Makefile Makefile; fi
if [ ! -f ${PROJECT_DIR}/${Subject}/PrepSubject.mk ] ; then ln -s ../templates/PrepSubject.mk PrepSubject.mk; fi
if [ ! -f ${PROJECT_DIR}/${Subject}/PreprocessSubject.mk ] ; then ln -s ../templates/PreprocessSubject.mk PreprocessSubject.mk; fi
if [ ! -f ${PROJECT_DIR}/${Subject}/feat.mk ] ; then ln -s ../templates/feat.mk feat.mk; fi
if [ ! -f ${PROJECT_DIR}/${Subject}/display.mk ] ; then ln -s ../templates/display.mk display.mk; fi

for i in `ls ${PROJECT_DIR}/${Subject}/nifti/ThreatReactivity?.nii.gz` ; do
    cd ${PROJECT_DIR}/${Subject}/threatreactivity
    ln -s ../nifti/`basename ${i}` `basename ${i}`
done

for i in `ls ${PROJECT_DIR}/${Subject}/nifti/ExtinctionRecall?.nii.gz` ; do
    cd ${PROJECT_DIR}/${Subject}/extinctionrecall
    ln -s ../nifti/`basename ${i}` `basename ${i}`
done

for i in `ls ${PROJECT_DIR}/${Subject}/nifti/WMShapes?.nii.gz` ; do
    cd ${PROJECT_DIR}/${Subject}/wmshapes
    ln -s ../nifti/`basename ${i}` `basename ${i}`
done

for i in `ls ${PROJECT_DIR}/${Subject}/nifti/WMFaces?.nii.gz` ; do
    cd ${PROJECT_DIR}/${Subject}/wmfaces
    ln -s ../nifti/`basename ${i}` `basename ${i}`
done

for i in `ls ${PROJECT_DIR}/${Subject}/nifti/GNG?.nii.gz` ; do
    cd ${PROJECT_DIR}/${Subject}/gng
    ln -s ../nifti/`basename ${i}` `basename ${i}`
done

for i in `ls ${PROJECT_DIR}/${Subject}/nifti/MPRAGE.nii.gz` ; do
    cd ${PROJECT_DIR}/${Subject}/mprage
    ln -s ../nifti/`basename ${i}` `basename ${i}`
done

for i in `ls ${PROJECT_DIR}/${Subject}/nifti/Rest.nii.gz` ; do
    cd ${PROJECT_DIR}/${Subject}/rest
    ln -s ../nifti/`basename ${i}` `basename ${i}`
done
