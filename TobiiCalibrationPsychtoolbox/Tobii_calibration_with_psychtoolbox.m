function Tobii_calibration_with_psychtoolbox(SubjectID)
%**************************
% Preliminaries
%**************************

global EXPERIMENT
global SUBJECT
global EXPFOLDER %This folder, path generated below
global DATAFOLDER %Where to save all data
global TOBII %Tobii mothership object
global EYETRACKER %will be the Tobii eyetracker object
global EXPWIN %Psychtoolbox window
global KEYBOARD %Psychtoolbox needs it
global KEYID %Put specific keycodes in here
global CENTER %Center of psychtoolbox window 
global WHITE 
global BLACK 

EXPERIMENT = 'TSAMPLE';
if ~ischar(SubjectID)
    SUBJECT = num2str(SubjectID);
else
    SUBJECT = SubjectID;
end

addpath(genpath('/Applications/TobiiProSDK'));
EXPFOLDER = fileparts(which('Tobii_calibration_with_psychtoolbox.m')); %add this folder to the path too.
addpath(genpath(EXPFOLDER));
DATAFOLDER = [EXPFOLDER '/Data'];

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

%Add all button presses you'll listen for here. 
KbName('UnifyKeyNames');
KEYBOARD=max(GetKeyboardIndices);
KEYID.SPACE=KbName('SPACE');
KEYID.Y = KbName('y');
KEYID.N = KbName('n');


%****************************
% Connect to eye tracker
%****************************

%eyetrackerhost = 'TT060-301-30700930.local.';
TOBII = EyeTrackingOperations();
EYETRACKER = TOBII.get_eyetracker('tet-tcp://169.254.5.184'); %use find_eyetrackers to find your eyetracker if IP unknown

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
