function [] = InitandCalibrate_Tobii()
%Just a wrapper to get the calibration routine going.  Cribbed from
%Rochester babylab code.

global parameters

%Run the Calibration!

if parameters.ConnTobii
    
    [parameters.quality, Error] = TobiiInit(parameters.hostName, parameters.portName, parameters.scr.winPtr, parameters.scr.res);
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

