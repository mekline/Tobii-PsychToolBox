function [] = TES(subNo, Condition, parafile)
%This is the main function for a Tobiified looking time experiment.  
%Make sure you have added paths to t2t and psychtoolbox!
%If you don't specify a parameter file above, it uses para.txt
%If the OPTIONAL parafile param is given we can use a different parafile (e.g. to 
%execute /without/ running any tobii-related code.)  If ConnTobii is set to
%zero, the exp should still run, including display and saving
%behavioral/timing info. 

    global parameters 

    %This is the struct that holds ALL the information needed/generated
    %during this experiment.  'global parameters' needs to be declared at the 
    %beginning of every file, and you shouldn't need to be passing in 
    %very many arguments to your functions. 

    folder = fileparts(which('TES.m')); %add this folder to the path too.
    addpath(genpath(folder));

    parameters.expFolder = genpath(folder); 
    %Assign variables from the function call
    parameters.subNo = subNo; 
    parameters.Condition = Condition;

    %%%%%
    % Initializing PToolbox & make sure we got reasonable arguments, then read in ALL the
    % parameters the experiment uses (adding those passed into this function)
    %%%%%

    %Check we got good arguments, then set up and and load parameters from our file
    if nargin == 4
        parameters.parafile = parafile;
    else
        parameters.parafile = 'para.txt';
    end
    if nargin >= 2
        if exist(parameters.parafile,'file') == 0
            error([parameters.parafile ' doesn''t exist!']);
            return;
        end

        Setup_PTool(); %Calls various Psychtoolbox initialization fns so everything is ready to go 
        SetParameters; %Sets all the default parameter values used in the experiment
        ReadParaFile(parameters.parafile); %Updates for any changes that are being made to this run

    else
        disp('Error using TES arguments! ==> TES(subNo, Condition, [parafile])');
        return
    end

    %%%%%
    % Run the experiment.  It's all inside a giant try/catch block so that we
    % exit cleanly
    %%%%%
    try
        if parameters.ConnTobii
            InitandCalibrate_Tobii();
        end
        Do_myexp(); %%YOUR EXPERIMENT GOES HERE!
        Closeout_PTool();
    catch anyerror
        Closeout_PTool();
        rethrow(anyerror); % Matlab will show up all the errors and links.
    end
end

