## Includes PrepSubject.mk, PreprocessSubjects.mk and feat.mk

cwd = $(shell pwd)
# The subject variable is set here and is available to recipes, targets, etc.
SUBJECT=$(notdir $(cwd))

# Set open MP number of threads to be 1, so that we can parallelize using make.
export OMP_NUM_THREADS=1

#Print out variable
print-%  : ; @echo $* = $($*)

SHELL=/bin/bash
PROJECT_DIR=/Users/kelly89/Projects/PreprocessingExample
STANDARD_DIR=$(PROJECT_DIR)/Standard
SUBJECTS_DIR=$(PROJECT_DIR)/FreeSurfer
FSL_DIR=/usr/share/fsl/5.0
AFNIpath=/usr/bin/afni
ANTSpath=/usr/local/ANTs-2.1.0-rc3/bin/
STD_BRAIN=$(FSL_DIR)/data/standard/MNI152_T1_2mm_brain.nii.gz
STD=$(FSL_DIR)/data/standard/MNI152_T1_2mm.nii.gz
SubjDIR=$(PROJECT_DIR)/$(SUBJECT)
SCRIPTpath=$(PROJECT_DIR)/bin
TEMPLATES=$(PROJECT_DIR)/templates
RScripts= $(SCRIPTpath)/QA_RScripts

#First Level FSFs
ExtinctionRecall_FEAT1_TEMPLATE=$(TEMPLATES)/FSF/extinctionrecall/ExtinctionRecall_FL_Sep.fsf
ThreatReactivity_FEAT1_TEMPLATE=$(TEMPLATES)/FSF/threatreactivity/ThreatReactivity_FL.fsf
WMShapes_FEAT1_TEMPLATE=$(TEMPLATES)/FSF/wmshapes/WMShapes_FL.fsf
WMFaces_FEAT1_TEMPLATE=$(TEMPLATES)/FSF/wmfaces/WMFaces_FL.fsf
GNG_FEAT1_TEMPLATE=$(TEMPLATES)/FSF/gng/GNG_FL.fsf

#Second Level FSFs
ThreatReactivity_FEAT2Combined_TEMPLATE=$(TEMPLATES)/FSF/threatreactivity/ThreatReactivity_HL_1Sample.fsf
ThreatReactivity_FEAT2Compared_TEMPLATE=$(TEMPLATES)/FSF/threatreactivity/ThreatReactivity_HL_2Sample.fsf
WMShapes_FEAT2Combined_TEMPLATE=$(TEMPLATES)/FSF/wmshapes/WMShapes_HL_1Sample.fsf
WMShapes_FEAT2Compared_TEMPLATE=$(TEMPLATES)/FSF/wmshapes/WMShapes_HL_2Sample.fsf
WMFaces_FEAT2Combined_TEMPLATE=$(TEMPLATES)/FSF/wmfaces/WMFaces_HL_1Sample.fsf
WMFaces_FEAT2Compared_TEMPLATE=$(TEMPLATES)/FSF/wmfaces/WMFaces_HL_2Sample.fsf
ExtinctionRecall_FEAT2Combined_TEMPLATE=$(TEMPLATES)/FSF/extinctionrecall/ExtinctionRecall_HL_1Sample.fsf
ExtinctionRecall_FEAT2Compared_TEMPLATE=$(TEMPLATES)/FSF/extinctionrecall/ExtinctionRecal_HL_2Sample.fsf
GNG_FEAT2Combined_TEMPLATE=$(TEMPLATES)/FSF/gng/GNG_HL_1Sample.fsf
#GNG_FEAT2Compared_TEMPLATE=$(TEMPLATES)/FSF/gng/GNG_HL_2Sample.fsf

#FEAT variables
allfeatdirs=$(wildcard */*.feat/)
allcopes=$(sort $(wildcard */*.feat/stats/cope*.nii.gz))
allvarcopes=$(subst stats/cope,reg_standard/stats/varcope,$(allcopes))
lastcopes=$(foreach d, $(allfeatdirs), $(lastword $(filter $(d)%,$(allcopes))))
lastgcopes=$(foreach e,$(patsubst %,%.feat/stats/,$(filter %1,$(EPIRUNS))), $(subst .nii.gz,.feat/stats/cope2.nii.gz, $(subst cope,.gfeat/cope, $(subst 1.feat/stats/,,$(filter $(e)%,$(lastcopes))))))


#EPIRuns
THREATREACT=$(patsubst %,threatreactivity/ThreatReactivity%, 1 2)
EXTRECALL=$(patsubst %,extinctionrecall/ExtinctionRecall%, 1 2)
WMFACE=$(patsubst %,wmfaces/WMFaces%, 1 2)
WMSHAPE=$(patsubst %,wmshapes/WMShapes%, 1 2)
GNG=$(patsubst %,gng/GNG%, 1 2 3)
REST=$(patsubst %,rest/%, Rest)
FUNCRUNS=$(patsubst %,%, $(THREATREACT) $(EXTRECALL) $(WMFACE) $(WMSHAPE) $(GNG))
EPIRUNS=$(patsubst %,%, $(THREATREACT) $(EXTRECALL) $(WMFACE) $(WMSHAPE) $(GNG) $(REST))
EPIRUNNAMES=$(notdir $(EPIRUNS))
EPIDIRNAMES=$(dir $(EPIRUNS))
FUNCRUNNAMES=$(notdir $(FUNCRUNS))
EPINORUNNUM=$(subst 1,,$(filter %1,$(EPIRUNS)))
FUNCNORUNNUM=$(subst 1,,$(filter %1,$(FUNCRUNS)))

T1_to_EPI=$(addprefix xfm_dir/,$(join $(EPIDIRNAMES),$(addsuffix .mat, $(addprefix T1_to_,$(EPIRUNNAMES)))))
fs_to_EPI=$(addprefix xfm_dir/,$(join $(EPIDIRNAMES),$(addsuffix .mat, $(addprefix fs_to_,$(EPIRUNNAMES)))))

HWHM=3
TR=2
SLICEORDER='ascending'
FDTHRESH=3

include ./PrepSubject.mk
include ./PreprocessSubject.mk
include ./feat.mk
include ./display.mk

subject: PrepSubject PreprocessSubject feat
