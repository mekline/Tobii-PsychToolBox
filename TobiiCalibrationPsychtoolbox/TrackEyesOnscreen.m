function TrackEyesOnscreen(Calib)
% Will show one dot per eye when the user positions himself in front of 
% the eye tracker. This version also plots some fun spinny shapes
% and boing sounds to keep kids oriented!
% Use spacebar (or any other) key press to continue.
%
%   Input:
%         Calib: The calib config structure (see SetCalibParams)

global EYETRACKER KEYBOARD KEYID EXPWIN BLACK WHITE CALIBVERSION

%Make a background to show eye movement on
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

if strcmpi(CALIBVERSION,'kid')
    attentionshape = imread('Media/shapes.001.jpeg');
    Screen('FillRect',EXPWIN,WHITE);
    Screen('PutImage', EXPWIN , attentionshape, figloc); 
else
    Screen('FillRect',EXPWIN,[0 0 100], figloc);
end

updateFrequencyInHz = 60;
pause(0.5);

% Get ready to plot the eyes dynamically onscreen
try
    GazeData = EYETRACKER.get_gaze_data; %dummy call bc the first call to the buffer often is empty
catch
end

%We'll track validity over the last few seconds of sample and condition the
%color of the eyes on that.
LValidity = zeros(1,60); 
RValidity = zeros(1,60);

timelooper = 0; %A small looper to play cute random noises for the kid
while 1 %(Runs until you hit the spacebar)
    %This loop is a little complex: at every timestep, it looks for eye
    %data, sets the volume of the music, and plots the background and eyes
    %onscreen. 
    
    pause(4/updateFrequencyInHz); %If you want to do live projection, make sure wait long enough to get a point!    
    GazeData = EYETRACKER.get_gaze_data; %dummy call to make sure we began getting ddata
    
    if strcmpi(CALIBVERSION, 'kid') %Update some cool noises and pix
        if mod(timelooper, 60) == 0
            Play_Sound('Media/bells_short.wav',0);
            attentionshape = imread('Media/shapes.001.jpeg');
        elseif mod(timelooper, 60) == 15
            Play_Sound('Media/bells_short.wav',0);
            attentionshape = imread('Media/shapes.002.jpeg');
        elseif mod(timelooper, 60) == 30
            Play_Sound('Media/boing.wav',0);
            attentionshape = imread('Media/shapes.003.jpeg');
        elseif mod(timelooper, 60) == 45
            Play_Sound('Media/boing.wav',0);
            attentionshape = imread('Media/shapes.004.jpeg');
        end
        timelooper = timelooper + 1;
    end
    %Update average validity of eyes
    LValid = strcmp(GazeData(end).LeftEye.GazePoint.Validity,'Valid');
    RValid = strcmp(GazeData(end).RightEye.GazePoint.Validity,'Valid');
    
    LValidity = [LValidity(2:60) LValid];
    RValidity = [RValidity(2:60) RValid]; 
    
    %If we didn't find either eye, complain to the user     
    if (~LValid && ~RValid)
        
        if strcmpi(CALIBVERSION, 'kid')
            Screen('FillRect',EXPWIN,WHITE);
            Screen('PutImage', EXPWIN , attentionshape, figloc); 
        else
            Screen('FillRect',EXPWIN,[0 0 100], figloc);
        end
        DrawFormattedText(EXPWIN, 'Eyes not detected. Reposition Participant',...
            'Center', Calib.screen.height*.2,BLACK);
        Screen(EXPWIN, 'Flip');
        
        [~,~,keyCode]=PsychHID('KbCheck', KEYBOARD); %No eyes, but still give the option to go on!
        if keyCode(KEYID.SPACE)
            disp('You dont have eyes, calibrating anyway');
            break;
        end
        continue; %loop back and wait for valid eye movements
    else
        if strcmpi(CALIBVERSION, 'kid')
            Screen('FillRect',EXPWIN,WHITE);
            Screen('PutImage', EXPWIN , attentionshape, figloc); 
        else
            Screen('FillRect',EXPWIN,[0 0 100], figloc);
        end       
    end
    
    %Then, if we found eyes, draw eyes
    
    Lav = mean(LValidity);
    Rav = mean(RValidity);
    Left_eyeDotColor = [100*(1-Lav) 100*Lav 0];   
    Right_eyeDotColor = [100*(1-Rav) 100*Rav 0];   
    
    
    disp('Make sure eyes are visibile and stable green. Press space to start calibration');
    
    %Draw the eyes on the screen!
    if LValid
        scaled_Lx = (150+GazeData(end).LeftEye.GazeOrigin.InUserCoordinateSystem(1))/300; %Just play with these until they stay mostly in the blue field, Tobii's user coordinate system is weird. 
        scaled_Ly = 1 - (500+GazeData(end).LeftEye.GazeOrigin.InUserCoordinateSystem(2))/1000;
        sLeft(1) = figloc(1) + (figlocWidth * scaled_Lx) - 15;
        sLeft(2) = figloc(2) + (figlocHeight * scaled_Ly) - 15 ;
        sLeft(3) = figloc(1) + (figlocWidth * scaled_Lx) + 15;
        sLeft(4) = figloc(2) + (figlocHeight * scaled_Ly) + 15;

        sLeft = double(sLeft);
        Screen('FillOval', EXPWIN, Left_eyeDotColor, sLeft);
    end


    if RValid
        scaled_Rx = (100+GazeData(end).RightEye.GazeOrigin.InUserCoordinateSystem(1))/200;
        scaled_Ry = 1 - (400+GazeData(end).RightEye.GazeOrigin.InUserCoordinateSystem(2))/800;
        sRight(1) = figloc(1) + (figlocWidth * scaled_Rx) - 15;
        sRight(2) = figloc(2) + (figlocHeight * scaled_Ry) - 15 ;
        sRight(3) = figloc(1) + (figlocWidth * scaled_Rx) + 15;
        sRight(4) = figloc(2) + (figlocHeight * scaled_Ry) + 15;

        sRight = double(sRight);
        Screen('FillOval', EXPWIN, Right_eyeDotColor, sRight);
    end

    Screen('DrawingFinished',EXPWIN);
    Screen(EXPWIN, 'Flip');

    
    [~,~,keyCode]=PsychHID('KbCheck', KEYBOARD);
    if keyCode(KEYID.SPACE)
        break;
    end
    
end

end

