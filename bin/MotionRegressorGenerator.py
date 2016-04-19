import numpy as np
import argparse
from sklearn.decomposition import  RandomizedPCA
from sklearn import preprocessing

#Pull the data in based on a parameter entered at the command line
parser = argparse.ArgumentParser()
parser.add_argument('--input', '-i', required=True, help='Name of .par file to import')
parser.add_argument('--output','-o', required=True, help='Prefix for output files')

args = parser.parse_args()

print args.input

print args.output

#Get Original Parameters
origparams=np.loadtxt(args.input,dtype=float)

#Get Power estimates of total and relative displacement
absdisplacement=np.sum(np.hstack((abs(origparams[:,0:3]*50),abs(origparams[:,3:6]))),axis=1)
reldisplacement=abs(np.diff(absdisplacement,axis=0))

#Get some summary statistics
meanabs=np.mean(absdisplacement)
maxabs=np.max(absdisplacement)
meanrel=np.mean(reldisplacement)
maxrel=np.max(reldisplacement)

#Save some files
np.savetxt((args.output + '_abs_disp.txt'),absdisplacement,fmt='%.4f',delimiter='\t',newline='\n')

np.savetxt((args.output + '_rel_disp.txt'),reldisplacement,fmt='%.4f',delimiter='\t',newline='\n')

with open((args.output + '_mean_abs_disp.txt'),'w') as f:
	f.write(str(meanabs))

with open((args.output + '_max_abs_disp.txt'),'w') as f:
	f.write(str(maxabs))

with open((args.output + '_mean_rel_disp.txt'),'w') as f:
	f.write(str(meanrel))

with open((args.output + '_max_rel_disp.txt'),'w') as f:
	f.write(str(maxrel))

#Calculate Derivatives and Quadratics
deriv=np.vstack(([0,0,0,0,0,0],np.diff(origparams,axis=0)))
#quadorig=origparams**2
#quadderiv=deriv**2

#Create a full motion parameter set
#fullmotionparams=np.hstack((origparams,deriv,quadorig,quadderiv))
#np.savetxt((args.output + '_All24Params.txt'),fullmotionparams,fmt='%.4f',delimiter='\t',newline='\n')

#Do singular value decomposition
#First scale the data for each column (because the estimates are not in the same units)
scaledparams=preprocessing.scale(origparams,axis=0)
scaledderivs=preprocessing.scale(deriv,axis=0)
#Now run the PCA
pca=RandomizedPCA(whiten=True)
pca.fit(scaledparams.T)
PC1=pca.components_[0]
PC1Explained=pca.explained_variance_ratio_[0]*100
np.savetxt((args.output + '_abs_pc1.txt'),PC1,fmt='%.4f',delimiter='\t',newline='\n')
with open((args.output + '_abs_pc1_percent.txt'),'w') as f:
	f.write(str(PC1Explained))

pca=RandomizedPCA(whiten=True)
pca.fit(scaledderivs.T)
PC1=pca.components_[0]
PC1Explained=pca.explained_variance_ratio_[0]*100
np.savetxt((args.output + '_rel_pc1.txt'),PC1,fmt='%.4f',delimiter='\t',newline='\n')
with open((args.output + '_rel_pc1_percent.txt'),'w') as f:
	f.write(str(PC1Explained))
