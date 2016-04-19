import pandas as pd
import numpy as np
import argparse
import csv
import os


#Pull the data in based on a parameter entered at the command line
#parser = argparse.ArgumentParser()
#parser.add_argument('--input', '-i', required=True, help='Name of reformatted eprime file')
#parser.add_argument('--task', '-t', required=True, help='Task name')
#args = parser.parse_args()

#infile = args.input
#task = args.task

infile = '/Users/kelly89/Desktop/Stress/Test/101_reformatted_eprime.csv'
task = 'ExtRecall'

print 'infile: ' + infile
print 'task: ' + task


aliases = {'ExtRecall':'ExtinctionRecall', 'FaceReactivity':'ThreatReactivity',
                'WMShape':'WMShapes', 'WMFace':'WMFaces', 'GNG':'GNG'}

alias = aliases[task]
print 'alias: ' + alias

Run1 = alias + 'Run1'
Run2 = alias + 'Run2'
if (task == 'GNG'):
    Run2 += 'and3'

colfile = '/Users/kelly89/Desktop/Stress/Test/ExtRecallSaveCols.csv'
#colfile = '/mnt/stressdevlab/dep_threat_pipeline/bin/eprimeparser/' + task + 'SaveCols.csv'
cols = pd.read_csv(colfile, low_memory = False)
print task + 'cols: ' + str(cols.shape)
x = list(cols.values.T)

data = pd.read_csv(infile, sep='\t', usecols = x, low_memory = False)
#print cols.shape
#print cols.T.shape
#print cols.values.to_list()
#x = pd.DataFrame.from_records(cols.T)
#print x[[0]].values.to_list()
#x = pd.DataFrame.from_records(cols.T)
#print(x)
#names = cols.values
#x = list(names)

#data = pd.read_csv(infile, sep='\t', low_memory = False)
#data = data[list(x)]

#print task + 'rawadata: ' + str(data.shape)
#df = data[data['ProcedureBlock'].isin([Run1,Run2])]
#print task + 'subsetcols: ' + str(df.shape)

#outfile = os.path.dirname(infile) + '/' + task + '-eprime.csv'
#df.to_csv(outfile, header = True, index = False)

#print task + 'rawadata: ' + str(data.shape)
#df = data[data['ProcedureBlock'].isin([Run1,Run2])]
#print task + 'subsetcols: ' + str(df.shape)

#outfile = os.path.dirname(infile) + '/' + task + '-eprime.csv'
#df.to_csv(outfile, header = True, index = False)


#names = cols.values
#print names.shape
#colnames = list(names)

#for col in colnames.columns:
#    colnames[col] = colnames[col].apply(lambda i: ''.join(i))
