function Calib = SetCalibParams(varargin)

global EXPWIN

p = inputParser;
p.addParamValue('x', [0.1 0.9 0.5 0.9 0.1], @ismatrix); % X coordinates in [0,1] coordinate system
p.addParamValue('y', [0.1 0.1 0.5 0.9 0.9], @ismatrix); % Y coordinates in [0,1] coordinate system
p.parse(varargin{:});
inputs = p.Results;

assert(length(inputs.x) == length(inputs.y), 'make sure x and y coordinates for calibration points match!');

screens = Screen('Screens'); % On OSX, set Preferences>Mission Control> 
    %check 'Displays have separate Spaces' if PTB thinks there is only 
    %one big screen instead of the eyetracker. 
    %Also make sure to attach tobii to computer BEFORE starting comp
    
%Select the screen where the stimulus is going to be presented
Calib.screenNumber=max(screens);

[EXPWIN, winRect] = Screen('OpenWindow', Calib.screenNumber);

Calib.screen.x = winRect(1);
Calib.screen.y = winRect(2);
Calib.screen.width = winRect(3);
Calib.screen.height = winRect(4);

%MK didn't implement this part, you need it if you want info on visual
%angle
% Calib.screen.sz=[ 51.9 32.5];  % [Horizontal, Vertical] Dimensions of screen (cm)
% Calib.screen.vdist= 60; % Observer's viewing distance to screen (cm)
% disp(['Using Viewing Distance of: ' num2str(Calib.screen.vdist) ...
%     'cm, with monitor width of ' num2str(Calib.screen.sz(1)) ...
%     'cm and height of ' num2str(Calib.screen.sz(2)) 'cm'])
% degperpix=2*((atan(Calib.screen.sz ./ (2*Calib.screen.vdist))).*(180/pi))./[Calib.screen.width Calib.screen.height];
% pixperdeg=1./degperpix;
% Calib.screen.degperpix = mean(degperpix);
% Calib.screen.pixperdeg = mean(pixperdeg);

Calib.points.x = inputs.x;  
Calib.points.y = inputs.y;  
Calib.points.n = size(Calib.points.x, 2); % Number of calibration points
Calib.bkcolor = [0.65 0.65 0.65]*255; % background color used in calibration process
Calib.fgcolor = [0 0 1]; % (Foreground) color used in calibration process
Calib.fgcolor2 = [1 0 0]; % Color used in calibratino process when a second foreground color is used (Calibration dot)
Calib.BigMark = 35; % the big marker
Calib.TrackStat = 25; %
Calib.SmallMark = 7; % the small marker
Calib.delta = 200; % Moving speed from point a to point b
Calib.resize = 1; % To show a smaller window
Calib.NewLocation = get(gcf,'position');


close all;
return



