%**************************
% Preliminaries
%**************************

global EXPERIMENT
global SUBJECT
global FOLDERNAME
global EYETRACKER %will be the Tobii eyetracker object
global EXPFOLDER 
global EXPWIN %Psychtoolbox window
global KEYBOARD 
global KEYID %Put keycodes in here
global CENTER %Center of psychtoolbox window 
global WHITE 
global BLACK 


addpath(genpath('/Applications/TobiiProSDK'));
EXPFOLDER = fileparts(which('Tobii_calibration_with_psychtoolbox.m')); %add this folder to the path too.
addpath(genpath(EXPFOLDER));

%Make PTB less verbose!
Screen('Preference', 'Verbosity', 0);
Screen('Preference', 'SkipSyncTests',1);
Screen('Preference', 'VisualDebugLevel',0);
PsychPortAudio('Verbosity',0);

%Open settings for screen & tracker
Calib=SetCalibParams;

%Window variables
CENTER = [round((Calib.screen.width - Calib.screen.x)/2) ...
    round((Calib.screen.height -Calib.screen.y)/2)];
BLACK = BlackIndex(EXPWIN); 
WHITE = WhiteIndex(EXPWIN);

KbName('UnifyKeyNames');
KEYBOARD=max(GetKeyboardIndices);
KEYID.SPACE=KbName('SPACE');
KEYID.Y = KbName('y');
KEYID.N = KbName('n');



%****************************
% Connect to eye tracker
%****************************

eyetrackerhost = 'TT060-301-30700930.local.';
Tobii = EyeTrackingOperations();
EYETRACKER = Tobii.get_eyetracker('tet-tcp://169.254.5.184'); %use find_eyetrackers to find your eyetracker if IP unknown

%Get and print the Frame rate of the current ET
fprintf('Frame rate: %d Hz.\n', EYETRACKER.get_gaze_output_frequency());

%*********************
% Track status of eyes (position participant before calibrating)
%*********************

TrackEyeStatus(Calib);

%*********************
% Calibration
%*********************

disp('Starting Calibration workflow');
HandleCalibWorkflow(Calib);
disp('Calibration workflow finished');
Screen('FillRect',EXPWIN,BLACK);
Screen(EXPWIN,'Flip');
 
%*********************
% Calibration finished, go on to your experiment 
%********************

disp('Starting simple Experiment')
%---run simple example of experiment loop
SimpleExp

%---Clean up and exit nicely
Screen('Close',EXPWIN);
clear all;
