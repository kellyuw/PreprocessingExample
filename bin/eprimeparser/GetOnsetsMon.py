##GetOnsets.py
## 1. Checks for Simpsons characters in each task-specific behavioral file.
## 2. Checks if corresponding image file exists in the subject's directory.
## 3. Uses functions defined in cells below to parse behavioral data for each task.

## Python dependencies
import pandas as pd
import numpy as np
import argparse
import csv
import os
import re

#Pull the data in based on a parameter entered at the command line
parser = argparse.ArgumentParser()
parser.add_argument('--subject', '-s', required=True, help='Name of subject to be processed')
args = parser.parse_args()
subject = args.subject

SubjectDir = '/mnt/stressdevlab/dep_threat_pipeline/' + str(subject) + '/'

## Utility functions

# Emulate unix touch (create dummy text file to mark progress in getting onsets)
def Touch(path):
    with open(path, 'a'):
        os.utime(path, None)


## Check if image file exists and return helpful information about the run
def GetRunData (Run):
    Task = filter(lambda x: x.isalpha(), Run)
    RunNum = str(re.findall('\d+', str(Run)))[2]
    FullTaskDir = str(SubjectDir) + Task.lower() + '/' + Run
    runData = {'RunNum': str(RunNum), 
               'Run': str(Run), 
               'RunName': Task + 'Run' + RunNum, 
               'Task': Task,
               'FullTaskDir': str(FullTaskDir),
               'ImageFileExists': str(os.path.exists(str(FullTaskDir + '.nii.gz')))}
    return runData


## Make Simpsons EV files
def FindSimpsons (data, runData):

    #Check here for columns that contain a SimpsonOnsetTime
    for OnsetTime in data.filter(like="SimpsonOnsetTime").columns.values:

        #Get Simpsons character here to create appropriate strings
        SimpsonChar = OnsetTime.split('Simpson')[0]
        SimpsonCharOnsetStr = SimpsonChar + 'SimpsonOnsetTime'
        SimpsonCharOnsetToOnsetStr = SimpsonChar + 'SimpsonOnsetToOnsetTime'

        #Simpson onset is all rows where SimpsonCharOnsetTime > 0
        SimpsonOnset = data[(data[SimpsonCharOnsetStr] > 0)]
        SimpsonOnsetTime = SimpsonOnset[[SimpsonCharOnsetStr]]
        TriggerWAITRTTimeBlock = SimpsonOnset[['TriggerWAITRTTimeBlock']]

        #Calibrate Simpson onset time with TriggerWAITRTTimeBlock
        AdjSimpsonOnset = ((SimpsonOnsetTime.values - TriggerWAITRTTimeBlock.values) / float(1000)).item(0,0)

        #Simpson OnsetToOnsetTime is equal to duration
        SimpsonDuration = (SimpsonOnset[[SimpsonCharOnsetToOnsetStr]].values / float(1000)).item(0,0)

        #Write 3-column EV file with information about Simpsons ITI onset, duration, and strength (1)
        OutputFile = open((runData['FullTaskDir'] + '_Simpson.txt'), "w")
        writer = csv.writer(OutputFile, delimiter=' ')
        writer.writerow([AdjSimpsonOnset, SimpsonDuration, str(1)])
        OutputFile.close()

    return data


# # Get behavioral data for working memory tasks (WMShapes and WMFaces)
# 
# ## WMFaces
# |Parameter | Rows | Column / value
# |--- | :---: | --- |
# | Condition 1 | ProcedureTrial = calm | 
# | Condition 2 | ProcedureTrial = angry |
# | OnsetTime | First subtrial in each block (Subtrial = 1) | prepOnsetTime
# | OffsetTime | Last subtrial in each block (Subtrial = 5) | probeOnsetTime + 1500ms
# | TriggerAdj | Rows from Onset and Offset subsets | TriggerWAITOnsetTimeBlock
# | Duration |  | AdjOffset - AdjOnset
# 
# 
# ## WMShapes
# |Parameter | Rows | Column / value
# |--- | :---: | --- |
# | Condition 1 | ProcedureTrial = low | 
# | Condition 2 | ProcedureTrial = high |
# | OnsetTime | First subtrial in each block (Subtrial = 1) | WMSprepOnsetTime
# | OffsetTime | Last subtrial in each block (Subtrial = 5) | WMSprobeOnsetTime + 1500ms
# | TriggerAdj | Rows from Onset and Offset subsets | TriggerWAITOnsetTimeBlock
# | Duration |  | AdjOffset - AdjOnset

# In[9]:

def ParseWM (data, runData):
  
    #Onsets for both WM tasks are taken from the prepOnsetTime column (offsets are from probeOnsetTime instead)
    OnsetStr = 'prepOnsetTime'
    OffsetStr = 'probeOnsetTime'
    
    #Conditions are different across WM tasks. Account for that here.
    #Also adjust column names (WMSprepOnsetTime for WMShapes and prepOnsetTime for WMFaces)
    if ('Faces' in runData['RunName']):
        Condition1 = 'calm'
        Condition2 = 'angry'
    elif ('Shapes' in runData['RunName']):
        Condition1 = 'low'
        Condition2 = 'high'
        OnsetStr = 'WMS' + str(OnsetStr)
        OffsetStr = 'WMS' + str(OffsetStr)
    else:
        print "Error, can not determine type of WM run."
        
        
    #The column name needs to be adjusted when run number = 2
    if (runData['RunNum'] == '2'):
        OnsetStr += '2'
        OffsetStr += '2'
        Condition1 += '2'
        Condition2 += '2'

    #Here we use for loop because parsing procedure should be identical across conditions
    for Condition in [str(Condition1), str(Condition2)]:
        
        #NoIntCondition is used in naming of files (don't want to treat low2 as different condition from low, since
        #we already account for RunNum in separate process)
        NoIntCondition = filter(lambda x: x.isalpha(), str(Condition))

        #In each block, first subtrial = 1 and last subtrial = 5
        FirstSubtrials = data[(data['ProcedureBlock'] == runData['RunName']) & (data['ProcedureTrial'] == Condition) & (data['SubTrial'] == 1)]
        LastSubtrials = data[(data['ProcedureBlock'] == runData['RunName']) & (data['ProcedureTrial'] == Condition) & (data['SubTrial'] == 5)]

        #We get onset for each block here (we want prepOnsetTime from first subtrials in each block)
        FirstSubtrialsOn = FirstSubtrials.loc[:,(OnsetStr)]

        #Offsets are trickier (we want probeOnsetTime + 1500ms from last subtrials in each block)
        LastSubtrialsOff = LastSubtrials.loc[:,(OffsetStr)] + float(1500)

        #We adjust block onsets and offsets by TriggerWAITRTimeBlock here
        AdjBlockOnsets = FirstSubtrialsOn -  FirstSubtrials.TriggerWAITRTTimeBlock
        AdjBlockOffsets = LastSubtrialsOff - LastSubtrials.TriggerWAITRTTimeBlock

        #To get the time in seconds (instead of ms), we divide by 1000
        BlockOnsetsInSec = AdjBlockOnsets.values / float(1000)
        BlockOffsetsInSec = AdjBlockOffsets.values / float(1000)
        BlockDurationsInSec =  BlockOffsetsInSec -  BlockOnsetsInSec
        
        #Here, we write output to EV files
        WMOutput(NoIntCondition, runData, BlockOnsetsInSec, BlockDurationsInSec)


def WMOutput (Condition, runData, BlockOnsets, BlockDurations):
    OutName = str(runData['FullTaskDir'] + '_' + Condition + '.txt')
    print OutName
    if (not BlockOnsets.empty):
		OutputFile = open(OutName, "w")
		writer = csv.writer(OutputFile, delimiter=' ')
		for row in range(0,len(BlockOnsets)):
	         print str(BlockOnsets[row]) + '\t' + str(BlockDurations[row]) + '\t' + str(1)
	         writer.writerow([str(BlockOnsets[row]), str(BlockDurations[row]), str(1)])
	         OutputFile.close()
	else:
		OutName = str(os.path.dirname(OutName) + '/' + os.path.basename(OutName).split('.txt')[0] + '-EMPTY.txt')
		Touch(OutName)
	print '\n'
    

for runname in ['WMShapes1','WMShapes2','WMFaces1','WMFaces2']:
    runData = GetRunData(runname)
    data = pd.read_csv(str(SubjectDir) + 'behavior/' + runData['Task'] + '-eprime.csv')
    noSimData = FindSimpsons(data, runData)
    ParseWM(noSimData, runData)
    Touch(str(runData['FullTaskDir'] + 'Onsets.txt'))


# # Get behavioral data for ThreatReactivity task
# 
# |Parameter | Row criteria | Column criteria
# |--- | :---: | --- |
# | Condition 1 | Emotion = 'C' | 
# | Condition 2 | Emotion = 'S' |
# | Condition 3 | Emotion = 'F' |
# | OnsetTime | First subtrial in each block (Subtrial = 1) | ReactivityITIOnsetTime
# | OffsetTime | Last subtrial in each block (Subtrial = 36) | ReactivityITIOnsetTime + 500 ms
# | TriggerAdj | Rows from Onset and Offset subsets | TriggerWAITRTTimeBlock
# | Duration |  | OnsetTime - OffsetTime
# 
# 
# ## Questions
# 1. TriggerAdj is 'TriggerWAITRTTimeBlock' in fear_pipeline scripts, but we are using TriggerWAITOnsetTimeBlock for other tasks in dep_threat (e.g. WMShapes). Is this correct?
# *ANSWER*: Yes, it should be TriggerWAITRTTimeBlock for all NOT OnsetTime

# In[17]:

def ParseThreatReactivity (data, runData):
    
    #The column name needs to be adjusted when run number = 2
    ReactivityITIStr = 'ReactivityITIOnsetTime'
    if (runData['RunNum'] == '2'):
        ReactivityITIStr += '2'

    for Condition in ['C','S','F']:

        FirstSubtrials = data[(data['ProcedureBlock'] == runData['RunName']) & (data['Emotion'] == Condition) & (data['SubTrial'] == 1)]
        LastSubtrials = data[(data['ProcedureBlock'] == runData['RunName']) & (data['Emotion'] == Condition) & (data['SubTrial'] == 36)]
  
        #Adjust block onsets and offsets by TriggerWAITRTTimeBlock
        FirstSubtrialsOn = FirstSubtrials.loc[:,(ReactivityITIStr)] - FirstSubtrials.loc[:,('TriggerWAITRTTimeBlock')]
        LastSubtrialsOff = LastSubtrials.loc[:,(ReactivityITIStr)] - LastSubtrials.loc[:,('TriggerWAITRTTimeBlock')]

        #Get onsets and offsets in seconds
        BlockOnsetsInSec = FirstSubtrialsOn / float(1000)
        BlockOffsetsInSec = (LastSubtrialsOff + float(500))/ float(1000)
        BlockDurationsInSec =  BlockOffsetsInSec.values -  BlockOnsetsInSec.values
        
        TROutput(Condition, runData, BlockOnsetsInSec, BlockDurationsInSec)
        

def TROutput (Condition, runData, BlockOnsets, BlockDurations):
    OutName = str(runData['FullTaskDir'] + '_' + Condition + '.txt')
    print str(OutName)
    if (not BlockOnsets.empty):
		OutputFile = open(OutName, "w")
		writer = csv.writer(OutputFile, delimiter=' ')
		for row in range(0,len(BlockOnsets)):
	         print str(BlockOnsets.iloc[row]) + '\t' + str(BlockDurations[row]) + '\t' + str(1)
	         writer.writerow([str(BlockOnsets.iloc[row]), str(BlockDurations[row]), str(1)])
	    OutputFile.close()
	else:
		OutName = str(os.path.dirname(OutName) + '/' + os.path.basename(OutName).split('.txt')[0] + '-EMPTY.txt')
		Touch(OutName)
	print '\n'
    
    
for runname in ['ThreatReactivity1','ThreatReactivity2']:
    runData = GetRunData(runname)
    data = pd.read_csv(str(SubjectDir) + 'behavior/' + runData['Task'] + '-eprime.csv')
    noSimData = FindSimpsons(data, runData)
    ParseThreatReactivity(noSimData, runData)
    Touch(str(runData['FullTaskDir'] + 'Onsets.txt'))


# # Get behavioral data for Go-NoGo task
# 
# |Parameter | Row criteria | Column criteria
# |--- | :---: | --- |
# | Condition 1 | ProcedureSubTrial = 'TwoGoProc' | 
# | Condition 2 | ProcedureSubTrial = 'ThreeGoProc' |
# | Condition 3 | ProcedureSubTrial = 'FourGoProc' |
# | Sub-Condition A | ConditionLogLevel5 = 'Go' |
# | Sub-Condition B | ConditionLogLevel5 = 'NoGo' |
# | RespType A | Incorrect (GNGACC = 0) |
# | RespType B | Correct (GNGACC = 1) | 
# | OnsetTime | Subtrials that match each Condition, Sub-Condition, and RespType (as defined above) | GNGCueOnsetTime
# | Duration | Subtrials that match each Condition, Sub-Condition, and RespType (as defined above) | GNGCueOnsetToOnsetTime
# | TriggerAdj | Rows from each group of trials (as defined above) | TriggerWAITOnsetTimeTrial
# 
# 
# ## Questions
# 1. I believe we want to use GNGCueOnsetTime for TrialOnsets and GNGCueOnsetToOnsetTime for TrialDuration, but am not entirely sure this is correct?
# *ANSWER*: Yes, onset time for onsets.
# 2. I'm also unclear about TriggerAdj column for this experiment. From data for subject 999: TriggerWAITOnsetTimeTrial + TriggerWAITRTTrial = TriggerWAITRTTimeTrial (in Run1, TriggerWAITRTTrial = 1839 ms and in Run2 it = 5332 ms). I assume we want Trigger to match our Onset (GNGCueOnset), so chose TriggerWAITOnsetTimeTrial, but can change, if incorrect?
# *ANSWER*: RT (not onset!) time for triggers!

def ParseGoNoGo (data, runData):
    
    for NumItems in ['Two','Three','Four']:
        GNGType = NumItems + 'GoProc'

        #Subtrials = data[(data['ProcedureBlock'] == runData['RunName'])]
        GNG = data[(data['ProcedureBlock'] == runData['RunName']) & (data['ProcedureSubTrial'] == GNGType)]
        
        for Condition in ['Go','NoGo']:
            for Accuracy in [0,1]:
                
                RespType = 'Correct'
                if (str(Accuracy) == '0'):
                    RespType = 'In' + RespType.lower()

                #print 'RespType: ' + str(RespType)
                Trials = GNG[(GNG['ConditionLogLevel5'] == str(Condition)) & (GNG['GNGACC'] == int(Accuracy))]
                TriggerOnsetTimes = Trials.TriggerWAITRTTimeTrial

                TrialOnsets = (Trials['GNGCueOnsetTime'] - TriggerOnsetTimes) / float(1000)
                TrialDurations = Trials['GNGCueOnsetToOnsetTime'] / float(1000)
                
                GNGOutput(str(NumItems + '_' + Condition + '_' + RespType), runData, TrialOnsets, TrialDurations)
        
    #Combine files for inaccurate go trials (across GNGTypes)
    GNG = data[(data['ProcedureBlock'] == runData['RunName']) & (data['ConditionLogLevel5'] == 'Go') & (data['GNGACC'] == 0)]
    TrialOnsets = (GNG['GNGCueOnsetTime'] - GNG['TriggerWAITRTTimeTrial']) / float(1000)
    TrialDurations = GNG['GNGCueOnsetToOnsetTime'] / float(1000)
    GNGOutput('ALL_Go_Incorrect', runData, TrialOnsets, TrialDurations)

def GNGOutput (Condition, runData, BlockOnsets, BlockDurations):
    OutName = str(runData['FullTaskDir'] + '_' + Condition + '.txt')
    print str(OutName)
	if (not dataA.empty):
		OutputFile = open(OutName, "w")
		writer = csv.writer(OutputFile, delimiter=' ')
		for row in range(0,len(BlockOnsets)):
	        print str(BlockOnsets.iloc[row]) + '\t' + str(BlockDurations.iloc[row]) + '\t' + str(1)
	        writer.writerow([str(BlockOnsets.iloc[row]), str(BlockDurations.iloc[row]), str(1)])
	    OutputFile.close()
	else:
		OutName = str(os.path.dirname(OutName) + '/' + os.path.basename(OutName).split('.txt')[0] + '-EMPTY.txt')
		Touch(OutName)
	print '\n'

    if (Condition == 'ALL_Go_Incorrect'):
        a = []
        for l in ['Two','Three','Four']:
            OutName = str(runData['FullTaskDir'] + '_' + l + '_' + 'Go_Incorrect.txt')
            print OutName    
            with open(OutName, 'r') as f:
                for line in f.readlines():
                    a.append(line.strip())
	    OutName = str(runData['FullTaskDir'] + '_' + Condition + '.txt')
	    OutputFile = open(OutName, "w")
	    writer = csv.writer(OutputFile)
	    for i in sorted(a):
	        print i
	        writer.writerow([str(i)])
	    OutputFile.close()
	    print '\n'

for runname in ['GNG1','GNG2','GNG3']:
    runData = GetRunData(runname)
    data = pd.read_csv(str(SubjectDir) + 'behavior/' + runData['Task'] + '-eprime.csv')
    noSimData = FindSimpsons(data, runData)
    ParseGoNoGo(noSimData, runData)
    Touch(str(runData['FullTaskDir'] + 'Onsets.txt'))


# # Get behavioral data for ExtinctionRecall task
# 
# |Parameter | Row criteria | Column criteria
# |--- | :---: | --- |
# | Condition 1 | StimulusTrial = 'CSPlus_Threat' | 
# | Condition 2 | StimulusTrial = 'CSMinus_Threat' |
# | Sub-Condition A | CSImageRecall |
# | Sub-Condition B | ThreatResp |
# | RespType A | NoResponse (RT = 0) |
# | RespType B | Response (RT > 0) | 
# | OnsetTime | Subtrials that match each Condition, Sub-Condition, and RespType (as defined above) | CSImageRecallOnsetTime (or ThreatRespOnsetTime)
# | Duration | Subtrials that match each Condition, Sub-Condition, and RespType (as defined above) | CSImageRecallOnsetToOnsetTime (or ThreatRespOnsetToOnsetTime)
# | TriggerAdj | Rows from each group of trials (as defined above) | TriggerWAITRTTimeBlock
# 
# 
# ## Questions
# 1. ExtinctionRecall trial duration appears to be ~2 seconds in Dep_Threat (vs. 4 seconds in Fear_Pipeline). Is this correct? 
# *ANSWER*: 4 seconds total (Image + ThreatResp)

# In[12]:

def ParseExtRecall (data, runData):
    
    #Set string names to match column names in behavioral file
    CSImageStr = 'CSImageRecall'
    ThreatRespStr = 'ThreatResp'
    CSImageStrOnsetTime = str(CSImageStr) + 'OnsetTime'
    CSImageStrOnsetToOnsetTime = str(CSImageStr) + 'OnsetToOnsetTime'
    ThreatRespStrOnsetTime = str(ThreatRespStr) + 'OnsetTime'
    ThreatRespStrOnsetToOnsetTime = str(ThreatRespStr) + 'OnsetToOnsetTime'
    CSImageStrRT = str(CSImageStr) + 'RT'
    ThreatRespStrRT = str(ThreatRespStr) + 'RT'

    #The column name needs to be adjusted when run number = 2
    if (runData['RunNum'] == '2'):
        CSImageStr += '2'
        ThreatRespStr += '2'
        CSImageStrOnsetTime += '2'
        CSImageStrOnsetToOnsetTime += '2'
        ThreatRespStrOnsetTime += '2'
        ThreatRespStrOnsetToOnsetTime += '2'
        CSImageStrRT += '2'
        ThreatRespStrRT += '2'

    #There are two condition in ExtinctionRecall (CSPlus_Threat and CSMinus_Threat)
    for TrialType in ['CSPlus','CSMinus']:
        Condition = TrialType + '_Threat'

        #Get TriggerOnsetTimes for each run and condition
        ImageRecallTrials = data[(data['ProcedureBlock'] == runData['RunName']) & (data['StimulusTrial'] == Condition)]
        TriggerOnsetTimes = ImageRecallTrials.TriggerWAITRTTimeBlock

        #Get ImageOnsets by selecting CSImageRecallOnsetTime and subtracting TriggerOnsetTimes for each run and conditon
        ImageOnsets = (ImageRecallTrials[CSImageStrOnsetTime] - TriggerOnsetTimes) / float(1000)

        #Get ImageDurations from same subset at above (but use CSImageRecallOnsetToOnsetTime column instead)
        ImageDurations = ImageRecallTrials[CSImageStrOnsetToOnsetTime] / float(1000)
           
        #Get ResponseOnsetTime from same subset as above (but use ThreatRespOnsetTime)
        ResponseOnsets = (ImageRecallTrials[ThreatRespStrOnsetTime] - TriggerOnsetTimes) / float(1000)

        #Get ResponseDurations from same subset at above (but use ThreatRespOnsetToOnsetTime)
        ResponseDurations = ImageRecallTrials[ThreatRespStrOnsetToOnsetTime] / float(1000)

        #CombinedDurations are equal to (*RESPONSE* Onsets + Durations) - (*IMAGE* Onsets + Durations)
        CombinedDurations = (ResponseOnsets + ResponseDurations) - (ImageOnsets + ImageDurations)
  
        #Get response times from same subset as above (but use ThreatRespRT)
        ResponseTimes = ImageRecallTrials[ThreatRespStrRT] / float(1000)

        #Print output for all trials
        ExtRecallOutput('Image','C', runData, TrialType, ImageOnsets, ImageDurations)
        ExtRecallOutput('Response','C', runData, TrialType, ResponseOnsets, ResponseDurations)
        ExtRecallOutput('ImageResponse','C', runData, TrialType, ImageOnsets, CombinedDurations)

        
        #Now, get onsets by response type:
        
        #Starting with Non-Responses (RT == 0)
        NRImageOnsets = ImageOnsets[(data[CSImageStrRT] == 0)]
        NRImageDurations = ImageDurations[(data[CSImageStrRT] == 0)]
        NRResponseOnsets = ResponseOnsets[(data[ThreatRespStrRT] == 0)]
        NRResponseDurations = ResponseDurations[(data[ThreatRespStrRT] == 0)]
        NRCombinedDurations = CombinedDurations[(data[CSImageStrRT] == 0) | (data[ThreatRespStrRT] == 0)]

        #Print output for Non-Responses
        ExtRecallOutput('Image','NR', runData, TrialType, NRImageOnsets, NRImageDurations)
        ExtRecallOutput('Response','NR', runData, TrialType, NRResponseOnsets, NRResponseDurations)
        ExtRecallOutput('ImageResponse','NR', runData, TrialType, NRImageOnsets, NRCombinedDurations)

        #Now, we move on to the responses (RT > 0)
        RImageOnsets = ImageOnsets[(data[CSImageStrRT] > 0)]
        RImageDurations = ImageDurations[(data[CSImageStrRT] > 0)]
        RResponseOnsets = ResponseOnsets[(data[ThreatRespStrRT] > 0)]
        RResponseDurations = ResponseDurations[(data[ThreatRespStrRT] > 0)]
        RCombinedDurations = CombinedDurations[(data[CSImageStrRT] > 0) | (data[ThreatRespStrRT] > 0)]
   
        #Print output for Responses now
        ExtRecallOutput('Image','R', runData, TrialType, RImageOnsets, RImageDurations)
        ExtRecallOutput('Response','R', runData, TrialType, RResponseOnsets, RResponseDurations)
        ExtRecallOutput('ImageResponse','R', runData, TrialType, RImageOnsets, RCombinedDurations)

def ExtRecallOutput(OutFileType, OutRespType, runData, TrialType, dataA, dataB):
	if (OutRespType == 'C'):
		OutName = str(runData['FullTaskDir'] + '_' + TrialType + '_' + OutFileType + '.txt')
	else:
		OutName = str(runData['FullTaskDir'] + '_' + TrialType + '_' + OutFileType + '_' + OutRespType + '.txt')
	print str(OutName)
	if (not dataA.empty):
		OutputFile = open(str(OutName), "w")
		writer = csv.writer(OutputFile, delimiter=' ')
		for row in range(0,len(dataA)):
			print str(dataA.values[row]) + '\t' + str(dataB.values[row]) + '\t' + str(1)
			writer.writerow([str(dataA.values[row]), str(dataB.values[row]), str(1)])
	else:
		OutName = str(os.path.dirname(OutName) + '/' + os.path.basename(OutName).split('.txt')[0] + '-EMPTY.txt')
		Touch(OutName)
	print '\n'

        
for runname in ['ExtinctionRecall1','ExtinctionRecall2']:
    runData = GetRunData(runname)
    data = pd.read_csv(str(SubjectDir) + 'behavior/' + runData['Task'] + '-eprime.csv')
    noSimData = FindSimpsons(data, runData)
    ParseExtRecall(noSimData, runData)
    Touch(str(runData['FullTaskDir'] + 'Onsets.txt'))