% pop_biosig() - import data files into EEGLAB using BIOSIG toolbox
%
% Usage:
%   >> OUTEEG = pop_biosig; % pop up window
%   >> OUTEEG = pop_biosig( filename, channels, type);
%
% Inputs:
%   filename - [string] file name
%
% Optional inputs:
%   'channels'   - [integer array] list of channel indices
%   'blockrange' - [min max] integer range of data blocks to import, in seconds.
%                  Entering [0 3] will import the first three blocks of data.
%                  Default is empty -> import all data blocks. 
%  'importevent' - ['on'|'off'] import events. Default if 'on'.
%  'importannot' - ['on'|'off'] import annotations (EDF+ only). Default if 'on'
%  'blockepoch'  - ['on'|'off'] force importing continuous data. Default is 'on'
%  'ref'         - [integer] channel index or index(s) for the reference.
%                  Reference channels are not removed from the data,
%                  allowing easy re-referencing. If more than one
%                  channel, data are referenced to the average of the
%                  indexed channels. WARNING! Biosemi Active II data 
%                  are recorded reference-free, but LOSE 40 dB of SNR 
%                  if no reference is used!. If you do not know which
%                  channel to use, pick one and then re-reference after 
%                  the channel locations are read in. {default: none}.
%                  For more information see http://www.biosemi.com/faq/cms&drl.htm
%  'rmeventchan' - ['on'|'off'] remove event channel after event 
%                  extraction. Default is 'on'.
%  'memorymapped' - ['on'|'off'] import memory mapped file (useful if 
%                  encountering memory errors). Default is 'off'.
%
% Outputs:
%   OUTEEG   - EEGLAB data structure
%
% Author: Arnaud Delorme, SCCN, INC, UCSD, Oct. 29, 2003-
%
% Note: BIOSIG toolbox must be installed. Download BIOSIG at 
%       http://biosig.sourceforge.net
%       Contact a.schloegl@ieee.org for troubleshooting using BIOSIG.

% Copyright (C) 2003 Arnaud Delorme, SCCN, INC, UCSD, arno@salk.edu
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

function [EEG, command, dat] = pop_biosig(filename, varargin); 
EEG = [];
command = '';

if nargin < 1
	% ask user
	[filename1, filepath] = uigetfile('*.*', 'Choose a data file -- pop_biosig()'); %%% this is incorrect in original version!!!!!!!!!!!!!!
    drawnow;
    
	if filename1 == 0 return; end;
	filename = [filepath filename1];
    
    % look if MEG
    % -----------
    if length(filepath)>4
        if strcmpi(filepath(end-3:end-1), '.ds'), filename = filepath(1:end-1); end;
    end;
    
    % open file to get infos
    % ----------------------
    disp('Reading data file header...');
    dat = sopen(filename, 'r', [], 'OVERFLOWDETECTION:OFF');
    if ~isfield(dat, 'NRec')
        error('Unsuported data format');
    end;
    
    % special BIOSEMI
    % ---------------
    % ---------------------------------------------------------------------
    % eeglab_options;
    
    % add script of eeglab_options here
    % edit by Li Dong $ 20171213
    % ---------------
    homefolder = '';
    try
        % -----------------------------------------------------------------
        % Original codes:
        %  eeg_optionsbackup;
        %  icadefs;
        % -------------------------
        %  add scripts of "eeg_optionsbackup.m" and "icadefs.m"
        %  edit by Li Dong $ 20171213
        % --------------------------
        % eeg_optionsbackup
        % STUDY and file options (set these checkboxes if you intend to work with studies)
        option_storedisk     = 0 ;  % If set, keep at most one dataset in memory. This allows processing hundreds of datasets within studies.
        option_savetwofiles  = 1 ;  % If set, save not one but two files for each dataset (header and data). This allows faster data loading in studies.
        option_saveversion6  = 1 ;  % If set, write Matlab files in Matlab v6.5 (max compatibility). If not, write files in Matlab v7.3 (larger than 2Gb).
        % Memory options
        option_single        = 1 ;  % If set, use single precision under Matlab 7.x. This saves RAM but can lead to rare numerical imprecisions.
        option_memmapdata    = 0 ;  % If set, use memory mapped array under Matlab 7.x. This may slow down some computation (beta).
        option_eegobject     = 0 ;  % If set, use the EEGLAB EEG object instead of the standard EEG structure (beta).
        % ICA options
        option_computeica    = 1 ;  % If set, precompute ICA activations. This requires more RAM but allows faster plotting of component activations.
        option_scaleicarms   = 1 ;  % If set, scale ICA component activities to RMS (Root Mean Square) in microvolt (recommended).
        % Folder options
        option_rememberfolder = 1 ;  % If set, when browsing to open a new dataset assume the folder/directory of previous dataset.
        % Toolbox options
        option_donotusetoolboxes = 0 ;  % If set, do not use Matlab additional toolboxes functions even if they are present (need to restart EEGLAB).
        % EEGLAB connectivity and support
        option_checkversion = 1 ;  % If set, check for new version of EEGLAB at startup.
        option_chat = 0 ;  % If set, enable EEGLAB chat - currently UCSD only - restart EEGLAB after changing that option.
        % --------------------------------------
        % icadefs;
        
        EEGOPTION_PATH = ''; % if empty, the home folder of the current user is used
        % Note that this may create problems under Windows
        % when unicode characters are part of the user name
        % In this case, enter the path name manually here.
        
        YDIR  = 1;                  % positive potential up = 1; negative up = -1
        % for most ERP plots
        HZDIR = 'up';               % ascending freqs = 'up'; descending = 'down'
        % (e.g., timef/newtimef frequency direction)
        % font size
        tmpComputer   = computer;
        tmpScreenSize = get(0, 'ScreenSize');
        retinaDisplay = false;
        if tmpScreenSize(3) == 1440 && ( tmpScreenSize(3) == 878 || tmpScreenSize(3) == 900 )
            retinaDisplay = true;
        end;
        
        % retinaDisplay = false; % uncoment this line if not retina display
        if retinaDisplay && strcmpi(tmpComputer(1:3), 'MAC')
            W_MAIN = findobj('tag', 'EEGLAB');
            if isempty(W_MAIN)
                disp('Mac OSX retina display detected. If this is not the case uncoment line 50 of icadefs.m');
            end;
            GUI_FONTSIZE  = 18; % graphic interface font size
            AXES_FONTSIZE = 18; % Axis labels and legend font size
            TEXT_FONTSIZE = 18; % Miscellaneous font sizes
        else
            GUI_FONTSIZE  = 10; % graphic interface font size
            AXES_FONTSIZE = 10; % Axis labels and legend font size
            TEXT_FONTSIZE = 10; % Miscellaneous font sizes
        end;
        clear retinaDisplay tmpScreenSize tmpComputer;
        
        % the eeg_options.m file also countains additional options
        
        % ----------------------------------------------------------------------
        % ------------------------ END OF DEFINITIONS --------------------------
        % ----------------------------------------------------------------------
        
        % INSERT location of ica executable (LINUX ONLY) for binica.m below
        eeglab_p = fileparts(which('pop_loadset'));
        ICABINARY = fullfile(eeglab_p, 'functions', 'resources', 'ica_linux');
        
        try
            set(0,'defaultaxesfontsize',AXES_FONTSIZE);
            set(0,'defaulttextfontsize',TEXT_FONTSIZE);
            set(0,'DefaultUicontrolFontSize',GUI_FONTSIZE);
        catch
            % most likely Octave here
        end;
        
        TUTORIAL_URL = 'http://sccn.ucsd.edu/wiki/EEGLAB'; % online version
        DEFAULT_SRATE = 256.0175;      % default local sampling rate (rarely used)
        DEFAULT_TIMLIM = [-1000 2000]; % default local epoch limits (ms)
        
        % Set EEGLAB figure and GUI colors
        % --------------------------------
        lowscreendepth = 0;
        if ~exist('OCTAVE_VERSION')
            if get(0, 'screendepth') <=8 % if mono or 8-bit color
                lowscreendepth = 1;
            end;
        end;
        if lowscreendepth
            fprintf('icadefs(): Setting display parameters for mono or 8-bit color\n');
            BACKCOLOR           = [1 1 1];    % Background figure color
            BACKEEGLABCOLOR     = [1 1 1];    % EEGLAB main window background
            GUIBUTTONCOLOR      = [1 1 1];    % Buttons colors in figures
            GUIPOPBUTTONCOLOR   = [1 1 1];    % Buttons colors in GUI windows
            GUIBACKCOLOR        = [1 1 1];    % GUI background color
            GUITEXTCOLOR        = [0 0 0];      % GUI foreground color for text
            PLUGINMENUCOLOR     = [.5 0 .5];  % plugin menu color
            
        else % if full color screen
            BACKCOLOR           = [.97 .97 .97];    % EEGLAB Background figure color
            % BACKEEGLABCOLOR     = [.66 .76 1];    % EEGLAB main window background
            BACKEEGLABCOLOR     = [.86 .86 .86];    % EEGLAB main window background
            GUIBUTTONCOLOR      = BACKEEGLABCOLOR;% Buttons colors in figures
            GUIPOPBUTTONCOLOR   = BACKCOLOR;      % Buttons colors in GUI windows
            GUIBACKCOLOR        = BACKEEGLABCOLOR;% EEGLAB GUI background color <---------
            GUITEXTCOLOR        = [0 0 0.4];      % GUI foreground color for text
            PLUGINMENUCOLOR     = [.5 0 .5];      % plugin menu color
        end;
        
        
        % THE FOLLOWING PARAMETERS WILL BE DEPRECATED IN LATER VERSIONS
        % -------------------------------------------------------------
        
        SHRINKWARNING = 1;          % Warn user about the shrink factor in topoplot() (1/0)
        
        MAXENVPLOTCHANS   = 264;  % maximum number of channels to plot in envproj.m
        MAXPLOTDATACHANS  = 264;  % maximum number of channels to plot in dataplot.m
        MAXPLOTDATAEPOCHS = 264;  % maximum number of epochs to plot in dataplot.m
        MAXEEGPLOTCHANS   = 264;  % maximum number of channels to plot in eegplot.m
        MAXTOPOPLOTCHANS  = 264;  % maximum number of channels to plot in topoplot.m
        
        DEFAULT_ELOC  = 'chan.locs'; % default electrode location file for topoplot.m
        DEFAULT_EPOCH = 10;       % default epoch width to plot in eegplot(s) (in sec)
        
        SC  =  ['binica.sc'];           % Master .sc script file for binica.m
        % MATLAB will use first such file found
        % in its path of script directories.
        % Copy to pwd to alter ICA defaults
        
        % -----------------------------------------------------------------
        % folder for eeg_options file (also update the pop_editoptions)
        if ~isempty(EEGOPTION_PATH)
            homefolder = EEGOPTION_PATH;
        elseif ispc
            if ~exist('evalc'), eval('evalc = @(x)(eval(x));'); end;
            homefolder = deblank(evalc('!echo %USERPROFILE%'));
        else homefolder = '~';
        end;
        
        option_file = fullfile(homefolder, 'eeg_options.m');
        oldp = pwd;
        try
            if ~isempty(dir(option_file))
                cd(homefolder);
            else
                tmpp2 = fileparts(which('eeglab_options.m'));
                cd(tmpp2);
            end;
        catch, end;
        cd(oldp);
        % -----------------------------------------------------------------
        % eeg_options; % default one with EEGLAB
        % add script of eeg_options here
        % edit by Li Dong $ 20171213
        % STUDY options (set these checkboxes if you intend to work with studies)
        option_storedisk = 0 ; % If set, keep at most one dataset in memory. This allows processing hundreds of datasets within studies.
        option_savetwofiles = 1 ; % If set, save not one but two files for each dataset (header and data). This allows faster data loading in studies.
        % Memory options
        option_single = 1 ; % If set, use single precision under Matlab 7.x. This saves RAM but can lead to rare numerical imprecisions.
        option_memmapdata = 0 ; % If set, use memory mapped array under Matlab 7.x. This may slow down some computation.
        % ICA options
        option_computeica = 0 ; % If set, precompute ICA activations. This requires more RAM but allows faster plotting of component activations.
        option_scaleicarms = 1 ; % If set, scale ICA component activities to RMS (Root Mean Square) in microvolt (recommended).
        % Folder options
        option_rememberfolder = 1 ; % If set, when browsing to open a new dataset assume the folder/directory of previous dataset.
        % -----------------------------------------------------------------
        option_savematlab = ~option_savetwofiles;
        % disp(['option_savetwofiles:',num2str(option_savetwofiles)]);
        
    catch
        lasterr
        disp('Warning: could not access the local eeg_options file');
    end;
    % ---------------------------------------------------------------------
    if strcmpi(dat.TYPE, 'BDF')
        disp(upper('We highly recommend that you choose a reference channel IF these are Biosemi data'));
        disp(upper('(e.g., a mastoid or other channel). Otherwise the data will lose 40 dB of SNR!'));
        disp('For more information, see <a href="http://www.biosemi.com/faq/cms&drl.htm">http://www.biosemi.com/faq/cms&drl.htm</a>');
    end;
    uilist = { { 'style' 'text' 'String' 'Channel list (defaut all):' } ...
                 { 'style' 'edit' 'string' '' } ...
                 { 'style' 'text' 'String' [ 'Data range (in seconds) to read (default all [0 ' int2str(dat.NRec) '])' ] } ...
                 { 'style' 'edit' 'string' '' } ...
                 { 'style' 'text' 'String' 'Extract event' } ...
                 { 'style' 'checkbox' 'string' '' 'value' 1 'enable' 'on' } {} ...
                 { 'style' 'text' 'String' 'Import anotations (EDF+ only)' } ...
                 { 'style' 'checkbox' 'string' '' 'value' 1 'enable' 'on' } {} ...
                 { 'style' 'text' 'String' 'Force importing continuous data' 'value' 1} ...
                 { 'style' 'checkbox' 'string' '' 'value' 0 } {} ...
                 { 'style' 'text' 'String' 'Reference chan(s) indices - required for BIOSEMI' } ...
                 { 'style' 'edit' 'string' '' } ...
                  { 'style' 'checkbox' 'String' 'Import as memory mapped file (use if out of memory error)' 'value' option_memmapdata } };
    geom = { [3 1] [3 1] [3 0.35 0.5] [3 0.35 0.5] [3 0.35 0.5] [3 1] [1] };

    result = inputgui( geom, uilist, 'pophelp(''pop_biosig'')', ...
                                 'Load data using BIOSIG -- pop_biosig()');
    if length(result) == 0 return; end;
    
    % decode GUI params
    % -----------------
    options = {};
    if ~isempty(result{1}), options = { options{:} 'channels'   eval( [ '[' result{1} ']' ] ) }; end;
    if ~isempty(result{2}), options = { options{:} 'blockrange' eval( [ '[' result{2} ']' ] ) }; end;
    if length(result) > 2
        if ~result{3},          options = { options{:} 'importevent'  'off'  }; end;
        if ~result{4},          options = { options{:} 'importannot'  'off'  }; end;
        if  result{5},          options = { options{:} 'blockepoch'   'off' }; end;
        if ~isempty(result{6}), options = { options{:} 'ref'        eval( [ '[' result{6} ']' ] ) }; end;
        if  result{7},          options = { options{:} 'memorymapped' 'on' }; end;
    end;
else
    options = varargin;
end;

% decode imput parameters
% -----------------------
g = finputcheck( options, { 'blockrange'   'integer' [0 Inf]    [];
                            'channels'     'integer' [0 Inf]    [];
                            'ref'          'integer' [0 Inf]    [];
                            'rmeventchan'  'string'  { 'on';'off' } 'on';
                            'importevent'  'string'  { 'on';'off' } 'on';
                            'importannot'  'string'  { 'on';'off' } 'on';
                            'memorymapped' 'string'  { 'on';'off' } 'off';
                            'blockepoch'   'string'  { 'on';'off' } 'off' }, 'pop_biosig');
if isstr(g), error(g); end;

% import data
% -----------
EEG = eeg_emptyset;
[dat DAT interval] = readfile(filename, g.channels, g.blockrange, g.memorymapped);

if strcmpi(g.blockepoch, 'off')
    dat.NRec = 1;
end;
    
EEG = biosig2eeglab(dat, DAT, interval, g.channels, strcmpi(g.importevent, 'on'));

if strcmpi(g.rmeventchan, 'on') & strcmpi(dat.TYPE, 'BDF') & isfield(dat, 'BDF')
    if size(EEG.data,1) >= dat.BDF.Status.Channel, 
        disp('Removing event channel...');
        EEG.data(dat.BDF.Status.Channel,:) = []; 
        if ~isempty(EEG.chanlocs) && length(EEG.chanlocs) >= dat.BDF.Status.Channel
            EEG.chanlocs(dat.BDF.Status.Channel) = [];
        end;
    end;
    EEG.nbchan = size(EEG.data,1);
end;

% -----------
try EEG.filename = filename1;catch,end; % add by Li Dong $ 2015/8/19
% rerefencing
% -----------
if ~isempty(g.ref)
    disp('Re-referencing...');
    refoptions = {};
    if length(g.ref) > 1, refoptions = { 'keepref' 'on' }; end;
    EEG = pop_reref(EEG, g.ref, refoptions{:});
%     EEG.data = EEG.data - repmat(mean(EEG.data(g.ref,:),1), [size(EEG.data,1) 1]);
%     if length(g.ref) == size(EEG.data,1)
%         EEG.ref  = 'averef';
%     end;
%     if length(g.ref) == 1
%         disp([ 'Warning: channel ' int2str(g.ref) ' is now zeroed (but still present in the data)' ]);
%     else
%         disp([ 'Warning: data matrix rank has decreased through re-referencing' ]);
%     end;
end;

% test if annotation channel is present
% -------------------------------------
if isfield(dat, 'EDFplus') && strcmpi(g.importannot, 'on')
    tmpfields = fieldnames(dat.EDFplus);
    for ind = 1:length(tmpfields)
        tmpdat = getfield(dat.EDFplus, tmpfields{ind});
        if length(tmpdat) == EEG.pnts
            EEG.data(end+1,:) = tmpdat;
            EEG.nbchan        = EEG.nbchan+1;
            if ~isempty(EEG.chanlocs)
                EEG.chanlocs(end+1).labels = tmpfields{ind};
            end;
        end;
    end;
end;

% convert data to single if necessary
% -----------------------------------
EEG = eeg_checkset(EEG,'makeur');   % Make EEG.urevent field
EEG = eeg_checkset(EEG);

% history
% -------
if isempty(options)
    command = sprintf('EEG = pop_biosig(''%s'');', filename); 
else
    command = sprintf('EEG = pop_biosig(''%s'', %s);', filename, vararg2str(options)); 
end;    

% ---------
% read data
% ---------
function [dat DAT interval] = readfile(filename, channels, blockrange, memmapdata);

if isempty(channels), channels = 0; end;
dat = sopen(filename, 'r', channels,'OVERFLOWDETECTION:OFF');

if strcmpi(memmapdata, 'off')
    fprintf('Reading data in %s format...\n', dat.TYPE);

    if ~isempty(blockrange)
        newblockrange    = blockrange;
%         newblockrange    = newblockrange*dat.Dur;    
        DAT=sread(dat, newblockrange(2)-newblockrange(1), newblockrange(1));
    else 
        DAT=sread(dat, Inf);% this isn't transposed in original!!!!!!!!
        newblockrange    = [];
    end
    sclose(dat);
else
    fprintf('Reading data in %s format (file will be mapped to memory so this may take a while)...\n', dat.TYPE);
    inc = ceil(250000/(dat.NS*dat.SPR)); % 1Mb block
    
    if isempty(blockrange), blockrange = [0 dat.NRec]; end;
    blockrange(2) = min(blockrange(2), dat.NRec);
    allblocks = [blockrange(1):inc:blockrange(end)];
    count = 1;
    for bind = 1:length(allblocks)-1
        TMPDAT=sread(dat, (allblocks(bind+1)-allblocks(bind))*dat.Dur, allblocks(bind)*dat.Dur);
        if bind == 1
            DAT = mmo([], [size(TMPDAT,2) (allblocks(end)-allblocks(1))*dat.SPR]);
        end;
        DAT(:,count:count+length(TMPDAT)-1) = TMPDAT';
        count = count+length(TMPDAT);
    end;
    sclose(dat);
end;

if ~isempty(blockrange)
     interval(1) = blockrange(1) * dat.SampleRate(1) + 1;
     interval(2) = blockrange(2) * dat.SampleRate(1);
else interval = [];
end
