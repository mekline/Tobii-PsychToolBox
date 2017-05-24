function [] = LogTobiiEvent(EventName, trialNo)
%Logs a Tobii event with some information.  Or if the eyetracker is 
%not connected, smoothly ignores.  This is a simple one
%that just records the trialnumber, you could put plently more
%here too.
%
%NOTE that while EventName can be a string, t2t expects everything
%else to be a (string, number) pair.

	global parameters;
	
    if(parameters.EYETRACKER)
    	talk2tobii('EVENT',EventName, 0, 'Trial#', trialNo);
    end

end