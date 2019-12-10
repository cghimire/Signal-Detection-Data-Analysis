% NMMVeto_CoinInfo is a do-it-all function that takes
% 
% for a single neutron run!
%
% the run data (NMMrunFile_nMode) and the trace data (NMMtraceFile_nMode)
% and then produces a data structure of NMM-muon coincident events
% along with information about them - if there was a muon, if they're
% interesting, what their favorite color is
% 
% this data structure is SAVED because it takes a long time to make
function [] = NMMVeto_CoinInfo(NMMrunFile_nMode, NMMtraceFile_nMode)

% STEP 1
% -------
% make a list ('shieldfullPathList') of all the muon files
% that belong to an NMM data file
 station = 'nw';
 mux = 3;
 shieldfullPathList = getShieldFiles(NMMtraceFile_nMode,station,mux);


% STEP 2
% ------
% use findEventNumber to NMM events that are near-in-time to a muon
% data processed: all the muon files in the list 'fullPathList'
% returns: a table with two columns: the NMM-muon time difference, 
% and the NMM event Number with that time difference
 timeDiffs_eventNums = findEventNumber(shieldfullPathList, NMMrunFile_nMode);
     

% STEP 3
% ------
% use findInterestingEvents to examine the coincident events
% input: table from step 2
% output: data structure.  Each event number has an entry.
% findInterestingEvents tests and records its results for muons, etc.

interestingEvents = findInterestingEvents(NMMtraceFile_nMode, timeDiffs_eventNums);


% STEP 4
% ------
% save the data structure made in step 3
% the data structure takes a long time to make if you have a lot of data
% and you have a lot of data

% make the filename to save the data
[NMM_dataDir NMM_fileName] = fileparts(NMMtraceFile_nMode);
saveData_fileName = [NMM_fileName '_NMM_muon_coinData.mat'];
saveData_fullFileName = fullfile('/home/cghimire/muon_NMM_coinStudy/data/nMode', saveData_fileName);

% now that we (hopefully!) have the filename, save the data
%interestingEvents = 'a';
save(saveData_fullFileName, 'interestingEvents');

% make plots of interesting events



end
