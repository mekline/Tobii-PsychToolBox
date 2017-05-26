%**************************
% Preliminaries
%**************************


global parameters; 

global EXPWIN %Psychtoolbox window
global KEYBOARD 
global SPACEKEY 
global CENTER %Center of psychtoolbox window 
global WHITE 
global BLACK 

addpath(genpath('/Applications/TobiiProSDK'));
parameters.folder = fileparts(which('Tobii_calibration_with_psychtoolbox.m')); %add this folder to the path too.
addpath(genpath(parameters.folder));



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


KEYBOARD=max(GetKeyboardIndices);
SPACEKEY = 32;%Windows system key code
KbName('UnifyKeyNames');
parameters.space=KbName('SPACE');
parameters.esc=KbName('ESCAPE');
parameters.z_press=KbName('z');
parameters.c_press=KbName('c');
parameters.n_press=KbName('n');
parameters.y_press=KbName('y');


%****************************
% Connect to eye tracker
%****************************
eyetrackerhost = 'TT060-301-30700930.local.';
Tobii = EyeTrackingOperations();
parameters.eyetracker = Tobii.get_eyetracker('tet-tcp://169.254.5.184'); %use find_eyetrackers to find your eyetracker if IP unknown

%Get and print the Frame rate of the current ET
fprintf('Frame rate: %d Hz.\n', parameters.eyetracker.get_gaze_output_frequency());
%*********************
% TrackStatus
%*********************
TrackStatus(Calib);

%*********************
% Calibration XXXXXXXXSTART HERE!!!!
%*********************
disp('Starting Calibration workflow');
[pts, CalibError] = HandleCalibWorkflow(Calib);
disp('Calibration workflow stopped');
Screen('FillRect',EXPWIN,BLACK);
Screen(EXPWIN,'Flip');
 
%*********************
% Calibration finished
%********************
disp('Displaying point by point error:')
disp('[Mean StandardDev]')
CalibError


disp('Starting Validation')
mOrder = randperm(Calib.points.n);
tetio_startTracking;
ValidationError=TestEyeTrackerError(Calib,mOrder);

disp('End of Validation Validation, displaying Error:')
disp('Displaying point by point error, Left Eye:')
disp('[Median StandardDev]')
ValidationError.Left

disp('Displaying point by point error, Left Eye:')
disp('[Median StandardDev]')
ValidationError.Right
disp('Click button to exit & start simple experiment example')


disp('Starting simple Experiment')
%---run simple example of experiment loop
SimpleExp


tetio_cleanUp()
Screen('Close',EXPWIN)
