function OpenScreen()
%OpenScreen opens and prepares the screen to be used for the experiment
%(Another PTB wrapper)

global parameters

scr = parameters.scr;

try
    % This script calls Psychtoolbox commands available only in OpenGL-based
    % versions of the Psychtoolbox. (So far, the OS X Psychtoolbox is the
    % only OpenGL-based Psychtoolbox.)  The Psychtoolbox command AssertOpenGL will issue
    % an error message if someone tries to execute this script on a computer without
    % an OpenGL Psychtoolbox
    AssertOpenGL;
    
    % Open double-buffered onscreen window
    if ~isempty(scr.winPtr)
        Screen('CloseAll');
        scr.winPrt = [];
    end

    [scr.winPtr, scr.winRect] = Screen('OpenWindow', scr.displayScreen, scr.bgcolor,scr.rect,[], scr.numberOfBuffers);

    
    scr.fps=Screen('FrameRate',scr.winPtr);      % frames per second

    scr.ifi=Screen('GetFlipInterval', scr.winPtr);
    if scr.fps==0
       scr.fps=1/scr.ifi;
    end;
    
    parameters.scr = scr;
    
    if parameters.debug
        Priority(0);
    else
        HideCursor;	% Hide the mouse cursor
        Priority(MaxPriority(scr.winPtr));
    end
catch
    Screen('CloseAll');
    ShowCursor;
    Priority(0);
    psychrethrow(psychlasterror);
end

end

