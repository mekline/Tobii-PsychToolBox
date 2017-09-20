function HandleCalibWorkflow(Calib)
%HandleCalibWorkflow Main function for handling the calibration workflow.
%   Input:
%         Calib: The calib config structure (see SetCalibParams)
%   Output:
%         pts: The list of points used for calibration. These could be
%         further used for the analysis such as the variance, mean etc.

global KEYID SUBJECT DATAFOLDER EXPERIMENT CALIBVERSION MAXCALIB

isCalibrated=0;
isGaveUp = 0;
triedCalib = 0;
  
while (~isCalibrated && (triedCalib < MAXCALIB))

    mOrder = randperm(Calib.points.n);

    % Put calibration points on the Tobii and compute calibration.
    if strcmp(lower(CALIBVERSION),'kid')
        [calibPlotData, calibError] = CalibrateKid(Calib,mOrder, 0, []); 
    else
        [calibPlotData, calibError] = Calibrate(Calib,mOrder, 0, []);
    end
    triedCalib = triedCalib + 1;

    if calibError
        disp('Calibration error, recenter participant before trying again! Track eyes [z], calibrate [n], or give up [y]?');
        
        %Take a response
        while 1
            [keyIsDown, ~, keyCode]= KbCheck;
            if keyIsDown
                if keyCode(KEYID.Y)
                    isCalibrated = 1;
                    isGaveUp = 1;
                    disp('we didnt calibrate, but move on');
                    break;
                elseif keyCode(KEYID.N)
                    disp('Recalibrating...');
                    break;
                elseif keyCode(KEYID.Z)
                    disp('Recenter participant');
                    TrackEyesOnscreen(Calib);
                    break;
                end
                while KeyIsDown; end
            end         
        end
    else %end caliberror

        %plot a separate window in standard matlab figure
        myfig = PlotCalibrationResults(calibPlotData, Calib);
        disp('You need to close the results window before moving on.');
        disp('Accept this calibration [y], or recalibrate [n]?');

        %Take a response
        while 1
            [keyIsDown, ~, keyCode]= KbCheck;
            if keyIsDown
                if keyCode(KEYID.Y)
                    isCalibrated = 1;
                    disp('Calibration accepted');
                    break;
                elseif keyCode(KEYID.N)
                    disp('Recalibrating...');
                    break;
                end
                while KeyIsDown; end
            end         
        end
    end
end

%Message if we never got a calibration!
if isGaveUp || ~isCalibrated
    disp('Calibration failed! Continuing to the experiment, but this data should probably be manually recalibrated');
else %Save the data before moving on! graph, mat and csv

    figname = [DATAFOLDER '/calib_' EXPERIMENT '_' SUBJECT];     
    get(myfig, 'Color'); %make sure figure handle is working;
    %savefig('test'); %I sure wish Matlab would let me save a figure right now. 

    save([figname '.mat'], 'calibPlotData'); %save as .mat
    SaveCalibData(calibPlotData); %save as wellformed csv
end
end








