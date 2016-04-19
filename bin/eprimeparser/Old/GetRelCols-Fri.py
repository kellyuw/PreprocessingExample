## GetRelCols.py
## 1. Reads SUBJECTID_clean_eprime.csv into pandas dataframe
## 2. Checks if image files exist and creates list of runs based on this information
## 3. Gets list of columns that are relevant to the task
## 4. Reads in subset of task-specific columns from eprime data file
## 5. Saves task-specific behavioral data to file

#Pull the data in based on a parameter entered at the command line
#parser = argparse.ArgumentParser()
#parser.add_argument('--input', '-i', required=True, help='Name of reformatted eprime file')
#args = parser.parse_args()
#infile = args.input
infile = '/mnt/stressdevlab/dep_threat_pipeline/999/behavior/999_clean_eprime.csv'

#Checks if image files exist and creates list of runs based on this info.
def CheckIfImageFilesExist (task):
    print task
    if (task == 'GNG'):
        ExpRunNums = range(1,4,1)
    else:
        ExpRunNums = range(1,3,1)
    
    results = pd.Series()
    
    #For testing purposes, we will assume all image files exist
    #for RunNum in ExpRunNums:
        #FileName = '/mnt/stressdevlab/dep_threat_pipeline/' + str(subject) + '/nifti/' + str(task) + str(RunNum) + '.nii.gz'
        #if os.path.isfile(FileName):
            #result = pd.Series([str(task + str(RunNum))])
            #results = results.append(result)
    #return results

    for RunNum in ExpRunNums:
        result = pd.Series([str(task + 'Run' + str(RunNum))])
        results = results.append(result)
    return results

#Makes Simpsons EV files
def RemoveSimpsons (data, task, fulltaskdir):

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

        #Get Run Number (to use in filename for Simpsons regressor)
        Run = SimpsonOnset[['ProcedureBlock']].values
        RunNum = str(re.findall('\d+', str(Run)))[2]
        print 'RunNum: ' + str(RunNum)

        #Write 3-column EV file with information about Simpsons ITI onset, duration, and strength (1)
        #For testing purposes, write to dirname of infile
        OutputFile = open((fulltaskdir + task + str(RunNum) + '_Simpson.txt'), "w")
        print 'OutputFile: ' + str(OutputFile)
        writer = csv.writer(OutputFile, delimiter=' ')
        writer.writerow([AdjSimpsonOnset, SimpsonDuration, str(1)])
        OutputFile.close()

        #Remove Simpsons row from data and reindex
        data = data.drop(data.index[SimpsonOnset.index])
        data = data.reindex(index = None)

    return data


for task in ['ExtinctionRecall','ThreatReactivity','WMShapes','WMFaces','GNG']:
    subject = os.path.basename(infile).split('_')[0]
    taskdir = task.lower()
    fulltaskdir = '/mnt/stressdevlab/dep_threat_pipeline/' + str(subject) + '/' + str(taskdir) + '/'
    
    print ''
    print 'Task: ' + task
    print 'Subject: ' + subject
    print 'FullTaskDir: ' + fulltaskdir
    
    
    Runs = CheckIfImageFilesExist(task)

    #Gets list of columns that are relevant to the task
    colfile = '/mnt/stressdevlab/dep_threat_pipeline/bin/eprimeparser/' + task + 'SaveCols.csv'
    cols = pd.read_csv(colfile, sep=',', low_memory = False)
    taskcols = cols.columns.values

    #Only read in the relevant columns (this helps immensely with readability of the data files!)
    data = pd.read_csv(infile, sep=',', usecols = taskcols, low_memory = False)
    #print data.columns.values

    #Filter rows to specific task
    subset = data[data['ProcedureBlock'].isin(Runs)]
    print 'Shape of data for ' + task + ': ' + str(subset.shape)

    #Write output to the behavior directory
    outfile = os.path.dirname(infile) + '/' + task + '-eprime.csv'
    subset.to_csv(outfile, header = True, index = False)