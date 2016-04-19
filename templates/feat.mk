# feat1.mk
# This makefile:
## 1. Runs first-level FEAT analyses for the Extinction Recall task.
## 2. Registers cope and varcope images to MNI space (using ANTs) for the Extinction Recall task.
## 3. Runs first-level FEAT analyses for the Reappraisal task.
## 4. Registers cope and varcope images to MNI space (using ANTs) for the Reappraisal task.
## 5. Runs first-level FEAT analyses and registers cope and varcope images to MNI space (using ANTs) for the Face Reactivity task.
## 6. Runs first-level FEAT analyses and registers cope and varcope images to MNI space (using ANTs) for the Fear Learning task.
## 7. Runs second-level FEAT analyses for all runs of the Extinction Recall task.
## 8. Runs second-level FEAT analyses for specific types (threat or memory) of the Extinction Recall task.
## 9. Runs second-level FEAT analyses for the Reappraisal task.
## 10. Runs second-level FEAT analyses for the Face Reactivity task.
## 11. Uses the makeResults script to create result images for the higher-level FEAT analyses. 
## 12. Uses the getBehavioralDataFiles.sh script to calculate the mean rating for the Extinction Recall and Reappraisal tasks.

# Possible additions / improvements
## 1. Register z-stat images to MNI space (using ANTs).
## 2. Perform FEAT analyses in custom template space (and later warp to MNI space to use standard FSL tools).


.PHONY: feat FirstLevelFeat 
#SecondLevelFeat
#BehavioralStats
.SECONDARY:

feat: FirstLevelFeat 
#SecondLevelFeat ResultImages
#BehavioralStats

#Feat

FirstLevelFeat: $(patsubst %,%.feat/report.html, $(FUNCRUNS))

SecondLevelFeat: $(patsubst %,extinctionrecall/ExtinctionRecall%.gfeat/cope4.feat/stats/cope2.nii.gz, Combined Compared) $(patsubst %,threatreactivity/ThreatReactivity%.gfeat/cope9.feat/stats/cope2.nii.gz, Combined Compared) $(patsubst %,wmshapes/WMShapes%.gfeat/cope4.feat/stats/cope2.nii.gz, Combined Compared) $(patsubst %,wmfaces/WMFaces%.gfeat/cope4.feat/stats/cope2.nii.gz, Combined Compared) $(patsubst %,gng/GNG%.gfeat/cope10.feat/stats/cope2.nii.gz, Combined Compared)


## 1. Runs first-level FEAT analyses.
%.feat/report.html: %_ssmooth.nii.gz %_nuisance_regressors.txt $(STD_BRAIN) $(STANDARD_DIR)/NIHtoMNIWarp.nii.gz $(STANDARD_DIR)/NIHtoMNIAffine.txt xfm_dir/T1_to_nih_deformed.nii.gz xfm_dir/%_to_nih_epireg_ants.nii.gz %-Onsets.txt
	rm -rf `dirname $(word 1,$^)`/`basename $(word 1,$^) _ssmooth.nii.gz`.feat ;\
	D=`dirname $(word 1,$^)` ;\
	RUN=`basename $(word 1,$^) _ssmooth.nii.gz` ;\
	RUNNUM=`echo $${RUN} | grep -o '[0-9]'` ;\
	echo $${RUN} $${RUNNUM} ;\
	NORUNNUM=`echo $${RUN} | sed 's/[0-9]//g'`;\
	NBVOLS=`fslval $(word 1,$^) dim4`;\
	echo $${NBVOLS} $${NORUNNUM} ;\
	sed -e 's/SUBJECT/$(SUBJECT)/g' -e "s/NB/$${NBVOLS}/g" -e "s/RUN/$${RUN}/g" $(TEMPLATES)/FSF/$${D}/$${NORUNNUM}_FL.fsf > $${D}/$${RUN}.fsf ;\
	bash ${SCRIPTpath}/CheckEmptyFiles.sh $${NORUNNUM} $${RUNNUM} $(SUBJECT) ;\
	feat $${D}/$${RUN}.fsf


define prep-feat-reg =
$(subst .feat/,,$(1)).feat/.ANTSREG : $(1)
	export ANTSPATH=$(ANTSpath)
	mkdir -p $(1)reg
	mkdir -p $(1)reg_standard/stats
	cp $(STD_BRAIN) $(1)reg/standard.nii.gz
	cp $(TEMPLATES)/selfreg.mat $(1)reg/example_func2standard.mat
	$(ANTSpath)/WarpImageMultiTransform 3 $(1)/example_func.nii.gz $(1)/reg_standard/example_func.nii.gz -R $(STD_BRAIN) $(STANDARD_DIR)/NIHtoMNIWarp.nii.gz $(STANDARD_DIR)/NIHtoMNIAffine.txt xfm_dir/T1_to_nih_Warp.nii.gz xfm_dir/T1_to_nih_Affine.txt xfm_dir/`dirname $(1)`/`basename $(1) .feat`_to_T1_ras.txt
	$(ANTSpath)/WarpImageMultiTransform 3 $(1)/mean_func.nii.gz $(1)/reg_standard/mean_func.nii.gz -R $(STD_BRAIN) $(STANDARD_DIR)/NIHtoMNIWarp.nii.gz $(STANDARD_DIR)/NIHtoMNIAffine.txt xfm_dir/T1_to_nih_Warp.nii.gz xfm_dir/T1_to_nih_Affine.txt xfm_dir/`dirname $(1)`/`basename $(1) .feat`_to_T1_ras.txt
	$(ANTSpath)/WarpImageMultiTransform 3 $(1)/mask.nii.gz $(1)/reg_standard/mask.nii.gz -R $(STD_BRAIN) $(STANDARD_DIR)/NIHtoMNIWarp.nii.gz $(STANDARD_DIR)/NIHtoMNIAffine.txt xfm_dir/T1_to_nih_Warp.nii.gz xfm_dir/T1_to_nih_Affine.txt xfm_dir/`dirname $(1)`/`basename $(1) .feat`_to_T1_ras.txt
endef

define make-feat-reg-cope =
$(subst stats/,reg_standard/stats/,$(1)) : $(1) $(subst stats/,,$(dir $(1)))
	export ANTSPATH=$(ANTSpath)
	$(ANTSpath)/WarpImageMultiTransform 3 $(1) $$@ -R $(STD_BRAIN) $(STANDARD_DIR)/NIHtoMNIWarp.nii.gz $(STANDARD_DIR)/NIHtoMNIAffine.txt xfm_dir/T1_to_nih_Warp.nii.gz xfm_dir/T1_to_nih_Affine.txt xfm_dir/`dirname $$(word 2,$$^)`/`basename $$(word 2,$$^) .feat`_to_T1_ras.txt
endef

define make-feat-reg-varcope = 
$(subst stats/cope,reg_standard/stats/varcope,$(1)) : $(subst cope,varcope,$(1)) $(subst stats/,,$(dir $(1)))
	export ANTSPATH=$(ANTSpath)
	$(ANTSpath)/WarpImageMultiTransform 3 $(1) $$@ -R $(STD_BRAIN) $(STANDARD_DIR)/NIHtoMNIWarp.nii.gz $(STANDARD_DIR)/NIHtoMNIAffine.txt xfm_dir/T1_to_nih_Warp.nii.gz xfm_dir/T1_to_nih_Affine.txt xfm_dir/`dirname $$(word 2,$$^)`/`basename $$(word 2,$$^) .feat`_to_T1_ras.txt
endef

define make-feat-reg-df =
$(dir $(1))FEtdof_t$(subst cope,,$(notdir $(1))): $(1) $(dir $(subst reg_standard/stats/cope,,$(1)))stats/dof
	fslmaths $(1) -mul 0 -add `cat $$(word 2,$$^)` `dirname $$(word 1,$$^)`/FEtdof_t`basename $(1) .nii.gz | sed 's/cope//g'`
endef

#define make-feat-reg-df =
#$(dir $(subst /reg_standard/stats/cope,,$(1)))/.FINISH-ANTSREG: $(1) $(dir $(1))FEtdof_t$(subst cope,,$(notdir $(1)))
#	touch $@
#endef

$(foreach b,$(allfeatdirs),$(eval $(call prep-feat-reg, $(b))))
$(foreach c,$(allcopes),$(eval $(call make-feat-reg-cope, $(c))))
$(foreach d,$(allcopes),$(eval $(call make-feat-reg-varcope, $(d))))
$(foreach e,$(subst stats/cope,reg_standard/stats/cope,$(allcopes)),$(eval $(call make-feat-reg-df, $(e))))
#$(foreach f,$(subst stats/cope,reg_standard/stats/cope,,$(lastcopes)),$(eval $(call finish-feat-reg, $(f))))

#TODO: Make gfeats more concise
#define run-gfeat =
#$(subst .gfeat,Combined.gfeat,$(1)): $(addsuffix .nii.gz, $(subst .gfeat,1.feat/stats/, $(subst .feat/stats/cope2.nii.gz,,$(1)))) $(addsuffix .nii.gz, $(subst .gfeat,1.feat/stats/, $(subst .feat/stats/cope2.nii.gz,,$(1))))
#	echo "TESTING $(1)"
#endef
#$(foreach g, $(lastgcopes),$(eval $(call run-gfeat, $(g))))

## 2. Runs second-level FEAT analyses for the Face Reactivity task.
threatreactivity/ThreatReactivityCombined.gfeat/cope9.feat/stats/cope2.nii.gz: $(ThreatReactivity_FEAT2Combined_TEMPLATE) $(patsubst %,threatreactivity/ThreatReactivity%.feat/.ANTSREG, 1 2) $(patsubst %,threatreactivity/ThreatReactivity%.feat/reg_standard/stats/cope9.nii.gz, 1 2) $(patsubst %,threatreactivity/ThreatReactivity%.feat/reg_standard/stats/varcope9.nii.gz, 1 2) $(patsubst %,threatreactivity/ThreatReactivity%.feat/reg_standard/stats/FEtdof_t9.nii.gz, 1 2)
oDir=`echo $@ | awk -F "/" '{print $$1"/"$$2}'` ;\
	rm -rf $${oDir} ;\
	sed -e 's/SUBJECT/$(SUBJECT)/g' $(word 1,$^) > $${oDir}.fsf ;\
	feat $${oDir}.fsf

threatreactivity/ThreatReactivityCompared.gfeat/cope9.feat/stats/cope2.nii.gz: $(ThreatReactivity_FEAT2Compared_TEMPLATE) $(patsubst %,threatreactivity/ThreatReactivity%.feat/.ANTSREG, 1 2) $(patsubst %,threatreactivity/ThreatReactivity%.feat/reg_standard/stats/cope9.nii.gz, 1 2) $(patsubst %,threatreactivity/ThreatReactivity%.feat/reg_standard/stats/varcope9.nii.gz, 1 2) $(patsubst %,threatreactivity/ThreatReactivity%.feat/reg_standard/stats/FEtdof_t9.nii.gz, 1 2)
	oDir=`echo $@ | awk -F "/" '{print $$1"/"$$2}'` ;\
	rm -rf $${oDir} ;\
	sed -e 's/SUBJECT/$(SUBJECT)/g' $(word 1,$^) > $${oDir}.fsf ;\
	feat $${oDir}.fsf

## 3. Runs second-level FEAT analyses for the Face Reactivity task.
extinctionrecall/ExtinctionRecallCombined.gfeat/cope4.feat/stats/cope2.nii.gz: $(ExtinctionRecall_FEAT2Combined_TEMPLATE) $(patsubst %,extinctionrecall/ExtinctionRecall%.feat/.ANTSREG, 1 2) $(patsubst %,extinctionrecall/ExtinctionRecall%.feat/reg_standard/stats/cope4.nii.gz, 1 2) $(patsubst %,extinctionrecall/ExtinctionRecall%.feat/reg_standard/stats/varcope4.nii.gz, 1 2) $(patsubst %,extinctionrecall/ExtinctionRecall%.feat/reg_standard/stats/FEtdof_t4.nii.gz, 1 2)
	oDir=`echo $@ | awk -F "/" '{print $$1"/"$$2}'` ;\
	rm -rf $${oDir} ;\
	sed -e 's/SUBJECT/$(SUBJECT)/g' $(word 1,$^) > $${oDir}.fsf ;\
	feat $${oDir}.fsf

extinctionrecall/ExtinctionRecallCompared.gfeat/cope4.feat/stats/cope2.nii.gz: $(ExtinctionRecall_FEAT2Compared_TEMPLATE) $(patsubst %,extinctionrecall/ExtinctionRecall%.feat/.ANTSREG, 1 2) $(patsubst %,extinctionrecall/ExtinctionRecall%.feat/reg_standard/stats/cope4.nii.gz, 1 2) $(patsubst %,extinctionrecall/ExtinctionRecall%.feat/reg_standard/stats/varcope4.nii.gz, 1 2) $(patsubst %,extinctionrecall/ExtinctionRecall%.feat/reg_standard/stats/FEtdof_t4.nii.gz, 1 2)
	oDir=`echo $@ | awk -F "/" '{print $$1"/"$$2}'` ;\
	rm -rf $${oDir} ;\
	sed -e 's/SUBJECT/$(SUBJECT)/g' $(word 1,$^) > $${oDir}.fsf ;\
	feat $${oDir}.fsf ;\

## 4. Runs second-level FEAT analyses for all runs of the WM Shapes task.

wmshapes/WMShapesCombined.gfeat/cope4.feat/stats/cope2.nii.gz: $(WMShapes_FEAT2Combined_TEMPLATE) $(patsubst %,wmshapes/WMShapes%.feat/.ANTSREG, 1 2) $(patsubst %,wmshapes/WMShapes%.feat/reg_standard/stats/cope4.nii.gz, 1 2) $(patsubst %,wmshapes/WMShapes%.feat/reg_standard/stats/varcope4.nii.gz, 1 2) $(patsubst %,wmshapes/WMShapes%.feat/reg_standard/stats/FEtdof_t4.nii.gz, 1 2)
	oDir=`echo $@ | awk -F "/" '{print $$1"/"$$2}'` ;\
	rm -rf $${oDir} ;\
	sed -e 's/SUBJECT/$(SUBJECT)/g' $(word 1,$^) > $${oDir}.fsf ;\
	feat $${oDir}.fsf ;\

wmshapes/WMShapesCompared.gfeat/cope4.feat/stats/cope2.nii.gz: $(WMShapes_FEAT2Compared_TEMPLATE) $(patsubst %,wmshapes/WMShapes%.feat/.ANTSREG, 1 2) $(patsubst %,wmshapes/WMShapes%.feat/reg_standard/stats/cope4.nii.gz, 1 2) $(patsubst %,wmshapes/WMShapes%.feat/reg_standard/stats/varcope4.nii.gz, 1 2) $(patsubst %,wmshapes/WMShapes%.feat/reg_standard/stats/FEtdof_t4.nii.gz, 1 2)
	oDir=`echo $@ | awk -F "/" '{print $$1"/"$$2}'` ;\
	rm -rf $${oDir} ;\
	sed -e 's/SUBJECT/$(SUBJECT)/g' $(word 1,$^) > $${oDir}.fsf ;\
	feat $${oDir}.fsf ;\

## 5. Runs second-level FEAT analyses for all runs of the WM Faces task.

wmfaces/WMFacesCombined.gfeat/cope4.feat/stats/cope2.nii.gz: $(WMFaces_FEAT2Combined_TEMPLATE) $(patsubst %,wmfaces/WMFaces%.feat/.ANTSREG, 1 2) $(patsubst %,wmfaces/WMFaces%.feat/reg_standard/stats/cope4.nii.gz, 1 2) $(patsubst %,wmfaces/WMFaces%.feat/reg_standard/stats/varcope4.nii.gz, 1 2) $(patsubst %,wmfaces/WMFaces%.feat/reg_standard/stats/FEtdof_t4.nii.gz, 1 2)
	oDir=`echo $@ | awk -F "/" '{print $$1"/"$$2}'` ;\
	rm -rf $${oDir} ;\
	sed -e 's/SUBJECT/$(SUBJECT)/g' $(word 1,$^) > $${oDir}.fsf ;\
	feat $${oDir}.fsf ;\

wmfaces/WMFacesCompared.gfeat/cope4.feat/stats/cope2.nii.gz: $(WMFaces_FEAT2Compared_TEMPLATE) $(patsubst %,wmfaces/WMFaces%.feat/.ANTSREG, 1 2) $(patsubst %,wmfaces/WMFaces%.feat/reg_standard/stats/cope4.nii.gz, 1 2) $(patsubst %,wmfaces/WMFaces%.feat/reg_standard/stats/varcope4.nii.gz, 1 2) $(patsubst %,wmfaces/WMFaces%.feat/reg_standard/stats/FEtdof_t4.nii.gz, 1 2)
	oDir=`echo $@ | awk -F "/" '{print $$1"/"$$2}'` ;\
	rm -rf $${oDir} ;\
	sed -e 's/SUBJECT/$(SUBJECT)/g' $(word 1,$^) > $${oDir}.fsf ;\
	feat $${oDir}.fsf ;\

## 6. Runs second-level FEAT analyses for all runs of the WM Faces task.

gng/GNGCombined.gfeat/cope10.feat/stats/cope2.nii.gz: $(GNG_FEAT2Combined_TEMPLATE) $(patsubst %,gng/GNG%.feat/.ANTSREG, 1 2 3) $(patsubst %,gng/GNG%.feat/reg_standard/stats/cope10.nii.gz, 1 2 3) $(patsubst %,gng/GNG%.feat/reg_standard/stats/varcope10.nii.gz, 1 2 3) $(patsubst %,gng/GNG%.feat/reg_standard/stats/FEtdof_t10.nii.gz, 1 2 3)
	oDir=`echo $@ | awk -F "/" '{print $$1"/"$$2}'` ;\
	rm -rf $${oDir} ;\
	sed -e 's/SUBJECT/$(SUBJECT)/g' $(word 1,$^) > $${oDir}.fsf ;\
	feat $${oDir}.fsf ;\

gng/GNGCompared.gfeat/cope10.feat/stats/cope2.nii.gz: $(GNG_FEAT2Compared_TEMPLATE) $(patsubst %,gng/GNG%.feat/.ANTSREG, 1 2) $(patsubst %,gng/GNG%.feat/reg_standard/stats/cope10.nii.gz, 1 2) $(patsubst %,gng/GNG%.feat/reg_standard/stats/varcope10.nii.gz, 1 2) $(patsubst %,gng/GNG%.feat/reg_standard/stats/FEtdof_t10.nii.gz, 1 2)
	oDir=`echo $@ | awk -F "/" '{print $$1"/"$$2}'` ;\
	rm -rf $${oDir} ;\
	sed -e 's/SUBJECT/$(SUBJECT)/g' $(word 1,$^) > $${oDir}.fsf ;\
	feat $${oDir}.fsf ;\


## 11. Uses the makeResults script to create result images for the higher-level FEAT analyses. 

ResultImages: $(patsubst %,threatreactivity/ThreatReactivity%.gfeat/cope9.feat/stats/cope2.nii.gz, Combined Compared)
#$(patsubst %,QA/images/extrecall/ExtRecall%_cope4_zstat2_z.gif, Combined_Sep Combined_NoSep Combined_Sep_Thr Combined_NoSep_Thr Combined_Sep_Mem Combined_NoSep_Mem Compared_Sep Compared_NoSep Compared_Sep_Thr Compared_NoSep_Thr Compared_Sep_Mem Compared_NoSep_Mem) $(patsubst %,threatreactivity/ThreatReactivity%.gfeat/cope9.feat/stats/cope2.nii.gz, Combined Compared) $(patsubst %,reappraisal/Reappraisal%.gfeat/cope13.feat/stats/cope2.nii.gz, Combined_Sep Combined_NoSep Compared_Sep Compared_NoSep) $(patsubst %,QA/images/FaceReactivity%_cope9_zstat2_z.gif, Combined Compared) $(patsubst %,QA/images/Reappraisal%_cope13_zstat2_z.gif, Combined_Sep Combined_NoSep Compared_Sep Compared_NoSep) QA/images/fearLearning/FearLearning_zstat9_z.gif

QA/Images/%_cope4_zstat2_z.gif: %.gfeat/cope4.feat/stats/cope2.nii.gz
	TASK=`echo $(word 1,$^) | awk -F "/" '{print $$1}'` ;\
	RUN=`echo $(word 1,$^) | awk -F "/" '{print $$2}'` ;\
	echo task=$$TASK run=$$RUN ;\
	for i in `ls $${TASK}/$${RUN}/cope*.feat/rendered_thresh_zstat*.nii.gz`; do cope=`echo $$i | awk -F "/" '{print $$3}'`; zstat=`echo $$i | awk -F "/" '{print $$4}'`; cope=$${cope/.feat/}; zstat=`basename $${zstat/rendered_thresh_/} .nii.gz`; echo cope=$$cope zstat=$$zstat; ${SCRIPTpath}/makeResults $$i `dirname $@`/`basename $@ _cope4_zstat2_z.gif`_$${cope}_$${zstat} 2; done ;\
	for j in `dirname $@`/`basename $$RUN .gfeat`_cope*_zstat*_?.png; do convert $$j `dirname $$j`/`basename $$j .png`.gif; done

QA/images/threatreactivity/ThreatReactivity%_cope9_zstat2_z.gif: threatreactivity/ThreatReactivity%.gfeat/cope9.feat/stats/cope2.nii.gz
	TASK=`echo $(word 1,$^) | awk -F "/" '{print $$1}'` ;\
	RUN=`echo $(word 1,$^) | awk -F "/" '{print $$2}'` ;\
	echo task=$$TASK run=$$RUN ;\
	for i in `ls $${TASK}/$${RUN}/cope*.feat/rendered_thresh_zstat*.nii.gz`; do cope=`echo $$i | awk -F "/" '{print $$3}'`; zstat=`echo $$i | awk -F "/" '{print $$4}'`; cope=$${cope/.feat/}; zstat=`basename $${zstat/rendered_thresh_/} .nii.gz`; echo cope=$$cope zstat=$$zstat; ${SCRIPTpath}/makeResults $$i `dirname $@`/`basename $@ _cope9_zstat2_z.gif`_$${cope}_$${zstat} 2; done ;\
	for j in `dirname $@`/`basename $$RUN .gfeat`_cope*_zstat*_?.png; do convert $$j `dirname $$j`/`basename $$j .png`.gif; done


## 12. Uses the getBehavioralDataFiles.sh script to calculate the mean rating for the Extinction Recall and Reappraisal tasks.

BehavioralStats: extrecall/MeanRating.txt reappraisal/MeanRating.txt

extrecall/MeanRating.txt: extrecall/ExtRecall_Thr_1_CSMinus_MeanRating.txt
	bash ${RScripts}/getBehavioralDataFiles.sh ;\

reappraisal/MeanRating.txt: reappraisal/Reappraisal1_Rating.txt
	bash ${RScripts}/getBehavioralDataFiles.sh ;\


