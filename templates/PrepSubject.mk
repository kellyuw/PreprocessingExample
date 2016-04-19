#PrepSubject1.mk
# This makefile:
## 1. Creates symbolic links for processing of the data, while leaving the raw data in an archival directory (nifti) which will be backed up. ##Added to subject_setup.sh!##
## 2. Converts E-Prime text file to tab-delimited file and gets onsets for tasks with various python scripts.
## 3. Starts FreeSurfer recon-all with reoriented T1 image as input and expert options (to set white matter lower threshold at 92).
## 4. Registers FreeSurfer brain to T1 space and performs skullstripping of T1 image (with FreeSurfer brainmask).
## 5. Register T1 to NIH (custom template), MNI (2mm FSL), and FreeSurfer with ANTs.
## 6. Uses optiBET for skull-stripping and registers new skull-strip to nih and mni space (with ANTs).
## 7. Creates movies of raw functional data (for later inclusion in QA reports).
## 8. Calculate similarity between the T1 image and template (for later inclusion in QA reports).
# Possible additions / improvements
## 1. Custom template for the study.

.PHONY: PrepSubject PrepStructurals ReconAll Getonsets struct_registrations RawMovies optiBET TemplateMetrics
.INTERMEDIATE:
.SECONDARY:

PrepSubject: PrepStructurals ReconAll Getonsets struct_registrations RawMovies optiBET TemplateMetrics

## 2. Converts E-Prime text file to tab-delimited file and gets onsets for tasks with various python scripts.

Getonsets: behavior/$(SUBJECT)_reformatted_eprime.csv behavior/$(SUBJECT)_clean_eprime.csv $(patsubst %,behavior/%-eprime.csv, ExtinctionRecall ThreatReactivity WMFaces WMShapes GNG) behavior/AllOnsets.txt $(patsubst %,%-Onsets.txt, $(FUNCRUNS))

behavior/$(SUBJECT)_reformatted_eprime.csv: behavior/fMRI_COMBINED_TASKS_$(SUBJECT).txt
	ruby /usr/local/bin/eprime2tabfile $(word 1,$^) -o $@

behavior/$(SUBJECT)_clean_eprime.csv: behavior/$(SUBJECT)_reformatted_eprime.csv
	python $(PROJECT_DIR)/bin/eprimeparser/CleanEprime-New.py -i $(PROJECT_DIR)/$(SUBJECT)/$(word 1,$^)

behavior/%-eprime.csv: behavior/$(SUBJECT)_clean_eprime.csv nifti/%1.nii.gz
	echo $* ;\
	python $(PROJECT_DIR)/bin/eprimeparser/GetRelCols-New.py -i $(PROJECT_DIR)/$(SUBJECT)/$(word 1,$^) -t $*

behavior/AllOnsets.txt: $(patsubst %,behavior/%-eprime.csv, $(lastword $(notdir $(FUNCNORUNNUM))))
	python $(PROJECT_DIR)/bin/eprimeparser/GetOnsets.py -s $(SUBJECT) > behavior/AllOnsets.txt

%-Onsets.txt: behavior/AllOnsets.txt %Onsets.txt
	mv $(word 2,$^) $@


## 3. Starts FreeSurfer recon-all with reoriented T1 image as input and expert options (to set white matter lower threshold at 92).

ReconAll: mprage/T1.nii.gz $(SUBJECTS_DIR)/$(SUBJECT)/mri/aparc+aseg.mgz

mprage/T1.nii.gz: mprage/MPRAGE.nii.gz
	fslreorient2std mprage/MPRAGE mprage/T1

$(SUBJECTS_DIR)/$(SUBJECT)/mri/aparc+aseg.mgz:  | mprage/T1.nii.gz
	source /usr/local/freesurfer/stable5_3/SetUpFreeSurfer.sh ;\
	export SUBJECTS_DIR=$(SUBJECTS_DIR) ;\
	/usr/local/freesurfer/stable5_3/bin/recon-all -i $(PROJECT_DIR)/$(SUBJECT)/mprage/T1.nii.gz -subjid $(SUBJECT) -all -expert $(PROJECT_DIR)/expert.opts ;\
	touch $(SUBJECTS_DIR)/$(SUBJECT)


## 4. Registers FreeSurfer brain to T1 space and performs skullstripping of T1 image (with FreeSurfer brainmask).

PrepStructurals: xfm_dir/fs_to_T1.mat $(patsubst %,mprage/T1_%.nii.gz, brain brain_mask brain_wmseg) $(patsubst %,QA/Images/%.gif, T1_brain csf gm wm)

xfm_dir/fs_to_T1.mat: $(SUBJECTS_DIR)/$(SUBJECT)/mri/aparc+aseg.mgz mprage/T1.nii.gz
	mkdir -p xfm_dir ;\
	source /usr/local/freesurfer/stable5_3/SetUpFreeSurfer.sh ;\
	export SUBJECTS_DIR=$(SUBJECTS_DIR) ;\
	tkregister2 --mov `dirname $(word 1,$^)`/orig.mgz --targ $(word 2,$^) --noedit --regheader --reg xfm_dir/fs_to_T1.dat --fslregout xfm_dir/fs_to_T1_init.mat ;\
	mri_convert `dirname $(word 1,$^)`/orig.mgz `dirname $(word 1,$^)`/orig.nii.gz ;\
	flirt -ref $(word 2,$^) -in `dirname $(word 1,$^)`/orig.nii.gz -init xfm_dir/fs_to_T1_init.mat -omat $@

# Use registration matrix to create skull stripped brain (T1_brain) from FreeSurfer's skull strip in fsl T1 space

$(SUBJECTS_DIR)/$(SUBJECT)/mri/brainmask.nii.gz: $(SUBJECTS_DIR)/$(SUBJECT)/mri/aparc+aseg.mgz
	source /usr/local/freesurfer/stable5_3/SetUpFreeSurfer.sh ;\
	mri_convert $(SUBJECTS_DIR)/$(SUBJECT)/mri/brainmask.mgz $@

mprage/T1_brain.nii.gz: xfm_dir/fs_to_T1.mat mprage/T1.nii.gz $(SUBJECTS_DIR)/$(SUBJECT)/mri/brainmask.nii.gz
	flirt -ref $(word 2,$^) -in $(word 3,$^) -init $(word 1,$^) -applyxfm -out $@

mprage/T1_brain_mask.nii.gz: mprage/T1_brain.nii.gz
	fslmaths $(word 1,$^) -bin $@

# Do segmentation with fast (only for later use of epi-reg) and make some pretty QA images of the segmentations

mprage/T1_brain_wmseg.nii.gz: mprage/T1_brain.nii.gz xfm_dir/nih_to_T1_flirt.mat $(STANDARD_DIR)/nihpd_t1_prior_csf.nii.gz $(STANDARD_DIR)/nihpd_t1_prior_gm.nii.gz $(STANDARD_DIR)/nihpd_t1_prior_wm.nii.gz
	rm -f $@ ;\
	fast -n 3 -t 1 -a $(word 2,$^) -A $(word 3,$^) $(word 4,$^) $(word 5,$^) -o mprage/T1_brain $(word 1,$^) ;\
	fslmaths mprage/T1_brain_pve_2 -thr 0.5 -bin $@

QA/Images/T1_brain.gif: mprage/T1.nii.gz mprage/T1_brain_mask.nii.gz
	bash $(SCRIPTpath)/MakeSlicerQA.sh overlay $(word 1,$^) $(word 2,$^) $@

QA/Images/csf.gif: mprage/T1_brain.nii.gz mprage/T1_brain_wmseg.nii.gz
	bash $(SCRIPTpath)/MakeSlicerQA.sh overlay $(word 1,$^) mprage/T1_brain_pve_0 $@

QA/Images/gm.gif: mprage/T1_brain.nii.gz mprage/T1_brain_wmseg.nii.gz
	bash $(SCRIPTpath)/MakeSlicerQA.sh overlay $(word 1,$^) mprage/T1_brain_pve_1 $@

QA/Images/wm.gif: mprage/T1_brain.nii.gz mprage/T1_brain_wmseg.nii.gz
	bash $(SCRIPTpath)/MakeSlicerQA.sh overlay $(word 1,$^) mprage/T1_brain_pve_2 $@

## 5. Register T1 to NIH (custom template), MNI (2mm FSL), and FreeSurfer spaces

struct_registrations : $(patsubst %,xfm_dir/T1_to_%.mat, fs nih_flirt) $(patsubst %,xfm_dir/nih_to_%.mat, T1_flirt) $(patsubst %,xfm_dir/T1_to_%_deformed.nii.gz, nih mni) $(patsubst %,xfm_dir/fs_to_%_deformed.nii.gz, nih mni) QA/Images/T1_to_nih_flirt.gif $(patsubst %,QA/Images/T1_to_%_deformed.gif, nih mni) $(patsubst %,QA/Images/fs_to_%_deformed.gif, nih mni)

# Inverse of freesurfer registration matrix
xfm_dir/T1_to_fs.mat: xfm_dir/fs_to_T1.mat
	mkdir -p xfm_dir ;\
	convert_xfm -omat $@ -inverse xfm_dir/fs_to_T1.mat

# FLIRT registrations (T1_to_nih and nih_to_T1)
xfm_dir/T1_to_nih_flirt.mat: mprage/T1_brain.nii.gz $(STANDARD_DIR)/nihpd_t1_brain.nii.gz
	mkdir -p xfm_dir ;\
	flirt -ref $(word 2,$^) -in $(word 1,$^) -omat $@ -out xfm_dir/`basename $@ .mat`.nii.gz

xfm_dir/nih_to_T1_flirt.mat: xfm_dir/T1_to_nih_flirt.mat
	mkdir -p xfm_dir ;\
	convert_xfm -omat $@ -inverse $(word 1,$^)

QA/Images/%_to_nih_flirt.gif: xfm_dir/%_to_nih_flirt.mat $(STANDARD_DIR)/nihpd_t1_brain.nii.gz
	bash $(SCRIPTpath)/MakeSlicerQA.sh slicer `dirname $(word 1,$^)`/`basename $(word 1,$^) .mat`.nii.gz $(word 2,$^) $@

# ANTs registrations (T1_to_nih)
xfm_dir/T1_to_nih_deformed.nii.gz: mprage/T1_brain.nii.gz $(STANDARD_DIR)/nihpd_t1_brain.nii.gz
	mkdir -p xfm_dir ;\
	export ANTSPATH=$(ANTSpath) ;\
	$(ANTSpath)antsIntroduction.sh -d 3 -i $(word 1,$^) -m 30x90x20 -o $(SubjDIR)/xfm_dir/T1_to_nih_ -s CC -r $(word 2,$^) -t GR

QA/Images/T1_to_nih_deformed.gif: xfm_dir/T1_to_nih_deformed.nii.gz $(STANDARD_DIR)/nihpd_t1_brain.nii.gz
	bash $(SCRIPTpath)/MakeSlicerQA.sh slicer $(word 1,$^) $(word 2,$^) $@

# ANTs registrations (T1_to_mni)
xfm_dir/T1_to_mni_deformed.nii.gz: mprage/T1_brain.nii.gz /usr/share/fsl/5.0/data/standard/MNI152_T1_2mm_brain.nii.gz $(STANDARD_DIR)/NIHtoMNIWarp.nii.gz $(STANDARD_DIR)/NIHtoMNIAffine.txt xfm_dir/T1_to_nih_deformed.nii.gz
	mkdir -p xfm_dir ;\
	export ANTSPATH=$(ANTSpath) ;\
	$(ANTSpath)WarpImageMultiTransform 3 $(word 1,$^) $@ -R $(word 2,$^) $(word 3,$^) $(word 4,$^) xfm_dir/`basename $(word 5,$^) _deformed.nii.gz`_Warp.nii.gz xfm_dir/`basename $(word 5,$^) _deformed.nii.gz`_Affine.txt

QA/Images/T1_to_mni_deformed.gif: xfm_dir/T1_to_mni_deformed.nii.gz /usr/share/fsl/5.0/data/standard/MNI152_T1_2mm_brain.nii.gz
	bash $(SCRIPTpath)/MakeSlicerQA.sh slicer $(word 1,$^) $(word 2,$^) $@

# ANTs registrations (fs_to_nih)
xfm_dir/fs_to_nih_deformed.nii.gz: $(SUBJECTS_DIR)/$(SUBJECT)/mri/brainmask.nii.gz $(STANDARD_DIR)/nihpd_t1_brain.nii.gz
	mkdir -p xfm_dir ;\
	export ANTSPATH=$(ANTSpath) ;\
	$(ANTSpath)antsIntroduction.sh -d 3 -i $(word 1,$^) -m 30x90x20 -o $(SubjDIR)/xfm_dir/fs_to_nih_ -s CC -r $(word 2,$^) -t GR

QA/Images/fs_to_nih_deformed.gif: xfm_dir/fs_to_nih_deformed.nii.gz $(STANDARD_DIR)/nihpd_t1_brain.nii.gz
	bash $(SCRIPTpath)/MakeSlicerQA.sh slicer $(word 1,$^) $(word 2,$^) $@

# ANTs registrations (fs_to_mni)
xfm_dir/fs_to_mni_deformed.nii.gz: $(SUBJECTS_DIR)/$(SUBJECT)/mri/brainmask.nii.gz /usr/share/fsl/5.0/data/standard/MNI152_T1_2mm_brain.nii.gz $(STANDARD_DIR)/NIHtoMNIWarp.nii.gz $(STANDARD_DIR)/NIHtoMNIAffine.txt xfm_dir/fs_to_nih_deformed.nii.gz
	mkdir -p xfm_dir ;\
	export ANTSPATH=$(ANTSpath) ;\
	$(ANTSpath)WarpImageMultiTransform 3 $(word 1,$^) $@ -R $(word 2,$^) $(word 3,$^) $(word 4,$^) xfm_dir/`basename $(word 5,$^) _deformed.nii.gz`_Warp.nii.gz xfm_dir/`basename $(word 5,$^) _deformed.nii.gz`_Affine.txt

QA/Images/fs_to_mni_deformed.gif: xfm_dir/fs_to_mni_deformed.nii.gz /usr/share/fsl/5.0/data/standard/MNI152_T1_2mm_brain.nii.gz
	bash $(SCRIPTpath)/MakeSlicerQA.sh slicer $(word 1,$^) $(word 2,$^) $@


## 6. Uses optiBET for skull-stripping and registers new skull-strip to nih and mni space (with ANTs).

optiBET: mprage/T1_optiBET_brain_mask.nii.gz $(patsubst %,QA/Images/T1_optiBET_%.gif, brain_mask to_nih_flirt FS_compare to_mni_deformed) $(patsubst %,xfm_dir/T1_optiBET_%, to_nih_flirt.mat to_mni_deformed.nii.gz) xfm_dir/nih_to_T1_optiBET_flirt.mat

mprage/T1_optiBET_brain_mask.nii.gz: mprage/T1.nii.gz
	bash $(SCRIPTpath)/optiBET.sh -i $(word 1,$^) -t

QA/Images/T1_optiBET_brain_mask.gif: mprage/T1.nii.gz mprage/T1_optiBET_brain_mask.nii.gz
	bash $(SCRIPTpath)/MakeSlicerQA.sh overlay $(word 1,$^) $(word 2,$^) $@

xfm_dir/T1_optiBET_to_nih_flirt.mat: mprage/T1_optiBET_brain.nii.gz $(STANDARD_DIR)/nihpd_t1_brain.nii.gz
	mkdir -p xfm_dir ;\
	flirt -ref $(word 2,$^) -in mprage/T1_optiBET_brain.nii.gz -omat $@ -out xfm_dir/`basename $@ .mat`.nii.gz

xfm_dir/nih_to_T1_optiBET_flirt.mat: xfm_dir/T1_optiBET_to_nih_flirt.mat
	mkdir -p xfm_dir ;\
	convert_xfm -omat $@ -inverse xfm_dir/T1_optiBET_to_nih_flirt.mat

QA/Images/T1_optiBET_to_nih_flirt.gif: xfm_dir/T1_optiBET_to_nih_flirt.mat $(STANDARD_DIR)/nihpd_t1_brain.nii.gz
	bash $(SCRIPTpath)/MakeSlicerQA.sh slicer `dirname $(word 1,$^)`/`basename $(word 1,$^) .mat`.nii.gz $(word 2,$^) $@

xfm_dir/T1_optiBET_to_mni_deformed.nii.gz: mprage/T1_optiBET_brain.nii.gz /usr/share/fsl/5.0/data/standard/MNI152_T1_2mm_brain.nii.gz $(STANDARD_DIR)/NIHtoMNIWarp.nii.gz $(STANDARD_DIR)/NIHtoMNIAffine.txt xfm_dir/T1_to_nih_deformed.nii.gz
	mkdir -p xfm_dir ;\
	export ANTSPATH=$(ANTSpath) ;\
	$(ANTSpath)WarpImageMultiTransform 3 $(word 1,$^) $@ -R $(word 2,$^) $(word 3,$^) $(word 4,$^) xfm_dir/`basename $(word 5,$^) _deformed.nii.gz`_Warp.nii.gz xfm_dir/`basename $(word 5,$^) _deformed.nii.gz`_Affine.txt

QA/Images/T1_optiBET_to_mni_deformed.gif: xfm_dir/T1_optiBET_to_mni_deformed.nii.gz /usr/share/fsl/5.0/data/standard/MNI152_T1_2mm_brain.nii.gz
	bash $(SCRIPTpath)/MakeSlicerQA.sh slicer $(word 1,$^) $(word 2,$^) $@

QA/Images/T1_optiBET_FS_compare.gif: mprage/T1.nii.gz mprage/T1_brain_mask.nii.gz mprage/T1_optiBET_brain_mask.nii.gz
	mkdir -p QA/Images ;\
	/usr/share/fsl/5.0/bin/overlay 1 1 $(word 1,$^) -a $(word 2,$^) 1 10 $(word 3,$^) $(SubjDIR)/QA/Images/rendered_T1_brain.nii.gz ;\
	$(SCRIPTpath)/slices $(SubjDIR)/QA/Images/rendered_T1_brain.nii.gz -o `dirname $@`/`basename $@ .gif`.png
	convert `dirname $@`/`basename $@ .gif`.png -resize 500 $@ ;\
	rm QA/rendered_T1_brain.nii.gz ;\
	rm `dirname $@`/`basename $@ .gif`.png


## 7. Creates movies of raw functional data (for later inclusion in QA reports).

RawMovies:
#$(patsubst %,QA/Images/%_z_animation.gif, $(EPIRUNS))

QA/Images/%_z_animation.gif: %.nii.gz
	mkdir -p `dirname $@`  ;\
	$(SCRIPTpath)/functional_movies_new $(word 1,$^) `dirname $@` 2


## 8. Calculate similarity between the T1 image and template (for later inclusion in QA reports).

TemplateMetrics: $(patsubst %,QA/Images/T1_to_%_similarity.csv, nih mni)

QA/Images/T1_to_nih_similarity.csv: $(STANDARD_DIR)/nihpd_t1_brain.nii.gz xfm_dir/T1_to_nih_deformed.nii.gz
	export ANTSPATH=$(ANTSpath) ;\
	MSQ=`$(ANTSpath)MeasureImageSimilarity 3 0 $(word 1,$^) $(word 2,$^) | grep "MSQ" | awk '{print $$NF}'` ;\
	CC=`$(ANTSpath)MeasureImageSimilarity 3 1 $(word 1,$^) $(word 2,$^) | grep "CC" | awk '{print $$NF}'` ;\
	MI=`$(ANTSpath)MeasureImageSimilarity 3 2 $(word 1,$^) $(word 2,$^) | grep "MI" | awk '{print $$NF}'` ;\
	echo "MSQ,CC,MI" > $@ ;\
	echo "$$MSQ,$$CC,$$MI" >> $@

QA/Images/T1_to_mni_similarity.csv: /usr/share/fsl/5.0/data/standard/MNI152_T1_2mm_brain.nii.gz xfm_dir/T1_to_mni_deformed.nii.gz
	export ANTSPATH=$(ANTSpath) ;\
	MSQ=`$(ANTSpath)MeasureImageSimilarity 3 0 $(word 1,$^) $(word 2,$^) | grep "MSQ" | awk '{print $$NF}'` ;\
	CC=`$(ANTSpath)MeasureImageSimilarity 3 1 $(word 1,$^) $(word 2,$^) | grep "CC" | awk '{print $$NF}'` ;\
	MI=`$(ANTSpath)MeasureImageSimilarity 3 2 $(word 1,$^) $(word 2,$^) | grep "MI" | awk '{print $$NF}'` ;\
	echo "MSQ,CC,MI" > $@ ;\
	echo "$$MSQ,$$CC,$$MI" >> $@
