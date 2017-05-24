function [] = TES(subNo, Condition, parafile)
%This is the main function for a Tobiified looking time experiment.  

%Make sure you have added paths to t2t and psychtoolbox!

%If the OPTIONAL parafile param is given we can use a different parafile (e.g. to 
%execute /without/ running any tobii-related code.)  It should however 
%display everything and take keyboard responses correctly for the 
%whole experiment!
%If you don't specify a parameter file, it uses para.txt

folder = fileparts(which('TES.m'));
addpath(genpath(folder));

global parameters 
%Note, this is the struct that holds ALL the information needed/generated
%during this experiment.  'global parameters' needs to be declared at the 
%beginning of every file, and you shouldn't need to be passing in 
%very many arguments to your functions. (except for the updated Calibration 
%files here, which I haven't attempted to beat into compliance with this...)



%%%%%
% Initializing PToolbox and setting parameters for the experiment: in this
% section we make sure we got reasonable arguments and read in ALL the
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
    parameters.subNo = subNo; %Assign variables you gave it from the function call
    parameters.Condition = Condition;
    AssignDataFiles; 

    parameters.hostName
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
        Calibrate_Tobii();
    end
    Do_myexp(); %%YOUR EXPERIMENT GOES HERE!
    Closeout_PTool();
catch anyerror
    Closeout_PTool();
    rethrow(anyerror); % Matlab will show up all the errors and links.
end




end

