function [] = Calibrate_Tobii()
%Just a wrapper to get the calibration routine going.  Cribbed from
%Rochester babylab code.

global parameters
%Note this global struct holds ALL of the various bits of info we need 
%throughout the experiment (e.g. size of the screen, 'white' color value, etc.) 
%This line needs to be at the top of every file in order for functions to 
%be able to see these values.

%OpenScreen;
%try
    OpenScreen;
%catch
%    error('Screen window not initialized!')
%end

%Run the Calibration!
scr = parameters.scr;

if parameters.ConnTobii
    [parameters.quality, Error] = TobiiInit(parameters.hostName, parameters.portName, scr.winPtr, scr.res);
    if Error
        error('Initialize Tobii fail!');
    else
        parameters.EYETRACKER = 1;
        dlmwrite(parameters.qualityFileName, parameters.quality, 'precision', 6);
    end
end

%Make sure the calibrator sounds turn off before we go on!
PsychPortAudio('Close');






end

