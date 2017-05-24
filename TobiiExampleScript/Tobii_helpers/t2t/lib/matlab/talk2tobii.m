function TALK2TOBII
% ===============================================================================
% This is a tobii MEX-file for interfacing the TETSERVER with Matlab.
% This program is distributed with the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
% OR FITNESS FOR A PARTICULAR PURPOSE.
% UNDER NO CIRCUMSTANCES SHALL THE AUTHORS BE LIABLE FOR ANY INCIDENTAL,
% SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES ARISING OUT OF OR RELATING TO
% THIS PROGRAM.
% 
% Written by Fani Deligianni, email: f.deligianni@bbk.ac.uk
% Centre of Brain and Cognitive Development, Birkbeck University, London, UK.
%    http://www.cbcd.bbk.ac.uk/
% Modified by Luca Filippin, email: luca.filippin@gmail.com
% Language, Cognition and  Development Laboratory, SISSA, Trieste, ITALY.
%    http://www.sissa.it/cns/
% ===============================================================================
% 11/07/2007 1.0.0 Base Version by Fani Deligianni
% 01/08/2010 1.1.0 Added: GET_GAZES_DATA, GET_EVENTS_DATA, START_AUTO_SYNC
%						  STOP_AUTO_SYNC, REMOVE_CALIBRATION_SAMPLES, <TIMESTAMP*>
%                  Changed: START_CALIBRATION, SAVE_DATA, GET_SAMPLE_EXT, 
%						  GET_SAMPLE, CLEAR_DATA, GET_STATUS, EVENT
% ===============================================================================
%
% This mex function is written in c++ and uses multi-threading to allow 
% building contingent eyetracking applications. It creates a 'tobii' thread
% that handles the communication between the underlyined application and the 
% TETserver. 
% The main matlab thread handles the display and any additional computation
% required. Eye tracking data and status can be acquired online so that the
% stimulus presentation may be updated accordingly.
% This function can be combined with the psychtoolbox that is able to deliver
% accurate stimulus presentation. 
%
% Contents:
% TALK2TOBII()
% TALK2TOBII('CONNECT',hostname);
% TALK2TOBII('DISCONNECT');
% TALK2TOBII('START_TRACKING');
% TALK2TOBII('STOP_TRACKING');
% [status,history] = TALK2TOBII('GET_STATUS');
% TALK2TOBII('CLEAR_HISTORY');
% gazeData=TALK2TOBII('GET_SAMPLE');
% gazeData=TALK2TOBII('GET_SAMPLE_EXT');
% TALK2TOBII('START_CALIBRATION', calib_pnts, clear_prev, n_samples, [,filename]);
% TALK2TOBII('START_CALIBRATION' [,filename [,recalculate]]);
% TALK2TOBII('ADD_CALIBRATION_POINT');
% TALK2TOBII('REMOVE_CALIBRATION_SAMPLES', remove_matrix);
% TALK2TOBII('DREW_POINT');
% quality = TALK2TOBII('CALIBRATION_ANALYSIS');
% TALK2TOBII('SYNCHRONISE');
% TALK2TOBII('START_AUTO_SYNC');
% TALK2TOBII('STOP_AUTO_SYNC');
% timeStart = TALK2TOBII('EVENT',Event_Name, duration, nameOfField, value, ...);
% TALK2TOBII('RECORD');
% TALK2TOBII('STOP_RECORD');
% TALK2TOBII('SAVE_DATA', eye_trackin_data, events, APPENDorTRUNK);
% [timeStart, eventDataNum, EventDataStr]=TALK2TOBII('GET_EVENTS_DATA', from_event);
% [timeStart, gazeData]=TALK2TOBII('GET_GAZES_DATA', from_sample);
% TALK2TOBII('CLEAR_DATA');
%
% ===============================================================================
%
% TALK2TOBII()
% Return a local timestamp.  
%
% ===============================================================================
% 
% TALK2TOBII('CONNECT',hostname);
% Sets a flag that allows the tobii thread to connect to the TETserver via TCP/IP. 
% 'hostname' is the ip address of the pc that runs the TETserver. This function 
% does not return any value. If an error has been occured cannot be detected with
% this function. Use 'GET_STATUS' to check the status of the connection with the 
% TET server and to detect any errors. 
% 
% -------------------------------------------------------------------------------
%
% TALK2TOBII('DISCONNECT');
% Sets a flag that allows the tobii thread to disconnect. If the tobii thread is 
% not connected with the TETserver nothing happens. This function does not destroy 
% tobii thread. Tobii tread is destroyed when the TALK2TOBII  
%
% -------------------------------------------------------------------------------
% 
% TALK2TOBII('START_TRACKING');
% Sets a flag that allows the tobii thread to start subscribing gaze data. 
% If the tobii thread is not connected with the TETserver nothing happens. 
% This function does not return any value. If an error has been occured 
% cannot be detected with this function. Use 'GET_STATUS' to check the status 
% of the connection with the TET server and to detect any errors. 
% 
% -------------------------------------------------------------------------------
% 
% TALK2TOBII('STOP_TRACKING');
% Sets a flag that allows the tobii thread to stop the subscription of gaze data. 
% If the tobii thread is not connected with the TETserver nothing happens. 
% This function does not return any value. If an error has been occured 
% cannot be detected with this function. Use 'GET_STATUS' to check the status 
% of the connection with the TET server and to detect any errors. 
% 
% -------------------------------------------------------------------------------
% 
% [status,history] = TALK2TOBII('GET_STATUS');
% This function returns an array with 0 or 1 describing bits that correspond
% to the following values, respectively:
% TET_API_CONNECT          -> to request connection
% TET_API_CONNECTED        -> 1 indicates that the communication with the 
%                              TETserver has been initialised succesfully
% TET_API_DISCONNECT       -> to request terminating the connection
% TET_API_CALIBRATING      -> to request calibration
% TET_API_CALIBSTARTED     -> 1 indicates that previous calibration has been 
%                              cleared succesfully and the calibration process
%                              has been started.
% TET_API_RUNNING          -> to request the subscription of eye tracking data
% TET_API_RUNSTARTED       -> 1 indicates that the subscription of gaze data
%                              has been initialised succesfully.
% TET_API_STOP             -> to request stopping the subscription of gaze data
% TET_API_FINISHED         -> 1 indicates that the tobii thread has exit
% TET_API_SYNCHRONISE      -> 1 indicates that synchronisation process has
%                              started
% TET_API_CALIBEND         -> 1 indicates that calibration has finished
% TET_API_SYNCHRONISED     -> 1 indicates that host and remote computer has 
%                              been synchronised
% TET_API_AUTOSYNCED       -> 1 indicates the last autosync op was successful
%                             see START_AUTO_SYNC/STOP_AUTO_SYNC
% TET_API_REMOVING_SAMPLES -> 1 indicates there's a calibration samples removal
%                             ongoing
% TET_API_CAN_DRAW_POINT   -> 1 indicates there's a calibration point has been
%                             successfully added and so it can be drawn
% 'history' is an m-by-2 array that records whether the main calls to the 
% TET API were succesful and a timestamp as it is recorded by GetSecs 
% after the function's call. 
% The first column of this array are integer values from 1-12 if an error
% has occur or integer values above 100 if an error has not occur:
% 0 -> 'Problem initialising tobii' (Tet_Init has failed)
% 1 -> 'Problem connecting with tobii' (Tet_Connect failed)
% 2 -> 'Problem clearing calibration' (Tet_CalibClear failed)
% 3 -> 'Problem adding Calibration point' (Tet_CallibAddPoint failed)
% 4 -> 'Warning: Problem calculating and setting calibration 
%      (Tet_CalibCalculateAndSet failed)
% 5 -> 'Warning: Pronlem getting calibration results (Tet_CalibGetResult
%      failed)
% 6 -> 'Warning: Problem saving calibration' (Tet_CalibSaveToFile failed)
% 7 -> 'Warning: Synchronisation failed' (Tet_Synchronise failed)
% 8 -> 'Problem starting tracking! EyeTracker will disconnect' (Tet_Start 
%      failed)
% 9 -> 'Warning: Problem loading calibration file' (Tet_CalibLoadFromFile 
%      failed)
% 10 -> 'Warning: Problem removing calibration samples' (Tet_CalibRemovePoints 
%      or Tet_CalibCalculateAndSet failed)
% 11 -> 'Warning:Problem getting calibration results (Tet_CalibGetResult
%      failed on calibration load from file)
% 100 -> 'connecting with tobii...success' (Tet_Connect was successful)
% 200 -> 'clearing calibration...success' (Tet_CalibClear was successful)
% 300 -> 'adding calibration point...success' (Tet_CallibAddPoint was 
%      successful)
% 400 -> 'calculating and setting calibration...success' 
%      (Tet_CalibCalculateAndSet was successful)
% 500 -> 'Calibration results have been obtained' (Tet_CalibGetResult
%      was successful)
% 600 -> 'Calibration have been saved' (Tet_CalibSaveToFile was successful)
% 700 -> 'Synchronised maximal error...' (Tet_Synchronise was successful)
% 800 -> 'starting track...success' (Tet_Start was successful)
% 900 -> 'Calibration has been loaded' (Tet_CalibLoadFromFile 
%      was successful)
% 1000 -> 'Calibration samples removal has been performed' (Tet_CalibRemovePoints 
%      or Tet_CalibCalculateAndSet failed)
% 1100 -> 'Calibration results have been obtained'  (Tet_CalibGetResult
%      was successfull on calibration load from file)
%
% -------------------------------------------------------------------------------
%
% TALK2TOBII('CLEAR_HISTORY');
% Discard previous history records. See the 'GET_STATUS' for more
% information on what history contains.
%
% -------------------------------------------------------------------------------
%
% gazeData=TALK2TOBII('GET_SAMPLE');
% Use this function to receive online gaze data
% It returns an array 'gazeData' with the following fields:
% x coordinate of the left eye
% y coordinate of the left eye
% x coordinate of the right eye
% y coordinate of the right eye
% time in Sec returned from the TETserver
% time in mSec returned form the TETserver
% left eye validity 
% right eye validity
%               (Validity indicates how likely is it that the eye is found)
%               0 - Certainly (>99%),
%               1 - Probably (80%),
%               2 - (50%),
%               3 - Likely not (20%),
%               4 - Certainly not (0%)
% left camera eye position - x coordinate
% left camera eye position - y coordinate
% right camera eye position - x coordinate
% right camera eye position - y coordinate
% time in millisecs: the TET remote timestamp converted to the local clock
%
% -------------------------------------------------------------------------------
%
% gazeData=TALK2TOBII('GET_SAMPLE_EXT');
% Use this function to receive online gaze data
% It returns an array 'gazeData' with the following fields:
% x gaze coordinate of the left eye
% y gaze coordinate of the left eye
% x gaze coordinate of the right eye
% y gaze coordinate of the right eye
% time in sec
% time in msec
% left eye validity
% right eye validity
% left camera eye position - x coordinate
% left camera eye position - y coordinate
% right camera eye position - x coordinate
% right camera eye position - y coordinate
% distance of the camera from the left eye
% distance of the camera from the right eye
% diameter of pupil of the left eye
% diameter of pupil of the right eye
% time in millisecs: the TET remote timestamp converted to the local clock
% 
% -------------------------------------------------------------------------------
% 
% TALK2TOBII('START_CALIBRATION', calib_pnts, clear_prev, n_samples, [,filename]);
% calib_pnts sets the calibration points. This should be an m-by-2 
% array where m is the number of points and the columns correspond to the x 
% and y coordinates respectively. The coordinates take values from 0 to 1.
% clear_prev if 1, discards the last calibration samples and starts from scratch
% n_samples is a positive integer generally between 6 and 24, which sets the number
% of samples per calibration point (if negative, this reset the number to 12).
% If present filename is the where calibration data will be saved.
%
% -------------------------------------------------------------------------------
%
% TALK2TOBII('START_CALIBRATION'[,filename [, recalculate]]);
% If no parameterss are passed, the command simply performs a recalculation and 
% set of the calibration (this might be useful after some samples were removed 
% from a previous calibration, but no new ones are supposed to be added). 
% Passing only the filename parameters, or the filename plus the 'recalculate' 
% flag set to 0, will load a pre-saved calibration. 
% Passing the filename plus a non zero 'recalculate' value, performs a recalculate
% and set of the calibration and also saves the calibration in the specified file. 
%
% -------------------------------------------------------------------------------
%
% TALK2TOBII('ADD_CALIBRATION_POINT');
% It informs the tobii thread that the drawing of the next point has been started
% and it blocks the thread till the eye tracker is ready to continue. 
% 
% -------------------------------------------------------------------------------
%
% TALK2TOBII('REMOVE_CALIBRATION_SAMPLES', remove_matrix);
% This command removes samples from the last calibration. The samples to remove
% are specified by a matrix of n rows and 4 columns: column 0 represents which eye
% samples to remove (1 = left, 2 = right, 3 = both), column 1 is an x coordinate,
% column 2 is a y coordinate, column 3 is a radius (all these last 3 parameters 
% are float value in [0,1]). All the sample whose distance from the point (x,y)
% is less than radius will be removed.
%
% -------------------------------------------------------------------------------
% 
% TALK2TOBII('DREW_POINT');
% It signals the tobii thread that the drawing of the calibration point has been
% finished and calibration can be continue with the next point.
% 
% -------------------------------------------------------------------------------
% 
% The three last functions are combined to calibrate the Tobii eye tracker.
% If there are not used properly the tobii thread MAY LOCK and do not allow 
% further interaction. See example code of how to use them properly.
% 
% -------------------------------------------------------------------------------
% 
% quality = TALK2TOBII('CALIBRATION_ANALYSIS');
% It returns an array of the data acquired during calibration and their 
% accuracy.
% 
% -------------------------------------------------------------------------------
% 
% TALK2TOBII('SYNCHRONISE');
% It synchronises the host pc time to the TETserver.
% 
% -------------------------------------------------------------------------------
% 
% TALK2TOBII('START_AUTO_SYNC');
% Starts background auto-sync thread. Wait a couple of seconds before checking for 
% the autosynced bit == 1 (if successfull) in the status array. 
%
% -------------------------------------------------------------------------------
% 
% TALK2TOBII('STOP_AUTO_SYNC');
% Stops background auto-sync thread.
% 
% -------------------------------------------------------------------------------
% 
% TALK2TOBII('EVENT',Event_Name, duration, 'nameOfField', value, ...);
% Use this function to record events:
% 'Event_Name' is a string that specifies the event
% 'duration' specifies the time that the event last in millisecs (set constant 
%            if it is not required).
% An unlimited number of pair values can be specified with the following format:
% 'nameOfField', numerical value that corresponds to this field. 
% Returns the time at which the event was set (in secs);
% 
% -------------------------------------------------------------------------------
% 
% TALK2TOBII('RECORD');
% It calls the TALK2TOBII('SYNCHRONISE') and it sets a flag to start recording
% the eyetracking data. Data are stored in memory and they are not saved on 
% hard drive unless 'SAVE_DATA' is called. This function does not start the 
% subscription of eye tracking data. Normally 'START_TRACKING' is called prior
% to this function.
% 
% -------------------------------------------------------------------------------
% 
% TALK2TOBII('STOP_RECORD');
% Sets a flag that prevents further eye tracking data to store on memory
% 
% -------------------------------------------------------------------------------
% 
% TALK2TOBII('SAVE_DATA', eye_trackin_data, events, 'APPENDorTRUNK');
% It writes in text files both the eye tracking data and events.
% 'Eye_tracking_data' specifies the filename that will be used to store 
% the data collected from tobii. The eye tracking data are stored in
% columns in the following order:
% time in sec
% time in msec
% x gaze coordinate of the left eye
% y gaze coordinate of the left eye
% x gaze coordinate of the right eye
% y gaze coordinate of the right eye
% left camera eye position - x coordinate
% left camera eye position - y coordinate
% right camera eye position - x coordinate
% right camera eye position - y coordinate
% left eye validity
% right eye validity
% diameter of pupil of the left eye
% diameter of pupil of the right eye
% distance of the camera from the left eye
% distance of the camera from the right eye
% 'events' specifies the filename that it will be used to store the events
% as they are specified during an 'EVENT' call. 
% A '#START timestamp' provides a timestamp of when gaze data subscription
% started. This time is acquired with a call to the psychtoolbox function
% 'GetSecs'.
% 'APPENDorTRUNK'-> use 'APPEND' to allow appending data to existing file or 
% 'TRUNK' to delete any previous data stored in the specified file.
% If 'events' and 'Eye_tracking_data' are equal, the data will be merged by timestamp
% and printed justified side by side on the same file: the fields are descripted 
% in the header of the file.
% 
% -------------------------------------------------------------------------------
%
% TALK2TOBII('GET_EVENTS_DATA', from_event)
% Return the events data since from_event on, plus the time when gaze data 
% subscription started. from_event is an positive integer value. 
% The eventdata are returned in 2 matrix, one for the numeric fields, the other
% for the string fields. The columns for the numeric matrix are in the following
% order:
% time in millisecs
% duration
% The columns for the strings matrix are in the following order:
% code
% details
% In case no data are avaiable, the matrixes will be 1x1
% 
% -------------------------------------------------------------------------------
%
% TALK2TOBII('GET_GAZES_DATA', from_sample)
% Return the eyetracking data since from_sample on, plus the time when gaze data 
% subscription started. from_sample is a positive integer value.
% The eye tracking data are stored in columns in the following order:
% x gaze coordinate of the left eye
% y gaze coordinate of the left eye
% x gaze coordinate of the right eye
% y gaze coordinate of the right eye
% time in sec
% time in msec
% left eye validity
% right eye validity
% left camera eye position - x coordinate
% left camera eye position - y coordinate
% right camera eye position - x coordinate
% right camera eye position - y coordinate
% distance of the camera from the left eye
% distance of the camera from the right eye
% diameter of pupil of the left eye
% diameter of pupil of the right eye
% time in millisecs: the TET remote timestamp converted to the local clock
% In case no data are avaiable, the matrix will be 1x1
%
% -------------------------------------------------------------------------------
%
% TALK2TOBII('CLEAR_DATA');
% Discard eye tracking data and events stored in memory
% There might be 2 optional input parameter which if not specified are valued -1
% up_sample_idx: < -1 all, -1 up to last saved, 0 don't clear, or del [0, up_sample_idx)
% up_event_idx: < -1 all, -1 up to last saved, 0 don't clear, or del [0, up_event_idx)
% -------------------------------------------------------------------------------
%
% 11/07/2007 Fani Deligianni
% 01/08/2010 Updated by Luca Filippin
%
% ===============================================================================
