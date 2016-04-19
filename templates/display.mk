# display1.mk
# This makefile:
## 1. Runs QAtools_v1.1 to generate images of FreeSurfer brain.
## 2. Uses TSNR from NiPy to create signal to noise images (in NIFTI and gif format).
## 3. Uses nipy_tsdiffana to create ts_diffana plots.
## 4. Uses MakingGraphs.R script to create motion graphs (from values in .par file).
## 5. Creates QA reports for each task.
## 6. Creates reports that include result images from higher-level FEAT analyses for each task.

# Possible additions / improvements
## 1. Link QA reports to higher-level directory (instead of actually moving the file).


.PHONY: display FreeSurferQA MotionGraphs TSNR QAReports
#FeatReports
.SECONDARY:

display: TSNR FreeSurferQA MotionGraphs TSNR QAReports
#FeatReports


## 1. Runs QAtools_v1.1 to generate images of FreeSurfer brain.

FreeSurferQA: /Users/kelly89/Projects/PreprocessingExample/FreeSurfer/QA/$(SUBJECT)/rgb/snaps/$(SUBJECT).html

/Users/kelly89/Projects/PreprocessingExample/FreeSurfer/QA/$(SUBJECT)/rgb/snaps/$(SUBJECT).html: /Users/kelly89/Projects/PreprocessingExample/raw_FreeSurfer/$(SUBJECT)/mri/aparc+aseg.mgz
	echo "Making FreesurferQA" ;\
	source /usr/local/freesurfer/stable5_3/SetUpFreeSurfer.sh ;\
	export SUBJECTS_DIR=$(SUBJECTS_DIR) ;\
	export QA_TOOLS=/usr/local/freesurfer/QAtools_v1.1 ;\
	$${QA_TOOLS}/recon_checker -s $(SUBJECT) -snaps-detailed
	mkdir -p QA/Images/FreeSurfer/ ;\
	cp $(SUBJECTS_DIR)/QA/$(SUBJECT)/rgb/snaps/$(SUBJECT)*.gif QA/Images/FreeSurfer ;\


## 2. Uses TSNR from NiPy to create signal to noise images (in NIFTI and gif format).

TSNR: $(patsubst %,QA/Images/%_tsnr.nii.gz, $(EPIRUNS) mprage/MPRAGE) $(patsubst %,QA/Images/%_tsnr.gif, $(EPIRUNS) mprage/MPRAGE) $(patsubst %,QA/Images/%_tsnr_mean.gif, $(EPIRUNS) mprage/MPRAGE) $(patsubst %,QA/Images/%_tsnr_stddev.gif, $(EPIRUNS) mprage/MPRAGE) $(patsubst %,QA/Images/%_tsdiffana.gif, $(EPIRUNS) mprage/MPRAGE)

QA/Images/%_tsnr.nii.gz: %.nii.gz
	python $(SCRIPTpath)/TSNR_Images.py -i $(word 1,$^) ;\
	mkdir -p `dirname $@` ;\
	mv *tsnr* `dirname $@`

QA/Images/%_tsnr.gif: QA/Images/%_tsnr.nii.gz
	/usr/share/fsl/5.0/bin/slices $(word 1,$^) -s 3 -o $@ ;\
	/usr/share/fsl/5.0/bin/slices `dirname $(word 1,$^)`/`basename $(word 1,$^) .nii.gz`_mean.nii.gz -s 3 -o `dirname $(word 1,$^)`/`basename $(word 1,$^) .nii.gz`_mean.gif ;\
	/usr/share/fsl/5.0/bin/slices `dirname $(word 1,$^)`/`basename $(word 1,$^) .nii.gz`_stddev.nii.gz -s 3 -o `dirname $(word 1,$^)`/`basename $(word 1,$^) .nii.gz`_stddev.gif ;\


## 3. Uses nipy_tsdiffana to create ts_diffana plots.

QA/Images/%_tsdiffana.gif: %.nii.gz
	/usr/local/anaconda/bin/nipy_tsdiffana --out-file `dirname $@`/`basename $@ .gif`.png $(word 1,$^) ;\
	convert `dirname $@`/`basename $@ .gif`.png $@


## 4. Uses MakingGraphs.R script to create motion graphs (from values in .par file).

MotionGraphs: $(patsubst %,QA/Images/%_MotionGraphRotations.gif, $(EPIRUNS))

QA/Images/%_MotionGraphRotations.gif: $(RScripts)/MakingGraphs.R %.par
	RUN=`basename $(word 2,$^) .par` ;\
	sed -e "s/TASK/`dirname $(word 2,$^)`/g" -e "s/RUN/`basename $(word 2,$^) .par`/g" -e 's/SUBJECT/$(SUBJECT)/g' $(RScripts)/MakingGraphs.R > QA/`basename $(word 2,$^) .par`.R ;\
	chmod ug+rx QA/`basename $(word 2,$^) .par`.R ;\
	Rscript QA/`basename $(word 2,$^) .par`.R ;\
	for i in `dirname $@`/`basename $@ _MotionGraphRotations.gif`*Motion*.png; do convert $$i `dirname $@`/`basename $$i .png`.gif; done ;\
	for j in `dirname $@`/`basename $@ _MotionGraphRotations.gif`*dvars*.png; do convert $$j `dirname $@`/`basename $$j .png`.gif; done ;\
	for k in `dirname $@`/`basename $@ _MotionGraphRotations.gif`*fd*.png; do convert $$k `dirname $@`/`basename $$k .png`.gif; done


## 5. Creates QA reports for each task.

QAReports: $(patsubst %,$(PROJECT_DIR)/QA/PreprocessingQA/$(SUBJECT)_%.html, $(EPIRUNNAMES) MPRAGE)

$(PROJECT_DIR)/QA/PreprocessingQA/$(SUBJECT)_MPRAGE.html: $(RScripts)/MPRAGE.Rmd mprage/MPRAGE.nii.gz
	RUN=`basename $(word 2,$^) .nii.gz` ;\
	sed -e 's/SUBJECT/$(SUBJECT)/g' -e "s/TASK/`dirname $(word 2,$^)`/g" -e "s/RUN/`basename $(word 2,$^) .nii.gz`/g" $(word 1,$^) > QA/MPRAGE.Rmd ;\
	R -e 'library("rmarkdown");rmarkdown::render("QA/MPRAGE.Rmd")' ;\
	mv QA/MPRAGE.html $@ ;\

#$(PROJECT_DIR)/QA/PreprocessingQA/$(SUBJECT)_%.html: $(RScripts)/Preprocessing.Rmd %.nii.gz QA/Images/%_MotionGraphRotations.gif QA/Images/%_tsnr.gif QA/Images/%_tsdiffana.gif QA/#Images/%_mc_z_animation.gif QA/Images/%_bet_z_animation.gif QA/Images/%_despike_z_animation.gif QA/Images/%_spikiness_z_animation.gif QA/Images/%_ssmooth_z_animation.gif
#	RUN=`basename $(word 2,$^) .nii.gz` ;\
#	sed -e 's/SUBJECT/$(SUBJECT)/g' -e "s/TASK/`dirname $(word 2,$^)`/g" -e "s/RUN/`basename $(word 2,$^) .nii.gz`/g" $(word 1,$^) > QA/$${RUN}.Rmd ;\
#	R -e 'library("rmarkdown");rmarkdown::render("QA/'$$RUN'.Rmd")' ;\
#	mv QA/$${RUN}.html $@ ;\


define make-preprocessing-qa =
$(PROJECT_DIR)/QA/PreprocessingQA/$(Subject)_$(notdir $(1)).html: $(RScripts)/Preprocessing.Rmd $(1).nii.gz QA/Images/$(1)_MotionGraphRotations.gif QA/Images/$(1)_tsnr.gif QA/Images/$(1)_tsdiffana.gif QA/Images/$(1)_mc_z_animation.gif QA/Images/$(1)_bet_z_animation.gif QA/Images/$(1)_despike_z_animation.gif QA/Images/$(1)_spikiness_z_animation.gif QA/Images/$(1)_ssmooth_z_animation.gif
	RUN=`basename $(word 2,$^) .nii.gz` ;\
	sed -e 's/SUBJECT/$(SUBJECT)/g' -e "s/TASK/`dirname $(word 2,$^)`/g" -e "s/RUN/`basename $(word 2,$^) .nii.gz`/g" $(word 1,$^) > QA/$${RUN}.Rmd ;\
	R -e 'library("rmarkdown");rmarkdown::render("QA/'$$RUN'.Rmd")' ;\
	mv QA/$${RUN}.html $@
endef

$(foreach a,$(EPIRUNS),$(eval $(call make-preprocessing-qa, $(a))))

## 6. Creates reports that include result images from higher-level FEAT analyses for each task.

FeatReports: $(PROJECT_DIR)/QA/$(SESSION)/FeatQA/$(SUBJECT)_ExtinctionRecall.html $(PROJECT_DIR)/QA/$(SESSION)/FeatQA/$(SUBJECT)_FaceReactivity.html $(PROJECT_DIR)/QA/$(SESSION)/FeatQA/$(SUBJECT)_Reappraisal.html $(PROJECT_DIR)/QA/$(SESSION)/FeatQA/$(SUBJECT)_FearLearning.html


$(PROJECT_DIR)/QA/$(SESSION)/FeatQA/$(SUBJECT)_ExtinctionRecall.html: extinctionRecall/ExtinctionRecallCombined_Sep.gfeat/cope4.feat/stats/cope2.nii.gz extinctionRecall/ExtinctionRecallCompared_Sep.gfeat/cope4.feat/stats/cope2.nii.gz extinctionRecall/ExtinctionRecallCombined_NoSep.gfeat/cope4.feat/stats/cope2.nii.gz extinctionRecall/ExtinctionRecallCompared_NoSep.gfeat/cope4.feat/stats/cope2.nii.gz QA/Images/extinctionRecall/ExtinctionRecallCombined_Sep_cope4_zstat2_z.gif QA/Images/extinctionRecall/ExtinctionRecallCompared_Sep_cope4_zstat2_z.gif extinctionRecall/ExtinctionRecallCombined_Sep_Mem.gfeat/cope4.feat/stats/cope2.nii.gz extinctionRecall/ExtinctionRecallCompared_Sep_Mem.gfeat/cope4.feat/stats/cope2.nii.gz extinctionRecall/ExtinctionRecallCombined_NoSep_Mem.gfeat/cope4.feat/stats/cope2.nii.gz extinctionRecall/ExtinctionRecallCompared_NoSep_Mem.gfeat/cope4.feat/stats/cope2.nii.gz QA/Images/extinctionRecall/ExtinctionRecallCombined_Sep_cope4_zstat2_z.gif QA/Images/extinctionRecall/ExtinctionRecallCompared_Sep_cope4_zstat2_z.gif extinctionRecall/ExtinctionRecallCombined_Sep_Thr.gfeat/cope4.feat/stats/cope2.nii.gz extinctionRecall/ExtinctionRecallCompared_Sep_Thr.gfeat/cope4.feat/stats/cope2.nii.gz extinctionRecall/ExtinctionRecallCombined_NoSep_Thr.gfeat/cope4.feat/stats/cope2.nii.gz extinctionRecall/ExtinctionRecallCompared_NoSep_Thr.gfeat/cope4.feat/stats/cope2.nii.gz extinctionRecall/MeanRating.txt
	featDir=`echo $(word 1,$^) | awk -F "/" '{print $$1"/"$$2}'` ;\
	TASK=`basename $$featDir Combined_Sep.gfeat` ;\
	task=`dirname $$featDir` ;\
	echo subject=${SUBJECT} session=${SESSION_NUM} task=$${task} ;\
	bash ${RScripts}/makeFeatRmd ${SUBJECT} ${SESSION_NUM} $${task} ;\
	R -e 'library("rmarkdown");rmarkdown::render("QA/FeatExtinctionRecall.Rmd")' ;\
	mv QA/FeatExtinctionRecall.html $@ ;\

$(PROJECT_DIR)/QA/$(SESSION)/FeatQA/$(SUBJECT)_FaceReactivity.html: faceReactivity/FaceReactivityCombined.gfeat/cope9.feat/stats/cope2.nii.gz faceReactivity/FaceReactivityCompared.gfeat/cope9.feat/stats/cope2.nii.gz QA/Images/faceReactivity/FaceReactivityCombined_cope9_zstat2_z.gif QA/Images/faceReactivity/FaceReactivityCompared_cope9_zstat2_z.gif
	featDir=`echo $(word 1,$^) | awk -F "/" '{print $$1"/"$$2}'` ;\
	TASK=`basename $$featDir Combined.gfeat` ;\
	task=`dirname $$featDir` ;\
	echo subject=${SUBJECT} session=${SESSION_NUM} task=$${task} ;\
	bash ${RScripts}/makeFeatRmd ${SUBJECT} ${SESSION_NUM} $${task} ;\
	R -e 'library("rmarkdown");rmarkdown::render("QA/FeatFaceReactivity.Rmd")' ;\
	mv QA/FeatFaceReactivity.html $@ ;\

$(PROJECT_DIR)/QA/$(SESSION)/FeatQA/$(SUBJECT)_Reappraisal.html: reappraisal/ReappraisalCombined_Sep.gfeat/cope13.feat/stats/cope2.nii.gz reappraisal/ReappraisalCompared_Sep.gfeat/cope13.feat/stats/cope2.nii.gz reappraisal/ReappraisalCombined_NoSep.gfeat/cope13.feat/stats/cope2.nii.gz reappraisal/ReappraisalCompared_NoSep.gfeat/cope13.feat/stats/cope2.nii.gz QA/Images/reappraisal/ReappraisalCombined_Sep_cope13_zstat2_z.gif QA/Images/reappraisal/ReappraisalCompared_Sep_cope13_zstat2_z.gif QA/Images/reappraisal/ReappraisalCombined_NoSep_cope13_zstat2_z.gif QA/Images/reappraisal/ReappraisalCompared_NoSep_cope13_zstat2_z.gif reappraisal/MeanRating.txt
	featDir=`echo $(word 1,$^) | awk -F "/" '{print $$1"/"$$2}'` ;\
	TASK=`basename $$featDir Combined_Sep.gfeat` ;\
	task=`dirname $$featDir` ;\
	echo subject=${SUBJECT} session=${SESSION_NUM} task=$${task} ;\
	bash ${RScripts}/makeFeatRmd ${SUBJECT} ${SESSION_NUM} $${task} ;\
	R -e 'library("rmarkdown");rmarkdown::render("QA/FeatReappraisal.Rmd")' ;\
	mv QA/FeatReappraisal.html $@ ;\

$(PROJECT_DIR)/QA/$(SESSION)/FeatQA/$(SUBJECT)_FearLearning.html: fearLearning/FearLearning.feat/reg_standard/stats/varcope9.nii.gz QA/Images/fearLearning/FearLearning_zstat9_z.gif
	featDir=`echo $(word 1,$^) | awk -F "/" '{print $$1"/"$$2}'` ;\
	TASK=`basename $$featDir .feat` ;\
	task=`dirname $$featDir` ;\
	echo subject=${SUBJECT} session=${SESSION_NUM} task=$${task} ;\
	bash ${RScripts}/makeFeatRmd ${SUBJECT} ${SESSION_NUM} $${task} ;\
	R -e 'library("rmarkdown");rmarkdown::render("QA/FeatFearLearning.Rmd")' ;\
	mv QA/FeatFearLearning.html $@ ;\
