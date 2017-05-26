function TrackStatus(Calib)
%TrackStatus script. Will show one dot per eye when the user positions himself in front of the eye tracker.
%Use spacebar (or any other) key press to continue.
%   Input:
%         Calib: The calib config structure (see SetCalibParams)

%global CENTER
global parameters KEYBOARD SPACEKEY EXPWIN BLACK

Screen('FillRect',EXPWIN,Calib.bkcolor);

if Calib.resize
    figloc(1) =  round(Calib.screen.x + Calib.screen.width/4);
    figloc(2) =  round(Calib.screen.y + Calib.screen.height/4);
    figloc(3) =  round(Calib.screen.width - Calib.screen.width/4);
    figloc(4) =  round(Calib.screen.height - Calib.screen.height/4);
    
    figlocWidth = figloc(3) - figloc (1);
    figlocHeight = figloc(4) - figloc (2);
    
else
    figloc(1) =  Calib.screen.x;
    figloc(2) =  Calib.screen.y;
    figloc(3) =  Calib.screen.width;
    figloc(4) =  Calib.screen.height;
end
Screen('FillRect',EXPWIN,[0 0 100], figloc);

updateFrequencyInHz = 60;

pause(0.5)
gaze_data = parameters.eyetracker.get_gaze_data; %dummy call to make sure we began getting data before the loop!

avgLValidity = zeros(1,60); %Track validity over the last few samples 
avgRValidity = zeros(1,60);

lpoints = [0 0];
while 1
    
    pause(4/updateFrequencyInHz); %If you want to do live projection, make sure wait long enough to get a point!    
    gaze_data = parameters.eyetracker.get_gaze_data; %dummy call to make sure we began getting ddata
    
    %Update average validity of eyes
    LValid = strcmp(gaze_data(end).LeftEye.GazePoint.Validity,'Valid');
    RValid = strcmp(gaze_data(end).RightEye.GazePoint.Validity,'Valid');
    
    avgLValidity = [avgLValidity(2:60) LValid];
    avgRValidity = [avgRValidity(2:60) RValid]; 
    
    if (~LValid || ~RValid)
        Screen('FillRect',EXPWIN,[0 0 100], figloc);
        DrawFormattedText(EXPWIN, 'Eyes not detected. Reposition Participant',...
            'Center', Calib.screen.height*.2,BLACK);
        Screen(EXPWIN, 'Flip');
        continue;
    else
        Screen('FillRect',EXPWIN,[0 0 100], figloc);
        EyeUpdateMsg = ['Left Eye ' num2str(gaze_data(end).LeftEye.GazePoint.InUserCoordinateSystem)];
        DrawFormattedText(EXPWIN, EyeUpdateMsg,...
            'Center', Calib.screen.height*.2,BLACK); 
    end
    
    %draw eyes
    %decide color for indication of validity
    % These color scheme & code is taken from the Talk2Tobii software
    % http://www.cbcd.bbk.ac.uk/people/affiliated/fani/talk2tobii
    % developed by Fani Deligianni
    
    Lsum = sum(avgLValidity);
    switch Lsum
        case num2cell(0:15),
            Left_eyeDotColor = [255 0 0];
        case num2cell(16:30),
            Left_eyeDotColor = [192 64 0];
        case num2cell(31:45),
            Left_eyeDotColor = [128 128 0];
        case num2cell(45:60),
            Left_eyeDotColor = [64 192 0];
        otherwise
            Left_eyeDotColor = [0 255 0];
    end
    
    Rsum = sum(avgRValidity);
    switch Rsum
        case num2cell(0:15),
            Right_eyeDotColor = [255 0 0];
        case num2cell(16:30),
            Right_eyeDotColor = [192 64 0];
        case num2cell(31:45),
            Right_eyeDotColor = [128 128 0];
        case num2cell(45:60),
            Right_eyeDotColor = [64 192 0];
        otherwise
            Right_eyeDotColor = [0 255 0];
    end

    
    DrawFormattedText(EXPWIN,...
        'Make sure eyes are visibile and stable green. Press space to start calibration',...
        'Center',Calib.screen.height*.8, BLACK);
    
    if LValid || RValid
        if LValid
            scaled_Lx = (150+gaze_data(end).LeftEye.GazePoint.InUserCoordinateSystem(1))/300; %Just play with these until they stay mostly in the blue field
            scaled_Ly = 1 - (500+gaze_data(end).LeftEye.GazePoint.InUserCoordinateSystem(2))/1000;
            sLeft(1) = figloc(1) + (figlocWidth * scaled_Lx) - 15;
            sLeft(2) = figloc(2) + (figlocHeight * scaled_Ly) - 15 ;
            sLeft(3) = figloc(1) + (figlocWidth * scaled_Lx) + 15;
            sLeft(4) = figloc(2) + (figlocHeight * scaled_Ly) + 15;
        
            sLeft = double(sLeft);
            Screen('FillOval', EXPWIN, Left_eyeDotColor, sLeft);
        end

        
        if RValid
            scaled_Rx = (100+gaze_data(end).RightEye.GazePoint.InUserCoordinateSystem(1))/200;
            scaled_Ry = 1 - (400+gaze_data(end).RightEye.GazePoint.InUserCoordinateSystem(2))/800;
            sRight(1) = figloc(1) + (figlocWidth * scaled_Rx) - 15;
            sRight(2) = figloc(2) + (figlocHeight * scaled_Ry) - 15 ;
            sRight(3) = figloc(1) + (figlocWidth * scaled_Rx) + 15;
            sRight(4) = figloc(2) + (figlocHeight * scaled_Ry) + 15;
        
            sRight = double(sRight);
            Screen('FillOval', EXPWIN, Right_eyeDotColor, sRight);
        end
        
        Screen('DrawingFinished',EXPWIN);
        Screen(EXPWIN, 'Flip');
     end
    
    [~,~,keyCode]=PsychHID('KbCheck', KEYBOARD);
    if keyCode(parameters.space)
        break;
    end
    
end

end

