function [muonTime] = findMuons(readFile)


% Load the veto shield data from specified file.
strVals=readLBCF_File(readFile,0,0);
C= uint64(strVals(: ,7:9));

% filter out non zero rows
M=C(all(C,2),:);

Time = M(:,3);

% Identify the hit stretcher/channel combinations.

    for ii=1:32
        Results_panel37(:,ii) = bitand(M(:,2),2^(ii-1))>0;  % Top Panel 37 stretcher 8, channels logical hit records.
        Results_panel38(:,ii) = bitand(M(:,1),2^(ii-1))>0;  % Same for bottom Panel 38 stretcher 7.
    end
    
      
  % stretcher 2nd!front-facing panel.
        a1f=1:2:15;
        b1f=2:2:16;
        d1f=3:2:15;
        e1f=2:2:14;
        c1f1=1:2:13;
        c1f2=4:2:16;
        
        
        cBoth1f1= Results_panel37(:,a1f)>0 & Results_panel37(:,b1f)>0;
        cBoth1f2= Results_panel37(:,d1f)>0 & Results_panel37(:,e1f)>0;
        cBoth1f2(:,8)=0;
     
        cBoth1f3= Results_panel37(:,c1f1)>0 & Results_panel37(:,c1f2)>0;
        cBoth1f3(:,8) = 0;
        
        cBoth_stretcher1f=cBoth1f1|cBoth1f2|cBoth1f3;
       
      
        % also stretcher 2nd!back-facing panel.
        a1b=17:2:31;
        b1b=18:2:32;
        d1b=19:2:31;
        e1b=18:2:30;
        c1b1=17:2:29;
        c1b2=20:2:32;

        cBoth1b1= Results_panel37(:,a1b)>0 & Results_panel37(:,b1b)>0;
        cBoth1b2= Results_panel37(:,d1b)>0 & Results_panel37(:,e1b)>0;
        cBoth1b2(:,8)=0;
        cBoth1b3= Results_panel37(:,c1b1)>0 & Results_panel37(:,c1b2)>0;
        cBoth1b3(:,8) = 0;
        
        cBoth_stretcher1b = cBoth1b1 |cBoth1b2|cBoth1b3 ;
        
        % This gives triggerable condition for top panel 37.
        cBoth_stretcher1= cBoth_stretcher1f | cBoth_stretcher1b;
    
        
        
    
        
 % for stretcher 1st:front facing of bottom panel 38.
  
        a2f=1:2:15;
        b2f=2:2:16;
        d2f=3:2:15;
        e2f=2:2:14;
        c2f1=1:2:13;
        c2f2=4:2:16;
        cBoth2f1= Results_panel38(:,a2f)>0 & Results_panel38(:,b2f)>0;
        cBoth2f2=Results_panel38(:,d2f)>0 & Results_panel38(:,e2f)>0;
        cBoth2f2(:,8)=0;
        
        cBoth2f3= Results_panel38(:,c2f1)>0 & Results_panel38(:,c2f2)>0;
        cBoth2f3(:,8)= 0;
     
        cBoth_stretcher2f = cBoth2f1 |cBoth2f2|cBoth2f3;
   
    
    
    % for panel 38 back facing
        a2b = 17:2:31;
        b2b = 18:2:32;
        d2b = 19:2:31;
        e2b = 18:2:30;
        c2b1 = 17:2:29;
        c2b2 = 20:2:32;
        
        cBoth2b1= Results_panel38(:,a2b)>0 & Results_panel38(:,b2b)>0;
        cBoth2b2=Results_panel38(:,d2b)>0 & Results_panel38(:,e2b)>0;
        cBoth2b2(:,8)=0;
        cBoth2b3= Results_panel38(:,c2b1)>0 & Results_panel38(:,c2b2)>0;
        cBoth2b3(:,8)= 0; 
        cBoth_stretcher2b= cBoth2b1| cBoth2b2|cBoth2b3;
      
        
        % OR of front and back facing of panel 38
        
        cBoth_stretcher2 = cBoth_stretcher2f | cBoth_stretcher2b;
        
        % combine the result of two pannels
        % Do AND of both channel to fit in our triger condition
     
      
      
      muonArray = any(cBoth_stretcher1,2) & any(cBoth_stretcher2,2);
    

     
          
      
      muonTime_arr = M(muonArray,3);
       
        % readFile is the user-input nameof the file
       % it's a string!
       [pathstr,name,ext] = fileparts(readFile);
       shieldDataFile = name;
      
        for j = 1:length(muonTime_arr)
            
            muonTime(j,1).timeStamp = muonTime_arr(j,1);
            muonTime(j,1).shieldDataFile  = shieldDataFile;
        end
            
            
       %{ 
        if length(muonTime) > 0
           disp(['there were ' num2str(length(muonTime))  'candidate of muons.  First time: ' num2str(muonTime(1)) ' Last time: ' num2str(muonTime(end))]);
        
           Number = length(muonTime);
           time = (muonTime(end)-muonTime(1))/1e6;
           triggerRate = (double(Number)/double(time))*60
        else 
           disp('No events looked like muons!');
        end  
  %}
        
       clearvars -except muonTime;
end

