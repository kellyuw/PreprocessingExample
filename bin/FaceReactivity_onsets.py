import numpy as np
import argparse
import csv

#Pull the data in based on a parameter entered at the command line
parser = argparse.ArgumentParser()
parser.add_argument('--input', '-i', required=True, help='Name of tab-delimited text file to import')
parser.add_argument('--run', '-r', required=True, help='Run number')
parser.add_argument('--output', '-o', required=True, help='Output path')

filename = parser.parse_args().input
Run=parser.parse_args().run
Output=parser.parse_args().output

#Get the data into an array
data=np.genfromtxt(filename, dtype=None, delimiter='\t', names=True)

#Deal with those pesky Simpson trials
CurrentProc='ThreatReactivityRun'+str(Run)

BartProc=data['ProcedureBlock'][data['BartSimpsonOnsetTime']>0]
HomerProc=data['ProcedureBlock'][data['HomerSimpsonOnsetTime']>0]

if BartProc==CurrentProc:
    SimpsonOnset=((data['BartSimpsonOnsetTime'][data['BartSimpsonOnsetTime']>0]-data['TriggerWAITRTTimeBlock'][data['BartSimpsonOnsetTime']>0])/float(1000))[0]
    SimpsonDuration=((data['BartSimpsonOnsetToOnsetTime'][data['BartSimpsonOnsetTime']>0])/float(1000))[0]
    OutputFile=open((Output + '/FaceReactivity' + str(Run) + '_Simpson.txt'), "w")
    writer = csv.writer(OutputFile, delimiter=' ')
    writer.writerow([str(SimpsonOnset), str(SimpsonDuration), str(1)])

elif HomerProc==CurrentProc:
    SimpsonOnset=((data['HomerSimpsonOnsetTime'][data['HomerSimpsonOnsetTime']>0]-data['TriggerWAITRTTimeBlock'][data['HomerSimpsonOnsetTime']>0])/float(1000))[0]
    SimpsonDuration=((data['HomerSimpsonOnsetToOnsetTime'][data['HomerSimpsonOnsetTime']>0])/float(1000))[0]

    OutputFile=open((Output + '/FaceReactivity' + str(Run) + '_Simpson.txt'), "w")
    writer = csv.writer(OutputFile, delimiter=' ')
    writer.writerow([str(SimpsonOnset), str(SimpsonDuration), str(1)])


#Get Block Onsets by Condition

for Condition in ['C','S','F']:

    BlockOnsets=(data['ReactivityITIOnsetTime'][np.logical_and(np.logical_and(data['Emotion']==str(Condition),data['ProcedureBlock']==str(CurrentProc)),data['SubTrial']==1)]-data['TriggerWAITRTTimeBlock'][np.logical_and(np.logical_and(data['Emotion']==str(Condition),data['ProcedureBlock']==str(CurrentProc)),data['SubTrial']==1)])/float(1000)
    #print(BlockOnsets)

    LastTriggerWaitRTTime = (data['TriggerWAITRTTimeBlock'][np.logical_and(np.logical_and(data['ProcedureBlock']==str(CurrentProc),data['Emotion']==Condition),data['SubTrial']==20)])
    #print(LastTriggerWaitRTTime)

    LastReactivityITIOnsetTime = (data['ReactivityITIOnsetTime'][np.logical_and(np.logical_and(data['ProcedureBlock']==str(CurrentProc),data['Emotion']==Condition),data['SubTrial']==20)])
    #print(LastReactivityITIOnsetTime)

    BlockOffsets = (LastReactivityITIOnsetTime - LastTriggerWaitRTTime) / float(1000)
    #print(BlockOffsets)

    BlockDurations=BlockOffsets-BlockOnsets
    print(BlockDurations)

    OutputFile=open(Output + '/FaceReactivity' + str(Run) + '_' + Condition + '.txt', "w")
    writer = csv.writer(OutputFile, delimiter=' ')
    for row in range(0,len(BlockOnsets)):
        writer.writerow([str(BlockOnsets[row]), str(BlockDurations[row]), str(1)])
