This demo folder shows how you can extract particular facial features using a SLEAP pose estimation file.  
In this example, we are working on video data collected from a headfixed mouse. The video is a close up of the mouse's face.
We created a mouse face skeleton structured for 23 points as follows:
   1 -         "upper_eye              "
   2 -         "lower_eye              "
   3 -         "inner_eye              "
   4 -         "outer_eye              "
   5 -         "inner_ear_lower        "
   6 -         "inner_ear_upper        "
   7 -         "ear_fold_top           "
   8 -         "upper_ear              "
   9 -         "outer_ear_upper_edge   "
   10 -         "outer_ear_lower_edge   "
   11 -         "bottom_ear             "
   12 -         "nose_upper             "
   13 -         "nose_tip               "
   14 -         "nostril_left           "
   15 -         "nostril_right          "
   16 -         "mouth_upper            "
   17 -         "mouth_lower            "
   18 -         "chin                   "
   19 -         "headplate              "
   20 -         "top_whisker_stem       "
   21 -         "top_whisker_end        " (not used, too unreliable!)
   22 -         "bottom_whisker_stem    "
   23 -         "bottom_whisker_end     " (not used, too unreliable!)

As you can see, in our initial SLEAP model, we ambitiously tried to track the whisker movement before realizing that the camera frame rate was too slow to effectively capture whiskers.
FEFE is designed to operate from a sleap skeleton using the node-names field.  That means that facial features can be extracted, even if your model uses a different number of keypoints or has different names associated with them.

