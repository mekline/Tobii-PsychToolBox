global TOBII EYETRACKER EXPWIN BLACK DATAFOLDER SUBJECT;

if ~ischar(SUBJECT)
    subname = num2str(SUBJECT);
else
    subname = SUBJECT;
end

numberTrials=3;

%Header for recording timestamps!
timeCell = {'subjectID', 'system_time_stamp', 'point_description'};
timeCell(end+1,:) = {SUBJECT,...
    TOBII.get_system_time_stamp,...
    'Experiment Start'};

for trial=1:numberTrials
  
    GazeData = EYETRACKER.get_gaze_data; %dummy call to make sure we clear & collect new data
    timeCell(end+1,:) = {SUBJECT,...
        TOBII.get_system_time_stamp,...
        ['Start_Trial ' num2str(trial)]};
    
    disp(['Start Trial: ' num2str(trial)])
    
    Screen('FillRect',EXPWIN,BLACK);
    
    %this would be where your experimental stimulus, task, main loop etc would go
    %we'll just wait and get a little eye tracking data.
    
    screentime=[];
    trial_exit=0;
    
    while(~trial_exit)
        
        DrawFormattedText(EXPWIN,'Read this text. The tracking data will be saved to a .mat file after 5s','Center',...
            Calib.screen.height/3, [255 255 255]);
        screentime(end+1)=Screen(EXPWIN,'Flip');
        
        if( (screentime(end)-screentime(1)) > 5 )
            trial_exit=1;
        end
    end
    
    
    GazeData = EYETRACKER.get_gaze_data;
    timeCell(end+1,:) = {SUBJECT,...
        TOBII.get_system_time_stamp,...
        ['End_Trial ' num2str(trial)]};
    
    
    %Save trial data as MAT, and add to the big CSV
    description = ['All_of_trial_' num2str(trial)]; %description of this timeperiod
    save([DATAFOLDER, '/gaze_' subname '_' description '.mat'], 'GazeData')
    SaveGazeData(GazeData, description);
    

end

%Experiment finalities...
timeTable = cell2table(timeCell(2:end,:));
timeTable.Properties.VariableNames = timeCell(1,:);
%And save the file!
filename = [DATAFOLDER, '/timestamps_' subname '.csv'];
writetable(timeTable, filename);

Screen('FillRect',EXPWIN,BLACK);
DrawFormattedText(EXPWIN,'Tracking data captured...Exiting','Center',...
    Calib.screen.height/3, [255 255 255]);
Screen(EXPWIN,'Flip');
WaitSecs(1.5)

