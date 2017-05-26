
function TobiiExpScript()

%An example script that connects to the eyetracker, calibrates in a kid
%friendly way, displays some stuff with PTB and saves output, then saves
%all the eyetracking data.

%%Preliminaries
global parameters; 
addpath(genpath('/Applications/TobiiProSDK'));
parameters.folder = fileparts(which('TobiiExpScript.m')); %add this folder to the path too.
addpath(genpath(parameters.folder));

Tobii = EyeTrackingOperations();
eyetracker = Tobii.get_eyetracker('tet-tcp://169.254.5.184'); %use find_eyetrackers to find your eyetracker if IP unknown

%%Calibrate
calib = ScreenBasedCalibration(eyetracker);
calib.enter_calibration_mode();
points_to_collect = [[0.1,0.1];[0.1,0.9];[0.5,0.5];[0.9,0.1];[0.9,0.9]];

% When collecting data a point should be presented on the screen in the
% appropriate position.
for i=1:size(points_to_collect,1)
    collect_result = calib.collect_data(points_to_collect(i,:));
    fprintf('Point [%.2f,%.2f] Collect Result: %s\n',points_to_collect(i,:),char(collect_result));
end

calibration_result = calib.compute_and_apply();
fprintf('Calibration Status: %s\n',char(calibration_result.Status));

% After analisyng the calibration result one might want to re-calibrate
% some of the points
points_to_collect = [[0.1,0.1];[0.1,0.9];[0.5,0.5];[0.9,0.1];[0.9,0.9]];

% When collecting data a point should be presented on the screen in the
% appropriate position.

points_to_recalibrate = [[0.1,0.1];[0.1,0.9]];

for i=1:size(points_to_recalibrate,1)
    calib.discard_data(points_to_recalibrate(i,:));
    collect_result = calib.collect_data(points_to_recalibrate(i,:));
    fprintf('Point [%.2f,%.2f] Collect Result: %s\n',points_to_recalibrate(i,:),char(collect_result));
end

calibration_result = calib.compute_and_apply();
fprintf('Calibration Status: %s\n',char(calibration_result.Status));

if calibration_result.Status == CalibrationStatus.Success
        points = calibration_result.CalibrationPoints;
        
        number_points = size(points,2);
        
        for i=1:number_points
            plot(points(i).PositionOnDisplayArea(1),points(i).PositionOnDisplayArea(2),'ok','LineWidth',10);
            mapping_size = size(points(i).RightEye,2);
            set(gca, 'YDir', 'reverse');
            axis([-0.2 1.2 -0.2 1.2])
            hold on;
            for j=1:mapping_size
                if points(i).LeftEye(j).Validity == CalibrationEyeValidity.ValidAndUsed
                    plot(points(i).LeftEye(j).PositionOnDisplayArea(1), points(i).LeftEye(j).PositionOnDisplayArea(2),'-xr','LineWidth',3);
                end
                if points(i).RightEye(j).Validity == CalibrationEyeValidity.ValidAndUsed
                    plot(points(i).RightEye(j).PositionOnDisplayArea(1),points(i).RightEye(j).PositionOnDisplayArea(2),'xb','LineWidth',3);
                end
            end
            
        end
end

calib.leave_calibration_mode()

end