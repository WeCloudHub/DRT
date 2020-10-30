% function eeglab_options
% eeglab_options() - handle EEGLAB options. This script (not function)
%                    set the various options in the eeg_options() file.
%
% Usage:
%   eeglab_options;
%
% Author: Arnaud Delorme, SCCN, INC, UCSD, 2006-

% Copyright (C) Arnaud Delorme, SCCN, INC, UCSD, 2006-
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

% load local file
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
