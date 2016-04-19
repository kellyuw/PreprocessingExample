# PreprocessSubject1.mk
# This makefile:
## 1. Uses Alexis Roche's 4dRegister algorithm from NiPy for simultaneous slice-timing and motion correction of functional images.
## 2. Uses bet for skull-stripping functional images with fractional intensity threshold of 0.3 (more conservative than default of 0.5).
## 3. Uses fslMotionOutliers (to find DVARS and FD outliers) and ibicIDSN.sh (to identify signal noise outliers). Also, creates formatted list of all outliers.
## 4. Uses AFNI 3dDespike to remove spikes from data and creates 'despike' and 'spikiness' images for inclusion in QA report.
## 5. Uses SUSAN to spatially smooth despiked data with kernel size of HWHM = 3.
## 6. Uses FSL's epi_reg to register functional (despiked) images to T1. Saves registration matrix in xfm_dir, so that it can be concatenated in more complex registration processes.
## 7. Uses c3d_affine_tool to convert registration matrices from step 6 (functional -> T1) to ITK format (suffix: _ras.txt). The ITK registration matrix (functional -> T1) and ANTs deformation field (T1 -> NIH) can then be used with ANTS WarpImageMultiTransform to register functional images to NIH space.
## 8. Uses ITK-formatted regstration matrices from step 6 (functional -> T1) and ANTs deformation fields (T1 -> NIH, NIH -> MNI) to create series of transformations that ANTs WarpImageMultiTransform will use to register functional images to MNI space.
## 9. Uses BBRegister to create registration matrices from functional -> FreeSurfer space and convert_xfm to create inverse of those registration matrices (for FreeSurfer -> functional registrations).
## 10. Uses c3d_affine_tool to convert registration matrices from step 9 (functional -> FreeSurfer) to ITK format (suffix: _ras.txt). The ITK registration matrix (functional -> FreeSurfer) and ANTs deformation field (FreeSurfer -> NIH) can then be used with ANTS WarpImageMultiTransform to register functional images to NIH space.
## 11. Uses ITK-formatted regstration matrices from step 10 (functional -> FreeSurfer) and ANTs deformation fields (FS -> NIH, NIH -> MNI) to create series of transformations that ANTs WarpImageMultiTransform will use to register functional images to MNI space.
## 12. Uses mri_binarize to extract WM and CSF masks in FreeSurfer space and registers these masks to functional space with FLIRT (using FreeSurfer -> functional registration matrices generated in step #9).
## 13. Runs MotionRegressorGenerator.py to calculate summary statistics about motion (mean and max values for absolute and relative displacement) and then does singular value decomposition (type of PCA) to save degrees of freedom in GLM.
## 14. Uses SinglePointGenerator.py to create list of single point regressors in FSL-compatible format (one column per regressor).
## 15. Pastes together all of the different regressor files (*csf.txt *wm.txt *.par *outlier_regressors.txt) to create single file of nuisance regressors (for inclusion in lower-level FEAT analyses).

# Possible additions / improvements
## 1. Katie's suggestion for SUSAN (set brightness threshold explicitly at .75 * median of tissue intensity instead of auto-set at 10% of robust range, seems to result in noticeably smoother image -> better GLM results?).
## 2. Implement script for creating QA images to reduce redundancy in makefile and improve parallelization.
## 3. Dependency graph / flowchart with makepp.


.PHONY: PreprocessSubject mc_stc bet outliers smooth registrations epi_registrations regressors OutlierRegressors NuisanceRegressors CombinedRegressors melodic MotionRegressors
.SECONDARY:


PreprocessSubject: mc_stc bet outliers smooth registrations epi_registrations regressors OutlierRegressors NuisanceRegressors CombinedRegressors melodic MotionRegressors


## 1. Uses Alexis Roche's 4dRegister algorithm from NiPy for simultaneous slice-timing and motion correction of functional images.

mc_stc: $(patsubst %,%_mc.nii.gz, extinctionrecall/ExtinctionRecall1 threatreactivity/ThreatReactivity1 gng/GNG1 wmfaces/WMFaces1 wmshapes/WMShapes1 rest/Rest) $(patsubst %,QA/Images/%_mc_z_animation.gif, $(EPIRUNS))

define make-mc-image =
%/$(notdir $(1))1_mc.nii.gz: %/$(notdir $(1))1.nii.gz
	python /Users/kelly89/Projects/PreprocessingExample/bin/4dRegister.py --inputs $(wildcard $(dir $(1))*.nii.gz) --tr 2 --slice_order 'ascending'
endef

$(foreach m,$(EPINORUNNUM),$(eval $(call make-mc-image,$(m))))

QA/Images/%_mc_z_animation.gif: %_mc.nii.gz
	$(SCRIPTpath)/functional_movies_new $(word 1,$^) `dirname $@` 2


## 2. Uses bet for skull-stripping functional images with fractional intensity threshold of 0.3 (more conservative than default of 0.5).
bet: $(patsubst %,%_bet.nii.gz, $(EPIRUNS)) $(patsubst %,QA/Images/%_bet_z_animation.gif, $(EPIRUNS))

%_bet.nii.gz: %_mc.nii.gz
	fslroi $(word 1,$^) vol0 0 1 ;\
	bet vol0 vol0 -f 0.3 ;\
	fslmaths vol0 -bin vol0 ;\
	fslmaths $(word 1,$^) -mas vol0 $@ ;\
	rm vol0.nii.gz

QA/Images/%_bet_z_animation.gif: %_bet.nii.gz
	$(SCRIPTpath)/functional_movies_new $(word 1,$^) `dirname $@` 2


## 3. Uses fslMotionOutliers (to find DVARS and FD outliers) and ibicIDSN.sh (to identify signal noise outliers). Also, creates formatted list of all outliers.

outliers: $(patsubst %,%_dvars_regressors, $(EPIRUNS)) $(patsubst %,%_fd_regressors, $(EPIRUNS)) $(patsubst %,%_SN_outliers.txt, $(EPIRUNS)) $(patsubst %,%_all_outliers.txt,$(EPIRUNS))

# fslMotionOutliers using dvars metric
%_dvars_regressors: %_bet.nii.gz
	${SCRIPTpath}/motion_outliers -i $(word 1,$^) -o $@ --dvars -s `dirname $(word 1,$^)`/`basename $(word 1,$^) _bet.nii.gz`_dvars_vals --nomoco ;\
	mv `dirname $(word 1,$^)`/dvars_thresh `dirname $(word 1,$^)`/`basename $(word 1,$^) _bet.nii.gz`_dvars_thresh ;\
	mv `dirname $(word 1,$^)`/dvars_spike_vols `dirname $(word 1,$^)`/`basename $(word 1,$^) _bet.nii.gz`_dvars_spike_vols
	touch $@

# fslMotionOutliers using fd metric and thresh of 3
%_fd_regressors: %_bet.nii.gz
	${SCRIPTpath}/motion_outliers -i $(word 1,$^) -o $@ --fd -s `dirname $(word 1,$^)`/`basename $(word 1,$^) _bet.nii.gz`_fd_vals -c `dirname $(word 1,$^)`/`basename $(word 1,$^) _bet.nii.gz`.par --nomoco --thresh=3 ;\
	mv `dirname $(word 1,$^)`/fd_thresh `dirname $(word 1,$^)`/`basename $(word 1,$^) _bet.nii.gz`_fd_thresh ;\
	mv `dirname $(word 1,$^)`/fd_spike_vols `dirname $(word 1,$^)`/`basename $(word 1,$^) _bet.nii.gz`_fd_spike_vols
	touch $@

# Identify scanner spikes by interrogating the signal outside of the brain
%_SN_outliers.txt: %.nii.gz %_bet.nii.gz
	bash ${SCRIPTpath}/ibicIDSN.sh $(word 1,$^) $(TR) ;\
	touch $@

# Find Unique Outliers
%_all_outliers.txt: %_dvars_regressors %_fd_regressors %_SN_outliers.txt
	cat `dirname $(word 1,$^)`/`basename $(word 1,$^) _regressors`_spike_vols | transpose > alloutliers.txt ;\
	cat `dirname $(word 1,$^)`/`basename $(word 2,$^) _regressors`_spike_vols | transpose >> alloutliers.txt ;\
	cat $(word 3,$^) >> alloutliers.txt ;\
	sort -nu alloutliers.txt > $@ ;\
	rm alloutliers.txt


## 4. Uses AFNI 3dDespike to remove spikes from data and creates 'despike' and 'spikiness' images for inclusion in QA report.

despike: $(patsubst %,%_despike.nii.gz, $(EPIRUNS)) $(patsubst %,QA/Images/%_despike_z_animation.gif, $(EPIRUNS)) $(patsubst %,QA/Images/%_spikiness_z_animation.gif, $(EPIRUNS))

%_despike.nii.gz: %_bet.nii.gz
	@echo "Despiking the functional data with AFNI" ;\
	rm -f `dirname $(word 1,$^)`/despike.nii.gz ;\
	rm -f `dirname $(word 1,$^)`/spikiness.nii.gz ;\
	rm `dirname $(word 1,$^)`/`basename $(word 1,$^) _bet.nii.gz`_despike.nii.gz ;\
	rm `dirname $(word 1,$^)`/`basename $(word 1,$^) _bet.nii.gz`_spikiness.nii.gz ;\
	3dDespike -ssave spikiness -q $(word 1,$^) ;\
	3dAFNItoNIFTI despike+orig.BRIK ;\
	3dAFNItoNIFTI spikiness+orig.BRIK ;\
	mv despike.nii `dirname $(word 1,$^)`/`basename $(word 1,$^) _bet.nii.gz`_despike.nii ;\
	mv spikiness.nii `dirname $(word 1,$^)`/`basename $(word 1,$^) _bet.nii.gz`_spikiness.nii ;\
	gzip `dirname $(word 1,$^)`/`basename $(word 1,$^) _bet.nii.gz`_despike.nii ;\
	gzip `dirname $(word 1,$^)`/`basename $(word 1,$^) _bet.nii.gz`_spikiness.nii ;\
	rm -f despike+orig* ;\
	rm -f spikiness+orig*

QA/Images/%_despike_z_animation.gif: %_despike.nii.gz
	$(SCRIPTpath)/functional_movies_new $(word 1,$^) `dirname $@` 2

QA/Images/%_spikiness_z_animation.gif: %_spikiness.nii.gz
	$(SCRIPTpath)/functional_movies_new $(word 1,$^) `dirname $@` 2


## 5. Uses SUSAN to spatially smooth despiked data with kernel size of HWHM = 3.

smooth: $(patsubst %,%_ssmooth.nii.gz, $(EPIRUNS)) $(patsubst %,QA/Images/%_ssmooth_z_animation.gif, $(EPIRUNS))

%_ssmooth.nii.gz: %_despike.nii.gz
	susan $(word 1,$^) -1.0 $(HWHM) 3 1 0 $@

QA/Images/%_ssmooth_z_animation.gif: %_ssmooth.nii.gz
	$(SCRIPTpath)/functional_movies_new $(word 1,$^) `dirname $@` 2


registrations: epi_registrations fsbb_registrations epireg_ants_registrations epireg_ants_registrations bbr_ants_registrations

## 6. Uses FSL's epi_reg to register functional (despiked) images to T1. Saves registration matrix in xfm_dir, so that it can be concatenated in more complex registration processes.

epi_registrations: $(patsubst %,xfm_dir/%_to_T1.mat, $(EPIRUNS)) $(T1_to_EPI)
#$(patsubst %,QA/Images/%_to_T1.gif, $(EPIRUNS))

xfm_dir/%_to_T1.mat: %_despike.nii.gz mprage/T1.nii.gz mprage/T1_brain.nii.gz
	mkdir -p `dirname $@` ;\
	fslroi $(word 1,$^) `dirname $(word 1,$^)`/`basename $(word 1,$^) .nii.gz`_vol0 0 1 ;\
	epi_reg --epi=`dirname $(word 1,$^)`/`basename $(word 1,$^) .nii.gz`_vol0  --t1=$(word 2,$^) --t1brain=$(word 3,$^) --out=`dirname $@`/`basename $@ .mat`

define inverse-mat-T1 =
$(dir $(1))T1_to_%.mat: $(dir $(1))%_to_T1.mat
	mkdir -p `dirname $$@` ;\
	convert_xfm -omat $$@ -inverse $$<
endef

$(foreach a,$(T1_to_EPI),$(eval $(call inverse-mat-T1,$(a))))

QA/Images/%_to_T1.gif: xfm_dir/%_to_T1.mat mprage/T1_brain.nii.gz
	bash $(SCRIPTpath)/MakeSlicerQA.sh slicer `dirname $(word 1,$^)`/`basename $(word 1,$^) .mat`.nii.gz $(word 2,$^) $@


## 7. Uses c3d_affine_tool to convert registration matrices from step 6 (functional -> T1) to ITK format (suffix: _ras.txt). The ITK registration matrix (functional -> T1) and ANTs deformation field (T1 -> NIH) can then be used with ANTS WarpImageMultiTransform to register functional images to NIH space.

epireg_ants_registrations: $(patsubst %,xfm_dir/%_to_nih_epireg_ants.nii.gz, $(EPIRUNS)) $(patsubst %,xfm_dir/%_to_mni_epireg_ants.nii.gz, $(EPIRUNS)) $(patsubst %,QA/Images/%_to_nih_epireg_ants.gif, $(EPIRUNS)) $(patsubst %,QA/Images/%_to_mni_epireg_ants.gif, $(EPIRUNS))

xfm_dir/%_to_nih_epireg_ants.nii.gz: %_despike.nii.gz $(STANDARD_DIR)/nihpd_t1_brain.nii.gz mprage/T1_brain.nii.gz xfm_dir/%_to_T1.mat xfm_dir/T1_to_nih_deformed.nii.gz
	mkdir -p `dirname $@` ;\
	fslroi $(word 1,$^) `dirname $(word 1,$^)`/`basename $(word 1,$^) .nii.gz`_vol0 0 1 ;\
	export ANTSPATH=$(ANTSpath) ;\
	${SCRIPTpath}/c3d/bin/c3d_affine_tool -ref $(word 3,$^) -src `dirname $(word 1,$^)`/`basename $(word 1,$^) .nii.gz`_vol0 $(word 4,$^) -fsl2ras -oitk `dirname $@`/`basename $(word 4,$^) .mat`_ras.txt ;\
	$(ANTSpath)/WarpImageMultiTransform 3 `dirname $(word 1,$^)`/`basename $(word 1,$^) .nii.gz`_vol0.nii.gz $@ -R $(word 2,$^) xfm_dir/`basename $(word 5,$^) _deformed.nii.gz`_Warp.nii.gz xfm_dir/`basename $(word 5,$^) _deformed.nii.gz`_Affine.txt `dirname $@`/`basename $(word 4,$^) .mat`_ras.txt

QA/Images/%_to_nih_epireg_ants.gif: xfm_dir/%_to_nih_epireg_ants.nii.gz  $(STANDARD_DIR)/nihpd_t1_brain.nii.gz
	bash $(SCRIPTpath)/MakeSlicerQA.sh slicer $(word 1,$^) $(word 2,$^) $@


## 8. Uses ITK-formatted regstration matrices from step 7 (functional -> T1) and ANTs deformation fields (T1 -> NIH, NIH -> MNI) to create series of transformations that ANTs WarpImageMultiTransform will use to register functional images to MNI space.

xfm_dir/%_to_mni_epireg_ants.nii.gz: %_despike.nii.gz $(STD_BRAIN) $(STANDARD_DIR)/NIHtoMNIWarp.nii.gz $(STANDARD_DIR)/NIHtoMNIAffine.txt xfm_dir/T1_to_nih_deformed.nii.gz xfm_dir/%_to_nih_epireg_ants.nii.gz
	mkdir -p `dirname $@` ;\
	fslroi $(word 1,$^) `dirname $(word 1,$^)`/`basename $(word 1,$^) .nii.gz`_vol0 0 1 ;\
	export ANTSPATH=$(ANTSpath) ;\
	$(ANTSpath)/WarpImageMultiTransform 3 `dirname $(word 1,$^)`/`basename $(word 1,$^) .nii.gz`_vol0.nii.gz $@ -R $(word 2,$^) $(word 3,$^) $(word 4,$^) `dirname $(word 5,$^)`/`basename $(word 5,$^) _deformed.nii.gz`_Warp.nii.gz `dirname $(word 5,$^)`/`basename $(word 5,$^) _deformed.nii.gz`_Affine.txt `dirname $@`/`basename $@ _mni_epireg_ants.nii.gz`_T1_ras.txt

QA/Images/%_to_mni_epireg_ants.gif: xfm_dir/%_to_mni_epireg_ants.nii.gz $(STD_BRAIN)
	bash $(SCRIPTpath)/MakeSlicerQA.sh slicer $(word 1,$^) $(word 2,$^) $@


## 9. Uses BBRegister to create registration matrices from functional -> FreeSurfer space and convert_xfm to create inverse of those registration matrices (for FreeSurfer -> functional registrations).

fsbb_registrations: $(patsubst %,xfm_dir/%_to_fs.mat, $(EPIRUNS)) $(fs_to_EPI) $(patsubst %,QA/Images/%_to_fs.mat, $(EPIRUNS))
#$(patsubst %,xfm_dir/extinctionrecall/fs_to_ExtinctionRecall%.mat, 1 2) $(patsubst %,xfm_dir/threatreactivity/fs_to_ThreatReactivity%.mat, 1 2) xfm_dir/rest/fs_to_rest.mat

xfm_dir/%_to_fs.mat: %_despike.nii.gz  $(SUBJECTS_DIR)/$(SUBJECT)/mri/aparc+aseg.mgz
	mkdir -p `dirname $@` ;\
	source /usr/local/freesurfer/stable5_3/SetUpFreeSurfer.sh ;\
	export SUBJECTS_DIR=$(SUBJECTS_DIR) ;\
	fslroi $(word 1,$^) `dirname $(word 1,$^)`/`basename $(word 1,$^) .nii.gz`_vol0 0 1 ;\
	bbregister --s $(SUBJECT) --mov `dirname $(word 1,$^)`/`basename $(word 1,$^) .nii.gz`_vol0.nii.gz --reg `dirname $@`/`basename $@ .mat`.dat --init-fsl --bold --o `dirname $@`/`basename $@ .mat`.nii.gz --fslmat $@

define inverse-mat-fs =
$(dir $(1))fs_to_%.mat: $(dir $(1))%_to_fs.mat
	mkdir -p `dirname $$@` ;\
	convert_xfm -omat $$@ -inverse $$<
endef

$(foreach b,$(fs_to_EPI),$(eval $(call inverse-mat-fs,$(b))))

QA/Images/%_to_fs.gif: xfm_dir/%_to_fs.mat $(SUBJECTS_DIR)/$(SUBJECT)/mri/brainmask.nii.gz
	mkdir -p `dirname $@` ;\
	fslreorient2std `dirname $@`/`basename $(word 1,$^) .mat`.nii.gz func.nii.gz ;\
	fslreorient2std $(word 2,$^) fs_to_std.nii.gz ;\
	/usr/share/fsl/5.0/bin/slicer func.nii.gz fs_to_std.nii.gz -s 2 -x 0.35 sla.png -x 0.45 slb.png -x 0.55 slc.png -x 0.65 sld.png -y 0.35 sle.png -y 0.45 slf.png -y 0.55 slg.png -y 0.65 slh.png -z 0.35 sli.png -z 0.45 slj.png -z 0.55 slk.png -z 0.65 sll.png ;\
	pngappend sla.png + slb.png + slc.png + sld.png + sle.png + slf.png + slg.png + slh.png + sli.png + slj.png + slk.png + sll.png QA/intermediate1.png ;\
	/usr/share/fsl/5.0/bin/slicer fs_to_std.nii.gz func.nii.gz -s 2 -x 0.35 sla.png -x 0.45 slb.png -x 0.55 slc.png -x 0.65 sld.png -y 0.35 sle.png -y 0.45 slf.png -y 0.55 slg.png -y 0.65 slh.png -z 0.35 sli.png -z 0.45 slj.png -z 0.55 slk.png -z 0.65 sll.png ;\
	pngappend sla.png + slb.png + slc.png + sld.png + sle.png + slf.png + slg.png + slh.png + sli.png + slj.png + slk.png + sll.png QA/intermediate2.png ;\
	pngappend QA/intermediate1.png - QA/intermediate2.png `dirname $@`/`basename $@ .gif`.png ;\
	rm -f sl?.png QA/intermediate?.png func.nii.gz fs_to_std.nii.gz ;\
	convert `dirname $@`/`basename $@ .gif`.png $@


## 10. Uses c3d_affine_tool to convert registration matrices from step 6 (functional -> FreeSurfer) to ITK format (suffix: _ras.txt). The ITK registration matrix (functional -> FreeSurfer) and ANTs deformation field (FreeSurfer -> NIH) can then be used with ANTS WarpImageMultiTransform to register functional images to NIH space.

bbr_ants_registrations: $(patsubst %,xfm_dir/%_to_nih_bbr_ants.nii.gz, $(EPIRUNS)) $(patsubst %,xfm_dir/%_to_mni_bbr_ants.nii.gz, $(EPIRUNS)) $(patsubst %,QA/Images/%_to_nih_bbr_ants.gif, $(EPIRUNS)) $(patsubst %,QA/Images/%_to_mni_bbr_ants.gif, $(EPIRUNS))

xfm_dir/%_to_nih_bbr_ants.nii.gz: %_despike.nii.gz $(STANDARD_DIR)/nihpd_t1_brain.nii.gz $(SUBJECTS_DIR)/$(SUBJECT)/mri/brainmask.nii.gz xfm_dir/%_to_fs.mat xfm_dir/fs_to_nih_deformed.nii.gz
	mkdir -p `dirname $@` ;\
	fslroi $(word 1,$^) `dirname $(word 1,$^)`/`basename $(word 1,$^) .nii.gz`_vol0 0 1 ;\
	export ANTSPATH=$(ANTSpath) ;\
	${SCRIPTpath}/c3d/bin/c3d_affine_tool -ref $(word 3,$^) -src `dirname $(word 1,$^)`/`basename $(word 1,$^) .nii.gz`_vol0 $(word 4,$^) -fsl2ras -oitk `dirname $(word 4,$^)`/`basename $(word 4,$^) .mat`_ras.txt ;\
	$(ANTSpath)WarpImageMultiTransform 3 `dirname $(word 1,$^)`/`basename $(word 1,$^) .nii.gz`_vol0.nii.gz $@ -R $(word 2,$^) xfm_dir/`basename $(word 5,$^) _deformed.nii.gz`_Warp.nii.gz xfm_dir/`basename $(word 5,$^) _deformed.nii.gz`_Affine.txt `dirname $(word 4,$^)`/`basename $(word 4,$^) .mat`_ras.txt

QA/Images/%_to_nih_bbr_ants.gif: xfm_dir/%_to_nih_bbr_ants.nii.gz  $(STANDARD_DIR)/nihpd_t1_brain.nii.gz
	bash $(SCRIPTpath)/MakeSlicerQA.sh slicer $(word 1,$^) $(word 2,$^) $@


## 11. Uses ITK-formatted registration matrices from step 10 (functional -> FreeSurfer) and ANTs deformation fields (FS -> NIH, NIH -> MNI) to create series of transformations that ANTs WarpImageMultiTransform will use to register functional images to MNI space.

xfm_dir/%_to_mni_bbr_ants.nii.gz: %_despike.nii.gz $(STD_BRAIN) $(STANDARD_DIR)/NIHtoMNIWarp.nii.gz $(STANDARD_DIR)/NIHtoMNIAffine.txt xfm_dir/fs_to_nih_deformed.nii.gz xfm_dir/%_to_nih_bbr_ants.nii.gz
	mkdir -p `dirname $@` ;\
	fslroi $(word 1,$^) `dirname $(word 1,$^)`/`basename $(word 1,$^) .nii.gz`_vol0 0 1 ;\
	export ANTSPATH=$(ANTSpath) ;\
	$(ANTSpath)WarpImageMultiTransform 3 `dirname $(word 1,$^)`/`basename $(word 1,$^) .nii.gz`_vol0.nii.gz $@ -R $(word 2,$^) $(word 3,$^) $(word 4,$^) xfm_dir/`basename $(word 5,$^) _deformed.nii.gz`_Warp.nii.gz xfm_dir/`basename $(word 5,$^) _deformed.nii.gz`_Affine.txt `dirname $@`/`basename $(word 1,$^) _despike.nii.gz`_to_fs_ras.txt

QA/Images/%_to_mni_bbr_ants.gif: xfm_dir/%_to_mni_bbr_ants.nii.gz $(STD_BRAIN)
	bash $(SCRIPTpath)/MakeSlicerQA.sh slicer $(word 1,$^) $(word 2,$^) $@


## 12. Uses mri_binarize to extract WM and CSF masks in FreeSurfer space and registers these masks to functional space with FLIRT (using FreeSurfer -> functional registration matrices generated in step #9).

regressors: fs_wm_mask.nii.gz fs_ventricles_mask.nii.gz $(patsubst %,%_wm.txt,$(EPIRUNS)) $(patsubst %,%_csf.txt, $(EPIRUNS)) $(patsubst %,QA/Images/%_wm.gif,$(EPIRUNS)) $(patsubst %,QA/Images/%_csf.gif,$(EPIRUNS))

#WM

fs_wm_mask.nii.gz: $(SUBJECTS_DIR)/$(SUBJECT)/mri/aparc+aseg.mgz
	source /usr/local/freesurfer/stable5_3/SetUpFreeSurfer.sh ;\
	export SUBJECTS_DIR=$(SUBJECTS_DIR) ;\
	mri_binarize --i $(word 1,$^) --o $@ --erode 1 --wm

define warp-wm =
$(dir $(1))%_wm.txt: fs_wm_mask.nii.gz $(dir $(1))%_despike.nii.gz xfm_dir/$(dir $(1))fs_to_%.mat
	flirt  -ref $$(word 2,$$^) -in $$(word 1,$$^) -out `dirname $$@`/`basename $$@ .txt`.nii.gz  -applyxfm -init $$(word 3,$$^) ;\
	fslmaths `dirname $$@`/`basename $$@ .txt`.nii.gz -thr .5 `dirname $$@`/`basename $$@ .txt`.nii.gz ;\
	fslmeants -i $$(word 2,$$^) -o  $$@ -m `dirname $$@`/`basename $$@ .txt`.nii.gz
endef

$(foreach c,$(patsubst %,%_wm.txt,$(EPIRUNS)),$(eval $(call warp-wm,$(c))))

QA/Images/%_wm.gif: %_despike.nii.gz %_wm.txt
	mkdir -p `dirname $@` ;\
	fslroi $(word 1,$^) `dirname $(word 1, $^)`/`basename $(word 1,$^) _despike.nii.gz`_vol0 0 1 ;\
	/usr/share/fsl/5.0/bin/overlay 1 1 `dirname $(word 1, $^)`/`basename $(word 1,$^) _despike.nii.gz`_vol0.nii.gz -a `dirname $(word 1, $^)`/`basename $(word 1,$^) _despike.nii.gz`_wm.nii.gz 1 10 `dirname $@`/rendered_wm_mask_in_`basename $(word 1,$^) _despike.nii.gz`.nii.gz ;\
	$(SCRIPTpath)/slices `dirname $@`/rendered_wm_mask_in_`basename $(word 1,$^) _despike.nii.gz`.nii.gz -o `dirname $@`/`basename $@ .gif`.png ;\
	convert `dirname $@`/`basename $@ .gif`.png $@

#CSF

fs_ventricles_mask.nii.gz: $(SUBJECTS_DIR)/$(SUBJECT)/mri/aparc+aseg.mgz
	source /usr/local/freesurfer/stable5_3/SetUpFreeSurfer.sh ;\
	export SUBJECTS_DIR=$(SUBJECTS_DIR) ;\
	mri_binarize --i $(word 1,$^) --o $@ --erode 1 --ventricles

define warp-csf =
$(dir $(1))%_csf.txt: fs_ventricles_mask.nii.gz $(dir $(1))%_despike.nii.gz xfm_dir/$(dir $(1))fs_to_%.mat
	flirt  -ref $$(word 2,$$^) -in $$(word 1,$$^) -out `dirname $$@`/`basename $$@ .txt`.nii.gz  -applyxfm -init $$(word 3,$$^) ;\
	fslmaths `dirname $$@`/`basename $$@ .txt`.nii.gz -thr .5 `dirname $$@`/`basename $$@ .txt`.nii.gz ;\
	fslmeants -i $$(word 2,$$^) -o  $$@ -m `dirname $$@`/`basename $$@ .txt`.nii.gz
endef

$(foreach d,$(patsubst %,%_csf.txt,$(EPIRUNS)),$(eval $(call warp-csf,$(d))))

QA/Images/%_csf.gif: %_despike.nii.gz %_csf.txt
	mkdir -p `dirname $@` ;\
	fslroi $(word 1,$^) `dirname $(word 1, $^)`/`basename $(word 1,$^) _despike.nii.gz`_vol0 0 1 ;\
	/usr/share/fsl/5.0/bin/overlay 1 1 `dirname $(word 1, $^)`/`basename $(word 1,$^) _despike.nii.gz`_vol0.nii.gz -a `dirname $(word 1, $^)`/`basename $(word 1,$^) _despike.nii.gz`_csf.nii.gz 1 10 `dirname $@`/rendered_csf_mask_in_`basename $(word 1,$^) _despike.nii.gz`.nii.gz ;\
	$(SCRIPTpath)/slices `dirname $@`/rendered_csf_mask_in_`basename $(word 1,$^) _despike.nii.gz`.nii.gz -o `dirname $@`/`basename $@ .gif`.png ;\
	convert `dirname $@`/`basename $@ .gif`.png $@


## 13. Uses MotionRegressorGenerator.py to calculate summary statistics about motion (mean and max values for absolute and relative displacement) and then does singular value decomposition (type of PCA) to save degrees of freedom in GLM.

MotionRegressors: $(patsubst %,%_rel_pc1_percent.txt, $(EPIRUNS)) $(patsubst %,%_abs_pc1_percent.txt, $(EPIRUNS))

%_rel_pc1_percent.txt: %.par
	python /mnt/stressdevlab/bin/MotionRegressorGenerator.py -i $(word 1,$^) -o `basename $(word 1,$^) .par` ;\
	TASK=`basename $(word 1,$^) .par` ;\
	for i in `ls $${TASK}*`; do mv $${i} `dirname $(word 1,$^)`; done ;\

%_abs_pc1.txt: %_mc.nii.gz
	python ${SCRIPTpath}/MotionRegressorGenerator.py -i `dirname $(word 1,$^)`/`basename $(word 1,$^) _mc.nii.gz`.par -o `dirname $(word 1,$^)`/`basename $(word 1,$^) _mc.nii.gz`


## 13. Uses SinglePointGenerator.py to create list of single point regressors in FSL-compatible format (one column per regressor).
OutlierRegressors: $(patsubst %,%_outlier_regressors.txt, $(EPIRUNS))

%_outlier_regressors.txt: %.nii.gz %_all_outliers.txt
	vols=`fslval $(word 1,$^) dim4` ;\
	python ${SCRIPTpath}/SinglePointGenerator.py -i $(word 2,$^) -v $$vols -o $@ -p `dirname $(word 1,$^)`/`basename $(word 1,$^) .nii.gz`_percent_outliers.txt ;\
	touch $@


## 14. Pastes together all of the different regressor files (*csf.txt *wm.txt *.par *outlier_regressors.txt) to create single file of nuisance regressors (for inclusion in lower-level FEAT analyses).

NuisanceRegressors: $(patsubst %,%_nuisance_regressors.txt, $(EPIRUNS))

%_nuisance_regressors.txt: %_csf.txt %_wm.txt %_outlier_regressors.txt %_bet.nii.gz
	paste $(word 1,$^) $(word 2,$^) `dirname $(word 4,$^)`/`basename $(word 4,$^) _bet.nii.gz`.par $(word 3,$^) > $@


## 15. Creates rest_regressors.feat.mat file for input into fsl_regfilt (from parameters in rest_nuisance_regressors.txt file). The image generated by fsl_regfilt (rest_postregression.nii.gz) is then fed into FSL Melodic to conduct ICA on the resting-state scan.

melodic: rest/Rest_designrange.txt rest/Rest_postregression.nii.gz rest/Rest.ica

rest/Rest_designrange.txt: rest/Rest_nuisance_regressors.txt
	Rscript $(SCRIPTpath)/rangeArray.R $< $@

rest/Rest_postregression.nii.gz: rest/Rest_ssmooth.nii.gz rest/Rest_nuisance_regressors.txt rest/Rest_designrange.txt
	npc=`awk '{print NF}' $(word 2, $^) | sort -nu | tail -n 1` ;\
	npts=`wc -l $(word 2, $^)` ;\
	echo "/NumWaves $$npc" >  `dirname $(word 1,$^)`/`basename $(word 1,$^) _ssmooth.nii.gz`_regressors.feat.mat ;\
	echo "/NumPoints $$npts" >> `dirname $(word 1,$^)`/`basename $(word 1,$^) _ssmooth.nii.gz`_regressors.feat.mat ;\
	echo "/PPheights " `cat $(word 3, $^)` >> `dirname $(word 1,$^)`/`basename $(word 1,$^) _ssmooth.nii.gz`_regressors.feat.mat ;\
	echo "/Matrix" >> `dirname $(word 1,$^)`/`basename $(word 1,$^) _ssmooth.nii.gz`_regressors.feat.mat ;\
	cat $(word 2, $^) >> `dirname $(word 1,$^)`/`basename $(word 1,$^) _ssmooth.nii.gz`_regressors.feat.mat ;\
	reglist="1"; for i in `seq 2 $$npc`; do reglist=`echo $$reglist`,$$i; done ;\
	echo $$reglist ;\
	fsl_regfilt -i  $(word 1, $^) -d `dirname $(word 1,$^)`/`basename $(word 1,$^) _ssmooth.nii.gz`_regressors.feat.mat -f $$reglist -o $@

rest/Rest.ica/: rest/Rest_postregression.nii.gz
	@echo "Running FSL Melodic" ;\
	melodic -i $< -o $@ --tr=$(TR) --report ;\
	touch $@


## 16. DTI preprocessing with script from Todd

#dti: dti/dDTI32FA.nii.gz
#
#dti/dDTI32FA.nii.gz: parrecs/DTI32.PAR parrecs/DTI32.REC /NAS_II/Projects/K_lab/SCRIPTS/Todds_DTI_scripts/dtiprep_script_tbss_step1_child_emotion.sh
#	rm -rf dti/* ;\
#	cp $(word 1,$^) dti/`basename $(word 1,$^)` ;\
# cp $(word 2,$^) dti/`basename $(word 2,$^)` ;\
#	mv dti ;\
#	bash /NAS_II/Projects/K_lab/SCRIPTS/Todds_DTI_scripts/dtiprep_script_tbss_step1_child_emotion.sh $(SUBJECT) $(SESSION_NUM)
#

#clean
