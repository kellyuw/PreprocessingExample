import pandas as pd
import numpy as np
import argparse
import csv
import os
import re

#Pull the data in based on a parameter entered at the command line
parser = argparse.ArgumentParser()
parser.add_argument('--input', '-i', required=True, help='Name of reformatted eprime file')
args = parser.parse_args()
infile = args.input

#Remove bad characters from header names ([,],.)
hdr = pd.read_csv(infile, sep = '\t', nrows = 1)
hdr.rename(columns=lambda x: re.sub('[\[\].]','',x), inplace=True)

#Get rest of the datafile with cleanheader
data = pd.read_csv(infile, sep = '\t', skiprows = [0], names = hdr, low_memory = False)
    
print str(infile) + ' shape: ' + str(data.shape)
    
#Write to file
outfile = os.path.dirname(infile) + '/' + os.path.basename(infile).split('_')[0] + '_clean_eprime.csv'
data.to_csv(outfile, sep=',')
