import argparse
import subprocess
import os
import re
from ocmbin import ocmbin

parser = argparse.ArgumentParser()
parser.add_argument('file', type=str, help='.ocmbin file', default='test.bin')

file = 'test.bin'

if __name__ == '__main__':
    args = parser.parse_args()

    A = ocmbin(args.file, do_load=False)
    header = A.read_header()

    directory, file = os.path.split(args.file)
    fname, ext = os.path.splitext(file)

#    if not os.path.isdir(os.path.join(directory, 'tmp')):
#        os.mkdir(os.path.join(directory, 'tmp'))

    output_file = os.path.join(directory, fname + '.json')

    with open(output_file, 'w+') as f:
        f.write(re.sub(r'\r\n', r'\n', header))

#    subprocess.call(['notepad++', output_file])