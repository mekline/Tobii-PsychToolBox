function [quality, ErrorCode]      = TobiiInit( hostName, portName, win, res)
% From the talk2tobii example code, updated by Melissa Kline for
% current t2t code and our specific Tobii setup.  Not guaranteed to
% work anywhere else :p
%
% This is a matlab function that initialises Tobii Connection 
% Calibrate Eye Tracker and subscribe gaze data
%
% hostName is the IP address of the PC running the TET server (or of the 
% Tobii itself in our case, the server is internal on t60 and other models)
% win is the handle of the window that has been initialised with the
% psychtoolbox
% res is a vector with the width and the height of the win in pixels
%
% ErrorCode returns 1 if there is an error or 0 if no error
% has occured

global parameters

%try max_wait times
%each time wait for tim_interv secs before try again 
max_wait = 60; 
tim_interv = 1;

%calibration points in X,Y coordinates
pos = [0.2 0.2;...
    0.8 0.2;
    0.5 0.5;
    0.2 0.8;
    0.8 0.8];
numpoints = length(pos);

%this call is important because it loads the 'GetSecs' mex file!
%without this call the talk2tobii mex file will crash
GetSecs();

%find indexes for correspond keys
ESCAPE=KbName('Escape');
SPACE=KbName('Space');
EX=KbName('x');

try

	%%make the background white so that kid eyes will reflect
	%%well
	rect = Screen('Rect', win);
	Screen('FillRect', win, [255 255 255], rect);
    Screen('Flip', win );
	
	
    ifi = Screen('GetFlipInterval',win,100);

    %% try to connect to the eyeTracker
    talk2tobii('CONNECT',hostName, portName);

    %check status of TETAPI
    cond_res = check_status(2, max_wait, tim_interv,1);
    tmp = find(cond_res==0);
    if( ~isempty(tmp) )
        error('check_status has failed');
    end


    %% monitor/find eyes
    talk2tobii('START_TRACKING');
    %check status of TETAPI
    cond_res = check_status(7, max_wait, tim_interv,1);
    
    tmp = find(cond_res==0);
    if( ~isempty(tmp) )
        error('failed to connect to tobii');
    end

    flagNotBreak = 0;
    disp('Press Esc to start calibration');
    while ~flagNotBreak
        eyeTrack = talk2tobii('GET_SAMPLE');
        DrawEyes(eyeTrack(1), eyeTrack(2), eyeTrack(3), eyeTrack(4), eyeTrack(7), eyeTrack(8));

        if( IsKey(ESCAPE) )
            flagNotBreak = 1;
            if( flagNotBreak )
                break;
            end
        end
    end

    talk2tobii('STOP_TRACKING');

    %% start calibration
    %display stimulus in the four corners of the screen
    totTime = 4;        % swirl total display time during calibration
    calib_not_suc = 1;
    while calib_not_suc
    
        talk2tobii('START_CALIBRATION', pos, 1, 6, './calibrFileTest.txt');
        %NOte: 6 samples works; setting it to 12 seems to not-work for some
        %reason
        
		%Check we'll be able to add point!
        check_status(5,90,1,1);
        
        %Start the attractive music!
        Play_Sound('hothothot.wav', 0);

        for i=1:numpoints
            position = pos(i,:);
            
            %Prompted start
            flagNotBreak = 0;
            disp('Press Space to start next calibration point, Press x to play attention getter');
            while ~flagNotBreak
             	if( IsKey(SPACE) )
             		flagNotBreak = 1;
            		if( flagNotBreak )
             			break;
            		end
            	elseif( IsKey(EX)) %Baby's not looking, get their attention back!
            		disp('Press any key to continue');
            		PsychPortAudio('Close');%stop the sound 
            		PlayCenterMovie('babylaugh.mov', '', 1, 0) %start playing baby attention getter.  This stops whenever you get (any) keypress
            		Play_Sound('hothothot.wav',0) %Start the music back up, and then set the flag to escape this loop!
             		flagNotBreak = 1;
            		if( flagNotBreak )
             			break;
            		end
        		end
    		end
    		
        	%check_status(5,90,1,1);
        	%This command appears to break the script, so I killed it
        	            
            %SWIRL CALIB
            when0 = GetSecs()+ifi;
            talk2tobii('ADD_CALIBRATION_POINT');
            StimulusOnsetTime=twirl(win,totTime,ifi,when0,position,1);
            talk2tobii('DREW_POINT');
            
        end
        
        %check that calibration has finished before running analysis
        cond_res = check_status([2 4 5], 60, 1, [1 0 0]);
        

        %check quality of calibration
        quality = talk2tobii('CALIBRATION_ANALYSIS');
                
        %++code should be added here to display and check the quality of the
        %calibration
        disp('CALIBRATION QUALITY:')
        if (numel(quality)==1) %something went wrong
        	0
        else
        	quality
        end
        
		%Prompted continue
        toCont = 0;
        disp('Press Space to continue to experiment!');
        while ~toCont
        	if( IsKey(SPACE) )
        		toCont = 1;
        		if( toCont)
             		break;
            	end
            end
        end
        
        %Done calibrating!
        calib_not_suc = 0;
        
        
        %Uncomment this part if you want to have the option to rerun the calibration, in my experience you just have to close out
        %and try again - which is tough with kids.
        
        %choose if you want to redo the calibration
        %disp('Press space to resume calibration or q to exit calibration and continue tracking');
        %tt= input('press "C" and "ENTER" to resume calibration or any other key to continue\n','s');
        %if( strcmpi(tt,'C') )
        %    calib_not_suc = 1;
        %else
        %    calib_not_suc = 0;
        %end

    end
    disp('EndOfCalibration');
    
        
    Screen('TextSize', win,50);
    Screen('DrawText', win, '+',res(1)/2,res(2)/2,[255 0 0]);
    Screen('Flip', win );
    
    
    talk2tobii('START_AUTO_SYNC');
    talk2tobii('RECORD');    
    talk2tobii('START_TRACKING');

    %check status of TETAPI
    cond_res = check_status(7, max_wait, tim_interv,1);
    tmp = find(cond_res==0);
    if( ~isempty(tmp) )
        error('check_status has failed');
    end
    
    ErrorCode = 0;
    
catch
    ErrorCode = 1;
    rethrow(lasterror);
    talk2tobii('STOP_TRACKING');
    talk2tobii('DISCONNECT');
end

return;



function ctrl=IsKey(key)
    global KEYBOARD;
    [keyIsDown,secs,keyCode]=PsychHID('KbCheck', KEYBOARD);
    if ~isnumeric(key)
        kc = KbName(key);
    else
        kc = key;
    end;
    ctrl=keyCode(kc);
return
