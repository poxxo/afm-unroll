# AFMunroll
Have you ever wanted to do a time-dependent atomic force microscopy-based measurement where you monitor the change of some quantity on the sample with the AFM (atomic force microscopy) probe fixed in place? And then soon found that the AFM software either doesn't let you record this quantity as a function of time, or for some reason won't allow a sufficiently high sampling rate? Welcome to the club.

With Asylum's software, there is a logger feature that lets you monitor things in time, and appears to let your sampling rate as well, but it doesn't seem to sample at fixed time intervals, and beyond a certain sampling rate (for me it was about 15 kHz) it doesn't care what you input. However, internally the software is able to sample faster than this: you can see this when you are scanning a frame with a sampling rate (per pixel) greater than the logger limit, and still record rapid changes.

The (admittedly hacky) solution is to do a scan over a very tiny area (e.g. 5 nm by 5 nm), and set the scan rate (in Asylum's software this is the rate at which each line in the image is scanned) and the image resolution (Points & Lines in the Asylum software). The effective sampling rate (per pixel) is then `Sampling Rate = 2*(Scan Rate)*(Points & Lines)`, where the factor of 2 is there because each line is scanned forward (trace) and backward (retrace).

After capturing the trace and retrace image for the quantity you are interested in, you can "unroll" both images and interlace them appropriately to get a time sequence. This is what this repo is for.
