import os
import numpy as np
import argparse

#Pull the data in based on a parameter entered at the command line
parser = argparse.ArgumentParser()
parser.add_argument('--input', '-i', required=True, help='File containing list of outliers')
parser.add_argument('--vols', '-v', required=True, help='Number of volumes in timeseries')
parser.add_argument('--output', '-o', required=True, help='Name of output file matrix')
parser.add_argument('--outputpercent', '-p', required=True, help='Name of output file for percent of volumes')

args = parser.parse_args()

if os.path.isfile(args.input):
	badvols=np.loadtxt(args.input,dtype=int)
	cols=len(badvols)
	rows=int(args.vols)

	if cols > 0:
		singlepointmat=np.zeros((rows,cols))
		for x in range(0,cols):
			singlepointmat[badvols[x],x]=1
		np.savetxt(args.output,singlepointmat,fmt='%d',delimiter='\t',newline='\n')
		percent=(float(cols)/float(rows))*100
		print 'Excluding ' + str(percent) + '% of volumes'
		with open(args.outputpercent,'w') as f:
			f.write(str(percent))

	else:
		percent=0
		print percent
		print 'Excluding ' + str(percent) + '% of volumes'
		with open(args.outputpercent,'w') as f:
			f.write(str(percent))
