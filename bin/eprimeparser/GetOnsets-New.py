import pandas as pd
import numpy as np
import argparse
import csv
import os
import re

#Makes Simpsons EV files
def RemoveSimpsons (data, runData):

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
        print 'AdjSimpsonOnset: ' + str(AdjSimpsonOnset)

        #Simpson OnsetToOnsetTime is equal to duration
        SimpsonDuration = (SimpsonOnset[[SimpsonCharOnsetToOnsetStr]].values / float(1000)).item(0,0)
        print 'SimpsonDuration: ' + str(SimpsonDuration)

        #Write 3-column EV file with information about Simpsons ITI onset, duration, and strength (1)
        #For testing purposes, write to dirname of infile
        OutputFile = open((runData['FullTaskDir'] + '_Simpson.txt'), "w")
        writer = csv.writer(OutputFile, delimiter=' ')
        writer.writerow([AdjSimpsonOnset, SimpsonDuration, str(1)])
        OutputFile.close()

    return data


def ParseExtRecall (data, runData):

    CSImageStr = 'CSImageRecall'
    ThreatRespStr = 'ThreatResp'
    CSImageStrOnsetTime = str(CSImageStr) + 'OnsetTime'
    CSImageStrOnsetToOnsetTime = str(CSImageStr) + 'OnsetToOnsetTime'
    ThreatRespStrOnsetTime = str(ThreatRespStr) + 'OnsetTime'
    ThreatRespStrOnsetToOnsetTime = str(ThreatRespStr) + 'OnsetToOnsetTime'
    CSImageStrRT = str(CSImageStr) + 'RT'
    ThreatRespStrRT = str(ThreatRespStr) + 'RT'

    if (runData['RunNum'] == '2'):
        CSImageStr += '2'
        ThreatRespStr += '2'
        CSImageStrOnsetTime += '2'
        CSImageStrOnsetToOnsetTime += '2'
        ThreatRespStrOnsetTime += '2'
        ThreatRespStrOnsetToOnsetTime += '2'
        CSImageStrRT += '2'
        ThreatRespStrRT += '2'

        print 'CSImageStr: ' + CSImageStr
        print 'ThreatRespStr: ' + ThreatRespStr

        for TrialType in ['CSPlus','CSMinus']:
            Condition = TrialType + '_Threat'
            print 'Condition: ' + Condition

            #Get CSImageRecallOnsetTime for Response & NonResponse (should match following criteria)
            #1. ProcedureBlock == CurrentProc (ExtinctionRecallRun1 or ExtinctionRecallRun2)
            #2. StimulusTrial == Condition (CSPlus_Threat or CSMinus_Threat)
            #print 'Run: ' + Run
            ImageRecallTrials = data[(data['ProcedureBlock'] == runData['RunName']) & (data['StimulusTrial'] == Condition)]
            TriggerOnsetTimes = ImageRecallTrials.TriggerWAITRTTimeBlock

            #Image onsets
            #['CSImageRecallOnsetTime']
            ImageOnsets = (ImageRecallTrials[CSImageStrOnsetTime] - TriggerOnsetTimes) / float(1000)
            #print ImageOnsets

            #Get ImageDurations from same subset at above
            #data['CSImageRecallOnsetToOnsetTime']
            ImageDurations = ImageRecallTrials[CSImageStrOnsetToOnsetTime] / float(1000)
            #print(ImageDurations)

            #Get ResponseOnsetTime from same subset as above
            #data[Task+'RespOnsetTime']
            ResponseOnsets = (ImageRecallTrials[ThreatRespStrOnsetTime] - TriggerOnsetTimes) / float(1000)
            #print(ResponseOnsets)

            #Get ResponseDurations from same subset at above
            #data[Task+'RespOnsetToOnsetTime']
            ResponseDurations = ImageRecallTrials[ThreatRespStrOnsetToOnsetTime] / float(1000)
            #print(ResponseDurations)

            #Get CombinedDurations (ResponseOnsets + ResponseDurations - (ImageOnsets + ImageDurations))
            #data[Task+'RespOnsetTime'] + data[Task+'RespOnsetToOnsetTime'] -  data['CSImageRecallOnsetTime'] + data['CSImageRecallOnsetToOnsetTime']
            CombinedDurations = (ResponseOnsets + ResponseDurations) - (ImageOnsets + ImageDurations)
            #print(CombinedDurations)

            #Get response times
            #ResponseTimes=data[Task+'RespRTTime']
            ResponseTimes = ImageRecallTrials[ThreatRespStrRT] / float(1000)
            #print(ResponseTimes)


            #Now, get onsets by response type!

            #First, start with non-responses
            #print ImageOnsets
            NRImageOnsets = ImageOnsets[(data[CSImageStrRT] == 0)]
            NRImageDurations = ImageDurations[(data[CSImageStrRT] == 0)]
            NRResponseOnsets = ResponseOnsets[(data[ThreatRespStrRT] == 0)]
            NRResponseDurations = ResponseDurations[(data[ThreatRespStrRT] == 0)]
            NRCombinedDurations = CombinedDurations[(data[CSImageStrRT] == 0) | (data[ThreatRespStrRT] == 0)]
            #print(NRCombinedDurations)

            #Print output for NR
            #print 'NRImageOnsets: ' + str(len(NRImageOnsets))
            #print 'NRResponseOnsets: ' + str(len(NRResponseOnsets))
            ExtRecallOutput('Image','NR', runData, TrialType, NRImageOnsets, NRImageDurations)
            ExtRecallOutput('Response','NR', runData, TrialType, NRResponseOnsets, NRResponseDurations)
            ExtRecallOutput('ImageResponse','NR', runData, TrialType, NRImageOnsets, NRCombinedDurations)

            #Now, we move on to the responses!
            RImageOnsets = ImageOnsets[(data[CSImageStrRT] > 0)]
            RImageDurations = ImageDurations[(data[CSImageStrRT] > 0)]
            RResponseOnsets = ResponseOnsets[(data[ThreatRespStrRT] > 0)]
            RResponseDurations = ResponseDurations[(data[ThreatRespStrRT] > 0)]
            RCombinedDurations = CombinedDurations[(data[CSImageStrRT] > 0) | (data[ThreatRespStrRT] > 0)]
            #print(RCombinedDurations)

            #Print output for R
            #print 'RImageOnsets: ' + str(len(RImageOnsets))
            #print 'RResponseOnsets: ' + str(len(RResponseOnsets))
            ExtRecallOutput('Image','R', runData, TrialType, RImageOnsets, RImageDurations)
            ExtRecallOutput('Response','R', runData, TrialType, RResponseOnsets, RResponseDurations)
            ExtRecallOutput('ImageResponse','R', runData, TrialType, RImageOnsets, RCombinedDurations)


            #Calculate response percentage
            #RImageOnsets / ImageOnsets
            #ResponsePct = (len(RImageOnsets) / len(ImageOnsets)) * float(100)
            #print 'ResponsePct: ' + str(ResponsePct)
            #print 'LENGTH IMAGE ONSETS: ' + str(len(ImageOnsets))
            #print 'LENGTH RIMAGE ONSETS: ' + str(len(RImageOnsets))
            #print 'LENGTH NRIMAGE ONSETS: ' + str(len(NRImageOnsets))
            #print 'LENGTH RESPONSE ONSETS: ' + str(len(ResponseOnsets))
            #print 'LENGTH NRRESPONSE ONSETS: ' + str(len(NRResponseOnsets))
            #print 'LENGTH RRESPONSE ONSETS: ' + str(len(RResponseOnsets))

            #Calculate mean rating
            #MeanRating = np.mean(ImageRecallTrials['ThreatRating'])
            #print 'MeanRating: ' + str(MeanRating)

            #Calculate reation times
            #MeanRT = np.mean(ImageRecallTrials[(ImageRecallTrials['ThreatRespRT'] > 0)].ThreatRespRT) / float(1000)
            #print 'MeanRT: ' + str(MeanRT)

#This checks if image file exists and returns information about the run
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

def ParseThreatReactivity (data, runData):
        
    ReactivityITIStr = 'ReactivityITIOnsetTime'
    if (runData['RunNum'] == '2'):
        ReactivityITIStr += '2'

    for Condition in ['C','S','F']:
        print 'Condition: ' + Condition

        FirstSubtrials = data[(data['ProcedureBlock'] == runData['RunName']) & (data['Emotion'] == Condition) & (data['SubTrial'] == 1)]
        LastSubtrials = data[(data['ProcedureBlock'] == runData['RunName']) & (data['Emotion'] == Condition) & (data['SubTrial'] == 36)]
            
        NumBlocks = FirstSubtrials.shape[0]
        print 'NumBlocks: ' + str(NumBlocks)
  
        #Adjust block onsets and offsets by TriggerWAITRTTimeBlock
        ##ASK: This is TriggerWAITRTTimeBlock in fear_pipeline scripts,
        #Confirm this is correct (instead of TriggerWAITOnsetTimeBlock)?
        FirstSubtrialsOn = FirstSubtrials.loc[:,(ReactivityITIStr)] - FirstSubtrials.loc[:,('TriggerWAITRTTimeBlock')]
        LastSubtrialsOff = LastSubtrials.loc[:,(ReactivityITIStr)] - LastSubtrials.loc[:,('TriggerWAITRTTimeBlock')]

        #Get onsets and offsets in seconds
        BlockOnsetsInSec = FirstSubtrialsOn / float(1000)
        BlockOffsetsInSec = LastSubtrialsOff / float(1000)
        BlockDurationsInSec =  BlockOffsetsInSec.values -  BlockOnsetsInSec.values
        
        TROutput(Condition, runData, BlockOnsetsInSec, BlockDurationsInSec)

def ParseGoNoGo (data, runData):
    
    for NumItems in ['Two','Three','Four']:
        GNGType = NumItems + 'GoProc'
        print 'GNGType: ' + GNGType

        #Subtrials = data[(data['ProcedureBlock'] == runData['RunName'])]
        GNG = data[(data['ProcedureBlock'] == runData['RunName']) & (data['ProcedureSubTrial'] == GNGType)]
        
        for Condition in ['Go','NoGo']:
            for Accuracy in [0,1]:
                
                RespType = 'Correct'
                if (str(Accuracy) == '0'):
                    RespType = 'In' + RespType.lower()

                #print 'RespType: ' + str(RespType)
                Trials = GNG[(GNG['ConditionLogLevel5'] == str(Condition)) & (GNG['GNGACC'] == int(Accuracy))]
                TriggerOnsetTimes = Trials.TriggerWAITOnsetTimeTrial
                #TriggerOnsetTimes = Trials.TriggerWAITRTTimeTrial

                TrialOnsets = (Trials['GNGCueOnsetTime'] - TriggerOnsetTimes) / float(1000)
                TrialDurations = Trials['GNGCueOnsetToOnsetTime'] / float(1000)
                
                GNGOutput(str(NumItems + '_' + Condition + '_' + RespType), runData, TrialOnsets, TrialDurations)
        
    #Combine files for inaccurate go trials (across GNGTypes)
    GNG = data[(data['ProcedureBlock'] == runData['RunName']) & (data['ConditionLogLevel5'] == 'Go') & (data['GNGACC'] == 0)]
    TrialOnsets = (GNG['GNGCueOnsetTime'] - GNG['TriggerWAITOnsetTimeTrial']) / float(1000)
    TrialDurations = GNG['GNGCueOnsetToOnsetTime'] / float(1000)
    GNGOutput('ALL_Go_Incorrect', runData, TrialOnsets, TrialDurations)

def GNGOutput (Condition, runData, BlockOnsets, BlockDurations):
    OutputFile = open(runData['FullTaskDir'] + '_' + Condition + '.txt', "w")
    writer = csv.writer(OutputFile, delimiter=' ')
    for row in range(0,len(BlockOnsets)):
        print str(BlockOnsets.iloc[row]) + '\t' + str(BlockDurations.iloc[row]) + '\t' + str(1)
        writer.writerow([str(BlockOnsets.iloc[row]), str(BlockDurations.iloc[row]), str(1)])
    OutputFile.close()

def TROutput (Condition, runData, BlockOnsets, BlockDurations):
    OutputFile = open(runData['FullTaskDir'] + '_' + Condition + '.txt', "w")
    writer = csv.writer(OutputFile, delimiter=' ')
    for row in range(0,len(BlockOnsets)):
        print str(BlockOnsets.iloc[row]) + '\t' + str(BlockDurations[row]) + '\t' + str(1)
        writer.writerow([str(BlockOnsets.iloc[row]), str(BlockDurations[row]), str(1)])
    OutputFile.close()
    
def WMOutput (Condition, runData, BlockOnsets, BlockDurations):
    OutputFile = open(runData['FullTaskDir'] + '_' + Condition + '.txt', "w")
    writer = csv.writer(OutputFile, delimiter=' ')
    for row in range(0,len(BlockOnsets)):
        print str(BlockOnsets[row]) + '\t' + str(BlockDurations[row]) + '\t' + str(1)
        writer.writerow([str(BlockOnsets[row]), str(BlockDurations[row]), str(1)])
    OutputFile.close()        

def ExtRecallOutput(OutFileType, OutRespType, runData, TrialType, dataA, dataB):
    if (not dataA.empty):

        OutputFile = open(str(runData['FullTaskDir'] + '_' + TrialType + '_' + OutFileType + '_' + OutRespType + '.txt'), "w")
        writer = csv.writer(OutputFile, delimiter=' ')
        for row in range(0,len(dataA)):
            writer.writerow([str(dataA.values[row]), str(dataB.values[row]), str(1)])
        OutputFile.close()
    
def ParseWM (data, runData):
  
    OnsetStr = 'prepOnsetTime'
    OffsetStr = 'probeOnsetTime'
    
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
        

    if (runData['RunNum'] == '2'):
        OnsetStr += '2'
        OffsetStr += '2'
        Condition1 += '2'
        Condition2 += '2'

    print 'OnsetStr = ' + str(OnsetStr)
    print 'OffsetStr = ' + str(OffsetStr)

    for Condition in [str(Condition1), str(Condition2)]:
        NoIntCondition = filter(lambda x: x.isalpha(), str(Condition))

        print 'Condition: ' + Condition
        print 'NoIntCondition: ' + NoIntCondition

        FirstSubtrials = data[(data['ProcedureBlock'] == runData['RunName']) & (data['ProcedureTrial'] == Condition) & (data['SubTrial'] == 1)]
        LastSubtrials = data[(data['ProcedureBlock'] == runData['RunName']) & (data['ProcedureTrial'] == Condition) & (data['SubTrial'] == 5)]

        NumBlocks = FirstSubtrials.shape[0]
        print 'NumBlocks: ' + str(NumBlocks)
        
        #Get onset for FirstSubtrials
        FirstSubtrialsOn = FirstSubtrials.loc[:,(OnsetStr)]

        #Get offset for LastSubtrials (and add 1500 ms)
        LastSubtrialsOff = LastSubtrials.loc[:,(OffsetStr)] + float(1500)

        #Adjust block onsets and offsets by TriggerWAITOnsetTimeBlock
        AdjBlockOnsets = FirstSubtrialsOn -  FirstSubtrials.TriggerWAITOnsetTimeBlock
        AdjBlockOffsets = LastSubtrialsOff - LastSubtrials.TriggerWAITOnsetTimeBlock

        #Get onsets and offsets in seconds
        BlockOnsetsInSec = AdjBlockOnsets.values / float(1000)
        BlockOffsetsInSec = AdjBlockOffsets.values / float(1000)
        BlockDurationsInSec =  BlockOffsetsInSec -  BlockOnsetsInSec
          
        WMOutput(NoIntCondition, runData, BlockOnsetsInSec, BlockDurationsInSec)


##MAIN##

#Pull the data in based on a parameter entered at the command line
parser = argparse.ArgumentParser()
parser.add_argument('--subject', '-s', required=True, help='Name of subject to be processed')
args = parser.parse_args()
subject = args.subject

SubjectDir = '/mnt/stressdevlab/dep_threat_pipeline/' + str(subject) + '/'

for runname in ['ExtinctionRecall1','ExtinctionRecall2','ThreatReactivity1','ThreatReactivity2', 'WMShapes1','WMShapes2','WMFaces1','WMFaces2','GNG1','GNG2','GNG3']:

    runData = GetRunData(runname)
    outStr = 'image file for ' + str(runData['RunName'])
                                     
    if (runData['ImageFileExists'] == 'True'):
        print 'Found ' + str(outStr) + '.' 
        print ''

        for key in runData.keys():
            print key + ': ' + runData[key]
            
        data = pd.read_csv(str(SubjectDir) + 'behavior/' + runData['Task'] + '-eprime.csv')

        if (runData['Task'] != 'GNG'):
            noSimData = RemoveSimpsons(data, runData)
        else:
            noSimData = data
        
        if ('WM' in runData['RunName']):
            ParseWM(noSimData, runData)
        elif ('ThreatReactivity' in runData['RunName']):
            ParseThreatReactivity(noSimData, runData)
        elif ('ExtinctionRecall' in runData['RunName']):
            ParseExtRecall(noSimData, runData)
        elif ('GNG' in runData['RunName']):
            ParseGoNoGo(noSimData, runData)
                                     
    else:
        print 'WARNING: Could not find ' + str(outStr) + '.'

os.mknod(str(SubjectDir) + 'behavior/BehDataProcessed.txt')
