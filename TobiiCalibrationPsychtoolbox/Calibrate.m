function [calibPlotData, calibError]= Calibrate(Calib,morder,iter,donts)
global EXPWIN
global parameters
%CALIBRATE calibrate the eye tracker
%   This function is used to set and view the calibration results for the tobii eye tracker.
%
%   Input:
%         Calib: The calib structure (see CalibParams)
%         morder: Order of the calibration point
%         iter: 0/1 (0 = A new calibation call, ensure that calibration is not already started)
%                   (1 = just fixing a few Calibration points)
%         donts: Points (with one in the index) that are to be
%         recalibrated, 0 else where
%   Output:
%         calibPlotData: The calibration plot data, specifying the input and output calibration data

calibError = 0;
calibPlotData = 0;
assert(Calib.points.n >= 2 && length(Calib.points.x)==Calib.points.n, ...
    'Err: Invalid Calibration params, Verify...');


Screen('FillRect',EXPWIN,Calib.bkcolor*255);
Screen(EXPWIN, 'Flip');
try
    calibObj = ScreenBasedCalibration(parameters.eyetracker);
    calibObj.enter_calibration_mode();
end

validmat = ones(1,Calib.points.n);
%generate validity matrix
if ~isempty(donts)
    validmat = zeros(1,Calib.points.n);
    for i = 1:length(donts)
        validmat(morder==donts(i))=1;
    end
end

pause(1);
step= 10; %shrinking steps (increase for powerful pcs)
tic;
for  i =1:Calib.points.n;
    %show the big marker
    if (validmat(i)==0)
        continue;
    end
    
    mb = Calib.BigMark;
    ms = Calib.SmallMark;
    %now shrink
    for j = 1:step
        
        bigDotLoc(1) = round(Calib.screen.width*Calib.points.x(morder(i))-mb/2);
        bigDotLoc(2) = round(Calib.screen.height*Calib.points.y(morder(i))-mb/2);
        bigDotLoc(3) = round(Calib.screen.width*Calib.points.x(morder(i))+mb/2);
        bigDotLoc(4) = round(Calib.screen.height*Calib.points.y(morder(i))+mb/2);
        smallDotLoc(1) = round(Calib.screen.width*Calib.points.x(morder(i))-ms/2);
        smallDotLoc(2) = round(Calib.screen.height*Calib.points.y(morder(i))-ms/2);
        smallDotLoc(3) = round(Calib.screen.width*Calib.points.x(morder(i))+ms/2);
        smallDotLoc(4) = round(Calib.screen.height*Calib.points.y(morder(i))+ms/2);
        Screen('FillOval',EXPWIN,Calib.fgcolor*255, bigDotLoc);
        Screen('FillOval',EXPWIN,Calib.fgcolor2*255, smallDotLoc);
        
        Screen(EXPWIN, 'Flip');
        
        if (j==1)
            pause(0.5);
        end
        if (j==step)
%             if ~isempty(donts)
%                 calibObj.discard_data([Calib.points.x(morder(i)), Calib.points.y(morder(i))]);
%                 disp(['deleted point ' num2str(morder(i)) ' and now adding it, where i = ' num2str(i)])
%             end
            calibObj.collect_data([Calib.points.x(morder(i)),Calib.points.y(morder(i))]);
            %['plotted a point at ' num2str([Calib.points.x(morder(i)),Calib.points.y(morder(i))])]
            pause(0.2);
        end
        mb = mb-ceil((Calib.BigMark - Calib.SmallMark)/step);
        pause(0.1)
        
    end
end

Screen('FillRect',EXPWIN,Calib.bkcolor*255);
Screen(EXPWIN, 'Flip');

try
    calibresult = calibObj.compute_and_apply();
    fprintf('Calibration status: %s\n', char(calibresult.Status));
    calibError = strcmp(calibresult.Status, 'Failure');
    
    calibPlotData = calibresult.CalibrationPoints;
    
catch me
    disp('Compute Calib failed, you must recalibrate')
    calibPlotData=[];
    calibError=1;
end

calibObj.leave_calibration_mode;

end



