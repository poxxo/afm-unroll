# AFMunroll
## Description
Have you ever wanted to do a time-dependent atomic force microscopy-based measurement where you monitor the change of some quantity on the sample with the AFM (atomic force microscopy) probe fixed in place? And then soon found that the AFM software either doesn't let you record this quantity as a function of time, or for some reason won't allow a sufficiently high sampling rate? Welcome to the club.

With Asylum's software, there is a logger feature that lets you monitor things in time, and appears to let your sampling rate as well, but it doesn't seem to sample at fixed time intervals, and beyond a certain sampling rate (for me it was about 15 kHz) it doesn't care what you input. However, internally the software is able to sample faster than this: you can see this when you are scanning a frame with a sampling rate (per pixel) greater than the logger limit, and still record rapid changes.

The (admittedly hacky) solution is to do a scan over a very tiny area (e.g. 5 nm by 5 nm), and set the scan rate (in Asylum's software this is the rate at which each line in the image is scanned) and the image resolution (Points & Lines in the Asylum software). The effective sampling rate (per pixel) is then `Sampling Rate = 2*(Scan Rate)*(Points & Lines)`, where the factor of 2 is there because each line is scanned forward (trace) and backward (retrace).

After capturing the trace and retrace image for the quantity you are interested in, you can "unroll" both images and interlace them appropriately to get a time sequence. This is what AFMunroll.m does.

## Supported platforms
The code has only been tested on Windows 10, and with .ibw (IGOR Pro binary wave) files obtained from measurements with Asylum MFP-3D. Support for data in an ASCII format will be added later.

## Caveat
Between the end of each line in the trace image and the beginning of the following line in the retrace image and vice versa, there seems to be a delay as long as ~42% of the time it takes to capture a single line, depending on Scan Rate and/or Points & Lines. This may be a deal breaker depending on the measurement.

## Usage examples
```Matlab
sequence = AFMunroll('path\to\file.ibw', 'UserIn0', 'FrameUp');

[sequence, time] = AFMunroll('path\to\file.ibw', {'Height', 'Deflection'}, 'FrameDown', 0.98, 4096);
plot(time, sequence(2, :)); % Plots deflection as a function of time.
```

## References
To recover data from .ibw files, a slightly modified version of the code Igor2Matlab is used:

Jakub Bialek (2020). Igor Pro file format (ibw) to matlab variable (https://www.mathworks.com/matlabcentral/fileexchange/42679-igor-pro-file-format-ibw-to-matlab-variable), MATLAB Central File Exchange. Retrieved February 4, 2020. 
