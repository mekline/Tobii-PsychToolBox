function SaveCalibData(CalibData)
% This function takes the calibration data that Tobii SDK produces
% and parses it as a long-form csv (ala tidyverse)

global DATAFOLDER SUBJECT

assert(length(CalibData) > 0, 'Calibration data is empty');
assert(isa(CalibData(1),'CalibrationPoint'), 'Not calibration data, is this gaze data instead?')
if ~ischar(SUBJECT)
    subname = num2str(SUBJECT);
else
    subname = SUBJECT;
end

calibCell = {'subjectID', 'calib_point_X', 'calib_point_Y', 'L_sample_valid','L_sample_X','L_sample_Y','R_sample_valid','R_sample_X','R_sample_Y'}; %Can't preallocate rows because each point may have a different n of samples


for i=1:length(CalibData)
    thisPoint = CalibData(i);
    nSamples = length(thisPoint.LeftEye);
    
    %Make a full row for each sample
    for j=1:nSamples
        calibCell(end+1,:) = {subname,...
            thisPoint.PositionOnDisplayArea(1),...
            thisPoint.PositionOnDisplayArea(2),...
            thisPoint.LeftEye(j).Validity,...
            thisPoint.LeftEye(j).PositionOnDisplayArea(1),...
            thisPoint.LeftEye(j).PositionOnDisplayArea(2),...
            thisPoint.RightEye(j).Validity,...
            thisPoint.RightEye(j).PositionOnDisplayArea(1),...
            thisPoint.RightEye(j).PositionOnDisplayArea(2)};
    end
    
end

calibTable = cell2table(calibCell(2:end,:));
calibTable.Properties.VariableNames = calibCell(1,:);
writetable(calibTable,[DATAFOLDER, '/calib_' subname '.csv']);

end
