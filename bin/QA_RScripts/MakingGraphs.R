library(dplyr)
library(tidyr)
library(ggplot2)

if (file.exists("/mnt/stressdevlab/dep_threat_pipeline/SUBJECT/TASK/RUN.par")){
  UnCorrectedData <- read.table("/mnt/stressdevlab/dep_threat_pipeline/SUBJECT/TASK/RUN.par")
  x <- UnCorrectedData$V1
  y <- UnCorrectedData$V2
  z <- UnCorrectedData$V3
  png('/mnt/stressdevlab/dep_threat_pipeline/SUBJECT/QA/Images/TASK/RUN_MotionGraphRotations.png')
  plot(c(1:length(UnCorrectedData$V1)),x,xlab="Slice number",ylab="rotations rad",col="blue",ylim=c(-0.06,0.06), type="l",lwd=3, main="Rotations")
  lines(y, type="l", col="goldenrod", lwd=3)
  lines(z, type="l", col="darkgreen", lwd=3)
  dev.off()
}

if (file.exists("/mnt/stressdevlab/dep_threat_pipeline/SUBJECT/TASK/RUN.par")){
  UnCorrectedData <- read.table("/mnt/stressdevlab/dep_threat_pipeline/SUBJECT/TASK/RUN.par")
  x <- UnCorrectedData$V4
  y <- UnCorrectedData$V5
  z <- UnCorrectedData$V6
  png('/mnt/stressdevlab/dep_threat_pipeline/SUBJECT/QA/Images/TASK/RUN_MotionGraphTranslations.png')
  plot(c(1:length(UnCorrectedData$V1)),x,xlab="Slice number",ylab="Translations mm",col="blue",ylim=c(-9,9), type="l",lwd=3, main="Translations")
  lines(y, type="l", col="goldenrod", lwd=3)
  lines(z, type="l", col="darkgreen", lwd=3)
  dev.off()
}

if (file.exists("/mnt/stressdevlab/dep_threat_pipeline/SUBJECT/TASK/RUN_fd_vals")) {
  fdVals <- read.table("/mnt/stressdevlab/dep_threat_pipeline/SUBJECT/TASK/RUN_fd_vals", header=FALSE)
  fdValsTable <- mutate(fdVals, iNum = rownames(fdVals))
  fdThresh <- read.table("/mnt/stressdevlab/dep_threat_pipeline/SUBJECT/TASK/RUN_fd_thresh", header=FALSE)
  png('/mnt/stressdevlab/dep_threat_pipeline/SUBJECT/QA/Images/TASK/RUN_fd_vals.png')
  plot( x = fdValsTable$iNum, y = fdValsTable$V1, type = "l", xlab="Slice number", ylab="fdVals",col="blue",ylim=c(0,5), lwd=5)
  abline (h = fdThresh, col="red")
  dev.off()
}

if (file.exists("/mnt/stressdevlab/dep_threat_pipeline/SUBJECT/TASK/RUN_dvars_vals")) {
  dVars <- read.table("/mnt/stressdevlab/dep_threat_pipeline/SUBJECT/TASK/RUN_dvars_vals", header=FALSE)
  dVarsTable <- mutate(dVars, iNum = rownames(dVars))
  dVarsThresh <- read.table("/mnt/stressdevlab/dep_threat_pipeline/SUBJECT/TASK/RUN_dvars_thresh", header=FALSE) 
  png('/mnt/stressdevlab/dep_threat_pipeline/SUBJECT/QA/Images/TASK/RUN_dvars_vals.png')
  plot( x = dVarsTable$iNum, y = dVarsTable$V1, type = "l", xlab="Slice number", ylab="dVars",col="blue",ylim=c(0,50), lwd=5)
  abline (h = dVarsThresh, col="red")
  dev.off()
}
