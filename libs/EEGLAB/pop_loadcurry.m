function [EEG, command] = pop_loadcurry(fullfilename, varargin)
%   Import a Neuroscan Curry file into EEGLAB. Currently supports Curry6
%   and Curry7 data files.
%
%   Input Parameters:
%        1    Specify the filename of the Curry file (extension should be either .dap, .dat, or .rs3). 
%
%   Example Code:
%
%       >> EEG = pop_loadcurry;   % an interactive uigetfile window
%       >> EEG = pop_loadcurry('C:\Studies\File1.dap');    % no pop-up window 
%
%   Author for reading into Matlab: Neuroscan 
%   Author for translating to EEGLAB: Matthew B. Pontifex, Health Behaviors and Cognition Laboratory, Michigan State University, August 26, 2015

    command = '';
    EEG = [];
    EEG = eeg_emptyset;
    
    if nargin < 1 % No file was identified in the call

        [filename, filepath] = uigetfile('*.dap;*.DAP;*.rs3;*.RS3', 'Choose a Neuroscan Curry file -- pop_loadcurry()'); 
        drawnow;
        if filename == 0; return; end;
        [pathstr,name,ext] = fileparts([filepath, filename]);
        fullfilename = [filepath, filename];
        guicall = 1;
    else
        
        [pathstr,name,ext] = fileparts(fullfilename);
        filename = [name,ext];
        filepath = [pathstr, filesep];
        guicall = 0;
    end
    file = [pathstr, filesep, name];
    
    % Curry7 Files are triplets
    boolfiles = 1;
    if (exist([file '.dap'], 'file') == 0) || (exist([file '.dat'], 'file') == 0) || (exist([file '.rs3'], 'file') == 0)
        boolfiles = 0;
        error('Error in pop_loadcurry(): The requested filename "%s" in "%s" does not have all three file components (.dap, .dat, .rs3) created by Curry. ', name, filepath)
    end
        
    if (boolfiles == 1)

        %% Provided by Neuroscan enclosed within Program Files Folder for Curry7
        % Received updated version on 9-22-2015 from Michael Wagner, Ph.D., Senior Scientist, Compumedics Germany GmbH, Heußweg 25, 20255 Hamburg, Germany
        
        % read parameters from dap file
        fid = fopen([file '.dap'],'rt');
        if (fid == -1)
           error('Error in pop_loadcurry(): Unable to open file.') 
        end
        cell = textscan(fid,'%s','whitespace','','endofline','');
        fclose(fid);
        cont = cell2mat(cell{1});

        % read parameters from dap file
        % tokens (second line is for Curry 6 notation)
        tok = { 'NumSamples'; 'NumChannels'; 'NumTrials'; 'SampleFreqHz';  'TriggerOffsetUsec';  'DataFormat'; 'DataSampOrder' 
                'NUM_SAMPLES';'NUM_CHANNELS';'NUM_TRIALS';'SAMPLE_FREQ_HZ';'TRIGGER_OFFSET_USEC';'DATA_FORMAT';'DATA_SAMP_ORDER' };

        % scan in cell 1 for keywords - all keywords must exist!
        nt = size(tok,1);
        a = zeros(nt,1);
        for i = 1:nt
             ctok = tok{i,1};
             ix = strfind(cont,ctok);
             if ~isempty ( ix )
                 text = sscanf(cont(ix+numel(ctok):end),' = %s');     % skip =
                 if strcmp ( text,'ASCII' ) || strcmp ( text,'CHAN' ) % test for alphanumeric values
                     a(i) = 1;
                 else 
                     c = sscanf(text,'%f');         % try to read a number
                     if ~isempty ( c )
                         a(i) = c;                  % assign if it was a number
                     end
                 end
             end 
        end
        
        % derived variables. numbers (1) (2) etc are the token numbers
        nSamples    = a(1)+a(1+nt/2);
        nChannels   = a(2)+a(2+nt/2);
        nTrials     = a(3)+a(3+nt/2);
        fFrequency  = a(4)+a(4+nt/2);
        fOffsetUsec = a(5)+a(5+nt/2);
        nASCII      = a(6)+a(6+nt/2);
        nMultiplex  = a(7)+a(7+nt/2);

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % open rs3 file
        fid = fopen([file '.rs3'],'rt');
        if (fid == -1)
           error('Error in pop_loadcurry(): Unable to open file.') 
        end
        cell = textscan(fid,'%s','whitespace','','endofline','');
        fclose(fid);
        cont = cell2mat(cell{1});

        % read labels from rs3 file
        % initialize labels
        labels = num2cell(1:nChannels);

        for i = 1:nChannels
            text = sprintf('EEG%d',i);
            labels(i) = cellstr(text);
        end

        % scan in cell 1 for LABELS (occurs four times per channel group)
        ix = strfind(cont,'LABELS');
        nt = size(ix,2);
        nc = 0;

        for i = 4:4:nt                                                      % loop over channel groups
            newlines = ix(i-1) - 1 + strfind(cont(ix(i-1):end),char(10));   % newline
            last = nChannels - nc;
            for j = 1:last                                                  % loop over labels
                text = cont(newlines(j)+1:newlines(j+1)-1);
                if isempty(strfind(text,'END_LIST'))
                    nc = nc + 1;
                    labels(nc) = cellstr(text);
                else 
                    break
                end
            end 
        end

        % read sensor locations from rs3 file
        % initialize sensor locations
        sensorpos = zeros(3,0);

        % scan in cell 1 for SENSORS (occurs four times per channel group)
        ix = strfind(cont,'SENSORS');

        newlines = ix(3) - 1 + strfind(cont(ix(3):ix(4)),char(10));     % newline
        last = size(newlines,2)-1;
        for j = 1:last                                                  % loop over labels
            text = cont(newlines(j)+1:newlines(j+1)-1);
            tcell = textscan(text,'%f');                           
            posx = tcell{1}(1);
            posy = tcell{1}(2);
            posz = tcell{1}(3);
            sensorpos = cat ( 2, sensorpos, [ posx; posy; posz ] );
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % read events from cef/ceo file
        % initialize events
        ne = 0;                                                             % number of events
        events = zeros(4,0);
        annotations = cellstr('empty');

        % find appropriate file
        fid = fopen([file '.cef'],'rt');

        if fid < 0
            fid = fopen([file '.ceo'],'rt');
        end

        if fid >= 0
            cell = textscan(fid,'%s','whitespace','','endofline','');
            fclose(fid);
            cont = cell2mat(cell{1});

            % scan in cell 1 for NUMBER_LIST (occurs five times)
            ix = strfind(cont,'NUMBER_LIST');

            newlines = ix(4) - 1 + strfind(cont(ix(4):ix(5)),char(10));     % newline
            last = size(newlines,2)-1;
            for j = 1:last                                                  % loop over labels
                text = cont(newlines(j)+1:newlines(j+1)-1);
                tcell = textscan(text,'%d');                           
                sample = tcell{1}(1);                                       % access more content using different columns
                type = tcell{1}(3);
                startsample = tcell{1}(5);
                endsample = tcell{1}(6);
                ne = ne + 1;
                events = cat ( 2, events, [ sample; type; startsample; endsample ] );
            end

            % scan in cell 1 for REMARK_LIST (occurs five times)
            ix = strfind(cont,'REMARK_LIST');
            na = 0;

            newlines = ix(4) - 1 + strfind(cont(ix(4):ix(5)),char(10));     % newline
            last = size(newlines,2)-1;
            for j = 1:last                                                  % loop over labels
                text = cont(newlines(j)+1:newlines(j+1)-1);
                na = na + 1;
                annotations(na) = cellstr(text);
            end    
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % read dat file
        if nASCII == 1
            fid = fopen([file '.dat'],'rt');
            if (fid == -1)
               error('Error in pop_loadcurry(): Unable to open file.') 
            end
            cell = textscan(fid,'%f',nChannels*nSamples*nTrials);
            fclose(fid);
            data = reshape([cell{1}],nChannels,nSamples*nTrials);
        else
            fid = fopen([file '.dat'],'rb');
            if (fid == -1)
               error('Error in pop_loadcurry(): Unable to open file.') 
            end
            data = fread(fid,[nChannels,nSamples*nTrials],'float32');
            fclose(fid);
        end

        % transpose?
        if nMultiplex == 1
            data = data';
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % time axis
        time = linspace(fOffsetUsec/1000,fOffsetUsec/1000+(nSamples*nTrials-1)*1000/fFrequency,nSamples*nTrials);

        %% Created to take this data and place it into EEGLAB format (v13.4.4b)

        EEG.trials = nTrials;
        EEG.pnts = nSamples;
        EEG.srate = fFrequency;
        EEG.times = time;
        EEG.data = data;
        EEG.xmin = 0;
        EEG.xmax = (EEG.pnts-1)/EEG.srate+EEG.xmin;
        
        % Populate channel labels
        EEG.chanlocs = struct('labels', [], 'ref', [], 'theta', [], 'radius', [], 'X', [], 'Y', [], 'Z', [],'sph_theta', [], 'sph_phi', [], 'sph_radius', [], 'type', [], 'urchan', []);
        for cC = 1:(numel(labels))
            EEG.chanlocs(cC).labels = char(upper(labels(cC))); % Convert labels to uppercase and store as character array string
            EEG.chanlocs(cC).urchan = cC;
        end
        
%         % Populate channel locations
%         % LPS sensor system:
%         % from right towards left, 
%         % from anterior towards posterior, 
%         % from inferior towards superior
%         
%         % MATLAB/EEGLAB system:
%         % x is towards the nose, 
%         % y is towards the left ear, 
%         % z towards the vertex.
%         
%         try, sensorpos; booler = 0; catch; booler = 1; end
%         if (booler == 0)
%             for cC = 1:size(sensorpos,2)
%                EEG.chanlocs(cC).Y = sensorpos(1,cC); 
%                EEG.chanlocs(cC).X = sensorpos(2,cC)*-1; 
%                EEG.chanlocs(cC).Z = sensorpos(3,cC); 
%             end
%             % Populate other systems based upon these values
%             EEG.chanlocs = convertlocs( EEG.chanlocs, 'auto');
%         end
%         THE CODE ABOVE WORKS, BUT THE NUMBERS DO NOT FIT THE HEAD MODEL IN EEGLAB

         % Determine if Triggers are present
        if ~isempty(find(strcmpi(labels,'Trigger')))
            
            % Remove baseline from trigger channel
            EEG.data(find(strcmpi(labels,'Trigger')),:) = EEG.data(find(strcmpi(labels,'Trigger')),:)-EEG.data(find(strcmpi(labels,'Trigger')),1); 

            % Populate list based on values above 0, triggers may last more than one sample
            templat = find(EEG.data(find(strcmpi(labels,'Trigger')),:)>0);
            templatrem = [];
            for cC = 2:numel(templat)
                % If the Time index is one off of the previous Time index
                if (find(EEG.times==templat(cC)) == (find(EEG.times==templat(cC-1))+1))
                   templatrem(end+1) = templat(cC);
                end
            end
            templat = setdiff(templat,templatrem);
            if ~isempty(templat)
                EEG.event = struct('type', [], 'latency', [], 'urevent', []);
                EEG.urevent = struct('type', [], 'latency', []);
                % Populate event list
                for cC = 1:numel(templat)
                    EEG.event(cC).urevent = cC;
                    EEG.event(cC).type = EEG.data(find(strcmpi(labels,'Trigger')),templat(cC));
                    EEG.urevent(cC).type = EEG.event(cC).type;
                    EEG.event(cC).latency = templat(cC);
                    EEG.urevent(cC).latency = EEG.event(cC).latency;
                end
            end
            
            % Remove Trigger Channel
            EEG.data(find(strcmpi(labels,'TRIGGER')),:) = [];
            EEG.chanlocs(find(strcmpi(labels,'TRIGGER'))) = [];
        end
        
        % Check if event list is populated as well
        if ~isempty(events)
            if isempty(EEG.event) % If no event structures exist
                EEG.event = struct('type', [], 'latency', [], 'urevent', []);
                EEG.urevent = struct('type', [], 'latency', []);
            end
            % Populate event list
            for cC = 1:size(events,2)
                
                % This information should already be in from when the
                % trigger channel was screened
                % But checking just to be safe.
                
                % Find time index for latency
                timeindex = find(EEG.times==events(1,cC));
                try
                   uptime = EEG.times(1,timeindex+1);
                catch
                   uptime = []; 
                end
                try
                    downtime = EEG.times(1,timeindex-1);
                catch
                    downtime = [];
                end
                % Search for exact match
                temp = find([EEG.event.latency]==events(1,cC));
                if isempty(temp) && ~isempty(uptime)
                    temp = find([EEG.event.latency]==uptime);
                    if (EEG.event(temp).type == events(2,cC))
                        EEG.event(temp).latency = events(1,cC); % Replace with marked latency
                    else
                       temp = []; 
                    end
                end
                if isempty(temp) && ~isempty(downtime)
                    temp = find([EEG.event.latency]==downtime);
                    if (EEG.event(temp).type == events(2,cC)) % If the type matches
                        EEG.event(temp).latency = events(1,cC); % Replace with marked latency
                    else
                       temp = []; 
                    end
                end
                if isempty(temp) % match was not found within 1 sample point on either side.
                    
                    lastindex = size(EEG.event,2);
                    EEG.event(lastindex+1).urevent = lastindex+1;
                    EEG.event(lastindex+1).type = events(2,cC);
                    EEG.event(lastindex+1).latency = events(1,cC);
                    EEG.urevent(lastindex+1).type = EEG.event(lastindex+1).type;
                    EEG.urevent(lastindex+1).latency = EEG.event(lastindex+1).latency;
                    
                end
            end
            [~,index] = sortrows([EEG.event.latency].'); EEG.event = EEG.event(index); clear index
            [~,index] = sortrows([EEG.urevent.latency].'); EEG.urevent = EEG.urevent(index); clear index
        end
            
        EEG.nbchan = size(EEG.data,1);
        EEG.urchanlocs = [];
        EEG.chaninfo.plotrad = [];
        EEG.chaninfo.shrink = [];
        EEG.chaninfo.nosedir = '+X';
        EEG.chaninfo.nodatchans = [];
        EEG.chaninfo.icachansind = [];

        EEG.setname = 'Neuroscan Curry file';
        EEG.filename = [name '.dap'];
        EEG.filepath = filepath;
        EEG.comments = sprintf('Original file: %s%s', filepath, [name '.dap']);
        EEG.ref = 'Common';
        EEG.history = sprintf('%s\nEEG = pop_loadcurry(''%s%s'');', EEG.history, filepath, [name '.dap']);
        
        % Use default channel locations for time being
        tempEEG = EEG; % for dipfitdefs
        % -----------------------------------------------------------------
        % dipfitdefs;
        % add script of dipfitdefs here
        % edit by Li Dong $ 21071214
        % -------------
        try
            if ~isfield(EEG, 'chanlocs')
                error('No electrode locations defined');
            end
            
            if ~isfield(EEG, 'icawinv')
                error('No ICA components present');
            end
            nchan = length(EEG(1).chanlocs);
            ncomp = size(EEG(1).icawinv, 2);
        catch
            nchan = 0;
        end;
        
        % create one-sphere model
        % defaultvolume.r = meanradius;
        % defaultvolume.c = 0.33http://www.google.com/;
        % defaultvolume.o = [0 0 0];
        
        % create three-sphere model
        % defaultvolume.r = meanradius * [0.0 0.92 0.88];
        % defaultvolume.c = [0.33 0.0042 0.33];
        % defaultvolume.o = [0 0 0];
        
        % create four-sphere model that is identical to the default of besa
        defaultvolume.r = [85-6-7-1 85-6-7 85-6 85];  % in mm
        defaultvolume.c = [0.33 1.00 0.0042 0.33];    % brain/csf/skull/skin
        defaultvolume.o = [0 0 0];
        
        % default file locations
        % ----------------------
        % if ~iseeglabdeployed
        %     folder = which('pop_dipfit_settings');
        %     folder = folder(1:end-21);
        % else
        %     folder = eeglabexefolder;
        % end;
        
        try
            folder = which('pop_dipfit_settings');
            folder = folder(1:end-21);
        catch
        end;
        
        
        try
            % delim  = folder(end);
            template_models(1).name     = 'Spherical Four-Shell (BESA)';
            template_models(1).hdmfile  = fullfile(folder, 'standard_BESA', 'standard_BESA.mat');
            template_models(1).mrifile  = fullfile(folder, 'standard_BESA', 'avg152t1.mat');
            template_models(1).chanfile = fullfile(folder, 'standard_BESA', 'standard-10-5-cap385.elp');
            template_models(1).coordformat = 'spherical';
            template_models(1).coord_transform(1).transform = [ ];
            template_models(1).coord_transform(1).keywords  = { 'standard-10-5-cap385' };
            template_models(1).coord_transform(2).transform = [ 13.4299     0.746361    -0.654923  0.000878113   -0.0818352    0.0023747     0.852832     0.941595      0.85887];
            template_models(1).coord_transform(2).keywords  = { 'standard_1005' };
            template_models(1).coord_transform(3).transform = [ -0.254232 0 -8.4081  0 0.00272526  0  8.59463     -10.9643      10.4963 ];
            template_models(1).coord_transform(3).keywords  = { 'gsn' 'sfp' };
            template_models(1).coord_transform(4).transform = [ 0 0 0 0 0.02 0 85 85 85 ];
            template_models(1).coord_transform(4).keywords  = { 'egi' 'elp' };
            
            template_models(2).name     = 'Boundary Element Model (MNI)';
            template_models(2).hdmfile  = fullfile(folder, 'standard_BEM', 'standard_vol.mat' );
            template_models(2).mrifile  = fullfile(folder, 'standard_BEM', 'standard_mri.mat' );
            template_models(2).chanfile = fullfile(folder, 'standard_BEM', 'elec', 'standard_1005.elc' );
            template_models(2).coordformat = 'MNI';
            template_models(2).coord_transform(1).transform = [ 0 0 0 0 0 -pi/2  1 1 1];
            template_models(2).coord_transform(1).keywords  = { 'standard_1005' };
            template_models(2).coord_transform(2).transform = [ 0.832146  -15.6287 2.41142 0.0812144 0.000937391 -1.5732 1.17419 1.06011 1.14846];
            template_models(2).coord_transform(2).keywords  = { 'standard-10-5-cap385' };
            template_models(2).coord_transform(3).transform = [ 0.0547605 -17.3653 -8.13178 0.0755019 0.00318357 -1.56963 11.7138 12.7933 12.213 ];
            template_models(2).coord_transform(3).keywords  = { 'gsn' 'sfp' };
            template_models(2).coord_transform(4).transform = [ 0 -15 0 0.08 0 -1.571 102 93 100 ];
            template_models(2).coord_transform(4).keywords  = { 'egi' 'elp' };
            
            template_models(3).name     = 'Spherical Four-Shell (custom conductances - see DIPFIT wiki)';
            template_models(3).hdmfile  = fullfile(folder, 'standard_BESA', 'standard_SCCN.mat');
            template_models(3).mrifile  = fullfile(folder, 'standard_BESA', 'avg152t1.mat');
            template_models(3).chanfile = fullfile(folder, 'standard_BESA', 'standard-10-5-cap385.elp');
            template_models(3).coordformat = 'spherical';
            template_models(3).coord_transform(1).transform = [ ];
            template_models(3).coord_transform(1).keywords  = { 'standard-10-5-cap385' };
            template_models(3).coord_transform(2).transform = [ 13.4299     0.746361    -0.654923  0.000878113   -0.0818352    0.0023747     0.852832     0.941595      0.85887];
            template_models(3).coord_transform(2).keywords  = { 'standard_1005' };
            template_models(3).coord_transform(3).transform = [ -0.254232 0 -8.4081  0 0.00272526  0  8.59463     -10.9643      10.4963 ];
            template_models(3).coord_transform(3).keywords  = { 'gsn' 'sfp' };
            template_models(3).coord_transform(4).transform = [ 0 0 0 0 0.02 0 85 85 85 ];
            template_models(3).coord_transform(4).keywords  = { 'egi' 'elp' };
            
            template_models(4).name     = 'Boundary Element Model (custom conductances - see DIPFIT wiki)';
            template_models(4).hdmfile  = fullfile(folder, 'standard_BEM', 'standard_vol_SCCN.mat' );
            template_models(4).mrifile  = fullfile(folder, 'standard_BEM', 'standard_mri.mat' );
            template_models(4).chanfile = fullfile(folder, 'standard_BEM', 'elec', 'standard_1005.elc' );
            template_models(4).coordformat = 'MNI';
            template_models(4).coord_transform(1).transform = [ 0 0 0 0 0 -pi/2  1 1 1];
            template_models(4).coord_transform(1).keywords  = { 'standard_1005' };
            template_models(4).coord_transform(2).transform = [ 0.832146  -15.6287 2.41142 0.0812144 0.000937391 -1.5732 1.17419 1.06011 1.14846];
            template_models(4).coord_transform(2).keywords  = { 'standard-10-5-cap385' };
            template_models(4).coord_transform(3).transform = [ 0.0547605 -17.3653 -8.13178 0.0755019 0.00318357 -1.56963 11.7138 12.7933 12.213 ];
            template_models(4).coord_transform(3).keywords  = { 'gsn' 'sfp' };
            template_models(4).coord_transform(4).transform = [ 0 -15 0 0.08 0 -1.571 102 93 100 ];
            template_models(4).coord_transform(4).keywords  = { 'egi' 'elp' };
            
        catch
            disp('Warning: problem when setting paths for dipole localization');
        end;
        
        template_models(5).name        = 'CTF MEG';
        template_models(5).coordformat = 'CTF';
        template_models(6).name        = 'Custom model files';
        template_models(6).coordformat = 'MNI'; % custom model
        
        % constrain electrode to sphere
        % -----------------------------
        meanradius = defaultvolume.r(4);
        
        % defaults for GUI pop_dipfit_settings dialog
        defaultelectrodes = sprintf('1:%d', nchan);
        
        % these settings determine the symmetry constraint that can be toggled on
        % for the second dipole
        %defaultconstraint = 'y';      % symmetry along x-axis
        % PROBLEM: change with respect to the model used. Now just assume perpendicular to nose
        
        % defaults for GUI pop_dipfit_batch dialogs
        rejectstr    = '40';	% in percent
        xgridstr     = sprintf('linspace(-%d,%d,11)', floor(meanradius), floor(meanradius));
        ygridstr     = sprintf('linspace(-%d,%d,11)', floor(meanradius), floor(meanradius));
        zgridstr     = sprintf('linspace(0,%d,6)', floor(meanradius));
        
        % Set DipoleDensity path
        DIPOLEDENSITY_STDBEM = fullfile(folder, 'standard_BEM', 'standard_vol.mat');
        % -----------------------------------------------------------------
%         tmpp = which('eeglab.m');
%         tmpp = fullfile(fileparts(tmpp), 'functions', 'resources', 'Standard-10-5-Cap385_witheog.elp');
          tmpp = which('pop_loadcurry.m');
          tmpp = fullfile(fileparts(tmpp),'Standard-10-5-Cap385_witheog.elp');
          % edit by Li Dong $ 20171214
        userdatatmp = { template_models(1).chanfile template_models(2).chanfile  tmpp };
        try
            [T, tempEEG] = evalc('pop_chanedit(tempEEG, ''lookup'', userdatatmp{1})');
        catch
            try
                [T, tempEEG] = evalc('pop_chanedit(tempEEG, ''lookup'', userdatatmp{3})');
            catch
                booler = 1;
            end
        end
        EEG.chanlocs = tempEEG.chanlocs;
        
        EEG = eeg_checkset(EEG);
        EEG.history = sprintf('%s\nEEG = eeg_checkset(EEG);', EEG.history);

        command = sprintf('\nEquivalent Command:\n\tEEG = pop_loadcurry(''%s%s'');',filepath, [name '.dap']);
        if (guicall == 1)
            disp(command)
        end
    end

end

