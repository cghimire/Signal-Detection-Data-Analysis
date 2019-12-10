function [h h2] = plotEventTrace(neutronProcFile,en)
  
% function [h_zoomedIN h_zoomedOUT] = plotEventTrace(en)
%
%
%

  cwd = pwd; 


persistent neutronProcFile_previous neutronProcInfo RunInfo EventData
if isempty(neutronProcFile_previous) | ~strcmp(neutronProcFile, neutronProcFile_previous)
    neutronProcInfo = load(neutronProcFile);
    RunInfo = neutronProcInfo.RunInfo;
    EventData = neutronProcInfo.EventData;
end
  
a= '/home/cghimire/muon_NMM_coinStudy/data/nMode/ucsb_data/trace_files/';
b = RunInfo.SeriesNumber;
dirName = [a b];
if strcmp(RunInfo.RunType(1),'M')
    cd(dirName);
    
    elseif strcmp(RunInfo.RunType(1),'N')
      cd(dirName);
end

   %{   
   elseif strcmp(RunInfo.RunType(1),'C')
      if strcmp(RunInfo.RunType(2),'o')
      cd /net/neutron/data/neutron/data_runs/calibration/co_60/trace_files/;
    elseif strcmp(RunInfo.RunType(2),'f')
      cd /net/neutron/data/neutron/data_runs/calibration/cf_252/trace_files/;
%}
  
  % ////////////////////////////////
  % which trace file should we load?  
  % it depends on the event number
  % ///////////////////////////////
  
  % the last file in the series breaks the pattern
  % find the 'enf' for the last file
  filelist = [dir(fullfile('.','*.mat'))];
  lastFileName = filelist(end).name;
  [start,finish] = regexp(lastFileName,'_0+[1-9][0-9]+');
  lastNumber = str2num(lastFileName(start+1:finish));
  broken_enf = floor(lastNumber/1000)+1;
  
  enf = floor((en-1)/1000) + 1;

  % the last file in the series breaks the pattern
  if enf == broken_enf
      % use the last filename for tf
      tf = lastFileName;
      
  % event numbers 1 - 10000
  elseif enf < 10
      tf = [RunInfo.SeriesNumber(1:9) '0000' num2str(enf) '000.mat'];
      
  % event numbers 10001 - 100000
  elseif enf < 100
      tf = [RunInfo.SeriesNumber(1:9) '000' num2str(enf) '000.mat'];
  end
  
  load(tf);
  
  % load the tracefile by hand
  % rawTraceFile = '/home/cghimire/lbcfbats/matlabInteractive/data/NrunTraces_20131030/20131030_00003000.mat';
  % load(rawTraceFile);
  
  ev = rem(en,1000);
  if ~ev
    ev = 1000;
  end
  data={data1(ev,:),data2(ev,:),data3(ev,:),data4(ev,:)};
  
  t = (RunInfo.TraceInfo.post + RunInfo.TraceInfo.dt - ...
       RunInfo.TraceInfo.ttime):RunInfo.TraceInfo.dt:RunInfo.TraceInfo.post;
   
  
  % matlab specifies colors with [r g b]
  % that's [red green blue]
  cols={[0 0 1], [0 0 1], [1 0.5 0], [1 0.5 0]};   
  cols2={'r', [1 0 0], [0 1 0.5], [0 1 0.5]};
  B = EventData(en).Nevents;
  leg={'SE pmt 32', 'SW pmt 34', 'NW pmt 37', 'NE pmt 40'};
  
  
  for j=1:2
    nc(j) = EventData(en).dcoin(j).N;
  end
  
  for m=1:4
    leg{m} = [leg{m} ', ' num2str(B(m)) ' Pulses, ' num2str(nc(ceil(m/2))) ' Coins'];
    %% leg{m} = [leg{m} ', ' num2str(B(m)) ' Pulses, '];
  end
  
  %% position of plot legends
  %% [x y width height]
  pos{1} = [.09 .731 .83 .214];
  pos{2} = [.09 .512 .83 .214];
  pos{3} = [.09 .293 .83 .214];
  pos{4} = [.09 .074 .83 .214];
  
  h=figure;
  set(gcf, 'position', [90 150 850 800]);
  clf;
  ts = EventData(en).time;
  
  %% loop over each PMT
  %% (there are four PMTs in the NMM)
  for ii=1:4
    ah(ii)=axes('position', pos{ii});
    p{ii}=plot(t,data{ii}, 'k','color',cols{ii});
    hold on;
    ax{ii}=axis;
    if EventData(en).sync==1
      % mark _all_ pulses found by findTrace
      if EventData(en).pmt(ii).t0s(1) ~=-9999
        for j=1:length(EventData(en).pmt(ii).t0s)
          plot(EventData(en).pmt(ii).t0s(j),0,'x','markersize',12,'color',cols2{ii});
        end
      end
   
 % mark only coincident pulses found by findTrace
      if EventData(en).pmt(ii).logic_t0s(1) ~=-9999
        for j=1:length(EventData(en).pmt(ii).logic_t0s)
          plot(EventData(en).pmt(ii).logic_t0s(j),0,'o','markersize',13,'color',cols2{ii});
        end
      end
    end
    
    % re-draw the actual PMT trace
    % so we can see it over the markers!
    p{ii}=plot(t,data{ii}, 'k','color',cols{ii});

    % make the plot look nice
    if (ax{ii}(3) < -.3);
      ax{ii}(3) = -.3;
    end
    axis([-100.2 100 ax{ii}(3:4)]);
    set(gca, 'fontsize', 14, 'fontweight', 'b');
    if ii==1
      title([ts{1}(1:8) '-' ts{1}(10:end) ' - Event ' num2str(en)]);
    elseif (ii==3)
      ylabel('Amplitude (V)');
    end
    if (ii < 4)
      set(gca, 'xticklabel', []);
    else
      xlabel('Time Relative to Trigger (\mus)');
    end
    if (ii == 2 || ii == 4)
      set(gca, 'yaxislocation', 'right');
    end;
    grid on;
    l(ii)=legend(leg{ii});
    %set(gca, 'xtick', [-100:20:100]);
  end
  set(gcf, 'paperpositionmode', 'auto');
    
  %% make the zoomed-in figure
  %% first copy the first figure h
  h = gcf;
  h2 = figure;
  copyobj(get(h,'children'),h2);
  axInFig = findall(h, 'type', 'axes', 'tag', '');
  set(axInFig(:), 'ylim', [0 0.1]);
  legInFig = findall(h, 'type','axes', 'tag', 'legend');
  delete(legInFig);
  set(h2,'Position',[100 100 1050 850]);
  
  %%%%%finding and labeling recorded events%%%%%%%%
  %{
  %lcols = {[1 0.5 0],'r',rgb('dark green'),'b'};
  lcols= {[1 0.5 0],'r',[0.1 1 0.1],'b'};
  for m=1:4
    if B(m)>0
      axes(ah(m));
      for k=1:B(m)
        clear ii l;
        ii = EventData(en).pmt(m).index(k);
        l = line(t(ii)*[1 1],[-.5 0]);
        set(l,'color',lcols{m});
        H(m,k) =(round(1000*(EventData(en).pmt(m).amps(k)))/1000);
        T = text(-108+12*k,ax{m}(4)*.85,num2str(H(m,k)));
        set(T,'fontsize',11,'fontweight','b');
      end
    end
  end
  %}
  %%%labeling Coincidence%%%%%
  
  ccols = {{[1 0.5 0],'r'},{[0.1 1 0.1],'b'}};
  for j=1:2
    N(j) = EventData(en).dcoin(j).N;
    for jj=1:2
      for jjj=1:N(j)
        RI{j}(jjj,jj) = EventData(en).dcoin(j).t0s(jjj,jj);
        if j == 1 & jj == 1
          axes(ah(1)); 
          a = ax{1}(4);
        elseif j == 1 & jj == 2
          axes(ah(2)); 
          a = ax{2}(4);
        elseif j == 2 & jj == 1
          axes(ah(3));
          a = ax{3}(4);
        elseif j == 2 & jj == 2
          axes(ah(4));
          a = ax{4}(4);
        end
        plot(RI{j}(jjj,jj),a*.5,'g*','color',ccols{j}{jj},'markersize',10);
      end
    end
  end
  
  
  cd(cwd);
  