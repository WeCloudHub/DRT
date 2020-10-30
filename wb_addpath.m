function wb_addpath()
% add pathsclc
% Written by Li Dong (Lidong@uestc.edu.cn)
% $ 2017.12.19
% -------------------------------------------------------------------------
wb_path = which('wb_addpath.m');
wb_path = wb_path(1:end-length('wb_addpath.m'));
if strcmpi(wb_path, './') || strcmpi(wb_path, '.\'), 
    wb_path = [ pwd filesep ]; 
end;

% test for local copy
% ------------------------
if ~isWBdeployed2
    addpath(wb_path);
    if ~exist(fullfile(wb_path),'dir')==7
        % warning('WeBrain subfolders not found');
    end;
end;

% add paths
% ---------
if ~isWBdeployed2
    % add custom functions
    myaddpath( wb_path, 'wb_loadEEG.m', ['customs',filesep]);
    
    % add EEGLAB
    myaddpath( wb_path, 'EEGLAB_Version.m', ['libs',filesep,'EEGLAB', filesep]);
    myaddpath( wb_path, 'EEGLAB_Version.m', fullfile('libs','EEGLAB','timefreqfunc'));
    myaddpath( wb_path, 'EEGLAB_Version.m', fullfile('libs','EEGLAB','external',...
                        'biosig-partial','doc'));
    myaddpath( wb_path, 'EEGLAB_Version.m', fullfile('libs','EEGLAB','external',...
                        'biosig-partial','t200_FileAccess'));
    myaddpath( wb_path, 'EEGLAB_Version.m', fullfile('libs','EEGLAB','external',...
                        'biosig-partial','t250_ArtifactPreProcessingQualityControl'));
    myaddpath( wb_path, 'EEGLAB_Version.m', fullfile('libs','EEGLAB','external',...
                        'firfilt1.6.2'));               
    % add BCT toolbox
    myaddpath( wb_path, 'clustering_coef_wu.m', fullfile('libs','2017_01_15_BCT')); 
    % add ADTF
    myaddpath( wb_path, 'ADTF.m', fullfile('libs','ADTF')); 
    myaddpath( wb_path, 'DTF.m', fullfile('libs','DTFComputation'));
    % add utilities
    myaddpath( wb_path, 'hlp_microcache.m', fullfile('libs','utilities'));
    
    % rPCA tool
    myaddpath( wb_path, 'inexact_alm_rpca.m', fullfile('libs','inexact_alm_rpca'));
    myaddpath( wb_path, 'inexact_alm_rpca.m', fullfile('libs','inexact_alm_rpca','PROPACK'));
    
    % clean_rawdata0.32
    myaddpath( wb_path, 'clean_rawdata.m', fullfile('libs','clean_rawdata0.32'));
    
    % MARA tool
    myaddpath( wb_path, 'pop_processMARA.m', fullfile('libs','MARA-master'));
    
    % ADJUST
    myaddpath( wb_path, 'ADJUST.m', fullfile('libs','ADJUST1.1.1'));
    
    % add fieldtrip-20181025
    myaddpath( wb_path, 'ft_prepare_headmodel.m', fullfile('libs','fieldtrip-20181025'));
    myaddpath( wb_path, 'ft_prepare_headmodel.m', fullfile('libs','fieldtrip-20181025','forward'));
    myaddpath( wb_path, 'ft_prepare_headmodel.m', fullfile('libs','fieldtrip-20181025','inverse'));
    myaddpath( wb_path, 'ft_prepare_headmodel.m', fullfile('libs','fieldtrip-20181025','utilities'));
    myaddpath( wb_path, 'ft_prepare_headmodel.m', fullfile('libs','fieldtrip-20181025','plotting'));
else
    % warning('WeBrain subfolders not added ');
end;
% -------------------------------------------------------------------------
% find a function path and add path if not present
function myaddpath(WeBrainPath, functionname, pathtoadd)

tmpp = which(functionname);
tmpnewpath = [ WeBrainPath pathtoadd ];
if ~isempty(tmpp)
    tmpp = tmpp(1:end-length(functionname));
    if length(tmpp) > length(tmpnewpath), tmpp = tmpp(1:end-1); end; % remove trailing filesep
    if length(tmpp) > length(tmpnewpath), tmpp = tmpp(1:end-1); end; % remove trailing filesep
    %disp([ tmpp '     |        ' tmpnewpath '(' num2str(~strcmpi(tmpnewpath, tmpp)) ')' ]);
    if ~strcmpi(tmpnewpath, tmpp)
        warning('off', 'MATLAB:dispatcher:nameConflict');
        addpath(tmpnewpath);
        warning('on', 'MATLAB:dispatcher:nameConflict');
    end;
else
    %disp([ 'Adding new path ' tmpnewpath ]);
    addpath(tmpnewpath);
end;

function val = isWBdeployed2
%val = 1; return;
if exist('isdeployed')
     val = isdeployed;
else val = 0;
end;