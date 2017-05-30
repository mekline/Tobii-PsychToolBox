function HandleCalibWorkflow(Calib)
%HandleCalibWorkflow Main function for handling the calibration workflow.
%   Input:
%         Calib: The calib config structure (see SetCalibParams)
%   Output:
%         pts: The list of points used for calibration. These could be
%         further used for the analysis such as the variance, mean etc.

global KEYID

trackError=[];
isCalibrated=0;

  
while ~isCalibrated

    mOrder = randperm(Calib.points.n);

    % Put calibration points on the Tobii and compute calibration.
    [calibPlotData, calibError] = Calibrate(Calib,mOrder, 0, []); 

    if calibError
        disp('Calibration error, recenter participant')
        TrackEyeStatus(Calib);
        continue;
    end
    
    %plot a separate window in standard matlab figure
    PlotCalibrationResults(calibPlotData, Calib);
    
    disp('Accept this calibration [y], or recalibrate [n]?')

    %Take a response
    while 1
        [keyIsDown, ~, keyCode]= KbCheck;
        if keyIsDown
            if keyCode(KEYID.Y)
                isCalibrated = 1;
                disp('Calibration accepted')
                break;
            elseif keyCode(KEYID.N)
                disp('Recalibrating...')
                break;
            end
            while KeyIsDown; end
        end         
    end
    
    if isCalibrated
        save('calib_sample.mat', 'calibPlotData'); %%%%XXXXRETURN TO ADD PARTICIPANT INFO HERE!
    end
end








