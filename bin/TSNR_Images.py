import nipype.algorithms.misc as misc
import argparse
from nipype.algorithms.misc import TSNR

parser=argparse.ArgumentParser()
parser.add_argument('--input', '-i', nargs='+', required=True, help='Image to process')

cmdInput=parser.parse_args()

for filename in cmdInput.input:
	tsnr=TSNR()
	print(filename)
	tsnr.inputs.in_file=filename
	results=tsnr.run()
	results=tsnr.run()
