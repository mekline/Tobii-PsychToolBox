function [calibPlotData, calibError]= CalibrateKid(Calib,morder,iter,donts)
global EXPWIN EYETRACKER

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


%Clear out any previous jaunty music that's going
PsychPortAudio('Close');
%Turn jaunty music back on
[y, freq] = audioread('hothothot.wav');
wavedata = y';
nrchannels = size(wavedata,1);
pahandle = PsychPortAudio('Open', [], [], 0, freq, nrchannels); % Open & buffer the default audio device
PsychPortAudio('FillBuffer', pahandle, wavedata);
PsychPortAudio('Start', pahandle, 1, 0, 1);

%Put the eyetracker in the right mode
try
    calibObj = ScreenBasedCalibration(EYETRACKER);
    calibObj.enter_calibration_mode();
catch
end

validmat = ones(1,Calib.points.n);
%generate validity matrix
if ~isempty(donts)
    validmat = zeros(1,Calib.points.n);
    for i = 1:length(donts)
        validmat(morder==donts(i))=1;
    end
end

pause(0.1);
tic;
for  i =1:Calib.points.n;
    if (validmat(i)==0)
        continue;
    end
    
    %Do a cool twirl!
    
    ifi = Screen('GetFlipInterval', EXPWIN);
    Screen('FillRect',EXPWIN,Calib.bkcolor*255);
    when0 = Screen(EXPWIN, 'Flip'); %Returns a time so that twirl can animate nicely
    twirl(EXPWIN,2,ifi,when0,[Calib.points.x(morder(i)), Calib.points.y(morder(i))])

    calibObj.collect_data([Calib.points.x(morder(i)),Calib.points.y(morder(i))]);
    ['plotted a point at ' num2str([Calib.points.x(morder(i)),Calib.points.y(morder(i))])]
    pause(0.2);
        
end

try
    calibresult = calibObj.compute_and_apply();
    fprintf('Calibration status: %s\n', char(calibresult.Status));
    calibError = strcmp(calibresult.Status, 'Failure');
    
    calibPlotData = calibresult.CalibrationPoints;
    
catch me
    disp('Compute Calib failed, you must recalibrate');
    calibPlotData=[];
    calibError=1;
end

calibObj.leave_calibration_mode;
PsychPortAudio('Close');

end



