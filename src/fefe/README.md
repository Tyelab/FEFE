# fefe — Facial Expression Feature Extraction functions

MATLAB functions that turn SLEAP keypoint tracks (`.analysis.h5`) into per-frame
facial-expression features. Most functions are skeleton-agnostic: they work from
node names and indices. The exception is `compute_polyface`, which expects the
21-node mouse face skeleton listed below.

See `../../demo/load_sleap_video_events.m` and `../../demo/compute_select_features_v02.m`
for a full worked pipeline.

---

## Common inputs and conventions

| Argument | Description |
|---|---|
| `mouseData` | struct for **one** session. Must contain `tracks` (`nVideoFrames × nKeypoints × 2`, x/y in pixels) and `node_names`. Optional `Spout` (see units). A 1×1 cell is unwrapped by some functions; a larger cell array raises an error. |
| `shockFrames` | **row vector** of video frame indices to compute features on (e.g. stimulus windows, or `1:size(tracks,1)` for the whole video). The functions use `size(shockFrames,2)` as the frame count. |
| `keypts` | cell array of node names (usually `mouseData.node_names`). Run through `clean_up_node_names`, so names become valid MATLAB field names. |
| `tempTrack` | optional output struct (a new one is created if it's left out). Each feature is added as a field holding an `nFrames × 1` column. Pass the same struct through successive calls to build up the feature set, then convert it to a table (see the demo). |

**Units (pixel → cm).** If `mouseData.Spout` exists and is non-empty, distance-,
velocity- and area-type features are multiplied by `mouseData.Spout.conversionFactor`
(derived from the known lick-spout length in the frame), and the feature name gets
a `_cm` suffix. Without it, values stay in pixels, which depend on camera
distance and angle.

**Angles** are in **radians**, in the range [0, π].

**Preprocessing done in the demo, not in these functions:** removal of unreliable
nodes (whisker ends, duplicate nostril) and Savitzky–Golay smoothing of the tracks
(`smoothdata(tracks,1,'sgolay',5)`).

---

## Feature catalog

### 1. Pairwise keypoint distances: `compute_dist_between_keypoints`

```matlab
tempTrack = compute_dist_between_keypoints(mouseData, shockFrames, keypts, tempTrack)
```

- Euclidean distance between **every unique pair** of keypoints in every frame.
  N keypoints give N(N−1)/2 features (210 for the 21-node face skeleton).
- **Feature name:** `<kp1>_<kp2>_dist[_cm]`
- Examples of facial actions these capture:
  - `upper_eye_lower_eye_dist`: eye opening (blink / squint / orbital tightening)
  - `mouth_upper_mouth_lower_dist`: mouth opening
  - `upper_ear_bottom_ear_dist`: ear height / ear flattening
  - `nose_tip_*`, `*_whisker_stem` pairs: snout and whisker-pad displacement

### 2. Three-point angles

```matlab
tempTrack = compute_angle_between_keypoints(mouseData, shockFrames, keypts, name1, name2, name3, tempTrack)
tempTrack = compute_angle_between_centroids(mouseData, shockFrames, keypts, idx1, idx2, idx3, name1, name2, name3, tempTrack)
```

- The angle at vertex **point 2**, between vectors 2→1 and 2→3:
  `atan2(|det([u;v])|, dot(u,v))`.
- Each of the three "points" can be a single keypoint or a **group**. A group's
  centroid (mean x, y) is used as the point.
- `compute_angle_between_keypoints` looks points up **by name** (`name1..3`).
- `compute_angle_between_centroids` uses the **indices** (`idx1..3`). An index can be
  a single keypoint or an array, e.g. `[1,2,3,4]` for the whole eye. The name is
  used only to label a group in the feature name, or to look up a point whose
  index is passed as `[]`. A warning is printed when a name is neither a node name
  nor the label for a group (more than one index). If the index is also empty,
  the warning says the angle will be all zeros.
- **Feature name:** `<p1>_<p2>_<p3>_angle`. If the field already exists, it is skipped.
- Used in the demo for:
  - whisker angle: `top_whisker_stem`, `nostril_right`, `bottom_whisker_stem`
  - ear angle: `outer_ear_upper_edge`, `outer_ear_lower_edge`, `upper_ear`
  - nostril angle: `nostril_left`, `nostril_right`, `mouth_upper`

`compute_angle_between_datasets(D1, D2, dbg)` is a related helper. It fits a line to
each of two N×2 point sets and returns the angle between the two lines
(in radians; 0 if either fit is NaN). It does not write to `tempTrack`.

### 3. Region polygon area: `compute_area`

```matlab
tempTrack = compute_area(mouseData, shockFrames, keypts_index_or_names, feature_name, tempTrack)
```

- Area of the polygon whose vertices are the given keypoints, computed with `polyarea`.
  Keypoints can be numeric indices or a cell array of node names.
- **Feature name:** `<feature_name>_area[_cm]`
- Demo uses: `whole_eye` (eye 1–4), `whole_ear` (outer ear 7–11), `whole_nose` (12–15).
- Vertex order matters: `polyarea` expects the points to go around the outline in order.

### 4. Triangle area: `compute_triangle_area`

```matlab
tempTrack = compute_triangle_area(mouseData, shockFrames, keypts, i, j, k, ~, ~, ~, tempTrack)
```

- Area of the triangle formed by keypoints `i, j, k`, from the three side lengths
  using Heron's formula: `¼·sqrt(4a²b² − (a²+b²−c²)²)`.
- **Feature name:** `<kp_i>_<kp_j>_<kp_k>_area[_cm]`. This name is in cm² when converted, even though the suffix is `_cm`.

### 5. Ellipse fit to a region: `compute_ellipse`

```matlab
tempTrack = compute_ellipse(mouseData, frames, keypoint_indices, feature_name, tempTrack, dbg)
```

Fits an ellipse to the keypoints in each frame using `src/util/fit_ellipse`. It is
designed for the ear (demo: nodes 6–11). If any keypoint is NaN, or the fit returns
a hyperbola, the features for that frame are NaN.

| Feature | Meaning |
|---|---|
| `<name>_ellipse_major_axis_len[_cm]` | long-axis length |
| `<name>_ellipse_minor_axis_len[_cm]` | short-axis length |
| `<name>_ellipse_axis_ratio` | major / minor (elongation) |
| `<name>_ellipse_tilt` | orientation φ (radians) |
| `<name>_ellipse_area[_cm]` | `π·major·minor`, using the axis lengths returned by `fit_ellipse` |
| `<name>_ellipse_eccentricity` | `sqrt(1 − minor²/major²)` |

`dbg=1` overlays the keypoints and the fitted ellipse on the video frame. This only
works when no cm conversion is applied (set `mouseData.Spout = []`).

### 6. Region centroid kinematics: `compute_centroid_features`

```matlab
tempTrack = compute_centroid_features(mouseData, shockFrames, keypts, keypts_index_or_names, feature_name, tempTrack, PRESERVE_NAN)
```

Takes the centroid of a group of keypoints (e.g. `whole_eye`, `whole_ear`,
`whole_nose`) and computes how it moves over time. With `PRESERVE_NAN=1` (the
default), NaN centroids are first filled by linear interpolation.

| Feature | Meaning |
|---|---|
| `<name>_velocity_001[_cm]` | frame-to-frame centroid displacement (speed, in units per frame) |
| `<name>_velocity_010[_cm]` | trailing moving mean of speed over the current frame plus the previous 10 |
| `<name>_velocity_030[_cm]` | trailing moving mean of speed over the current frame plus the previous 30 |
| `<name>_acceleration_001[_cm]` | magnitude of the second difference of centroid position |
| `<name>_aoc_velocity_001/010/030[_cm]` | area under the speed curve (`trapz`) over a trailing 5-frame window |
| `<name>_aoc_acceleration_001[_cm]` | area under the acceleration curve over a trailing 5-frame window |

- Velocity and acceleration go through `remove_outliers` (values above mean + 6 SD are set to 0).
- The centroid x/y positions are used along the way but are not kept as features.

### 7. Whole-face motion energy: `compute_ave_dist_from_previous_frame`

```matlab
tempTrack = compute_ave_dist_from_previous_frame(mouseData, shockFrames, keypts, tempTrack)
```

- **Feature:** `pointDistAllAve` is the displacement of each keypoint since the
  previous video frame, averaged over all keypoints. It is a global "how much is
  the face moving" signal.
- Set to 0 on the first frame of `shockFrames` and on the first frame of each new
  trial (detected as a gap of more than 20 frames in `shockFrames`), since those
  frames have no previous frame in the same trial. Outliers are removed. Values are always in pixels (no cm conversion).
- The old `compute_dist_features` was removed. Use `compute_dist_between_keypoints`
  for its pairwise distances and this function for its `pointDistAllAve`.

### 8. "Polyface" triangle mesh: `compute_polyface`

```matlab
tempTrack = compute_polyface(mouseData, shockFrames, keypts, tempTrack)
```

Splits the face into a fixed mesh of keypoint triangles. For each triangle it adds
one **angle** feature (via `compute_angle_between_centroids`) and one **area**
feature (via `compute_triangle_area`). By default (`USE_EAR_POINTS = 0`) it uses
21 triangles covering the eye, under-eye/cheek, nose bridge, nose tip and nostrils,
whisker pad, mouth and chin. Setting `USE_EAR_POINTS = 1` adds 13 ear, temple and
lower-cheek triangles, for 34 in total.

Requires node names to match this skeleton **exactly and in this order**:

| # | node | # | node | # | node |
|---|---|---|---|---|---|
| 1 | upper_eye | 8 | upper_ear | 15 | nostril_right |
| 2 | lower_eye | 9 | outer_ear_upper_edge | 16 | mouth_upper |
| 3 | inner_eye | 10 | outer_ear_lower_edge | 17 | mouth_lower |
| 4 | outer_eye | 11 | bottom_ear | 18 | chin |
| 5 | inner_ear_lower | 12 | nose_upper | 19 | headplate |
| 6 | inner_ear_upper | 13 | nose_tip | 20 | top_whisker_stem |
| 7 | ear_fold_top | 14 | nostril_left | 21 | bottom_whisker_stem |

---

## Post-processing and normalization helpers

| Function | Purpose |
|---|---|
| `clean_up_node_names(keypts)` | Trims whitespace and replaces spaces and special characters with `_` so node names work as struct and table field names. |
| `remove_outliers(x, dbg)` | Sets values above mean + 6·SD to 0 (one-sided; N×1 input). |
| `compute_binary_threshold(x, dbg)` | Binarizes a feature at its mean (0 below the mean, 1 above). |
| `compute_tortuosity(x)` | Path length ÷ endpoint distance for an n×2 trajectory. A value of 1 means a straight path; larger values mean a more winding path. |
| `compute_point_dist(x, y)` | Euclidean distance between two 2-D points. |
| `compute_mean_std_table(T)` | Mean and SD of each column of a feature table, returned as `mean_*` / `std_*` tables (e.g. from baseline frames pooled across sessions). |
| `zscore_table(T, mu, sigma)` | Z-scores each table column using the given `mu`/`sigma` tables (e.g. from `compute_mean_std_table`). If they are omitted, it uses the table's own statistics. |
| `zscore_feature_table_by_session(T, session_array, features)` | Z-scores each feature separately within each session. |
| `zscore_feature_table_by_session_baseline(T, baseline_T)` | Meant to normalize to a baseline (ITI) table. **Currently disabled**: it raises an error on entry. |

---

## Known caveats (as of this survey)

These are worth checking before relying on specific features:

1. **Fixed (2026-10-08): index lookup in `compute_angle_between_centroids`.** It used
   to ignore its index arguments and look points up by name. That caused two bugs:
   - Every `compute_polyface` triangle produced the same
     `upper_eye_lower_eye_inner_eye_angle`.
   - Group angles such as the demo's `whole_eye`/`whole_ear`/`whole_nose` were
     always 0.

   The function now uses the indices, so polyface produces 21 distinct angle
   features. **Feature tables and models built before this fix contain the wrong
   angle values and columns, so recompute them.** `compute_polyface` still passes
   `keypts{1},keypts{2},keypts{3}` as the name arguments. This is harmless now,
   because single-point labels come from the indices.

   The function now also prints a warning when a name is neither a node name nor
   a group label (see section 2), so a mistyped name no longer silently produces
   a zero angle. `compute_angle_between_keypoints` has **no** such check. It looks
   points up by name only, so a mistyped name there still gives an angle of 0 for
   every frame without any warning.
2. **Fixed (2026-10-08): frame indexing in areas.** `compute_area` and
   `compute_triangle_area` used to read `tracks(ii,…)` / `tracks(ff,…)` (the loop
   counter) instead of the requested video frame. They now index by
   `shockFrames`. Results were already correct for `shockFrames = 1:N`. For any
   other frame set, earlier area features came from the wrong frames and should
   be recomputed.
3. **Fixed (2026-10-08): `compute_ave_dist_from_previous_frame` frame handling.**
   - The stray `end` after the first error check was removed.
   - Trial starts used to be the *positions* returned by `find(diff(shockFrames) > 20)`,
     compared against frame numbers. As a result:
     - The function errored when `shockFrames` began at video frame 1, because
       it read `tracks(0,…)`. That includes the demo's `1:N`.
     - The first frame of each later trial was compared with the last frame of
       the previous trial.
   - Trial starts are now the frame numbers of the first frame and of the frame
     after each gap, and those frames get 0. Earlier `pointDistAllAve` values at
     trial boundaries should be recomputed.
4. **Fixed (2026-10-08): `nargin` checks for `tempTrack`.** Several functions used
   `nargin<4` even though `tempTrack` is a later argument. Leaving `tempTrack` out
   then raised an "undefined variable" error instead of creating a new struct.
   The checks now match each function's argument position:
   `compute_angle_between_centroids` and `compute_triangle_area` (10),
   `compute_angle_between_keypoints` (7), `compute_centroid_features` (6),
   `compute_area` (5). `tempTrack` is now optional in every feature function.
5. **Fixed (2026-10-08): numeric keypoint indices in `compute_area` and
   `compute_centroid_features`.** Both functions checked `isdouble(keypts_index_in)`,
   which is not a MATLAB function. Passing numeric indices such as `[1,2,3,4]`, as
   the demo does, raised `Unrecognized function or variable 'isdouble'`. The check
   is now `isnumeric`, so numeric indices and cell arrays of node names both work.
