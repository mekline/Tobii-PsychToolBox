function [] = Write_KnownVerbResultFile(Verb, LeftSide)
%Writes out the randomization of an LT_Trial
%Makes it a little easier for humans to read, by printing out the following
%info: Subject Transitive Jump playedRightSide

global parameters

if LeftSide
    activeSide = 'Left';
else
    activeSide = 'Right';
end



% Write trial result to file:
fprintf(parameters.datafile,'%i %s %s %s\n', ... %Have to tell it what to expect here, e.g. integer, string, string, string
    parameters.subNo, ...
    parameters.Condition, ...
    Verb, ...
    activeSide)


end

