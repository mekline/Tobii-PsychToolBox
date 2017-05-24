function [] = Do_myexp()
%Executes the actual TobiiWugging routine, for an eyetracking setup (note that
%there is a parameter in para.txt which determines whether any calls to Tobii will 
%actually be made!  But it should also act gracefully if the tobii fails to connect.)

global parameters

%%%%%
% Get ready for the experiment!  Here we set any random/counterbalanced
% variables that need to be set for a specific run of the experiment.
%
% NOTE: for this version, we let the action-side match be constant, but
% manipulate order of side and causal-version presentation.
%%%%%

%Known-verb counterbalancing:
verber = [0,1];
verber = verber(randperm(2));
parameters.jumpLeft = verber(1);
parameters.hugLeft = verber(2);

%Verb trial counterbalancing
counterbalancer = zeros(1, parameters.ntrials);
counterbalancer(1:floor(parameters.ntrials/2)) = ones;
parameters.leftFirst = counterbalancer(randperm(parameters.ntrials));
parameters.causalFirst = counterbalancer(randperm(parameters.ntrials));


try
    %Do intro/attention getter trials
    GetAttention();
    Jump_Trial();
    Write_KnownVerbResultFile('Jump', parameters.jumpLeft);
    
catch
    Closeout_PTool();
    psychrethrow(psychlasterror);
end

end

