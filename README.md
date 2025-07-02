# FEFE
Facial Expression Feature Extraction toolbox (Matlab)

This toolbox extracts various features from facial tracked sleap videos using Matlab.  The folder /src/fefe  contains functions for extracting specific types of features and can be applied to any skeleton.

The /demo/ folder contains example data from a head-fixed mouse including: pose estimates from SLEAP, an events file detailing reward and adversive stimuli, and a spout file.  The spout file is a matlab file that imports the length of the spout in the facial video and uses it to convert distances from pixels to cm.
The file load_sleap_events_video.m shows how to load and extract the features.

## System requirements
To run this code, you must have MATLAB installed. This code was tested using MATLAB version 9.14.0.2286388 (R2023a) Update 3.

## Citation

Coley AA, Batra K, Delahanty JM, Keyes LR, Pamintuan R, Ramot A, Hagemann J, Lee CR, Liu V, Adivikolanu H, Cressy J, Jia C, Massa F, LeDuke D, Gabir M, Durubeh B, Linderhof L, Patel R, Wichmann R, Li H, Fischer KB, Pereira T, Tye KM. *Predicting Future Development of Stress-Induced Anhedonia From Cortical Dynamics and Facial Expression*. **bioRxiv** [Preprint]. 2024 Dec 20:2024.12.18.629202. doi: 10.1101/2024.12.18.629202. PMID: 39764017; PMCID: PMC11702711.
