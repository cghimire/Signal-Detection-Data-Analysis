% this function eat the shieldDataFile and gives us time stamps of  selected
% muon events

% function inputs: shieldDataFile_arr is the array of data file from the muon veto shield (has
% timestamp and hit pattern information)
%                : NMMrunFile_nMode is NMM data (neutron mode triggering)
%                has time information for all events in a (run?)
% function output: a single struct that has fields 'eventNums' and 'timeDiff'

function [time_events] = findEventNumber(shieldDataFile_arr, NMMrunFile_nMode)

% get muon times from the shield data
% all the shield data files in the list
% mutimes is a column
mutimes = [];
for i = 1:length(shieldDataFile_arr)
    mutimes = [mutimes ; findMuons(shieldDataFile_arr{1,i})];   
end

%loop over shift of timestamp 
for j = 1:length(mutimes)
mutimes(j,1).timeStamp = mutimes(j,1).timeStamp - 1000021;
end

% make array of NMM times
load(NMMrunFile_nMode);
NMMTimes= uint64(double(symTimeSec)*1e6 + double(symTimeMuSec));
NMMTimes= NMMTimes';

% diffs_good holds the good values in 'diffs'.  It is shorter than diffs!
% strVals is array of NMM times (NMMTimes) closest to muon shield times
% (mutimes)
[diffs, evnum, strVals, cRemoveRange] = findClosestTimes(double([mutimes.timeStamp]'),double(NMMTimes),1);
diffs_good = diffs(diffs ~= inf);
mutimes_good = mutimes(diffs ~= inf);

diffs_good = unique(diffs_good);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% loop over the time differences
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% get event numbers for each time difference
% time_events.timeDiff
% time_events.eventNums
for j=1:length(diffs_good)
    
    % we look for NMM event numbers that havea time difference
    % equal to 'timeDifference'
    time_events(j).timeDiff = diffs_good(j);
    
    thisEventNum = int16.empty();
    thisTimeStamp = uint64.empty();
    thisfileName = {};
    diffs_index=find(diffs==time_events(j).timeDiff);

    % at the end of this loop,
    % thisEventNum should be an array that holds
    % all the event numbers that have a time difference
    % of 'timeDifference'
    for ii = 1:length(diffs_index)
        % diffs_index is an index - it picks out the NMM times (strVals)
        % that we want
        thisEventNum(end + 1) = find(NMMTimes == uint64(strVals(diffs_index(ii) )));
        thisTimeStamp(end + 1) = uint64( mutimes(diffs_index(ii)).timeStamp );
        thisfileName{ii}= mutimes(diffs_index(ii)).shieldDataFile;
    end
    
    time_events(j).eventNums = thisEventNum;
    time_events(j).shieldTimeStamp = thisTimeStamp;
    time_events(j).shieldFileName = thisfileName;
end

end
