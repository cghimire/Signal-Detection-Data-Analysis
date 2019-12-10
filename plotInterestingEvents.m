% INPUT: EVENT INFORMATION
% an array of event structures - each event has fields 'isMuonSouth',c
% 'isMuonNorth', 'VmaxNE', 'VmaxNW', 'VmaxSE', 'VmaxSW', and 'eventNum'

% INPUT: NMM run information needed by the function 'plotEventTrace'
% 'plotEventTrace' calls this input neutronProcFile, so we'll use the same
% name here
function [] = plotInterestingEvents(eventInfo_arr, neutronProcFile)

persistent neutronProcFile_previous neutronProcInfo RunInfo
if isempty(neutronProcFile_previous) | ~strcmp(neutronProcFile, neutronProcFile_previous)
    neutronProcFile_previous = neutronProcFile;
    neutronProcInfo = load(neutronProcFile);
    RunInfo = neutronProcInfo.RunInfo;
end

uuid = char(java.util.UUID.randomUUID);
filename = ['/home/cghimire/muon_NMM_coinStudy/plots/allCleanNeutrons_sn' RunInfo.SeriesNumber '_' uuid '.pdf'];

% don't open a window to show the figure
% set(0,'DefaultFigureVisible','off');


% ////////////////////////////////////////////////////////////////
% evaluate the events, and make a plot if the maximum amplitude is
% neutron-like in at least one tank
% ////////////////////////////////////////////////////////////////

for ii=1:length(eventInfo_arr)
    
    % get an event struct
     thisEvent = eventInfo_arr(ii);
    
    % most of the events are muons - not clean neutron events
    makePlot = false;
    
    % test for a neutron-like amplitude in the north and south tank
    VmaxS = thisEvent.VmaxSE + thisEvent.VmaxSW;
    VmaxN = thisEvent.VmaxNW + thisEvent.VmaxNE;
    isNeutAmpS = VmaxS >0.05 & VmaxS < 0.3;
    isNeutAmpN = VmaxN> 0.05 & VmaxN < 0.3; 
    
    % if there's a (clean) neutron-like amplitude in at least one tank,
    % we'd like to plot that event
    makePlot = isNeutAmpS | isNeutAmpN;
    
    
    
    % make the plot if 'makePlot' is true
    % makePlot = true;
    if(makePlot)
    en = double(thisEvent.eventNum);
         [fig_zoom, fig_noZoom]= plotEventTrace(neutronProcFile,en);
        
      
 % save the figure (append it onto a single file?)
        export_fig(fig_zoom, filename, '-pdf', '-append');
        export_fig(fig_noZoom, filename, '-pdf', '-append');
        close(fig_zoom);
        close(fig_noZoom);
         
    end

end
% now that we're done, return MatLab to its default plotting
% set(0,'DefaultFigureVisible','on');
end