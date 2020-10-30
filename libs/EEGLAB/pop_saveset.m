% pop_saveset() - save one or more EEG dataset structures
%
% Usage:
%   >> pop_saveset( EEG ); % use an interactive pop-up window 
%   >> EEG = pop_saveset( EEG, 'key', 'val', ...); % no pop-up
%                                              
% Inputs:
%   EEG        - EEG dataset structure. May only contain one dataset.
%
% Optional inputs:
%   'filename' - [string] name of the file to save to
%   'filepath' - [string] path of the file to save to
%   'check'    - ['on'|'off'] perform extended syntax check. Default 'off'.
%   'savemode' - ['resave'|'onefile'|'twofiles'] 'resave' resave the 
%                current dataset using the filename and path stored
%                in the dataset; 'onefile' saves the full EEG 
%                structure in a Matlab '.set' file, 'twofiles' saves 
%                the structure without the data in a Matlab '.set' file
%                and the transposed data in a binary float '.dat' file.
%                By default the option from the eeg_options.m file is 
%                used.
%   'version' - ['6'|'7.3'] save Matlab file as version 6 or
%               '7.3' (default; as defined in eeg_option file).
%
% Outputs:
%   EEG        - saved dataset (after extensive syntax checks)
%   ALLEEG     - saved datasets (after extensive syntax checks)
%
% Note: An individual dataset should be saved with a '.set' file extension
%
% Author: Arnaud Delorme, CNL / Salk Institute, 2001
%
% See also: pop_loadset(), eeglab()
  
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
 
function [EEG, com] = pop_saveset( EEG, varargin);

com = '';
if nargin < 1
	help pop_saveset;
	return;
end;
if isempty(EEG)  , error('Cannot save empty datasets'); end;

% empty filename (resave file)
emptyfilename = 0;
if nargin > 1
    if isempty(varargin{1}) && isempty(EEG.filename), emptyfilename = 1; end;
    if strcmpi(varargin{1},'savemode') 
        if length(EEG) == 1
            if isempty(EEG(1).filename), varargin{2} = ''; emptyfilename = 1; end;
        else
            if any(cellfun(@isempty, { EEG.filename }))
                error('Cannot resave files who have not been saved previously');
            end;
        end;
    end;
end;

if nargin < 2 || emptyfilename
    if length(EEG) >1, error('For reasons of consistency, this function  does not save multiple datasets any more'); end;
    % pop up window to ask for file
    [filename, filepath] = uiputfile2('*.set', 'Save dataset with .set extension -- pop_saveset()'); 
    if ~isstr(filename), return; end;
    drawnow;
    options = { 'filename' filename 'filepath' filepath };
else
    % account for old calling format
    % ------------------------------
   if isempty(strmatch( lower(varargin{1}), { 'filename' 'filepath' 'savemode' 'check' }))
        options = { 'filename' varargin{1} };
        if nargin > 2
            options = { options{:} 'filepath' varargin{2} };
        end;
    else
        options = varargin;
    end;
end;

% decode input parameters
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


defaultSave = fastif(option_saveversion6, '6', '7.3');
g = finputcheck(options,  { 'filename'   'string'   []     '';
                            'filepath'   'string'   []     '';
                            'version'    'string'   { '6','7.3' } defaultSave;
                            'check'      'string'   { 'on','off' }     'off';
                            'savemode'   'string'   { 'resave','onefile','twofiles','' } '' });
if isstr(g), error(g); end;

% current filename without the .set
% ---------------------------------
if emptyfilename == 1, g.savemode = ''; end;
[g.filepath filenamenoext ext] = fileparts( fullfile(g.filepath, g.filename) ); ext = '.set';
g.filename = [ filenamenoext ext ];

% performing extended syntax check
% --------------------------------
if strcmpi(g.check, 'on')
    fprintf('Pop_saveset: Performing extended dataset syntax check...\n');
    EEG = eeg_checkset(EEG, 'eventconsistency');
    EEG = eeg_checkset(EEG);
else
    EEG = eeg_checkset(EEG);
end

% check for change in saving mode
% -------------------------------
if length(EEG) == 1
    if strcmpi(g.savemode, 'resave') && isfield(EEG, 'datfile') && ~option_savetwofiles
        disp('Note that your memory options for saving datasets does not correspond')
        disp('to the format of the datasets on disk (ignoring memory options)')
% $$$         but = questdlg2(strvcat('This dataset has an associated ''.dat'' file, but since you have', ...
% $$$                           'changed of saving mode, all the data will now be saved within the', ...
% $$$                           'Matlab file and the ''.dat'' file will be deleted.', ...
% $$$                           '(Note: Just press ''No'' if you do not know what you are doing)'), ...
% $$$                           'Warning: saving mode changed', 'Cancel', 'No, save as before', 'Yes, do it', 'Yes, do it');
% $$$         switch but
% $$$             case 'Cancel', return;
% $$$             case 'No, save as before', % nothing
% $$$             case 'Yes, do it', g.savemode = 'onefile';
% $$$         end;
% $$$         g.filename = EEG.filename;
% $$$         g.filepath = EEG.filepath;
    elseif strcmpi(g.savemode, 'resave') && ~isfield(EEG, 'datfile') && option_savetwofiles
        disp('Note that your memory options for saving datasets does not correspond')
        disp('to the format of the datasets on disk (ignoring memory options)')
% $$$         but = questdlg2(strvcat('This dataset does not have yet an associated ''.dat'' file, but since you have', ...
% $$$                           'changed of saving mode, all the data will now be saved within the ''.dat''', ...
% $$$                           'file and not in the Matlab file (as it is currently the case).', ...
% $$$                           '(Note: Just press ''No'' if you do not know what you are doing)'), ...
% $$$                           'Warning: saving mode changed', 'Cancel', 'No, save as before', 'Yes, do it', 'Yes, do it');
% $$$         switch but
% $$$             case 'Cancel', return;
% $$$             case 'No, save as before', % nothing
% $$$             case 'Yes, do it', g.savemode = 'twofiles';
% $$$         end;
% $$$         g.filename = EEG.filename;
% $$$         g.filepath = EEG.filepath;
    end;
end;

% default saving otion
% --------------------
save_as_dat_file = 0;
data_on_disk     = 0;
if strcmpi(g.savemode, 'resave')
    % process multiple datasets
    % -------------------------
    if length(EEG) > 1
        for index = 1:length(EEG)
            pop_saveset(EEG(index), 'savemode', 'resave');
            EEG(index).saved = 'yes';
        end;
        com = sprintf('%s = pop_saveset( %s, %s);', inputname(1), inputname(1), vararg2str(options));
        return;
    end;
    
    if strcmpi( EEG.saved, 'yes'), disp('Dataset has not been modified; No need to resave it.'); return; end;
    g.filename = EEG.filename;
    g.filepath = EEG.filepath;
    if isfield(EEG, 'datfile')
        if ~isempty(EEG.datfile)
            save_as_dat_file = 1;
        end;
    end;
    if isstr(EEG.data) & ~save_as_dat_file % data in .set file
        TMP = pop_loadset(EEG.filename, EEG.filepath);
        EEG.data = TMP.data;
        data_on_disk = 1;
    end;
else
    if length(EEG) >1, error('For reasons of consistency, this function  does not save multiple datasets any more'); end;
    if ~strcmpi(EEG.filename, g.filename) | ~strcmpi(EEG.filepath, g.filepath)
         EEG.datfile = '';
    end;
    EEG.filename    = g.filename;
    EEG.filepath    = g.filepath;
    if isempty(g.savemode)
        if option_savematlab, g.savemode = 'onefile';
        else                  g.savemode = 'twofiles';
        end;
    end;
    if strcmpi(g.savemode, 'twofiles')
        save_as_dat_file = 1;
        EEG.datfile = [ filenamenoext '.fdt' ];
    end;
end;

% Saving data as float and Matlab
% -------------------------------
tmpica       = EEG.icaact;
EEG.icaact   = [];
if ~isstr(EEG.data)
    if ~strcmpi(class(EEG.data), 'memmapdata') && ~strcmpi(class(EEG.data), 'mmo') && ~strcmpi(class(EEG.data), 'single')
        tmpdata       = single(reshape(EEG.data, EEG.nbchan,  EEG.pnts*EEG.trials));
    else 
        tmpdata = EEG.data;
    end;
    no_resave_dat = 'no';
else 
    no_resave_dat = 'yes';
end;
v = version;
try, 
    fprintf('Saving dataset...\n');
    EEG.saved = 'yes';
    if save_as_dat_file
        if ~isstr(EEG.data)
            EEG.data = EEG.datfile;
            tmpdata = floatwrite( tmpdata, fullfile(EEG.filepath, EEG.data), 'ieee-le');
        end;
    else
        if isfield(EEG, 'datfile')
            if ~isempty(EEG.datfile)
                if exist(fullfile(EEG.filepath, EEG.datfile))
                    try, 
                        delete(fullfile(EEG.filepath, EEG.datfile));
                        disp('Deleting .dat/.fdt file on disk (all data is within the Matlab file)');
                    catch, end;
                end;
            end;
            EEG.datfile = [];
        end;
    end;

    try
        if strcmpi(g.version, '6') save(fullfile(EEG.filepath, EEG.filename), '-v6',   '-mat', 'EEG');
        else                       save(fullfile(EEG.filepath, EEG.filename), '-v7.3', '-mat', 'EEG');
        end;
    catch
        save(fullfile(EEG.filepath, EEG.filename), '-mat', 'EEG');
    end;
    if save_as_dat_file & strcmpi( no_resave_dat, 'no' )
        EEG.data = tmpdata;
    end;
    
    % save ICA activities
    % -------------------
%     icafile = fullfile(EEG.filepath, [EEG.filename(1:end-4) '.icafdt' ]);
%     if isempty(EEG.icaweights) & exist(icafile)
%         disp('ICA activation file found on disk, but no more ICA activities. Deleting file.');
%         delete(icafile);
%     end;
%     if ~option_saveica & exist(icafile)
%         disp('Options indicate not to save ICA activations. Deleting ICA activation file.');
%         delete(icafile);
%     end;
%     if option_saveica & ~isempty(EEG.icaweights)
%         if ~exist('tmpdata')
%             TMP = eeg_checkset(EEG, 'loaddata');
%             tmpdata = TMP.data;
%         end;
%         if isempty(tmpica)
%              tmpica2 = (EEG.icaweights*EEG.icasphere)*tmpdata(EEG.icachansind,:);
%         else tmpica2 = tmpica;
%         end;
%         tmpica2 = reshape(tmpica2, size(tmpica2,1), size(tmpica2,2)*size(tmpica2,3));
%         floatwrite( tmpica2, icafile, 'ieee-le');
%         clear tmpica2;
%     end;
    
catch,
    rethrow(lasterror);
end;

% try to delete old .fdt or .dat files
% ------------------------------------
tmpfilename = fullfile(EEG.filepath, [ filenamenoext '.dat' ]);
if exist(tmpfilename) == 2
    disp('Deleting old .dat file format detected on disk (now replaced by .fdt file)');
    try,
        delete(tmpfilename);
        disp('Delete sucessfull.');
    catch, disp('Error while attempting to remove file'); 
    end;
end;
if save_as_dat_file == 0
    tmpfilename = fullfile(EEG.filepath, [ filenamenoext '.fdt' ]);
    if exist(tmpfilename) == 2
        disp('Old .fdt file detected on disk, deleting file the Matlab file contains all data...');
        try,
            delete(tmpfilename);
            disp('Delete sucessfull.');
        catch, disp('Error while attempting to remove file'); 
        end;
    end;
end;

% recovering variables
% --------------------
EEG.icaact = tmpica;
if data_on_disk
    EEG.data = 'in set file';
end;
if isnumeric(EEG.data) && v(1) < 7
    EEG.data   = double(reshape(tmpdata, EEG.nbchan,  EEG.pnts, EEG.trials));
end;
EEG.saved = 'justloaded';

com = sprintf('%s = pop_saveset( %s, %s);', inputname(1), inputname(1), vararg2str(options));
return;

function num = popask( text )
	 ButtonName=questdlg2( text, ...
	        'Confirmation', 'Cancel', 'Yes','Yes');
	 switch lower(ButtonName),
	      case 'cancel', num = 0;
	      case 'yes',    num = 1;
	 end;


