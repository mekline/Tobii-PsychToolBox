function [] = Jump_Trial()
%Plays a nice intro trial with a known intransitive verb.
%Ideally this should look pretty transparently like the experiment logic, 
%with PTB and t2t calls hidden away.

    global parameters
    
    %Set movies to play
    if parameters.jumpLeft
        leftMovie = 'Movies/Jump.mov';
        rightMovie = 'Movies/Wave.mov';
    else
        leftMovie = 'Movies/Wave.mov';
        rightMovie = 'Movies/Jump.mov';
    end
    
    %Clear screen
    Show_Blank;
    
    LogTobiiEvent('TrialStart', -1);
    
    %Play the prompt, e.g. "She's gonna jump!
    LogTobiiEvent('Voiceover.1.Start', -1);
    Play_Sound('Voiceovers/Jump_Prep1.wav',1);
    LogTobiiEvent('Voiceover.1.End', -1);
    
    %Show Verb round 1 - Both movies at the same time, with verb voiceover
    %for the condition, e.g. "Look, she's jumping, she's jumping, look she's jumping!"
    %MOVIE 8s long
    LogTobiiEvent('Comparison.1.Start', -1);
    Play_Sound('Voiceovers/Jump_Compare1.wav',0); %The 0 means it goes on to play vid at the same time.
    PlaySideMovies(leftMovie, rightMovie, 0, 0, 0);
    LogTobiiEvent('Comparison.1.End', -1);
    
    %Play the second prompt, e.g. "She jumped!  Find jumping!"
    Show_Blank;
    LogTobiiEvent('Voiceover.2.Start', -1);
    Play_Sound('Voiceovers/Jump_Prep2.wav',1);
    LogTobiiEvent('Voiceover.2.End', -1);
    
    %Show Verb round 2 - Both movies at the same time, with verb voiceover
    %for the condition, e.g. "Look, she's jumping, find jumping, find jumping"
    LogTobiiEvent('Comparison.2.Start', -1);
    Play_Sound('Voiceovers/Jump_Compare2.wav',0);
    PlaySideMovies(leftMovie, rightMovie, 0, 0, 0);
    LogTobiiEvent('Comparison.2.End', -1);
    
    Show_Blank;

end