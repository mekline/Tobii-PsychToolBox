global EYETRACKER EXPWIN BLACK;

numberTrials=3;

timestamps(1).timepoint = EYETRACKER.get_time_sync_data();
timestamps(1).name = 'Experiment Start';

for trial=1:numberTrials
  
    GazeData = EYETRACKER.get_gaze_data; %dummy call to make sure we began getting data before the loop!
    timestamps(end+1).timepoint = EYETRACKER.get_time_sync_data();
    timestamps(end).name = ['Start Trial ' num2str(trial)];
    
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
    timestamps(end+1).timepoint = EYETRACKER.get_time_sync_data();
    timestamps(end).name = ['End Trial ' num2str(trial)];
end

save('eyegaze_sample.mat', 'GazeData')
save('timestamps.mat', 'timestamps')
Screen('FillRect',EXPWIN,BLACK);
DrawFormattedText(EXPWIN,'Tracking data captured...Exiting','Center',...
    Calib.screen.height/3, [255 255 255]);
Screen(EXPWIN,'Flip');
WaitSecs(1.5)
