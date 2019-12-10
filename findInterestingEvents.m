function [interestingEvents] = findInterestingEvents(NMMtraceFile_nMode, eNum_struct)
% initialize the return array
interestingEvents = [];

% load the NMM trace file
neutronProcFile = load(NMMtraceFile_nMode);

% choose an event number
for i = 1:length(eNum_struct)
    for j =1:length(eNum_struct(i).eventNums)
en = eNum_struct(i).eventNums(j);
FileName =eNum_struct(i).shieldFileName{j};
TimeStamp = eNum_struct(i).shieldTimeStamp(j);
seriesNumber = neutronProcFile.EventData(en).time;
nCoin_south = neutronProcFile.EventData(en).dcoin(1).N;
nCoin_north = neutronProcFile.EventData(en).dcoin(2).N;

% /////////////////////////
% look at South tank: muon?
% /////////////////////////
if neutronProcFile.EventData(en).dcoin(1).N > 0
    arr1=neutronProcFile.EventData(en).dcoin(1).amps(:,1);
    arr2=neutronProcFile.EventData(en).dcoin(1).amps(:,2);
    VmaxSE = max(neutronProcFile.EventData(en).dcoin(1).amps(:,1));
    VmaxSW = max(neutronProcFile.EventData(en).dcoin(1).amps(:,2));
    isMuonSouth = any(arr1>0.5) & any(arr2>0.5);
    
else
    % if there are no coincidences, there's no muon
    isMuonSouth = false;
    VmaxSE = false;
    VmaxSW = false;
end 

% /////////////////////////
% look at North tank: muon?
% /////////////////////////
if neutronProcFile.EventData(en).dcoin(2).N > 0
    arr3=neutronProcFile.EventData(en).dcoin(2).amps(:,1);
    arr4=neutronProcFile.EventData(en).dcoin(2).amps(:,2);
    VmaxNW = max(neutronProcFile.EventData(en).dcoin(2).amps(:,1));
    VmaxNE = max(neutronProcFile.EventData(en).dcoin(2).amps(:,2));
    isMuonNorth = any(arr3>0.5) & any(arr4>0.5);
    
else
    % if there are no coincidences, there's no muon
    isMuonNorth = false;
    VmaxNE = false;
    VmaxNW = false;
end


% /////////////////////////
% is this event intersting?
% /////////////////////////
% these are all the cases where the event is NOT interesting
% muon in both tanks
if isMuonSouth & isMuonNorth
    isInteresting = false;
end

% muon in North tank, no muon in South tank AND no coincidences in South
% tank
if isMuonNorth & ~isMuonSouth
    if neutronProcFile.EventData(en).dcoin(1).N <2
        isInteresting = false;
    end
end    

% muon in South tank, no muon in North tank AND < 2 coincidences in North
% tank
if isMuonSouth & ~isMuonNorth
    if neutronProcFile.EventData(en).dcoin(2).N <2
        isInteresting = false;
    end
end

% otherwise, the event might be interesting
% isInteresting = true;
% neutrons in the south tank, muon in the north tank
% there might be neutrons in the north tank,
% but it's hard to tell because the north-tank PMT
% is going crazy from the muon
if isMuonNorth & ~isMuonSouth
    if neutronProcFile.EventData(en).dcoin(1).N >=2
        isInteresting= true;
    end
end

% muon in the south tank, (may be) neutron in the north tank
if isMuonSouth & ~isMuonNorth
    if neutronProcFile.EventData(en).dcoin(2).N >=2
        isInteresting = true;
    end
end

% no muons at all (!), but maybe neutrons
if ~isMuonSouth & ~isMuonNorth
    if  neutronProcFile.EventData(en).dcoin(1).N + neutronProcFile.EventData(en).dcoin(2).N  >=2
        isInteresting =  true;
    end
end


% record the information we figured out
% for theses event
index = length(interestingEvents) + 1;
interestingEvents(index).eventNum = en;
interestingEvents(index).timeDiff = eNum_struct(i).timeDiff;
interestingEvents(index).isMuonNorth = isMuonNorth;
interestingEvents(index).isMuonSouth = isMuonSouth;
interestingEvents(index).isInteresting = isInteresting;
interestingEvents(index).VmaxSE = VmaxSE;
interestingEvents(index).VmaxSW = VmaxSW;
interestingEvents(index).VmaxNE = VmaxNE;
interestingEvents(index).VmaxNW = VmaxNW;
interestingEvents(index).seriesNumber = seriesNumber;
interestingEvents(index).nCoinSouth = nCoin_south;
interestingEvents(index).nCoinNorth = nCoin_north;
interestingEvents(index).ampsSouth = neutronProcFile.EventData(en).dcoin(1).amps;
interestingEvents(index).ampsNorth = neutronProcFile.EventData(en).dcoin(2).amps;
interestingEvents(index).areaSouth = neutronProcFile.EventData(en).dcoin(1).area;
interestingEvents(index).areaNorth = neutronProcFile.EventData(en).dcoin(2).area;
interestingEvents(index).timeSouth = mean(neutronProcFile.EventData(en).dcoin(1).t0s,2);
interestingEvents(index).timeNorth = mean(neutronProcFile.EventData(en).dcoin(2).t0s,2);
interestingEvents(index).shieldTimeStamp = TimeStamp;
interestingEvents(index).shieldFileName = FileName;





    end % end of loop over events with the same diff
end% end of loop over entries in input table
        

end