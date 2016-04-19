#!/bin/bash -x

QAType=$1
firstImage=$2
secondImage=$3
resultImage=$4
pngImage="`dirname ${resultImage}`/`basename ${resultImage} .gif`.png"
niftiImage="`dirname ${resultImage}`/`basename ${resultImage} .gif`.nii.gz"

#Make sure directory of resultImage exists
mkdir -p `dirname ${resultImage}`

#Make random directory
tempDir=`mktemp -d`

if [[ ${QAType} == *s* ]] || [[ ${QAType} == *S* ]]; then

	# Make intermediate1.png
	/usr/share/fsl/5.0/bin/slicer ${firstImage} ${secondImage} -s 2 -x 0.35 ${tempDir}/sla.png -x 0.45 ${tempDir}/slb.png -x 0.55 ${tempDir}/slc.png -x 0.65 ${tempDir}/sld.png -y 0.35 ${tempDir}/sle.png -y 0.45 ${tempDir}/slf.png -y 0.55 ${tempDir}/slg.png -y 0.65 ${tempDir}/slh.png -z 0.35 ${tempDir}/sli.png -z 0.45 ${tempDir}/slj.png -z 0.55 ${tempDir}/slk.png -z 0.65 ${tempDir}/sll.png
	pngappend ${tempDir}/sla.png + ${tempDir}/slb.png + ${tempDir}/slc.png + ${tempDir}/sld.png + ${tempDir}/sle.png + ${tempDir}/slf.png + ${tempDir}/slg.png + ${tempDir}/slh.png + ${tempDir}/sli.png + ${tempDir}/slj.png + ${tempDir}/slk.png + ${tempDir}/sll.png ${tempDir}/intermediate1.png

	#Make intermediate2.png
	/usr/share/fsl/5.0/bin/slicer ${secondImage} ${firstImage} -s 2 -x 0.35 ${tempDir}/sla.png -x 0.45 ${tempDir}/slb.png -x 0.55 ${tempDir}/slc.png -x 0.65 ${tempDir}/sld.png -y 0.35 ${tempDir}/sle.png -y 0.45 ${tempDir}/slf.png -y 0.55 ${tempDir}/slg.png -y 0.65 ${tempDir}/slh.png -z 0.35 ${tempDir}/sli.png -z 0.45 ${tempDir}/slj.png -z 0.55 ${tempDir}/slk.png -z 0.65 ${tempDir}/sll.png
	pngappend ${tempDir}/sla.png + ${tempDir}/slb.png + ${tempDir}/slc.png + ${tempDir}/sld.png + ${tempDir}/sle.png + ${tempDir}/slf.png + ${tempDir}/slg.png + ${tempDir}/slh.png + ${tempDir}/sli.png + ${tempDir}/slj.png + ${tempDir}/slk.png + ${tempDir}/sll.png ${tempDir}/intermediate2.png

	#Make pngImage
	pngappend ${tempDir}/intermediate1.png - ${tempDir}/intermediate2.png ${pngImage}

elif [[ ${QAType} == *o* ]] || [[ ${QAType} == *o* ]]; then
	/usr/share/fsl/5.0/bin/overlay 1 1 ${firstImage} -a ${secondImage} 1 10 ${tempDir}/rendered_`basename ${niftiImage}`
	/project_space/child_emotion/stress_pipeline/bin/slices ${tempDir}/rendered_`basename ${niftiImage}` -o ${pngImage}
	convert ${pngImage} ${resultImage}
fi

#Convert pngImage to resultImage
convert ${pngImage} ${resultImage}

#Remove tempDir and pngImage
rm -r /tmp/`basename $tempDir`
rm ${pngImage}
