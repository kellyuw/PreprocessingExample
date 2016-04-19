
#Pull the data in based on a parameter entered at the command line
#parser = argparse.ArgumentParser()
#parser.add_argument('--input', '-i', required=True, help='Name of reformatted eprime file')
#args = parser.parse_args()
#infile = args.input
infile = '/mnt/stressdevlab/dep_threat_pipeline/999/behavior/999_clean_eprime.csv'


def ParseExtRecall (data, Runs):

    for Run in Runs:
        RunNum = str(re.findall('\d+', str(Run)))[2]
        print 'Task: ' + task
        print 'RunNum: ' + str(RunNum)
        print 'Run: ' + str(Run)


        CSImageStr = 'CSImageRecall'
        ThreatRespStr = 'ThreatResp'
        if (RunNum == '2'):
            CSImageStr += '2'
            ThreatRespStr += '2'

        CSImageStrOnsetTime = str(CSImageStr) + 'OnsetTime'
        CSImageStrOnsetToOnsetTime = str(CSImageStr) + 'OnsetToOnsetTime'
        ThreatRespStrOnsetTime = str(ThreatRespStr) + 'OnsetTime'
        ThreatRespStrOnsetToOnsetTime = str(ThreatRespStr) + 'OnsetToOnsetTime'

        print 'CSImageStr: ' + CSImageStr
        print 'ThreatRespStr: ' + ThreatRespStr

        for TrialType in ['CSPlus','CSMinus']:
            Condition = TrialType + '_Threat'
            print 'Condition: ' + Condition

            #Get CSImageRecallOnsetTime for Response & NonResponse (should match following criteria)
            #1. ProcedureBlock == CurrentProc (ExtinctionRecallRun1 or ExtinctionRecallRun2)
            #2. StimulusTrial == Condition (CSPlus_Threat or CSMinus_Threat)
            #print 'Run: ' + Run
            ImageRecallTrials = data[(data['ProcedureBlock'] == Run) & (data['StimulusTrial'] == Condition)]
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
            ThreatRespStrRT = str(ThreatRespStr) + 'RT'
            ResponseTimes = ImageRecallTrials[ThreatRespStrRT] / float(1000)
            #print(ResponseTimes)


            #Now, get onsets by response type!

            #First, start with non-responses
            #print ImageOnsets
            CSImageStrRT = str(CSImageStr) + 'RT'
            ThreatRespStrRT = str(ThreatRespStr) + 'RT'
            NRImageOnsets = ImageOnsets[(data[CSImageStrRT] == 0)]
            NRImageDurations = ImageDurations[(data[CSImageStrRT] == 0)]
            NRResponseOnsets = ResponseOnsets[(data[ThreatRespStrRT] == 0)]
            NRResponseDurations = ResponseDurations[(data[ThreatRespStrRT] == 0)]
            NRCombinedDurations = CombinedDurations[(data[CSImageStrRT] == 0) | (data[ThreatRespStrRT] == 0)]
            #print(NRCombinedDurations)

            #Print output for NR
            #print 'NRImageOnsets: ' + str(len(NRImageOnsets))
            #print 'NRResponseOnsets: ' + str(len(NRResponseOnsets))
            ExtRecallOutput('Image','NR', RunNum, TrialType, NRImageOnsets, NRImageDurations)
            ExtRecallOutput('Response','NR', RunNum, TrialType, NRResponseOnsets, NRResponseDurations)
            ExtRecallOutput('ImageResponse','NR', RunNum, TrialType, NRImageOnsets, NRCombinedDurations)

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
            ExtRecallOutput('Image','R', RunNum, TrialType, RImageOnsets, RImageDurations)
            ExtRecallOutput('Response','R', RunNum, TrialType, RResponseOnsets, RResponseDurations)
            ExtRecallOutput('ImageResponse','R', RunNum, TrialType, RImageOnsets, RCombinedDurations)


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

def ExtRecallOutput(OutFileType, OutRespType, RunNum, TrialType, dataA, dataB):
    if (not dataA.empty):
        OutputFile = open(SubjectDir + '/extinctionrecall/ExtinctionRecall' + str(RunNum) + '_' + TrialType + '_' + OutFileType + '_' + OutRespType + '.txt', "w")
        writer = csv.writer(OutputFile, delimiter=' ')
        for row in range(0,len(dataA)):
            writer.writerow([str(dataA.values[row]), str(dataB.values[row]), str(1)])
        OutputFile.close()

        
def ParseFaceReactivity (data, Runs):

    for Run in Runs:
        RunNum = str(re.findall('\d+', str(Run)))[2]
        print 'Task: ' + task
        print 'RunNum: ' + str(RunNum)
        print 'Run: ' + str(Run)
        
        ReactivityITIStr = 'ReactivityITIOnsetTime'
        if (str(RunNum) == '2'):
            ReactivityITIStr = 'ReactivityITI2OnsetTime'

        for Condition in ['C','S','F']:
            print 'Condition: ' + Condition

            FirstSubtrials = data[(data['ProcedureBlock'] == Run) & (data['Emotion'] == Condition) & (data['SubTrial'] == 1)]
            LastSubtrials = data[(data['ProcedureBlock'] == Run) & (data['Emotion'] == Condition) & (data['SubTrial'] == 36)]

            if (FirstSubtrials.size == 306):
                TriggerOnsetTimes = FirstSubtrials.TriggerWAITRTTimeBlock
                #print TriggerOnsetTimes

                BlockOnsets = (FirstSubtrials[ReactivityITIStr] - TriggerOnsetTimes) / float(1000)
                #print BlockOnsets


                if (LastSubtrials.size == 306):
                    TriggerOffsetTimes = LastSubtrials.TriggerWAITRTTimeBlock
                    #print TriggerOffsetTimes

                    BlockOffsets = (LastSubtrials[ReactivityITIStr] - TriggerOffsetTimes) / float(1000)
                    #print BlockOffsets

                    BlockDurations = BlockOffsets.values - BlockOnsets.values
                    #print BlockDurations

                    OutputFile = open(SubjectDir + 'threatreactivity/ThreatReactivity' + str(RunNum) + '_' + Condition + '.txt', "w")
                    writer = csv.writer(OutputFile, delimiter=' ')
                    for row in range(0,len(BlockOnsets)):
                        print str(BlockOnsets.iloc[row]) + '\t' + str(BlockDurations[row]) + '\t' + str(1)
                        writer.writerow([str(BlockOnsets.iloc[row]), str(BlockDurations[row]), str(1)])
                    OutputFile.close()
                    
                    
def ParseWMShape (data, Runs):

    for Run in Runs:
        RunNum = str(re.findall('\d+', str(Run)))[2]
        print 'Task: ' + task
        print 'RunNum: ' + str(RunNum)
        print 'Run: ' + str(Run)
        
        OnsetStr = 'WMSprepOnsetTime'
        OffsetStr = 'WMSprobeOnsetTime'
        Condition1 = 'low'
        Condition2 = 'high'
            
        if (str(RunNum) == '2'):
            OnsetStr = 'WMSprep2OnsetTime'
            OffsetStr = 'WMSprobe2OnsetTime'
            Condition1 += '2'
            Condition2 += '2'

        for Condition in [str(Condition1), str(Condition2)]:
            
            NoIntCondition = filter(lambda x: x.isalpha(), str(Condition))
                   
            print 'Condition: ' + Condition
            print 'NoIntCondition: ' + NoIntCondition

            FirstSubtrials = data[(data['ProcedureBlock'] == Run) & (data['ProcedureTrial'] == Condition) & (data['SubTrial'] == 1)]
            LastSubtrials = data[(data['ProcedureBlock'] == Run) & (data['ProcedureTrial'] == Condition) & (data['SubTrial'] == 5)]
            
            #Add 1500 ms to each offset
            LastSubtrials[OffsetStr] = LastSubtrials[OffsetStr] + float(1500)
            
            #Adjust block onsets and offsets by TriggerWAITOnsetTimeBlock
            AdjBlockOnsets = FirstSubtrials[OnsetStr] -  FirstSubtrials.TriggerWAITOnsetTimeBlock
            AdjBlockOffsets = LastSubtrials[OffsetStr] - LastSubtrials.TriggerWAITOnsetTimeBlock
            
            BlockOnsetsInSec = AdjBlockOnsets.values / float(1000)
            BlockOffsetsInSec = AdjBlockOffsets.values / float(1000)
            BlockDurationsInSec =  BlockOffsetsInSec -  BlockOnsetsInSec
            
            print BlockOnsetsInSec
            print BlockOffsetsInSec
            print BlockDurationsInSec
            
            OutputFile = open(SubjectDir + '/wmshapes/WMShapes' + str(RunNum) + '_' + NoIntCondition + '.txt', "w")
            writer = csv.writer(OutputFile, delimiter=' ')
            for row in range(0,len(BlockOnsetsInSec)):
                print str(BlockOnsetsInSec[row]) + '\t' + str(BlockDurationsInSec[row]) + '\t' + str(1)
                writer.writerow([str(BlockOnsetsInSec[row]), str(BlockDurationsInSec[row]), str(1)])
            OutputFile.close()



for task in ['ExtinctionRecall','ThreatReactivity','WMShapes','WMFaces','GNG']:

    SubjectDir = '/mnt/stressdevlab/dep_threat_pipeline/' + subject
    infile = str(SubjectDir) + '/behavior/' + task + '-eprime.csv'
    
    print ''
    print 'Task: ' + task
    print 'Subject: ' + subject
    
    Runs = CheckIfImageFilesExist(task)
    
    #Get the data into an array
    subset = pd.read_csv(infile, sep=',', low_memory = False)

    #Remove Simpsons characters from the dataset 
    #data = RemoveSimpsons(subset, task, fulltaskdir)
    
    if (task == 'ExtinctionRecall'):
        ParseExtRecall(data, Runs)
    elif (task == 'ThreatReactivity'):
        ParseFaceReactivity(data, Runs)
    elif (task == 'WMShapes'):
        ParseWMShape(data, Runs)
    else:
        print "Other tasks not ready to be parsed yet."