import argparse
import os


#Pull the data in based on a parameter entered at the command line
parser = argparse.ArgumentParser()
parser.add_argument('--task', '-t', required=True, help='Name of task')
parser.add_argument('--task', '-r', required=True, help='Run number')
parser.add_argument('--subject', '-s', required=True, help='Subject ID number')
args = parser.parse_args()
task = args.task
run = args.run


OnsetFiles = {ExtinctionRecall:[CSPlus_ImageResponse_R,CSMinus_ImageResponse_R, Simpson, CSPlus_ImageResponse_NR, CSMinus_ImageResponse_NR]},


}
os.stat("file").st_size == 0