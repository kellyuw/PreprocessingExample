import pandas as pd
import numpy as np
import argparse
import csv
import os

#Pull the data in based on a parameter entered at the command line
parser = argparse.ArgumentParser()
parser.add_argument('--input', '-i', required=True, help='Name of reformatted eprime file')
parser.add_argument('--task', '-t', required=True, help='Task name')
args = parser.parse_args()

infile = args.input
task = args.task

print 'infile: ' + infile
print 'task: ' + task

#Match name from directory structure to task name in eprime file
aliases = {'ExtRecall':'ExtinctionRecall', 'FaceReactivity':'ThreatReactivity',
                    'WMShape':'WMShapes', 'WMFace':'WMFaces', 'GNG':'GNG'}

alias = aliases[task]
print 'alias: ' + alias

Run1 = alias + 'Run1'
Run2 = alias + 'Run2'
if (task == 'GNG'):
    Run2 += 'and3'

#Get list of columns that are relevant to the task
colfile = '/mnt/stressdevlab/dep_threat_pipeline/bin/eprimeparser/' + task + 'SaveCols.csv'
cols = pd.read_csv(colfile, sep=',', low_memory = False)
x = cols.columns.values

#Only read in the relevant columns (this helps immensely with readability of the data files!)
data = pd.read_csv(infile, sep=',', usecols = x, low_memory = False)
print(data.columns.values)

#Filter rows to specific task
df = data[data['ProcedureBlock'].isin([Run1,Run2])]
print task + 'subsetcols: ' + str(df.shape)

#Write output to the behavior directory
outfile = os.path.dirname(infile) + '/' + task + '-eprime.csv'
df.to_csv(outfile, header = True, index = False)
