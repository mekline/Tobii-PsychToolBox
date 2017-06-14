This is a basic demo that uses the *new* Tobii SDK (released March 2017) 
and Psychtoolbox-3 together for an end-to-end, minimal script
that connects to your tobii, conducts calibration, plays a short set of trials
with video, and exits, saving all the gaze data from each trial in its own file. 
It's a direct modification of scripts by Estefania Dominguez and Brian Sullivan (https://visionresearchblog.wordpress.com/category/psychophysics-toolbox/).

The main script is:

Tobii_calibration_with_psychtoolbox(SubjectID, options).

Good luck! If you try this and have feedback, you can submit an issue report or contact me at mekline@mit.edu The hardest parts of getting this to your own setup are likely to be getting matlab to connect to the tobii, and getting PTB to play movies (especially on macs).

I recommend starting by running the PTB demo scripts, then running Tobii_calibration_with_psychtoolbox(SubjectID, 'use_eyetracker', 0)
to ensure you don't have weird PTB bugs in your way (this will just play SimpleExp and exit.)

For the moment, this includes one 'vanilla' calibration and one that was written
for kids, including music that plays contingent on collecting good data, and
a spinny calibrator shape by Fani Deligianni for kids. 

--Notes from the original demo package (It used the old Tobii SDK 3.0, which has now been significantly updated)

Version 1.1 (27-07-15)
-----------
Some of the code has been cleaned up and a brief experiment example
was added. After calibration & validation a sample experiment
trial loop is shown, tracking data is gathered for a few seconds and then
exits saving a .mat file. This should be enough to demonstrate how to
get eye tracking data from a short experimental trial. 

Note I'm using the internal buffer of the eye tracker so I use GetEyeData(FirstFrameOfTrial, LastFrameOfTrial).
The eye tracker holds about 30s of most recent data (I'm not sure it may be a bit more or less)

If you have trials that are longer you should query the eye tracker on each frame,
i.e. use GetEyeData(CurrentFrame, LastFrame). Each time a flip is done, it returns
the time the flip occured. You should use this screentime for polling data from the tracker.


Version 1.0
-----------
This demo shows how to calibrate Tobii remote eye trackers using Psychtoolbox.
It follows the same procedure as the Tobii SDK matlab sample but on a psychtoolbox window.
To start with the demo run the file: "Tobii_calibration_with_psychtoolbox.m".
If you are using an Apple operating system you may need to change the keyboard codes.

You must update the eyetrackerhost variable found in 
Tobii_calibration_with_psychtoolbox.m with the Tobii tracker id string,
found in Eye Tracker Browser, referred to as host name and a copy function is provided
to copy & paste. This information is also available via calls in the SDK (see manual for details).

For visual angle calculations to be correct you must edit SetCalibParams.m with
your monitor setup information

The software assumes that you have placed the Tobii Matlab SDK in matlab's path settings