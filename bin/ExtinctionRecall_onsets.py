import numpy as np
import argparse
import csv

#Pull the data in based on a parameter entered at the command line
parser = argparse.ArgumentParser()
parser.add_argument('--input', '-i', required=True, help='Name of tab-delimited text file to import')
parser.add_argument('--task', '-t', required=True, help='Task (Threat or Memory)')
parser.add_argument('--run', '-r', required=True, help='Run number')
parser.add_argument('--output', '-o', required=True, help='Output path')

filename = parser.parse_args().input
Task=parser.parse_args().task
Run=parser.parse_args().run
Output=parser.parse_args().output

#filename='/Users/kelly89/Projects/PreprocessingExample/Test/102_reformatted_eprime.csv'
#Task='Threat'
#Run='1'
#Output='/Users/kelly89/Projects/PreprocessingExample/Test'

#Get the data into an array
data=np.genfromtxt(filename, dtype=None, delimiter='\t', names=True)

#Deal with those pesky Simpson trials
CurrentProc='ExtinctionRecall'+Task+str(Run)

MaggieProc=data['ProcedureBlock'][data['MaggieSimpsonOnsetTime']>0]
MargeProc=data['ProcedureBlock'][data['MargeSimpsonOnsetTime']>0]

if MaggieProc==CurrentProc:
    SimpsonOnset=((data['MaggieSimpsonOnsetTime'][data['MaggieSimpsonOnsetTime']>0]-data['TriggerWAITRTTimeBlock'][data['MaggieSimpsonOnsetTime']>0])/float(1000))[0]
    SimpsonDuration=((data['MaggieSimpsonOnsetToOnsetTime'][data['MaggieSimpsonOnsetTime']>0])/float(1000))[0]
    OutputFile=open((Output + '/ExtinctionRecall_' + Task[:1] + '_' + str(Run) + '_Simpson.txt'), "w")
    print(OutputFile)
    writer = csv.writer(OutputFile, delimiter=' ')
    writer.writerow([str(SimpsonOnset), str(SimpsonDuration), str(1)])

elif MargeProc==CurrentProc:
    SimpsonOnset=((data['MargeSimpsonOnsetTime'][data['MargeSimpsonOnsetTime']>0]-data['TriggerWAITRTTimeBlock'][data['MargeSimpsonOnsetTime']>0])/float(1000))[0]
    SimpsonDuration=((data['MargeSimpsonOnsetToOnsetTime'][data['MargeSimpsonOnsetTime']>0])/float(1000))[0]

    OutputFile=open((Output + '/ExtinctionRecall_' + Task[:3] + '_' + str(Run) + '_Simpson.txt'), "w")
    print(OutputFile)
    writer = csv.writer(OutputFile, delimiter=' ')
    writer.writerow([str(SimpsonOnset), str(SimpsonDuration), str(1)])

for TrialType in ['CSPlus','CSMinus']:
    Condition=TrialType +'_' + Task
    print(Condition)

    #Get onsets for Response & NonResponse Combined
    ImageOnsets=(data['CSImageRecallOnsetTime'][np.logical_and(data['StimulusTrial']==Condition,data['ProcedureBlock']==('ExtinctionRecallRun'+str(Run)))]-data['TriggerWAITRTTimeBlock'][np.logical_and(data['StimulusTrial']==Condition,data['ProcedureBlock']==('ExtinctionRecallRun'+str(Run)))])/float(1000)
    ImageDurations=(data['CSImageRecallOnsetToOnsetTime'][np.logical_and(data['StimulusTrial']==Condition,data['ProcedureBlock']==('ExtinctionRecallRun'+str(Run)))])/float(1000)

    ResponseOnsets=(data[Task+'RespOnsetTime'][np.logical_and(data['StimulusTrial']==Condition,data['ProcedureBlock']==('ExtinctionRecallRun'+str(Run)))]-data['TriggerWAITRTTimeBlock'][np.logical_and(data['StimulusTrial']==Condition,data['ProcedureBlock']==('ExtinctionRecallRun'+str(Run)))])/float(1000)
    ResponseDurations=(data[Task+'RespOnsetToOnsetTime'][np.logical_and(data['StimulusTrial']==Condition,data['ProcedureBlock']==('ExtinctionRecallRun'+str(Run)))])/float(1000)

    CombinedDurations=(data[Task+'RespOnsetToOnsetTime'][np.logical_and(data['StimulusTrial']==Condition,data['ProcedureBlock']==('ExtinctionRecallRun'+str(Run)))] + data[Task+'RespOnsetTime'][np.logical_and(data['StimulusTrial']==Condition,data['ProcedureBlock']==('ExtinctionRecallRun'+str(Run)))] - data['CSImageRecallOnsetTime'][np.logical_and(data['StimulusTrial']==Condition,data['ProcedureBlock']==('ExtinctionRecallRun'+str(Run)))])/float(1000)

    ResponseTimes=(data[Task+'RespRTTime'][np.logical_and(data['StimulusTrial']==Condition,data['ProcedureBlock']==('ExtinctionRecallRun'+str(Run)))])

    OutputFile=open(Output + '/ExtinctionRecall' + str(Run) + '_' + TrialType + '_Image.txt', "w")
    writer = csv.writer(OutputFile, delimiter=' ')
    for row in range(0,len(ImageOnsets)):
        writer.writerow([str(ImageOnsets[row]), str(ImageDurations[row]), str(1)])

    OutputFile=open(Output + '/ExtinctionRecall' + str(Run) + '_' + TrialType + '_Response.txt', "w")
    writer = csv.writer(OutputFile, delimiter=' ')
    for row in range(0,len(ResponseOnsets)):
        writer.writerow([str(ResponseOnsets[row]), str(ResponseDurations[row]), str(1)])

    OutputFile=open(Output + '/ExtinctionRecall' + str(Run) + '_' + TrialType + '_ImageResponse.txt', "w")
    writer = csv.writer(OutputFile, delimiter=' ')
    for row in range(0,len(ImageOnsets)):
        writer.writerow([str(ImageOnsets[row]), str(CombinedDurations[row]), str(1)])
        print(row)

    #Get Onsets by Response Type
    NRImageOnsets=ImageOnsets[ResponseTimes==0]
    NRImageDurations=ImageDurations[ResponseTimes==0]
    NRResponseOnsets=ResponseOnsets[ResponseTimes==0]
    NRResponseDurations=ResponseDurations[ResponseTimes==0]
    NRCombinedDurations=CombinedDurations[ResponseTimes==0]

    if len(NRImageOnsets)>0:
        OutputFile=open(Output+'/ExtinctionRecall' + str(Run) + '_' + TrialType + '_Image_NR.txt', "w")
        writer = csv.writer(OutputFile, delimiter=' ')
        for row in range(0,len(NRImageOnsets)):
            writer.writerow([str(NRImageOnsets[row]), str(NRImageDurations[row]), str(1)])

        OutputFile=open(Output+'/ExtinctionRecall' + str(Run) + '_' + TrialType + '_Response_NR.txt', "w")
        writer = csv.writer(OutputFile, delimiter=' ')
        for row in range(0,len(NRResponseOnsets)):
            writer.writerow([str(NRResponseOnsets[row]), str(NRResponseDurations[row]), str(1)])

        OutputFile=open(Output+'/ExtinctionRecall' + str(Run) + '_' + TrialType + '_ImageResponse_NR.txt', "w")
        writer = csv.writer(OutputFile, delimiter=' ')
        for row in range(0,len(NRImageOnsets)):
            writer.writerow([str(NRImageOnsets[row]), str(NRCombinedDurations[row]), str(1)])

    RImageOnsets=ImageOnsets[ResponseTimes>0]
    RImageDurations=ImageDurations[ResponseTimes>0]
    RResponseOnsets=ResponseOnsets[ResponseTimes>0]
    RResponseDurations=ResponseDurations[ResponseTimes>0]
    RCombinedDurations=CombinedDurations[ResponseTimes>0]

    if len(RImageOnsets)>0:
        OutputFile=open(Output+'/ExtinctionRecall' + str(Run) + '_' + TrialType + '_Image_R.txt', "w")
        writer = csv.writer(OutputFile, delimiter=' ')
        for row in range(0,len(RImageOnsets)):
            writer.writerow([str(RImageOnsets[row]), str(RImageDurations[row]), str(1)])

        OutputFile=open(Output+'/ExtinctionRecall' + str(Run) + '_' + TrialType + '_Response_R.txt', "w")
        writer = csv.writer(OutputFile, delimiter=' ')
        for row in range(0,len(RResponseOnsets)):
            writer.writerow([str(RResponseOnsets[row]), str(RResponseDurations[row]), str(1)])

        OutputFile=open(Output+'/ExtinctionRecall' + str(Run) + '_' + TrialType + '_ImageResponse_R.txt', "w")
        writer = csv.writer(OutputFile, delimiter=' ')
        for row in range(0,len(RImageOnsets)):
            writer.writerow([str(RImageOnsets[row]), str(RCombinedDurations[row]), str(1)])


    #Calculate Response percentage
    ResponseRate=np.array(float(len(data['CSImageRecallOnsetTime'][np.logical_and(np.logical_and(data['StimulusTrial']==Condition,data['ProcedureBlock']==('ExtinctionRecallRun'+str(Run))),data[Task+'RespRT']>0)]))/len(data['CSImageRecallOnsetTime'][np.logical_and(data['StimulusTrial']==Condition,data['ProcedureBlock']==('ExtinctionRecallRun'+str(Run)))])*float(100))
    print(ResponseRate)
    np.savetxt(Output+'/ExtinctionRecall' + str(Run) + '_' + TrialType + '_PercentResponse.txt',ResponseRate.reshape(1),fmt='%s')

    #Calculate Rating
    MeanRating=np.mean(data['ThreatRating'][np.logical_and(data['StimulusTrial']==Condition,data['ProcedureBlock']==('ExtinctionRecallRun'+str(Run)))])
    print(MeanRating)
    np.savetxt((Output+'/ExtinctionRecall' + str(Run) + '_' + TrialType + '_MeanRating.txt'),MeanRating.reshape(1),fmt='%s')

    #Calculate RT
    RT=np.mean(data['ThreatRespRT'][np.logical_and(np.logical_and(data['StimulusTrial']==Condition,data['ProcedureBlock']==('ExtinctionRecallRun'+str(Run))),data['ThreatRespRT']>0)])
    print(RT)
    np.savetxt((Output+'/ExtinctionRecall' + str(Run) + '_' + TrialType + '_MeanRT.txt'),RT.reshape(1),fmt='%s')
