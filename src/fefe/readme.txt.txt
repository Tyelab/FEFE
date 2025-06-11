This directory contains matlab functions to compute generic features based on nodenames in a SLEAP skeleton.
FEFE = Facial Expression Feature Extraction 

Notes
 compute_dist_features and compute_dist_between_keypoints are similar and both compute the distances between keypoints.
 But compute_dist_features also computes the total movement of all points from the last frame (pointDistAllAve)

 compute_dist_features is deprecated as it was broken into 2 functions:
 - compute_dist_between_keypoints.m
 - compute_ave_dist_from_previous_frame.m

