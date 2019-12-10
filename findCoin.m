%function [RunInfo,EventData] = findCoin(DataSeries, lth, dth, dtype, comment, varargin)
function [RunInfo,EventData] = findCoin(DataSeries, lth, dth, dtype, comment, EventData)

% function [RunInfo,EventData] = findCoin(DataSeries, lth, dth, dtype, comment)
%
% DataSeries is the unique date_time string identifier for a particular data run.
%
% dth is in units of micro-seconds and is the maximum distance in time 
% for two pulses in data to count as a "coincedence". 
%
% lth is in units of micro-seconds and is the maximum distance in time 
% for two pulses in logic to count as a "coincedence". (Usually 0.16, for 160 ns)
%
% dtype is a string that specifies whether
% the run was a neutron (n, N, neutron, or Neutron), muon (m, M, muon, or Muon),
% Cf-252 (cf, Cf, cf-252 or Cf-252), or Co-60 (co, Co, Co-60, or co-60) run. 
%
% comment is a string containing
% any desired comments regarding this particular run of the coincidence code.
%
% This script is designed to find the coincedence pulses, down to some threshold
% It does this by cycleing through previously analyzed traces (the output of findTrace4)
%
% The script will cycle through each event in the DataSeries, which is handy
% because that is how EventData is arranged. Then I cycle through each Tank, looking
% at PMT 1 and PMT 3 since each coincidence must appear in two tubes, making looking
% at pmts 2 & 4 redundant.
%
% Adds the following fields to the RunInfo and EventData structures, the index k
% refers to the event number, while the index tank is 1 for the south tank, and 2
% for the north tank:
%
% EventData(k).dcoin(tank).N      ... Number of coincidences found between a tanks tubes
%                                     in the amplitude traces
%
% EventData(k).lcoin(tank).N      ... Number of coincidneces found between a tanks tubes
%                                     in the logical traces
%
% EventData(k).dcoin(tank).t0s    ... A matrix of pulse start times for coincident pairs
%                                     found in the amplitude traces, each row represents 
%                                     a coincidnece while each column represents a pmt channel
%
% EventData(k).lcoin(tank).t0s    ... A matrix of logical pulse start times for coincident
%                                     pairs found in the logical traces ... same form as above
%
% EventData(k).dcoin(tank).amps   ... A matrix of pulse amplitudes for coincident pairs found
%                                     in the amplitude traces, each row has two entries (one
%                                     for each pmt channel)... the amplitudes of the coincident
%                                     pulses
% 
% EventData(k).dcoin(tank).index  ... A matrix of indecies into the amplitude traces, marking
%                                     the start times of coincident pulses... same form as other
%                                     matrices
% 
% RunInfo.coin.comment            ... Optional comment string input by user at time of function
%                                     call
% 
% RunInfo.coin.version            ... software version of this coincidence code
%
% RunInfo.coin.lth                ... user specified overlap time for finding logical pulse
%                                     coincidences ... should be ~0.160 us
%
% RunInfo.coin.dth                ... user specified overlap time for finding amplitude pulse
%                                     coincidences ... shoud be ~0.160 us
  
  
%%%%%%%%%%%%%%%%%%%%%%%%
%%% Revision History %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% April 6th, 2010 ... RAB --> Modified the function's inputs and outputs to    %%%
%%%                             make better use of the new output format of      %%%
%%%                             findTrace4. Added the comment input.             %%%
%%%                             Changed the first input to be a string of the    %%%
%%%                             SeriesNumber to make use of the way data is      %%%
%%%                             organized on neutron.physics.ucsb.edu            %%%
%%% April 16th, 2010 .. CJQ --> Added logic to find only best coincedence for    %%%
%%%                             each pulse.                                      %%%
%%% April 21st, 2010 .. CJQ --> Tested script  -failed-                          %%%
%%% May 17th, 2010 ...  CJQ --> Fixed and tested the script again                %%%
%%% May 27th, 2010 ...  CJQ --> Incorporated structure to find the coincedences  %%%
%%% version 2.0                 from the logic pulse signals from hitMask struct %%%
%%%                                                                              %%%
%%% June 1st, 2010 ...  RAB --> Updated to reflect new directory structure and   %%%
%%% version 2.1                 the new runs types (co-60 and cf-252)            %%%
%%%                                                                              %%%
%%% June 7th, 2010 ...  RAB --> Updated to include this scripts version number   %%%
%%% version 2.2                                                                  %%%
%%%                                                                              %%%
%%% June 22nd, 2010 ..  RAB --> Revised script for clarity. Added comments       %%%
%%% version 2.3                 describing the coincidence variables that are    %%%
%%%                             added to RunInfo and EventData.                  %%%
%%%                                                                              %%%
%%% Aug 7th,  2010 ...  CJQ --> Upgraded it by recording the areas for           %%%
%%% version 2.4                 coincident pulses.                               %%%
%%%                                                                              %%%
%%% Sept 20th 2010 ...  CJQ --> Upgraded it by recording the widths.(Failed)     %%%
%%%                                                                              %%%
%%% Sept 22nd 2010 ...  CJQ --> Upgraded by recording the index of original      %%% 
%%% version 2.5                 pulses in the pmt struct.                        %%%
%%%                                                                              %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  cwd = pwd;
  %nargin
  %if nargin > 5
  %    1+2
  %    EventData = varargin{6}
  %end
  
  loadFile_bool = false;
  %if ~(exist EventData var)
  if loadFile_bool
      disp('loading the data, may take a few minutes...');
      % load the relevant data depending on whether it was a neutron, muon, Cf or Co run
      if strcmp(dtype,'m') | strcmp(dtype,'M') | strcmp(dtype,'muon') | strcmp(dtype,'Muon')
          cd /net/neutron/data/neutron/data_runs/background/muon/new_format/EventData/;
      elseif strcmp(dtype,'n') | strcmp(dtype,'N') | strcmp(dtype,'neutron') | strcmp(dtype,'Neutron')
          cd /net/neutron/data/neutron/data_runs/background/neutron/new_format/EventData/;
      elseif strcmp(dtype,'co') | strcmp(dtype,'Co') | strcmp(dtype,'co-60') | strcmp(dtype,'Co-60')
          cd /net/neutron/data/neutron/data_runs/calibration/co_60/EventData/;
      elseif strcmp(dtype,'cf') | strcmp(dtype,'Cf') | strcmp(dtype,'cf-252') | strcmp(dtype,'Cf-252')
          cd /net/neutron/data/neutron/data_runs/calibration/cf_252/EventData/;
      else
          disp(['Incorrect input data run type specified... please input either' ...
              ' N for neutron run, or M for muon run']);
          return;
      end
      
      % Check if the EventData file exists ... if so load the data structures
      fid = fopen(['EventData_' DataSeries '.mat']);
      if fid == -1
          disp(['Unable to locate file EventData_' DataSeries '.mat, please check the run type and' ...
              ' data series number']);
          return;
      else
          fclose(fid);
      end
      load(['EventData_' DataSeries '.mat']);
      
      % Add new coincidence field to RunInfo structure
      RunInfo.coin.comment = comment;
      RunInfo.coin.version = 2.5;
      RunInfo.coin.ltime   = lth;
      RunInfo.coin.dtime   = dth;
  end
  
  % Aug 7th CJQ
  % Add the area finding function here
  if ~(isfield(EventData(1).pmt, 'area'))
      disp('Integrating Pulses to get Area');
      disp('STUB Correct Script Running');
      [RunInfo,EventData] = IntegratePulses(RunInfo,EventData,RunInfo.Scale);
      disp('Finding Coincidences');
  end
  
  
  % Add new coincidence fields to the EventData structure
  for j = 1:length(EventData)
      EventData(j).dcoin = struct('N',[],'t0s',[],'index',[],'amps',[],'area',[],'orgix',[]);
      EventData(j).lcoin = struct('N',[],'t0s',[]);
  end
  
  %%% Main Loop through all events %%%
  for i = 1:length(EventData)
    
    % This outputs the progress of the code
    if(mod(i,500)==1) 
      PercentComplete = 100*(i-1)/length(EventData);
      disp(['Percent Complete = ' num2str(PercentComplete)]);
    end
    
    %%% Secondary Loop through each tank %%%
    for k = 1:2:3
      
      % 1 = South tank, 3 = North tank
      if(k == 1)
        tank = 1;
      elseif(k == 3);
        tank = 2;
      end
      
      % Initialize dcoin and lcoin structures
      EventData(i).dcoin(tank).N = 0;
      EventData(i).dcoin(tank).t0s = [];
      EventData(i).dcoin(tank).amps= [];
      EventData(i).dcoin(tank).index=[];
      EventData(i).dcoin(tank).area =[];
      EventData(i).dcoin(tank).orgix=[];
      EventData(i).lcoin(tank).t0s = [];
      EventData(i).lcoin(tank).N = 0; 
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      %%% Data coincidneces--from amplitude traces %%%
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
      % first test to see if each of a tank's two tubes has at least one pulse
      if (EventData(i).Nevents(k) > 0) & (EventData(i).Nevents(k+1) > 0)
        clear tmp l1 l2 t1 t2 a1 a2 i1 i2;
        t1 = EventData(i).pmt(k).t0s;
        t2 = EventData(i).pmt(k+1).t0s;
        a1 = EventData(i).pmt(k).amps;
        a2 = EventData(i).pmt(k+1).amps;
        i1 = EventData(i).pmt(k).index;
        i2 = EventData(i).pmt(k+1).index;
        % 8-7-10 CJQ added this to allow for area record of coincidences
        ar1= EventData(i).pmt(k).area;
        ar2= EventData(i).pmt(k+1).area;
        % 9-20-10 CJQ added this to allow for width record in coincidences
        wi1= EventData(i).pmt(k).widths;
        wi2= EventData(i).pmt(k+1).widths;
        l1 = length(t1);
        l2 = length(t2);
        
        % make a matrix of the time-distance between PMT1 and PMT2 pulses
        % [iRows, iColumns] = [length(PMT1), length(PMT2)]
        clear diff_mat;
        for jj = 1: length(t1)
            diff_mat(jj,:) = t2-t1(jj);
            abs_RowCo = abs(diff_mat);
        end
         
        % search the matrix for coincidences
          for jj = 1: length(t1)
              % which PMT2 value is the best (=smallest)?
              [dt imin2] = min(abs_RowCo(jj,:));
              
          % Look at the PMT2 (iRows) 
          if dt <= dth
              [dt imin1] = min(abs_RowCo(:,imin2));
              if jj == imin1
                  % a coincidence
                  % save coincidence values
                  EventData(i).dcoin(tank).t0s  = [EventData(i).dcoin(tank).t0s; t1(jj) t2(imin2)];
                  EventData(i).dcoin(tank).amps = [EventData(i).dcoin(tank).amps; a1(jj) a2(imin2)];
                  EventData(i).dcoin(tank).index= [EventData(i).dcoin(tank).index; i1(jj) i2(imin2)];
                  EventData(i).dcoin(tank).area = [EventData(i).dcoin(tank).area; ar1(jj) ar2(imin2)]; 
                  EventData(i).dcoin(tank).N = EventData(i).dcoin(tank).N + 1;
                  N = EventData(i).dcoin(tank).N;
                  EventData(i).dcoin(tank).orgix(N,1:2) = [jj imin2];
              end
          end
          end
          
          % if there are no coincidences at all,
          % store dummy values
          if EventData(i).dcoin(tank).N == 0
              EventData(i).dcoin(tank).t0s   = -9999;
              EventData(i).dcoin(tank).index = -9999;
              EventData(i).dcoin(tank).amps  = -9999;
              EventData(i).dcoin(tank).area  = -9999;
              Eventdata(i).dcoin(tank).orgix = -9999;
          end
          
      % case 2: there are no pulses
      else
        % no pulses => no possible coincidences, 
        % fill dcoin structure with dummy values
        EventData(i).dcoin(tank).t0s   = -9999;
        EventData(i).dcoin(tank).index = -9999;
        EventData(i).dcoin(tank).amps  = -9999;
        EventData(i).dcoin(tank).area  = -9999;
        Eventdata(i).dcoin(tank).orgix = -9999;
      end
      
      %%%%% logical coincidneces--from logical traces
      
      % Test to see if each of a tank's two tubes has any logic pulse information
      if (EventData(i).pmt(k).logic_t0s(1) ~= -9999) & (EventData(i).pmt(k+1).logic_t0s(1) ~= -9999)
        clear l1 t1 t2;
        t1 = EventData(i).pmt(k).logic_t0s;
        t2 = EventData(i).pmt(k+1).logic_t0s;
        l1 = length(t1);
        l2 = length(t2);
        if l1<=l2
          for jj=1:l1
            clear dt imin;
            [dt imin] = min(abs(t2-t1(jj)));
            if dt<=lth
              EventData(i).lcoin(tank).t0s = [EventData(i).lcoin(tank).t0s; t1(jj) t2(imin)];
              EventData(i).lcoin(tank).N   = EventData(i).lcoin(tank).N + 1;
              t2(1:imin) = -9999;
            end
          end
        else
          for jj=1:l2
            clear dt imin;
            [dt imin] = min(abs(t1-t2(jj)));
            if dt<=lth
              EventData(i).lcoin(tank).t0s = [EventData(i).lcoin(tank).t0s; t1(imin) t2(jj)];
              EventData(i).lcoin(tank).N   = EventData(i).lcoin(tank).N + 1;
              t1(1:imin) = -9999;
            end
          end
        end
        if EventData(i).lcoin(tank).N ==0
          EventData(i).lcoin(tank).t0s = -9999;
        end
      else
        % if there are no possible logcial coincidences, fill lcoin structure with dummy values
        EventData(i).lcoin(tank).t0s = -9999;
      end
    end
  end




  % ~~~~~~~~~~ NOW WE SAVE THE DATA ~~~~~~~~~~~~
  disp('Percent Complete = 100!');
  
  ucsb_bool = false;
  if(ucsb_bool)
  if strcmp(dtype,'N')|strcmp(dtype,'n')|strcmp(dtype,'Neutron')|strcmp(dtype,'neutron')
    cd /net/neutron/data/neutron/data_runs/background/neutron/new_format/EventData/;
    disp('Saving Data in: /net/neutron/data/neutron/data_runs/background/neutron/new_format/EventData/');
  elseif strcmp(dtype,'M')|strcmp(dtype,'m')|strcmp(dtype,'Muon')|strcmp(dtype,'muon')
    cd /net/neutron/data/neutron/data_runs/background/muon/new_format/EventData/;
    disp('Saving Data in: /net/neutron/data/neutron/data_runs/background/muon/new_format/EventData/;');
  elseif strcmp(dtype,'co')|strcmp(dtype,'Co')|strcmp(dtype,'Co-60')|strcmp(dtype,'co-60')
    cd /net/neutron/data/neutron/data_runs/calibration/co_60/EventData/;
    disp('Saving Data in: /net/neutron/data/neutron/data_runs/calibration/co_60/EventData/');
  elseif strcmp(dtype,'cf')|strcmp(dtype,'Cf')|strcmp(dtype,'Cf-252')|strcmp(dtype,'cf-252')
    cd /net/neutron/data/neutron/data_runs/calibration/cf_252/EventData/;
    disp('Saving Data in: /net/neutron/data/neutron/data_runs/calibration/cf_252/EventData/');
  else
    cd /net/top/homes/cquinlan/matlab/DataAnalysis/data
    disp('Saving Data in: /net/top/homes/cquinlan/matlab/DataAnalysis/data');
  end
  
  save(['EventDataCoin_' RunInfo.SeriesNumber],'EventData','RunInfo');
  
  % back to analysis script folder
  cd(cwd);
  else
      RunInfo = 'undefined';
      t = datestr(clock, 30);
      save(['EventDataCoin_' t],'EventData');
  end
  
  disp('Well done good and faithful servant!');


