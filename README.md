## avi2ufmf

This is a Matlab script to compress .avi video files to .ufmf files
(the "micro fly movie format", see [the Ctrax
website](https://ctrax.sourceforge.net/)).

### Installation

To install, extract all the files in the repo to a folder, say
"/my/folder/avi2ufmf", and then do this in Matlab:
```
cd('/my/folder/avi2ufmf')
modpath
```
Also do
```
savepath()
```
if you want the path changes to persist across Matlab restarts

### Usage

To compress a file in the current Matlab folder that is named
`foo.avi`, do this:
```
avi2ufmf('foo.avi')
```
This will create an output file named `foo.ufmf` in the current
folder.  In my limited experiments, compression ratios of about 40x are
typical relative to uncompressed .avi.

Note that `avi2ufmf()` only works on 8-bit grayscale videos.  And it's
only been testing in Ubuntu.  But it's pure Matlab code, so should
work on any OS where Matlab is supported.  

To get good results, you will probably have to play around with some
of the parameters to `avi2ufmf`.  A call to `avi2ufmf()` that
explicitly sets all of the optional parameters looks like this:
```
avi2ufmf('foo.avi', ...
         'ufmfname', 'foo.ufmf', ...
         'startframe', 1, ...
         'endframe', inf, ...
         'verbose', 1, ...
         'diffmode', 'other', ...
         'blocknframes',200,...
         'bgnframes',50,...
         'bgthresh', 8) ;
```

Most of these you can probably guess what they do.

To explain the others, a bit of background: Like a lot of video
compression algorithms, `avi2ufmf()` encodes a video by recording
"keyframes" every n frames.  In .ufmf, these are stored uncompressed.
Each frame is then encoded as a set of differences relative to the
most recent keyframe.  In .ufmf, these differences are saved as a set
of rectangular subimages ("boxes") where the encoded frame differs
from the last keyframe, and what the pixel data should be in that box.

During encoding, the difference between the current frame and the last
keyframe are computed.  If the difference at a pixel is big enough,
that pixel will be consided a "foreground" pixel, and its pixel data
will be saved in the encoded frame.  Only pixel differences as large
as the parameter `bgthresh`, or larger, are considered foreground
pixels.  Because encoded frames are not guaranteed to be exactly equal
to the input frames, the encoding process a kind of "lossy"
compression.

Note that generating a (hopefully short) list of rectangular boxes
that cover every foreground pixel means that usually some
non-foreground pixels get encoded in each frame.  So it goes.

`diffmode` specifies whether any large-enough difference between a
keyframe pixel and an input frame could be encoded, or whether
deviations in one direction or the other should be ignored.  The value
`'dark-on-light-background'` is typically used for videos with dark
flies (or whatever) moving against a light background, and means that
a frame pixel that is brighter than the keyframe pixel will not be
encoded.  The value `'light-on-dark-background'` is typically used for
videos with light flies (or whatever) moving against a dark
background, and means that a frame pixel that is darker than the
keyframe pixel will not be encoded.  The value `'other'` means that
any large deviation, whether brighter or darker, will be encoded.

`blocknframes` specifies how many frames are between any two keyframes.
E.g. a value of 200 means a keyframe is recorded every 200 frames.
All the frames that share a keyframe are called a "block".

`bgnframes` specifies how many frames in a block are used to compute
the keyframe.  E.g. if `blocknframes` is 200 and `bgnframes` is 50,
every fourth frame will be included in the keyframe computation.  The
keyframe will be the median of these 50 frames, computed as each pixel
independently.

`bgthresh`, as mentioned above, specifies how large the difference
between a frame pixel and the keyframe pixel must be for that frame
pixel to be considered a foreground pixel, and therefore guaranteed to
be encoded in the frame.  E.g. if `diffmode` is `'other'`, `bgnthresh`
is 8, and a keyframe pixel has the value 100, then pixels with values
from 0 to 92, or from 108 to 255, will be considered foreground, and
always encoded.  Pixels with values from 93 to 107 will be considered
"close enough" and not encoded, unless they happen to be near a
foreground pixel and end up in the same box that includes the nearby
foreground pixels.

We include the `showufmf()` function written by [Kristen
Branson](https://www.janelia.org/people/kristin-branson) for
inspecting the generated .ufmf files.

### Credits

This code is all based on code and technologies developed by the
[Branson Lab](https://www.janelia.org/lab/branson-lab), and borrows a
lot of source code from the [FlyDiscoAnalysis
repo](https://github.com/kristinbranson/FlyDiscoAnalysis/) and/or the
[JAABA repo](https://github.com/kristinbranson/JAABA).

This code was developed with funding from the [Aso
Lab](https://www.janelia.org/lab/aso-lab).

Adam L. Taylor
2024-01-25

