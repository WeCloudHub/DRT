function Fail_Flag=wb_EEGfiles_GenerateDescription(IO_Path,FileName)
% Description: Generate description file for the EEG data file, 
%              supporting '*.set'、'*.cnt'、'*.EEG'、'*.vhdr'、'*.bdf'
% Param:
%   IO_Path : input and output path 
%   FileName: EEG data file name
% 
% Written by Yufan Zhang (zyf15816794709@163.com)
% $ 2020.2.25
% 
% -------------------------------------------------------------------------

%delete Suffix
file_count=find('.'==FileName);
Suffix=FileName(file_count:end);
FileName_NoSuffix=FileName(1:file_count-1);

EEGfile_Path=[IO_Path,FileName]; %gain the path of original file

Fail_Flag = 0 ; % 0:unknown  1:info fail  2:channel fail  3:event fail 4: success

switch Suffix
	case '.set' 
        %load the information from '*.set' file
        set=pop_loadset(FileName,IO_Path,'info');
        SamplingFrequency=set.srate;
        SamplingPointCount=set.pnts;
        RecordingDuration=set.xmax-set.xmin;
        EEGChannelCount=set.nbchan;
        Event=set.event;
        EventCount=length(Event);
        Epoch =set.epoch;
        EEGReference=set.ref;
        Fail_Flag = 4 ;
        
    case '.cnt'
        cnt=loadcnt(EEGfile_Path);
        SamplingFrequency=cnt.header.rate;
        SamplingPointCount=cnt.header.numsamples;
        RecordingDuration=cnt.header.xmax-cnt.header.xmin; 
        EEGChannelCount=cnt.header.nchannels;
        Event=cnt.event;
        EventCount=length(Event);
        Epoch=[];
        EEGReference=[];
        Fail_Flag = 4 ;
       
    case '.EEG'
        EEG = pop_loadeeg(EEGfile_Path); 
        SamplingFrequency=EEG.srate;
        SamplingPointCount=EEG.pnts;
        RecordingDuration=EEG.xmax-EEG.xmin; 
        EEGChannelCount=EEG.nbchan;
        Event=EEG.event;
        EventCount=length(EEG.event);
        Epoch=EEG.epoch;
        EpochCount=length(EEG.epoch);
        EEGReference=EEG.ref;
        Fail_Flag = 4 ;
        
    case {'.bdf','.edf'}
        bdf=pop_readbdf(EEGfile_Path);
        SamplingFrequency=bdf.srate;
        SamplingPointCount=bdf.pnts;
        RecordingDuration=bdf.xmax-bdf.xmin; 
        EEGChannelCount=bdf.nbchan;
        Event=bdf.event;
        EventCount=length(bdf.event);
        Epoch=bdf.epoch;
        EpochCount=length(bdf.epoch);
        EEGReference=bdf.ref;

    case '.gdf'
        gdf=pop_biosig(EEGfile_Path);
        SamplingFrequency=gdf.srate;
        SamplingPointCount=gdf.pnts;
        RecordingDuration=gdf.xmax-gdf.xmin; 
        EEGChannelCount=gdf.nbchan;
        Event=gdf.event;
        EventCount=length(gdf.event);
        Epoch=gdf.epoch;
        EpochCount=length(gdf.epoch);
        EEGReference=gdf.ref;

    case '.vhdr'
        vhdr=pop_loadbv(IO_Path,FileName); 
        SamplingFrequency=vhdr.srate;
        SamplingPointCount=vhdr.pnts;
        RecordingDuration=vhdr.xmax-vhdr.xmin; 
        EEGChannelCount=vhdr.nbchan;
        Event=vhdr.event;
        EventCount=length(Event);
        Epoch=vhdr.epoch;
        EpochCount=length(Epoch);
        EEGReference=vhdr.ref;
        Fail_Flag = 4 ;

    case '.mat' 
        srate=' ';
        data=pop_importdata('data',EEGfile_Path,'srate',str2num(srate),'dataformat','matlab');
        
        SamplingFrequency=srate;
        SamplingPointCount=data.pnts;
        RecordingDuration=data.xmax-data.xmin; 
        EEGChannelCount=data.nbchan;
        Event=data.event;
        EventCount=length(Event);
        Epoch=data.epoch;
        EpochCount=length(Epoch);
        EEGReference=data.ref;
        Fail_Flag = 4 ;
        
    otherwise
        return;
end;

%Generate json file  
NewFileName=[FileName_NoSuffix,'_info.json'];

DetailFile_Dir=[IO_Path,NewFileName];
fid = fopen(DetailFile_Dir, 'w+');

%fill the information in json file
% eeg_json.TaskName = 'null';
% eeg_json.Manufacturer = 'null';
% eeg_json.PowerLineFrequency = 'null';

try
    if isempty(SamplingFrequency) eeg_json.SamplingFrequency = 'null';
    else eeg_json.SamplingFrequency = [num2str(SamplingFrequency),'Hz'];
    end

    if isempty(SamplingPointCount) eeg_json.SamplingPointCount = 'null';
    else eeg_json.SamplingPointCount = SamplingPointCount ;
    end

    if isempty(RecordingDuration) || RecordingDuration == 0
        eeg_json.RecordingDuration = 'null';
    else
        eeg_json.RecordingDuration = [num2str(RecordingDuration),'s'];
    end

    eeg_json.RecordingType = 'null';

    if isempty(EEGReference) eeg_json.EEGReference = 'null';
    else eeg_json.EEGReference = EEGReference;
    end

    eeg_json.EEGGround = 'null';
    eeg_json.EEGPlacementScheme = 'null';

    if isempty(EEGChannelCount) eeg_json.EEGChannelCount = 'null';
    else eeg_json.EEGChannelCount = EEGChannelCount;
    end

    eeg_json.MiscChannelCount = 'null';
    eeg_json.TriggerChannelCount = 'null';

    if isempty(Event) eeg_json.event = 'null';
    else  eeg_json.event = EventCount;
    end

    if isempty(Epoch) eeg_json.epoch = 'null';
    else  eeg_json.epoch = EpochCount;
    end
    
    subJson = savejson('',eeg_json);
    fprintf(fid, '%s',subJson);
    
catch
    warning('Failed to generate *_info.json file');
    disp(['Failed: ',NewFileName]);
	Fail_Flag = 1 ; % 0:success  1:info fail  2:channel fail  3:event fail
end;


%----------------------------------------------------------------
%Generate tsv file about channels
channels_filename=[FileName_NoSuffix,'_channels.csv'];
channels_Dir=[IO_Path,channels_filename];
fid = fopen(channels_Dir, 'w+');

try
    for i=1:EEGChannelCount  
        
        switch Suffix
            case '.set' 
                if i == 1 
                    fprintf(fid, ['label',',','X',',','Y',',','Z',',','sph_theta',',','sph_phi',',','sph_radius',',','theta',',','radius',',','ref',',','type',',','urchan','\n']); % Add first line 
                end

                if isempty(set.chanlocs(i).labels) label='null';
                else label=set.chanlocs(i).labels;
                end

                X=set.chanlocs(i).X ;
                Y=set.chanlocs(i).Y ;
                Z=set.chanlocs(i).Z ;
                sph_theta=set.chanlocs(i).sph_theta ;
                sph_phi=set.chanlocs(i).sph_phi ;
                sph_radius=set.chanlocs(i).sph_radius ;
                theta=set.chanlocs(i).theta ;
                radius=set.chanlocs(i).radius ;
                ref=set.chanlocs(i).ref ;
                type=set.chanlocs(i).type ;
                urchan=set.chanlocs(i).urchan ;
                fprintf(fid, ['%s',',','%f',',','%f',',','%f',',','%f',',','%f',',','%f',',','%f',',','%f',',','%s',',','%f',',','%f','\n'],label,X,Y,Z,sph_theta,sph_phi,sph_radius,theta,radius,ref,type,urchan );
                
            case '.cnt'
                if i == 1 
                    fprintf(fid, ['label',',','coordinate',',','reference','\n']); % Add first line 
                end
                
                if isempty(cnt.electloc(i).lab) label='null';
                else label=cnt.electloc(i).lab;
                end
                if ( isempty(cnt.electloc(i).x_coord)|isempty(cnt.electloc(i).y_coord) ) coordinate='null';
                else coordinate=['(',mat2str(cnt.electloc(i).x_coord),',',mat2str(cnt.electloc(i).y_coord),')'];
                end
                ref=cnt.electloc(i).reference ;
                fprintf(fid, ['%s',',','%s',',','%s','\n'], label , coordinate , ref );
                
            case '.EEG'
                if i == 1
                    fprintf(fid, ['label',',','ref',',','theta',',','radius',',','X',',','Y',',','Z',',','sph_theta',',','sph_phi',',','sph_radius',',','type',',','urchan','\n']); % Add first line 
                end

                label=EEG.chanlocs(i).labels;
                ref=EEG.chanlocs(i).ref ;
                theta=EEG.chanlocs(i).theta ;
                radius=EEG.chanlocs(i).radius ;
                X=EEG.chanlocs(i).X ;
                Y=EEG.chanlocs(i).Y ;
                Z=EEG.chanlocs(i).Z ;
                sph_theta=EEG.chanlocs(i).sph_theta;
                sph_phi=EEG.chanlocs(i).sph_phi ;
                sph_radius=EEG.chanlocs(i).sph_radius ;
                type=EEG.chanlocs(i).type ;
                urchan=EEG.chanlocs(i).urchan ;
                fprintf(fid, ['%s',',','%s',',','%f',',','%f',',','%f',',','%f',',','%f',',','%f',',','%f',',','%f',',','%f',',','%f','\n'],label,ref,theta,radius,X,Y,Z,sph_theta,sph_phi,sph_radius,type,urchan ); 
 
             case {'.bdf','.edf'}
                if i == 1
                    fprintf(fid, ['label',',','ref',',','theta',',','radius',',','X',',','Y',',','Z',',','sph_theta',',','sph_phi',',','sph_radius',',','type',',','urchan','\n']); % Add first line 
                end
                            
                label=bdf.chanlocs(i).labels;
                sph_radius=bdf.chanlocs(i).sph_radius ;
                sph_theta=bdf.chanlocs(i).sph_theta ;
                sph_phi=bdf.chanlocs(i).sph_phi ;
                theta=bdf.chanlocs(i).theta ;
                radius=bdf.chanlocs(i).radius ;
                X=bdf.chanlocs(i).X ;
                Y=bdf.chanlocs(i).Y ;
                Z=bdf.chanlocs(i).Z ;
                type=bdf.chanlocs(i).type ;
                ref=bdf.chanlocs(i).ref ;
                urchan=bdf.chanlocs(i).urchan ;          
                fprintf(fid, ['%s',',','%f',',','%f',',','%f',',','%f',',','%f',',','%f',',','%f',',','%f',',','%f',',','%f',',','%f','\n'],label,ref,theta,radius,X,Y,Z,sph_theta,sph_phi,sph_radius,type,urchan ); 
                
            case '.gdf'
                if i == 1
                    fprintf(fid, ['label',',','ref',',','theta',',','radius',',','X',',','Y',',','Z',',','sph_theta',',','sph_phi',',','sph_radius',',','type',',','urchan','\n']); % Add first line 
                end
                          
                label=gdf.chanlocs(i).labels;
                sph_radius=gdf.chanlocs(i).sph_radius ;
                sph_theta=gdf.chanlocs(i).sph_theta ;
                sph_phi=gdf.chanlocs(i).sph_phi ;
                theta=gdf.chanlocs(i).theta ;
                radius=gdf.chanlocs(i).radius ;
                X=gdf.chanlocs(i).X ;
                Y=gdf.chanlocs(i).Y ;
                Z=gdf.chanlocs(i).Z ;
                type=gdf.chanlocs(i).type ;
                ref=gdf.chanlocs(i).ref ;
                urchan=gdf.chanlocs(i).urchan ;          
                fprintf(fid, ['%s',',','%f',',','%f',',','%f',',','%f',',','%f',',','%f',',','%f',',','%f',',','%f',',','%f',',','%f','\n'],label,ref,theta,radius,X,Y,Z,sph_theta,sph_phi,sph_radius,type,urchan ); 
                
            case '.vhdr'
                if i == 1
                    fprintf(fid, ['label',',','sph_radius',',','sph_theta',',','sph_phi',',','theta',',','radius',',','X',',','Y',',','Z',',','type',',','ref',',','urchan','\n']); % Add first line 
                end
             
                label=vhdr.chanlocs(i).labels;
                sph_radius=vhdr.chanlocs(i).sph_radius ;
                sph_theta=vhdr.chanlocs(i).sph_theta ;
                sph_phi=vhdr.chanlocs(i).sph_phi ;
                theta=vhdr.chanlocs(i).theta ;
                radius=vhdr.chanlocs(i).radius ;
                X=vhdr.chanlocs(i).X ;
                Y=vhdr.chanlocs(i).Y ;
                Z=vhdr.chanlocs(i).Z ;
                type=vhdr.chanlocs(i).type ;
                ref=vhdr.chanlocs(i).ref ;
                urchan=vhdr.chanlocs(i).urchan ;          
                fprintf(fid, ['%s',',','%f',',','%f',',','%f',',','%f',',','%f',',','%f',',','%f',',','%f',',','%f',',','%f',',','%f','\n'],label,sph_radius,sph_theta,sph_phi,theta,radius,X,Y,Z,type,ref,urchan );  
            case '.mat'     
                fprintf('"*.mat" is unable to generate the list file of channels ');  
            case '.txt'     
                fprintf('"*.mat" is unable to generate the list file of channels ');      
            otherwise
        end;       
               
    end
catch
    warning('Failed to generate *_channel.csv file');
    disp(['Failed: ',channels_filename]);
	Fail_Flag = 2 ; % 0:success  1:info fail  2:channel fail  3:event fail
end
    


%----------------------------------------------------------------
%Generate tsv file about events
events_filename=[FileName_NoSuffix,'_events.csv'];
events_Dir=[IO_Path,events_filename];
fid = fopen(events_Dir, 'w+');

try
    for i=1:EventCount 
        switch Suffix
            case '.set'  
                if i == 1 
                    fprintf(fid, ['type',',','latency',',','duration','\n']); % Add first line 
                end              

                if isa(set.event(i).type,'numeric')  %if set.event(i).type is num, num2str
                    type = num2str(set.event(i).type) ;
                else
                    type = set.event(i).type;
                end 
                latency = set.event(i).latency ;
                if ~isfield(set.event(i),'duration') duration = 'null';
                else  duration = set.event(i).duration ;
                end
                fprintf(fid, ['%s',',','%d',',','%s','\n'], type , latency , duration );
                
            case '.cnt' 
                if i == 1
                    fprintf(fid, ['stimtype',',','accept_ev1',',','offset',',','latency',',','epochevent',',','accuracy','\n']); % Add first line 
                end
                 
                if isa(cnt.event(i).stimtype,'numeric')  %if cnt.event(i).type is num, num2str
                    stimtype = num2str(cnt.event(i).stimtype) ;
                else
                    stimtype = cnt.event(i).stimtype;
                end 
                accept_ev1 = cnt.event(i).accept_ev1 ;
                offset = cnt.event(i).offset ;
                latency = cnt.event(i).latency ;
                epochevent = cnt.event(i).epochevent ;
                accuracy = cnt.event(i).accuracy ;
                fprintf(fid, ['%s',',','%d',',','%d',',','%d',',','%d',',','%d','\n'],stimtype,accept_ev1,offset,latency,epochevent,accuracy );
             
            case '.EEG' 
                if i == 1 
                    fprintf(fid, ['type',',','latency',',','duration',',','accept',',','response',',','epochtype',',','urevent','\n']); % Add first line 
                end
               
                if isa(EEG.event(i).type,'numeric')  %if cnt.event(i).type is num, num2str
                    type = num2str(EEG.event(i).type) ;
                else
                    type = EEG.event(i).type;
                end 
                
                latency = EEG.event(i).latency ;
                duration = EEG.event(i).duration ;
                accept = EEG.event(i).accept ;
                response = EEG.event(i).response ;
                epochtype = EEG.event(i).epochtype ;
                urevent = EEG.event(i).urevent ;
                fprintf(fid, ['%s',',','%f',',','%f',',','%f',',','%f',',','%f',',','%f','\n'],type,latency,duration,accept,response,epochtype,urevent );                
 
            case {'.bdf','.edf'}
                if i == 1 
                    fprintf(fid, ['type',',','latency',',','duration',',','accept',',','response',',','epochtype',',','urevent','\n']); % Add first line 
                end
                
                if isa(bdf.event(i).type,'numeric')  %if cnt.event(i).type is num, num2str
                    type = num2str(bdf.event(i).type) ;
                else
                    type = bdf.event(i).type;
                end 
                
                bdf.event(i)
                
                latency = bdf.event(i).latency ;
                duration = bdf.event(i).duration ;
                accept = bdf.event(i).accept ;
                response = bdf.event(i).response ;
                epochtype = bdf.event(i).epochtype ;
                urevent = bdf.event(i).urevent ;
                fprintf(fid, ['%s',',','%f',',','%f',',','%f',',','%f',',','%f',',','%f','\n'],type,latency,duration,accept,response,epochtype,urevent);  
                
            case '.gdf' 
                if i == 1 
                    fprintf(fid, ['type',',','latency',',','duration',',','urevent','\n']); % Add first line 
                end
                                
                if isa(gdf.event(i).type,'numeric')  %if cnt.event(i).type is num, num2str
                    type = num2str(gdf.event(i).type) ;
                else
                    type = gdf.event(i).type;
                end 
                
                latency = gdf.event(i).latency ;
                duration = gdf.event(i).duration ;
                urevent = gdf.event(i).urevent ;
                fprintf(fid, ['%s',',','%f',',','%f',',','%f','\n'],type,latency,duration,urevent);  
                
            case '.vhdr' 
                if i == 1 
                    fprintf(fid, ['latency',',','duration',',','channel',',','bvtime',',','bvmknum',',','type',',','code',',','urevent','\n']); % Add first line 
                end
               
                latency = vhdr.event(i).latency ;
                duration = vhdr.event(i).duration ;
                channel = vhdr.event(i).channel ;
                bvtime = vhdr.event(i).bvtime ;
                bvmknum = vhdr.event(i).bvmknum ;
                if isa(vhdr.event(i).type,'numeric')  %if cnt.event(i).type is num, num2str
                    type = num2str(vhdr.event(i).type) ;
                else
                    type = vhdr.event(i).type;
                end 
                code = vhdr.event(i).code ;
                urevent = vhdr.event(i).urevent ;
                fprintf(fid, ['%d',',','%d',',','%d',',','%d',',','%d',',','%s',',','%s',',','%d','\n'],latency,duration,channel,bvtime,bvmknum,type,code,urevent );    
                
             case '.mat'     
                warning('"*.mat" is unable to generate the list file of events ');  
                disp(['Failed: ',events_filename]);
                Fail_Flag = 3 ; % 0:success  1:info fail  2:channel fail  3:event fail
             case '.txt'     
                warning('"*.txt" is unable to generate the list file of events ');
                disp(['Failed: ',events_filename]);
                Fail_Flag = 3 ; % 0:success  1:info fail  2:channel fail  3:event fail
             otherwise
        end
    end
catch
    warning('Failed to generate *_event.csv file');
    disp(['Failed: ',events_filename]);
    Fail_Flag = 3 ; % 0:success  1:info fail  2:channel fail  3:event fail
end

end

    
