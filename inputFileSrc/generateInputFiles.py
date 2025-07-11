# Code to generate a parameter set and make folders and input files

import numpy as np
from scipy.stats import qmc
import generateModelFile
import sys
import os

# Check if the correct number of command-line arguments is provided
if len(sys.argv) != 2:
    print("Usage: python generateInputFiles.py <num of samples to pick from> ")
    sys.exit(1)

N=int(sys.argv[1])
# Latin hypercube sampling of parameter space
# Variables in order:
# a_0, b_0, D_GB,  \tau_s, \tau_0, b, \gamma_0,n
# Note this paper: https://www.sciencedirect.com/science/article/pii/S0167844216303135#t0005, 
# gives D_gb numbers for austenitic SS, which is too low

# some in log because they span several orders of magnitude
upperBounds=[np.log10(4e-3), np.log10(6), np.log10(1e-14), 100, 100, 70, np.log10(1e-5), 14, 300]
lowerBounds=[np.log10(4e-7), np.log10(6e-4),np.log10(1e-19), 5, 5, 30, np.log10(1e-9), 4, 30]
log_indices = [0, 1, 2, 6]
sampler=qmc.LatinHypercube(d=9)
sample=sampler.random(n=N)
sample_scaled=qmc.scale(sample, lowerBounds, upperBounds)
sample_scaled[:, log_indices] = 10 ** sample_scaled[:, log_indices] # get the log values back to linear scale

#enforce \tau_s > \tau_0, this is a hardening material
filtered_sample = sample_scaled[sample_scaled[:, 4] <= sample_scaled[:, 3]]


# Now create folders and files for each set of parameters and save in relevant folder


# Loop through each sample in filtered_sample
for idx, sample in enumerate(filtered_sample):
    folder_name = str(idx)
    os.makedirs(folder_name, exist_ok=True)

    # Extract individual parameters
    a0, b0, D_GB, tau_sat, tau_0, b, gamma0, n, load = sample

    # Generate the XML file
    xml_file_path = os.path.join(folder_name, f"{idx}")
    generateModelFile.writeXML(xml_file_path, 'voce', tau_sat, tau_0, gamma0, n, b)

    # Generate the .i file
    i_file_path = os.path.join(folder_name, f"{idx}.i")
    with open(i_file_path, "w") as f:
        f.write("[Materials]\n")
        f.write("  [GB_props]\n")
        f.write("    type = GenericConstantMaterial\n")
        f.write("    prop_names = 'a0 b0 D_GB E G w eta_s T0 FN Nc'\n")
        f.write(f"    prop_values = '{a0} {b0} {D_GB} 150e3 58.3657588e3 0.0113842 1e20 200 1.8e5 0.91'\n")
        f.write("    boundary = 'interface'\n")
        f.write("  []\n")
        f.write("[]\n")

    # write load file
    loadFile = os.path.join(folder_name,"load.i")
    with open(loadFile, "w") as f:
        f.write(f"load = {int(load)}")