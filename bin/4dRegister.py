#!/usr/bin/env python

import numpy as np
import os as os
import argparse
from nipy import load_image, save_image
from nipy.algorithms.registration import FmriRealign4d
from sys import exit

parser = argparse.ArgumentParser()
parser.add_argument('--inputs', '-i', nargs='+', required=True, help='One or more 4d fMRI inputs to realign and interpolate')
parser.add_argument('--tr', '-t', required=True, type=float, help='The repetition time (TR) of the acquisition sequence')
parser.add_argument('--slice_order', '-s', nargs='+', required=True, help='Order of slices (0-based array): commonly seqasc, seqdesc,interleaved')
parser.add_argument('--prefix', '-p', required=False, default='_mc', help='File prefix for resampled data.')
parser.add_argument('--mats', '-m', action="store_true", required=False, default=False, help='Whether to output affine transformation matrices.')

cmdInput = parser.parse_args()

slice_order=None
interleaved=False

if len(cmdInput.slice_order) == 1:
    if not cmdInput.slice_order[0].lower() in ['ascending', 'descending', 'interleaved']:
        print "--slice_order must be ascending, descending, interleaved, or a numeric array of slice ordering"
        exit(1)

    if cmdInput.slice_order[0].lower() == 'interleaved':
        print "Assuming interleaved ascending beginning with bottom slice: 0, 2, 4, ... 1, 3, 5, ..."
        slice_order="ascending"
        interleaved=True
    else:
        slice_order=cmdInput.slice_order[0].lower()
else:
    print "Processing custom slice order. Remember that 0 is the bottom slice."
    slice_order=[int(i) for i in cmdInput.slice_order] #convert to list of integers

runs = [load_image(f) for f in cmdInput.inputs]

R = FmriRealign4d(runs, tr=cmdInput.tr, slice_order=slice_order, interleaved=interleaved, time_interp=True)

#estimate motion and slice timing realignment
R.estimate()

#resample data
ra_runs = R.resample()

#save resampled images
for i, corrImage in enumerate(ra_runs):
    #save realigned image
    #trim off .nii or .nii.gz extension
    iname = cmdInput.inputs[i].split('.')
    if len(iname) > 2 and (iname[-1].lower() == "gz" and iname[-2].lower() == "nii"):
        imname = '.'.join(iname[:-2]) + cmdInput.prefix + '.nii.gz' #drop last two dotted pieces: .nii.gz
    elif len(iname) > 1 and iname[-1].lower() == "nii":
        immname = '.'.join(iname[:-1])  + cmdInput.prefix + '.nii' #drop last dotted piece: .nii
    else:
        print "Can't determine file name of input properly."
        exit(1)
    save_image(corrImage, imname)

    #save motion estimates, stored in realign object _transforms
    motion = R._transforms[i]

    #trim off .nii or .nii.gz extension
    iname = cmdInput.inputs[i].split('.')
    if len(iname) > 2 and (iname[-1].lower() == "gz" and iname[-2].lower() == "nii"):
        mname = '.'.join(iname[:-2]) + '.par' #drop last two dotted pieces: .nii.gz
    elif len(iname) > 1 and iname[-1].lower() == "nii":
        mname = '.'.join(iname[:-1]) + '.par' #drop last dotted piece: .nii
    else:
        print "Can't determine file name of input properly."
        exit(1)

    mfile = open(mname, 'w')

    #Make mats dir if needed
    if cmdInput.mats:
        idir = os.path.dirname(cmdInput.inputs[i]) #get directory of this input
        tdir = os.path.join(idir, 'mats')
        if not os.path.exists(tdir):
            os.makedirs(tdir)

    #reformat motion parameters to be consistent with fsl mcflirt output
    for j, mo in enumerate(motion):
        params = ['%.10f' % item for item in np.hstack((mo.rotation, mo.translation))]
        string = ' '.join(params) + '\n'
        mfile.write(string)
        if cmdInput.mats:
            np.savetxt(os.path.join(tdir, 'mot%.4d.mat' % j), mo.as_affine(), fmt='%.8f')

    mfile.close()
