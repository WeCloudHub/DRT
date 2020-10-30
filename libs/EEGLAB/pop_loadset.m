% pop_loadset() - load an EEG dataset. If no arguments, pop up an input window.
%
% Usage:
%   >> EEGOUT = pop_loadset; % pop up window to input arguments
%   >> EEGOUT = pop_loadset( 'key1', 'val1', 'key2', 'val2', ...);
%   >> EEGOUT = pop_loadset( filename, filepath); % old calling format
%
% Optional inputs:
%   'filename'  - [string] dataset filename. Default pops up a graphical
%                 interface to browse for a data file.
%   'filepath'  - [string] dataset filepath. Default is current folder. 
%   'loadmode'  - ['all', 'info', integer] 'all' -> load the data and
%                 the dataset structure. 'info' -> load only the dataset 
%                 structure but not the actual data. [integer] ->  load only 
%                 a specific channel. This is efficient when data is stored 
%                 in a separate '.dat' file in which individual channels 
%                 may be loaded independently of each other. {default: 'all'}
%   'eeg'       - [EEG structure] reload current dataset
% Note:
%       Multiple filenames and filepaths may be specified. If more than one,
%       the output EEG variable will be an array of EEG structures.
% Output
%   EEGOUT - EEG dataset structure or array of structures
%
% Author: Arnaud Delorme, CNL / Salk Institute, 2001; SCCN/INC/UCSD, 2002-
%
% See also: eeglab(), pop_saveset()

% Copyright (C) 2001 Arnaud Delorme, Salk Institute, arno@salk.edu
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

% 01-25-02 reformated help & license -ad 

function [EEG, command] = pop_loadset( inputname, inputpath, varargin)

command = '';
EEG  = [];

if nargin < 1
    % pop up window
    % -------------
	[inputname, inputpath] = uigetfile2('*.SET*;*.set', 'Load dataset(s) -- pop_loadset()', 'multiselect', 'on');
    drawnow;
	if isequal(inputname, 0) return; end;
    options = { 'filename' inputname 'filepath' inputpath };
else
    % account for old calling format
    % ------------------------------
    if ~strcmpi(inputname, 'filename') && ~strcmpi(inputname, 'filepath') && ~strcmpi(inputname, 'eeg')
        options = { 'filename' inputname }; 
        if nargin > 1
            options = { options{:} 'filepath' inputpath }; 
        end;
        if nargin > 2
            options = { options{:} 'loadmode' varargin{1} }; 
        end;
    else
        options = { inputname inputpath varargin{:} };
    end;
end;

% decode input parameters
% -----------------------
g = finputcheck( options, ...
                 { 'filename'   { 'string';'cell' }    []   '';
                   'filepath'   'string'               []   '';
                   'check'      'string'               { 'on';'off' }   'on';
                   'loadmode'   { 'string';'integer' } { { 'info' 'all' } [] }  'all';
                   'eeg'        'struct'               []   struct('data',{}) }, 'pop_loadset');
if isstr(g), error(g); end;
if isstr(g.filename), g.filename = { g.filename }; end;

% reloading EEG structure from disk
% ---------------------------------
if ~isempty(g.eeg)

    EEG = pop_loadset( 'filepath', g.eeg.filepath, 'filename', g.eeg.filename);

else
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
    ALLEEGLOC = [];
    for ifile = 1:length(g.filename)
        
         if ifile > 1 && option_storedisk
              g.loadmode = 'last';
%             warndlg2(strvcat('You may only load a single dataset','when selecting the "Store at most one', 'dataset in memory" option'));
%             break;
         end;
        
        % read file
        % ---------
        filename = fullfile(g.filepath, g.filename{ifile});
        % fprintf('pop_loadset(): loading file %s ...\n', filename); % edit by Li Dong $ 2018.1.8
        %try
        TMPVAR = load('-mat', filename);
        %catch,
        %    error([ filename ': file is protected or does not exist' ]);
        %end;

        % variable not found
        % ------------------
        if isempty(TMPVAR)
            error('No dataset info is associated with this file');
        end;

        if isfield(TMPVAR, 'EEG')

            % load individual dataset
            % -----------------------
            EEG = checkoldformat(TMPVAR.EEG);
            [ EEG.filepath EEG.filename ext ] = fileparts( filename );
            EEG.filename = [ EEG.filename ext ];

            % account for name changes etc...
            % -------------------------------
            if isstr(EEG.data) && ~strcmpi(EEG.data, 'EEGDATA')

                [tmp EEG.data ext] = fileparts( EEG.data ); EEG.data = [ EEG.data ext];
                if ~isempty(tmp) && ~strcmpi(tmp, EEG.filepath)
                    disp('Warning: updating folder name for .dat|.fdt file');
                end;
                if ~strcmp(EEG.filename(1:end-3), EEG.data(1:end-3))
                    disp('Warning: the name of the dataset has changed on disk, updating .dat & .fdt data file to the new name');
                    EEG.data = [ EEG.filename(1:end-3) EEG.data(end-2:end) ];
                    EEG.saved = 'no';
                end;

            end;

            % copy data to output variable if necessary (deprecated)
            % -----------------------------------------
            if ~strcmpi(g.loadmode, 'info') && isfield(TMPVAR, 'EEGDATA')
                if ~option_storedisk || ifile == length(g.filename)
                    EEG.data = TMPVAR.EEGDATA;
                end;
            end;

        elseif isfield(TMPVAR, 'ALLEEG') % old format
            
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
            % -------------------------------------------------------------            
            if option_storedisk
                error('Cannot load multiple dataset file. Change memory option to allow multiple datasets in memory, then try again. Remember that this file type is OBSOLETE.');
            end;

            % this part is deprecated as of EEGLAB 5.00
            % since all dataset data have to be saved in separate files
            % -----------------------------------------------------
            disp('pop_loadset(): appending datasets');
            EEG = TMPVAR.ALLEEG;
            for index=1:length(EEG)
                EEG(index).filename = '';
                EEG(index).filepath = '';        
                if isstr(EEG(index).data), 
                    EEG(index).filepath = g.filepath; 
                    if length(g.filename{ifile}) > 4 && ~strcmp(g.filename{ifile}(1:end-4), EEG(index).data(1:end-4)) && strcmpi(g.filename{ifile}(end-3:end), 'sets')
                        disp('Warning: the name of the dataset has changed on disk, updating .dat data file to the new name');
                        EEG(index).data = [ g.filename{ifile}(1:end-4) 'fdt' int2str(index) ];
                    end;
                end;
            end;
        else
            EEG = checkoldformat(TMPVAR);
            if ~isfield( EEG, 'data')
                error('pop_loadset(): not an EEG dataset file');
            end;
            if isstr(EEG.data), EEG.filepath = g.filepath; end;
        end;
        
        %ALLEEGLOC = pop_newset(ALLEEGLOC, EEG, 1);
        ALLEEGLOC = eeg_store(ALLEEGLOC, EEG, 0, 'verbose', 'off');
                
    end;
    EEG = ALLEEGLOC;
end;

% load all data or specific data channel
% --------------------------------------
if strcmpi(g.check, 'on')
    EEG = eeg_checkset(EEG);
end;
if isstr(g.loadmode)
    if strcmpi(g.loadmode, 'all')
        EEG = eeg_checkset(EEG, 'loaddata');
    elseif strcmpi(g.loadmode, 'last')
        EEG(end) = eeg_checkset(EEG(end), 'loaddata');
    end;
else
    % load/select specific channel
    % ----------------------------
    EEG.datachannel = g.loadmode;
    EEG.data   = eeg_getdatact(EEG, 'channel', g.loadmode);
    EEG.nbchan = length(g.loadmode);
    if ~isempty(EEG.chanlocs)
        EEG.chanlocs = EEG.chanlocs(g.loadmode);
    end;
    EEG.icachansind = [];
    EEG.icaact = [];
    EEG.icaweights = [];
    EEG.icasphere = [];
    EEG.icawinv = [];
    %if isstr(EEG.data)
    %    EEG.datfile = EEG.data;
    %    fid = fopen(fullfile(EEG.filepath, EEG.data), 'r', 'ieee-le');
    %    fseek(fid, EEG.pnts*EEG.trials*( g.loadmode - 1), 0 );
    %    EEG.data    = fread(fid, EEG.pnts*EEG.trials, 'float32');
    %    fclose(fid);
    %else
    %    EEG.data        = EEG.data(g.loadmode,:,:);
    %end;
end;

% set file name and path
% ----------------------
if length(EEG) == 1
    tmpfilename = g.filename{1};
    if isempty(g.filepath)
        [g.filepath tmpfilename ext] = fileparts(tmpfilename);
        tmpfilename = [ tmpfilename ext ];
    end;
    EEG.filename = tmpfilename;
    EEG.filepath = g.filepath;
end;

% set field indicating that the data has not been modified
% --------------------------------------------------------
if isfield(EEG, 'changes_not_saved')
    EEG = rmfield(EEG, 'changes_not_saved');
end;
for index=1:length(EEG)
    EEG(index).saved = 'justloaded';
end;

command = sprintf('EEG = pop_loadset(%s);', vararg2str(options));
return;

function EEG = checkoldformat(EEG)
	if ~isfield( EEG, 'data')
		fprintf('pop_loadset(): Incompatible with new format, trying old format and converting...\n');
		eegset = EEG.cellArray;
		
		off_setname             = 1;  %= filename
		off_filename            = 2;  %= filename
		off_filepath            = 3;  %= fielpath
		off_type                    = 4;  %= type EEG AVG CNT
		off_chan_names          = 5;  %= chan_names
		off_chanlocs            = 21;  %= filename
		off_pnts                    = 6;  %= pnts
		off_sweeps                  = 7; %= sweeps
		off_rate                    = 8;  %= rate
		off_xmin                    = 9;  %= xmin
		off_xmax                    = 10;  %= xmax
		off_accept                  = 11; %= accept
		off_typeeeg                 = 12; %= typeeeg
		off_rt                      = 13; %= rt
		off_response            = 14; %= response
		off_signal                  = 15; %= signal
		off_variance            = 16; %= variance
		off_winv                    = 17; %= variance
		off_weights             = 18; %= variance
		off_sphere                  = 19; %= variance
		off_activations         = 20; %= variance
		off_entropytrial        = 22; %= variance
		off_entropycompo        = 23; %= variance
		off_threshold       = 24; %= variance
		off_comporeject     = 25; %= variance
		off_sigreject       = 26;
		off_kurtA                       = 29;
		off_kurtR                       = 30;
		off_kurtDST                 = 31;
		off_nbchan                  = 32;
		off_elecreject      = 33;
		off_comptrial       = 34;
		off_kurttrial       = 35; %= variance
		off_kurttrialglob   = 36; %= variance
		off_icareject       = 37; %= variance
		off_gcomporeject    = 38; %= variance
		off_eegentropy          = 27;
		off_eegkurt             = 28;
		off_eegkurtg            = 39;

		off_tmp1                        = 40;
		off_tmp2                        = 40;
		
		% must convert here into new format
		EEG.setname    = eegset{off_setname   };
		EEG.filename   = eegset{off_filename  };
		EEG.filepath   = eegset{off_filepath  };
		EEG.namechan   = eegset{off_chan_names};
		EEG.chanlocs    = eegset{off_chanlocs   };
		EEG.pnts       = eegset{off_pnts      };
		EEG.nbchan     = eegset{off_nbchan    };
		EEG.trials     = eegset{off_sweeps    };
		EEG.srate       = eegset{off_rate      };
		EEG.xmin       = eegset{off_xmin      };
		EEG.xmax       = eegset{off_xmax      };
		EEG.accept     = eegset{off_accept    };
		EEG.eegtype    = eegset{off_typeeeg   };
		EEG.rt         = eegset{off_rt        };
		EEG.eegresp    = eegset{off_response  };
		EEG.data     = eegset{off_signal    };
		EEG.icasphere  = eegset{off_sphere    };
		EEG.icaweights = eegset{off_weights   };
		EEG.icawinv       = eegset{off_winv      };
		EEG.icaact        = eegset{off_activations  };
		EEG.stats.entropy    = eegset{off_entropytrial };
		EEG.stats.kurtc      = eegset{off_kurttrial    };
		EEG.stats.kurtg      = eegset{off_kurttrialglob};
		EEG.stats.entropyc   = eegset{off_entropycompo };
		EEG.reject.threshold  = eegset{off_threshold    };
		EEG.reject.icareject  = eegset{off_icareject    };
		EEG.reject.compreject = eegset{off_comporeject  };
		EEG.reject.gcompreject= eegset{off_gcomporeject };
		EEG.reject.comptrial  = eegset{off_comptrial    };
		EEG.reject.sigreject  = eegset{off_sigreject    };
		EEG.reject.elecreject = eegset{off_elecreject   };
		EEG.stats.kurta      = eegset{off_kurtA        };
		EEG.stats.kurtr      = eegset{off_kurtR        };
		EEG.stats.kurtd      = eegset{off_kurtDST      };
		EEG.stats.eegentropy = eegset{off_eegentropy   };
		EEG.stats.eegkurt    = eegset{off_eegkurt      };
		EEG.stats.eegkurtg   = eegset{off_eegkurtg     };
		%catch
		%	disp('Warning: some variables may not have been assigned');
		%end;
		
		% modify the eegtype to match the new one
		
		try
			if EEG.trials > 1
				EEG.events  = [ EEG.rt(:) EEG.eegtype(:) EEG.eegresp(:) ];
			end;
		catch, end;
	end;
	% check modified fields
	% ---------------------
	if isfield(EEG,'icadata'), EEG.icaact = EEG.icadata; end;  
	if isfield(EEG,'poschan'), EEG.chanlocs = EEG.poschan; end;  
	if ~isfield(EEG, 'icaact'), EEG.icaact = []; end;
	if ~isfield(EEG, 'chanlocs'), EEG.chanlocs = []; end;
	
	if isfield(EEG, 'events') && ~isfield(EEG, 'event')
		try
			if EEG.trials > 1
				EEG.events  = [ EEG.rt(:) ];
				
				EEG = eeg_checkset(EEG);
				EEG = pop_importepoch(EEG, EEG.events, { 'rt'}, {'rt'}, 1E-3);
			end;
			if isfield(EEG, 'trialsval')
				EEG = pop_importepoch(EEG, EEG.trialsval(:,2:3), { 'eegtype' 'response' }, {},1,0,0);
			end;
			EEG = eeg_checkset(EEG, 'eventconsistency');
		catch, disp('Warning: could not import events'); end;			
	end;
	rmfields = {'icadata' 'events' 'accept' 'eegtype' 'eegresp' 'trialsval' 'poschan' 'icadata' 'namechan' };
	for index = 1:length(rmfields)
		if isfield(EEG, rmfields{index}), 
			disp(['Warning: field ' rmfields{index} ' is deprecated']);
		end;
	end;
