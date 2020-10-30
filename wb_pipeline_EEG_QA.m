function wb_pipeline_EEG_QA(Input,Output,combs_project_id,WindowSeconds,HighPassband,seleChanns,badWindowThreshold,...
  robustDeviationThreshold,PowerFrequency,FrequencyNoiseThreshold,flagNotchFilter,correlationThreshold,...
  ransacCorrelationThreshold,ransacChannelFraction,ransacSampleSize,srate,ModeFlag)
% -------------------------------------------------------------------------
% Quality Assessmenting of a continuous EEG data, automatically. The bad data in small windows 
% of each channel could be detected by kinds of 4 methods, and a number of 
% indices related to the data quality will be calculated. Meanwhile, 
% the overall data quality rating will be also provided, including levels 
% of A, B, C, D (corresponding to perfect, good, poor, bad).

% Method 1:Detect constant or NaN/Inf singals in each window.
%
% Method 2: Detecting unusually high or low amplitude using robust standard 
%           deviation across time points in each window (Method 2). If the z 
%           score of robust time deviation falls below ‘robustDeviationThreshold’ 
%           or the absolute amplitude exceeds 200 microvolts (μV), the small 
%           window is considered to be bad.
% Method 3: Detecting high or power frequency noises in each window by 
%           calculating the noise-to-signal ratio based on Christian Kothe's 
%           method (Method 3). If the z score of estimate of signal above 40 Hz 
%           (power frequency - 10Hz) to that below 40 Hz above ‘highFrequencyNoiseThreshold’
%           or absolute NSR exceeds 0.5, the small window is considered to be bad.
%           Noting that if the sampling rate is below 2*power frequency, 
%           this step will be skipped.
% Method 4a: Detecting low correlations with other channels in each window using 
%           Pearson correlation (Method 4a). For Pearson correlation, If the
%           maximum correlation of the window of a channel to the other channels 
%           falls below ‘correlationThreshold’, the window is considered bad.
% Method 4b: Detecting low correlations with other channels in each window using 
%            RANSAC correlation (Method 4b).For RANSAC correlation, each 
%            window of a channel is predicted using RANSAC interpolation based 
%            on a RANSAC fraction of the channels. If the correlation of the 
%            prediction to the actual behavior falls below‘ransacCorrelationThreshold’
%            or calculation is too long, the window is marked as bad. The 
%            time cost of this method is high, and the channel locations are 
%            required. The RANSAC correlation is optional and default is not performed.
%
% Assumptions:
%  - The signal is a structure of continuous data with data, srate at least
%  - No segments of the EEG data have been removed.

% Methods 2 and 4b are adapted from code by Christian Kothe and Methods 3
% and 4a are adapted from code by Nima Bigdely-Shamlo
% -------------------------------------------------------------------------
% Input:
%     Input: zip paths of each subject (separate by commas).
%             e.g. '*\sub_01.zip,*\sub_02.zip'. EEG data will be loaded as
%         EEG structure imported using EEGLAB. EEG.data should be channels
%         X time points OR channels X time points X epoches.
%      Output: output path.
%      combs_project_id: project ID (only print for WeBrain).

%      WindowSeconds : window size in seconds (default = 1 sec)
%      HighPassband :  lower edge of the frequency for high pass filtering,
%                      Hz.Default is 1 Hz.
%      seleChanns : number with indices of the selected channels
%                      (e.g. [1:4,7:30] or 'all').Default is 'all';
%      badWindowThreshold : cutoff fraction of bad windows (default = 0.4)
%                      for detecting bad channels.
%
%      robustDeviationThreshold : Z-score cutoff for robust channel deviation (default = 5)
%
%      PowerFrequency : power frequency. default is 50 Hz (in Chinese).
%                      Noting that in USA, power frequency is 60Hz
%      flagNotchFilter : flagNotchFilter = 1: remove 0.5* power frequency
%                      noise using notch filtering. Default is off (flagNotchFilter = 0).
%      FrequencyNoiseThreshold : Z-score cutoff for noise-signal-rate (signal above 40 Hz).
%                                Default is 3;
%
%      correlationThreshold : maximal correlation below which window is bad (range is (0,1), default = 0.6)
%
%      ransacSampleSize : samples for computing ransac (default = 50)
%      ransacChannelFraction : fraction of channels for robust reconstruction (default = 0.3)
%      ransacCorrelationThreshold : cutoff correlation for abnormal wrt
%                           neighbors(default = [] | --> not
%                           performed).Default is 0.6.
%      srate: sampling rate of EEG data. It can be automatically detected in
%             EEG data. But for ASCII/Float .txt File or MATLAB .mat File, 
%             user should fill the sampling rate by hand. Default is ‘[]’.

% Output: a structure array of QA results.

% Qulaity Measures:

% results_QA.ONS   % Overall ratio of No Signal windows
% results_QA.OHA   % Overall ratio of windows of High Amplitudes
% results_QA.OFN   % Overall ratio of windows of high Frequency and power frequency Noise
% results_QA.OLC   % Overall ratio of windows of Low Correlation
% results_QA.OLRC  % Overall ratio of windows of Low RANSAC Correlation (optional)
% results_QA.badChannels   % Bad channels based on overall bad windows
% results_QA.NBC           % No. of bad channels
% results_QA.OBC           % Overall ratio of Bad Channels
% results_QA.OBClus        % Overall ratio of Bad Clusters 
% results_QA.ODQ           % Overall Data Quality: overall ratio of windows of good data
% results_QA.DataQualityRating  % Overall Data Quality Rating.
%                            % A: ODQ >= 90
%                            % B: ODQ >= 80 && ODQ < 90
%                            % C: ODQ >= 60 && ODQ < 80
%                            % D: ODQ < 60
%
% results_QA.allMAV      % mean absolute value of all windows
% results_QA.badMAV      % mean absolute value of bad windows
% results_QA.goodMAV     % mean absolute value of good windows
%
% results_QA.NoSignalMask                 % mask of windows with no signals
% results_QA.AmpliChannelMask             % mask of windows with high amplitudes
% results_QA.FrequencyNoiseMask           % mask of windows with high frequency (and power frequency, if applicable) noise
% results_QA.LowCorrelationMask           % mask of windows with low correlations
% results_QA.RansacBadWindowMask          % mask of windows with RANSAC low correlations
% results_QA.OverallBadMask               % mask of windows with overall bad signals
% results_QA.fractionBadWindows           % fractions of bad windows for each channel
% results_QA.badChannelsFromAll           % bad channels from all methods

% Paramerters:
% results_QA.parameters.srate                    % sampling rate
% results_QA.parameters.WindowSeconds            % window size in seconds (default = 1 sec)
% results_QA.parameters.HighPassband             % lower edge of the frequency for high pass filtering, Hz
% results_QA.parameters.selechanns               % number with indices of the selected channels (e.g. [1:4,7:30] or 'all').Default is 'all';
% results_QA.parameters.badWindowThreshold       % cutoff fraction of bad windows (default = 0.4)
% results_QA.parameters.PowerFrequency           % power frequency. default is 50 Hz (in Chinese). Noting that in USA, power frequency is 60Hz
%
% results_QA.parameters.robustDeviationThreshold     % Z-score cutoff for robust channel deviation (default = 4)
% results_QA.parameters.FrequencyNoiseThreshold      % Z-score cutoff for nosie-to-signal ratio (signal above 40 Hz).
% results_QA.parameters.correlationThreshold         % maximal correlation below which window is bad (range is (0,1), default = 0.4)
%
% results_QA.parameters.chanlocsflag                % flag of channel locations.flag == 1: have channel locations.
% results_QA.parameters.chanlocsXYZ                 % xyz coordinates of selected channels
% results_QA.parameters.chanlocs                    % channel locations of selected channels
% results_QA.parameters.ransacSampleSize            % samples for computing ransac (default = 50)
% results_QA.parameters.ransacChannelFraction       % fraction of channels for robust reconstruction (default = 0.25)
% results_QA.parameters.ransacCorrelationThreshold  % cutoff correlation for abnormal wrt neighbors(default = [] | --> not performed)
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% Code Summary for working in School of Life Science and Technology,UESTC.
% Author: Li Dong, e-mail: Lidong@uestc.edu.cn
% This template is for non commercial use only.
% It is freeware but not in the public domain.

% Written by Li Dong (UESTC, Lidong@uestc.edu.cn)
% $ 2020.03.04
% -------------------------------------------------------------------------

try
  wb_addpath();% add path
  disp('---------------------------------------------');
  disp(datestr(now));% computing date
  disp('Adding paths......');
  % ---------------------
  % check all inputs
  if nargin < 3
    disp('********FAILED********');
    disp('3 inputs are required at least.');
    error('3 inputs are required at least.');
  elseif nargin == 3
    WindowSeconds = 1;
    HighPassband = 1;
    seleChanns = 'all';
    badWindowThreshold = 0.4;
    robustDeviationThreshold = 5;
    PowerFrequency = 50;
    FrequencyNoiseThreshold = 3;
    flagNotchFilter = 0;
    correlationThreshold = 0.6;
    ransacCorrelationThreshold = [];
    ransacChannelFraction = 0.3;
    ransacSampleSize = 50;
    srate = '[]';
  elseif nargin == 4
    HighPassband = 1;
    seleChanns = 'all';
    badWindowThreshold = 0.4;
    robustDeviationThreshold = 5;
    PowerFrequency = 50;
    FrequencyNoiseThreshold = 3;
    flagNotchFilter = 0;
    correlationThreshold = 0.6;
    ransacCorrelationThreshold = [];
    ransacChannelFraction = 0.3;
    ransacSampleSize = 50;
    srate = '[]';
  elseif nargin == 5
    seleChanns = 'all';
    badWindowThreshold = 0.4;
    robustDeviationThreshold = 5;
    PowerFrequency = 50;
    FrequencyNoiseThreshold = 3;
    flagNotchFilter = 0;
    correlationThreshold = 0.6;
    ransacCorrelationThreshold = [];
    ransacChannelFraction = 0.3;
    ransacSampleSize = 50;
    srate = '[]';
  elseif nargin == 6
    badWindowThreshold = 0.4;
    robustDeviationThreshold = 5;
    PowerFrequency = 50;
    FrequencyNoiseThreshold = 3;
    flagNotchFilter = 0;
    correlationThreshold = 0.6;
    ransacCorrelationThreshold = [];
    ransacChannelFraction = 0.3;
    ransacSampleSize = 50;
    srate = '[]';
  elseif nargin == 7
    robustDeviationThreshold = 5;
    PowerFrequency = 50;
    FrequencyNoiseThreshold = 3;
    flagNotchFilter = 0;
    correlationThreshold = 0.6;
    ransacCorrelationThreshold = [];
    ransacChannelFraction = 0.3;
    ransacSampleSize = 50;
    srate = '[]';
  elseif nargin == 8
    PowerFrequency = 50;
    FrequencyNoiseThreshold = 3;
    flagNotchFilter = 0;
    correlationThreshold = 0.6;
    ransacCorrelationThreshold = [];
    ransacChannelFraction = 0.3;
    ransacSampleSize = 50;
    srate = '[]';
  elseif nargin == 9
    FrequencyNoiseThreshold = 3;
    flagNotchFilter = 0;
    correlationThreshold = 0.6;
    ransacCorrelationThreshold = [];
    ransacChannelFraction = 0.3;
    ransacSampleSize = 50;
    srate = '[]';
  elseif nargin == 10
    flagNotchFilter = 0;
    correlationThreshold = 0.6;
    ransacCorrelationThreshold = [];
    ransacChannelFraction = 0.3;
    ransacSampleSize = 50;
    srate = '[]';
  elseif nargin == 11
    correlationThreshold = 0.6;
    ransacCorrelationThreshold = [];
    ransacChannelFraction = 0.3;
    ransacSampleSize = 50;
    srate = '[]';
  elseif nargin == 12
    ransacCorrelationThreshold = [];
    ransacChannelFraction = 0.3;
    ransacSampleSize = 50;
    srate = '[]';
  elseif nargin == 13
    ransacChannelFraction = 0.3;
    ransacSampleSize = 50;
    srate = '[]';
  elseif nargin == 14
    ransacSampleSize = 50;
    srate = '[]';
  elseif nargin == 15
    srate = '[]';
  end
  
  % check inputs
  
  if isempty(WindowSeconds) || isequal(WindowSeconds,'[]')
    WindowSeconds = 1;
  elseif ischar(WindowSeconds)
    WindowSeconds = str2num(WindowSeconds);
  end
  
  if isempty(HighPassband) || isequal(HighPassband,'[]')
    HighPassband = 1;
  elseif ischar(HighPassband)
    HighPassband = abs(str2num(HighPassband));
  end
  
  if isempty(seleChanns) || isequal(seleChanns,'[]')
    seleChanns = 'all';
  end
  
  if isempty(badWindowThreshold) || isequal(badWindowThreshold,'[]')
    badWindowThreshold = 0.4;
  elseif ischar(badWindowThreshold)
    badWindowThreshold = str2num(badWindowThreshold);
    if badWindowThreshold < 0 || badWindowThreshold >1
      badWindowThreshold = 0.4;
    end
  end
  
  if isempty(robustDeviationThreshold) || isequal(robustDeviationThreshold,'[]')
    robustDeviationThreshold = 5;
  elseif ischar(robustDeviationThreshold)
    robustDeviationThreshold = str2num(robustDeviationThreshold);
    if robustDeviationThreshold < 0
      robustDeviationThreshold = 5;
    end
  end
  
  if isempty(PowerFrequency) || isequal(PowerFrequency,'[]')
    PowerFrequency = 50;
  elseif ischar(PowerFrequency)
    PowerFrequency = str2num(PowerFrequency);
    if PowerFrequency < 0
      PowerFrequency = 50;
    end
  end
  
  
  if isempty(FrequencyNoiseThreshold) || isequal(FrequencyNoiseThreshold,'[]')
    FrequencyNoiseThreshold = 3;
  elseif ischar(FrequencyNoiseThreshold)
    FrequencyNoiseThreshold = str2num(FrequencyNoiseThreshold);
    if FrequencyNoiseThreshold < 0
      FrequencyNoiseThreshold = 3;
    end
  end
  
  if isempty(flagNotchFilter) || isequal(flagNotchFilter,'[]')
    flagNotchFilter = 0;
  elseif ischar(flagNotchFilter)
    flagNotchFilter = str2num(flagNotchFilter);
    if flagNotchFilter > 1 || flagNotchFilter < 0
      flagNotchFilter = 0;
    end
  end
  
  
  if isempty(correlationThreshold) || isequal(correlationThreshold,'[]')
    correlationThreshold = 0.6;
  elseif ischar(correlationThreshold)
    correlationThreshold = str2num(correlationThreshold);
    if correlationThreshold < 0 || correlationThreshold >1
      correlationThreshold = 0.6;
    end
  end
  
  if isempty(ransacCorrelationThreshold) || isequal(ransacCorrelationThreshold,'[]')
    ransacCorrelationThreshold = [];
  elseif ischar(ransacCorrelationThreshold)
    ransacCorrelationThreshold = str2num(ransacCorrelationThreshold);
    if ransacCorrelationThreshold < 0 || ransacCorrelationThreshold >1
      ransacCorrelationThreshold = [];
    end
  end
  
  
  if isempty(ransacChannelFraction) || isequal(ransacChannelFraction,'[]')
    ransacChannelFraction = 0.3;
  elseif ischar(ransacChannelFraction)
    ransacChannelFraction = str2num(ransacChannelFraction);
    if ransacChannelFraction < 0 || ransacChannelFraction >1
      ransacChannelFraction = 0.3;
    end
  end
  
  if isempty(ransacSampleSize) || isequal(ransacSampleSize,'[]')
    ransacSampleSize = 50;
  elseif ischar(ransacSampleSize)
    ransacSampleSize = str2num(ransacSampleSize);
    if ransacSampleSize < 0
      ransacSampleSize = 50;
    end
  end
  
  % ----------
  % display parameters
  disp('Start Project......');
  disp(['Project ID: ',num2str(combs_project_id)]);
  % -------------------------------------------------------------------------
  % loading data and calculating
  % fprintf(fid,'loading data and calculating...,\r\n');
  disp('loading data and calculating......');
  files = regexp(Input,',','split'); % split strings by comma
  Ns = length(files); % number of subjects
  disp(['No. of subjects: ',num2str(Ns)]);
  skipped_filename = [];
  temp_QA = []; % temp indices of quality assessment for all subjects
  k = 1;
  
  global bar bar_str;
  if ModeFlag == 2 
     bar_str=['运行中...','10','%'];   
     waitbar(10/100,bar,bar_str);        % 更新进度条bar
  elseif ModeFlag == 3
     bar_str=['运行中...','55','%'];   
     waitbar(55/100,bar,bar_str);        % 更新进度条bar    
  end

  for s = 1:Ns
    [filepath,filename,~] = fileparts(files{s});
    disp('===============');
    if ~isempty(filename)
      folders = regexp(filepath,filesep,'split');
      if isempty(folders{length(folders)})
        foldername = folders{length(folders)-1};
      else
        foldername = folders{length(folders)};
      end
      if length(filename)>33 && isequal('0',foldername)
        filename = filename(34:end); % if filename is too long, display last words only
      end
      disp(['calculating: ',filename]);
    else
      folders = regexp(files{s},filesep,'split');
      if isempty(folders{length(folders)})
        filename = folders{length(folders)-1};
        try foldername = folders{length(folders)-2};catch;foldername = [];end;
      else
        filename = folders{length(folders)};
        try foldername = folders{length(folders)-1};catch;foldername = [];end;
      end
      
      if length(filename)>33 && isequal('0',foldername)
        filename = filename(34:end); % if filename is too long, display last words only
      end
      disp(['calculating: ',filename]);
    end
    % -------------------
    try
      % loading data
      EEG = wb_loadEEG(files{s},Output); % load EEG data
      Nchanns = size(EEG.data,1); % No. of channels in EEG
      % -------------------
      % check sampling rate
      if ~isequal(srate,'[]')
        srate1 = str2num(srate);
        if isfinite(srate1) && srate1 > 0
          EEG.srate = srate1;
        end
      end
      
      % check select channs
      if isequal(seleChanns,'all')
        selchan = 1:Nchanns;
      else
        selchan = str2num(seleChanns);
      end
      
      if isnumeric(selchan) && all(isfinite(selchan)) && ~isempty(selchan) && max(selchan) <= Nchanns % is numeric array?
        disp(['No. of channels: ',num2str(Nchanns)]);
        disp(['No. of selected channels: ',num2str(length(selchan))]);
        disp(['Selected channels: ',num2str(selchan)]);
      else
        % disp('********FAILED********');
        warning('selchan is invalid.');
        error('selchan is invalid.');
      end
      % -------------------------
      try
        % Quality Assessmenting
        [results_QA] = wb_EEG_QA(EEG,WindowSeconds,HighPassband,selchan,badWindowThreshold,...
          robustDeviationThreshold,PowerFrequency,FrequencyNoiseThreshold,flagNotchFilter,correlationThreshold,...
          ransacCorrelationThreshold,ransacChannelFraction,ransacSampleSize);
      
        disp(['Overall Data Quality (raw data): ',num2str(results_QA.ODQ)]);
        disp(['Data Quality Rating (raw data): ',results_QA.DataQualityRating]);
        % now the webrain can load several format of EEG data, and also save results or data.
        % ------------------
        % saving results
        disp('saving results...');
        output_temp = fullfile(Output,['results_QA_',filename,'.mat']);
        save(output_temp,'results_QA');
        
        % save QA indices in temporary cell
        temp_QA{s,1} = s;
        temp_QA{s,2} = filename;
        temp_QA{s,3} = results_QA.ONS;
        temp_QA{s,4} = results_QA.OHA;
        temp_QA{s,5} = results_QA.OFN;
        temp_QA{s,6} = results_QA.OLC;
        temp_QA{s,7} = results_QA.OLRC;
        temp_QA{s,8} = results_QA.badChannels;
        temp_QA{s,9} = results_QA.NBC;
        temp_QA{s,10} = results_QA.OBC;
        temp_QA{s,11} = results_QA.OBClus;
        temp_QA{s,12} = results_QA.allMAV;
        temp_QA{s,13} = results_QA.badMAV;
        temp_QA{s,14} = results_QA.goodMAV;
        temp_QA{s,15} = results_QA.ODQ;
        temp_QA{s,16} = results_QA.DataQualityRating;
      catch
        warning('Failed to assess EEG data');
        disp(['Skip: ',filename]);
        skipped_filename{k} = filename;
        temp_QA{s,1} = s;
        temp_QA{s,2} = filename;
        for k1 = 3:15
          temp_QA{s,k1} = [];
        end
        k = k+1;
      end;
    catch
      warning('Failed to load or assess EEG data');
      disp(['Skip: ',filename]);
      skipped_filename{k} = filename;
      temp_QA{s,1} = s;
      temp_QA{s,2} = filename;
      for k1 = 3:15
        temp_QA{s,k1} = [];
      end
      k = k+1;
    end
    
    if ModeFlag == 2 
        process_num=10+s*70/Ns;
        bar_str=['运行中...',num2str(process_num),'%'];   
        waitbar(process_num/100,bar,bar_str);        % 更新进度条bar
    elseif ModeFlag == 3
        process_num=55+s*35/Ns;
        bar_str=['运行中...',num2str(process_num),'%'];   
        waitbar(process_num/100,bar,bar_str);        % 更新进度条bar    
    end
    
  end
  
  
  if ModeFlag == 2 
     bar_str=['运行中...','80','%'];   
     waitbar(80/100,bar,bar_str);        % 更新进度条bar
  elseif ModeFlag == 3
     bar_str=['运行中...','90','%'];   
     waitbar(90/100,bar,bar_str);        % 更新进度条bar    
  end
  
  try
    VariName1 = {'SubNumber','filename','ONS','OHA','OFN','OLC','OLRC','badChannels',...
      'NBC','OBC','OBClus','allMAV','badMAV','goodMAV','ODQ','DataQualityRating'};
    QA_table = cell2table(temp_QA,'VariableNames',VariName1);
    disp('saving a table containing all QA results...');
    if ischar(combs_project_id)
      output_temp = fullfile(Output,['TaskID-', combs_project_id,'_QA_table.mat']);
    else
      output_temp = fullfile(Output,['TaskID-', num2str(combs_project_id),'_QA_table.mat']);
    end
    save(output_temp,'QA_table');  % save as matlab table
    
    try
      C1 = table2cell(TableQA);
      xlswrite(output_temp,[VariName1;C1]); % try to save as excel file
    catch
    end
  catch
    warning('Failed to save all QA results in a table');
  end;
  
  
  if ModeFlag == 2 
     bar_str=['运行中...','90','%'];   
     waitbar(90/100,bar,bar_str);        % 更新进度条bar
  elseif ModeFlag == 3
     bar_str=['运行中...','95','%'];   
     waitbar(95/100,bar,bar_str);        % 更新进度条bar    
  end
  
  disp('------------------------')
  if isempty(skipped_filename)
    disp('********SUCCESS********');
  else
    disp('********CalculatedSubjects********');
    disp(['No. of Calculated Subjects:',num2str(Ns-length(skipped_filename))]);
    disp('********SkippedSubjects********');
    disp(['No. of Skipped Subjects:',num2str(length(skipped_filename))]);
    for k1 = 1:length(skipped_filename)
      disp(skipped_filename{k1});
    end
    disp('********SUCCESS********');
  end
catch
  disp('********FAILED********');
  close(bar);
end;
