function [results] = wb_EEG_QA_erp(EEG,event1,epochlimits,HighPassband,selechanns,badEpochThreshold,...
    robustDeviationThreshold,PowerFrequency,FrequencyNoiseThreshold,flagNotchFilter,correlationThreshold,...
    ransacCorrelationThreshold,ransacChannelFraction,ransacSampleSize)
% Quality Assessmenting of ERP data at trial level, automatically. This function uses 5 methods
% for detecting bad channels in ERP epoch windows. And also the overall data quality rating will
% be provided, including levels of A,B,C,D (corresponding to perfect, good, poor, bad).

% Method 1:Detect constant or NaN/Inf singals in each epoch.
%
% Method 2: too low or high amplitude in each epoch. If the z score of robust
%           channel deviation falls below robustDeviationThreshold, the channel is
%           considered to be bad in that epoch.
% Method 3: too low an NSR in each epoch. If the z score of estimate of signal above
%           40 Hz (power frequency - 10Hz) to that below 40 Hz above highFrequencyNoiseThreshold,
%           the channel is considered to be bad in that epoch.
% Method 4: low correlation with other channels. Here correlationWindowSize is the epoch
%           size over which the correlation is computed. If the maximum
%           correlation of the channel to the other channels falls below
%           correlationThreshold, the channel is considered bad in that epoch.
% Method 5: each channel is predicted using ransac interpolation based
%           on a ransac fraction of the channels in each epoch. If the correlation of
%           the prediction to the actual behavior is too low for too
%           long, the channel is marked as bad in that epoch. The time cost
%           of this method is high, and the method is optional (Default is not performed).
%
% Assumptions:
%  - The signal is a structure of continuous data with data, srate at least
%  - No segments of the EEG data have been removed.

% Methods 2 and 5 are adapted from code by Christian Kothe and Methods 3
% and 4 are adapted from code by Nima Bigdely-Shamlo
% -------------------------------------------------------------------------
% Input:
%      EEG:  EEG structure loaded by EEGLAB (EEG data is raw data).
%            EEG.data and EEG.srate are required at least.
%      eventl: specified event types or event indices (e.g. event label)
%              If event label is not found, NO data will be assessed.
%      epochlimits : epoch latency range [start, end] in seconds relative
%                    to the time-locking events. Default is [-0.2,0.8].
%      HighPassband :  lower edge of the frequency for high pass filtering,
%                      Hz.Default is 1.
%      selechanns : number with indices of the selected channels
%                      (e.g. [1:4,7:30] or 'all').Default is 'all';
%      badEpochThreshold : cutoff fraction of bad epochs (default = 0.4)
%                      for detecting bad channels.
%
%      robustDeviationThreshold : Z-score cutoff for robust channel deviation (default = 5)
%
%      PowerFrequency : power frequency. default is 50 Hz (in Chinese).
%                      Noting that in USA, power frequency is 60Hz
%      flagNotchFilter : flagNotchFilter = 1: remove 0.5* power frequency
%                      noise using notch filtering. Default is off (flagNotchFilter = 0).
%      FrequencyNoiseThreshold = : Z-score cutoff for NSR (signal above 40 Hz).
%                                Default is 3;
%
%      correlationThreshold : maximal correlation below which epoch is bad (range is (0,1), default = 0.6)
%
%      ransacSampleSize : samples for computing ransac (default = 50)
%      ransacChannelFraction : fraction of channels for robust reconstruction (default = 0.3)
%      ransacCorrelationThreshold : cutoff correlation for abnormal wrt
%                           neighbors(default = [] | --> not
%                           performed).Default is 0.6.

% Output: a structure of results.

% Qulaity Measures:

% results.ONS   % Overall ratio of No Signal epochs
% results.OHA   % Overall ratio of epochs of High Amplitudes
% results.OFN   % Overall ratio of epochs of high Frequency and power frequency Noise
% results.OLC   % Overall ratio of epochs of Low Correlation
% results.OLRC  % Overall ratio of epochs of Low RANSAC Correlation (optional)
% results.badChannels   % Bad channels based on overall bad trials
% results.NBC           % No. of bad channels
% results.OBC           % Overall ratio of Bad Channels
% results.ODQ           % Overall Data Quality: overall ratio of trials/epochs of good data
% results.DataQualityRating  % Overall Data Quality Rating.
%                            % A: ODQ >= 90
%                            % B: ODQ >= 80 && ODQ < 90
%                            % C: ODQ >= 60 && ODQ < 80
%                            % D: ODQ < 60
%
% results.allMAV      % mean value of all epochs
% results.badMAV      % mean value of bad epochs
% results.goodMAV     % mean value of good epochs
%
% results.NoSignalMask                 % mask of epochs with no signals
% results.AmpliChannelMask             % mask of epochs with high amplitudes
% results.FrequencyNoiseMask           % mask of epochs with high frequency (and power frequency, if applicable) noise
% results.LowCorrelationMask           % mask of epochs with low correlations
% results.RansacBadEpochMask          % mask of epochs with RANSAC low correlations
% results.OverallBadMask               % mask of epochs with overall bad signals
% results.fractionBadEpochs           % fractions of bad trials/epochs for each channel
% results.badChannelsFromAll           % bad channels from all methods

% Paramerters:
% results.parameters.srate                    % sampling rate
% results.parameters.event                    % event type (event1)
% results.parameters.eventlist                % event list of event1
% results.parameters.Nepoch                   % No. of epochs
% results.parameters.HighPassband             % lower edge of the frequency for high pass filtering, Hz
% results.parameters.selechanns               % number with indices of the selected channels (e.g. [1:4,7:30] or 'all').Default is 'all';
% results.parameters.badEpochThreshold       % cutoff fraction of bad epochs (default = 0.4)
% results.parameters.PowerFrequency           % power frequency. default is 50 Hz (in Chinese). Noting that in USA, power frequency is 60Hz
%
% results.parameters.robustDeviationThreshold     % Z-score cutoff for robust channel deviation (default = 4)
% results.parameters.FrequencyNoiseThreshold      % Z-score cutoff for NSR (signal above 40 Hz).
% results.parameters.correlationThreshold         % maximal correlation below which epoch is bad (range is (0,1), default = 0.4)
%
% results.parameters.chanlocsflag                % flag of channel locations.flag == 1: have channel locations.
% results.parameters.chanlocsXYZ                 % xyz coordinates of selected channels
% results.parameters.chanlocs                    % channel locations of selected channels
% results.parameters.ransacSampleSize            % samples for computing ransac (default = 50)
% results.parameters.ransacChannelFraction       % fraction of channels for robust reconstruction (default = 0.25)
% results.parameters.ransacCorrelationThreshold  % cutoff correlation for abnormal wrt neighbors(default = [] | --> not performed)
% -------------------------------------------------------------------------
% usage example:
%
% HighPassband = 1;        % lower edge of the frequency for high pass filtering, Hz. default is 1 Hz.
% selechanns = 'all'; %[1:31,33:62];%'all';      % number with indices of the selected channels (e.g. [1:4,7:30] or 'all').Default is 'all';
% badEpochThreshold = 0.4;         % cutoff fraction of bad epochs (default = 0.4) for detecting bad channels.
% PowerFrequency = 50;              % power frequency. default is 50 Hz (in Chinese). Noting that in USA, power frequency is 60Hz
% flagNotchFilter = 0;              % flagNotchFilter = 1: remove 0.5* power frequency noise using notch filtering.
%
% robustDeviationThreshold = 5;     % Z-score cutoff for robust channel deviation (default = 5)
% FrequencyNoiseThreshold = 3;      % Z-score cutoff for NSR (signal above 40 Hz).Default is 3.
% correlationThreshold = 0.6;       % correlation below which epoch is bad (range is (0,1), default = 0.6)
%
% ransacSampleSize = 50;            % samples for computing ransac (default = 50)
% ransacChannelFraction = 0.3;      % fraction of channels for robust reconstruction (default = 0.3)
% ransacCorrelationThreshold = [];  % cutoff correlation for abnormal wrt neighbors(default = [] | --> not performed)
% epochlimits = [-0.2,0.8];
% event1 = 'S22,S222';
% [results] = wb_EEG_QA_erp(EEG,event1,epochlimits,HighPassband,selechanns,badEpochThreshold,...
%           robustDeviationThreshold,PowerFrequency,FrequencyNoiseThreshold,flagNotchFilter,correlationThreshold,...
%           ransacCorrelationThreshold,ransacChannelFraction,ransacSampleSize);
% -------------------------------------------------------------------------
% Written by Li Dong,UESTC (Lidong@uestc.edu.cn)
% $ 2019.10.2
% -------------------------------------------------------------------------
if nargin < 2
    error ('Two input is reqiured at least!!!!!');
elseif nargin == 2
    epochlimits = [-0.2,0.8];
    HighPassband = 1;
    selechanns = 'all';
    badEpochThreshold = 0.4;
    robustDeviationThreshold = 5;
    PowerFrequency = 50;
    FrequencyNoiseThreshold = 3;
    flagNotchFilter = 0;
    correlationThreshold = 0.6;
    ransacCorrelationThreshold = [];
    ransacChannelFraction = 0.3;
    ransacSampleSize = 50;
elseif nargin == 3
    HighPassband = 1;
    selechanns = 'all';
    badEpochThreshold = 0.4;
    robustDeviationThreshold = 5;
    PowerFrequency = 50;
    FrequencyNoiseThreshold = 3;
    flagNotchFilter = 0;
    correlationThreshold = 0.6;
    ransacCorrelationThreshold = [];
    ransacChannelFraction = 0.3;
    ransacSampleSize = 50;
elseif nargin == 4
    selechanns = 'all';
    badEpochThreshold = 0.4;
    robustDeviationThreshold = 5;
    PowerFrequency = 50;
    FrequencyNoiseThreshold = 3;
    flagNotchFilter = 0;
    correlationThreshold = 0.6;
    ransacCorrelationThreshold = [];
    ransacChannelFraction = 0.3;
    ransacSampleSize = 50;
elseif nargin == 5
    badEpochThreshold = 0.4;
    robustDeviationThreshold = 5;
    PowerFrequency = 50;
    FrequencyNoiseThreshold = 3;
    flagNotchFilter = 0;
    correlationThreshold = 0.6;
    ransacCorrelationThreshold = [];
    ransacChannelFraction = 0.3;
    ransacSampleSize = 50;
elseif nargin == 6
    robustDeviationThreshold = 5;
    PowerFrequency = 50;
    FrequencyNoiseThreshold = 3;
    flagNotchFilter = 0;
    correlationThreshold = 0.6;
    ransacCorrelationThreshold = [];
    ransacChannelFraction = 0.3;
    ransacSampleSize = 50;
elseif nargin == 7
    PowerFrequency = 50;
    FrequencyNoiseThreshold = 3;
    flagNotchFilter = 0;
    correlationThreshold = 0.6;
    ransacCorrelationThreshold = [];
    ransacChannelFraction = 0.3;
    ransacSampleSize = 50;
elseif nargin == 8
    FrequencyNoiseThreshold = 3;
    flagNotchFilter = 0;
    correlationThreshold = 0.6;
    ransacCorrelationThreshold = [];
    ransacChannelFraction = 0.3;
    ransacSampleSize = 50;
elseif nargin == 9
    flagNotchFilter = 0;
    correlationThreshold = 0.6;
    ransacCorrelationThreshold = [];
    ransacChannelFraction = 0.3;
    ransacSampleSize = 50;
elseif nargin == 10
    correlationThreshold = 0.6;
    ransacCorrelationThreshold = [];
    ransacChannelFraction = 0.3;
    ransacSampleSize = 50;
elseif nargin == 11
    ransacCorrelationThreshold = [];
    ransacChannelFraction = 0.3;
    ransacSampleSize = 50;
elseif nargin == 12
    ransacChannelFraction = 0.3;
    ransacSampleSize = 50;
elseif nargin == 13
    ransacSampleSize = 50;
end

% -------------------------------------------------------------------------
% checking all inputs

if isempty(epochlimits)
    epochlimits = [-0.2,0.8];
end
if isempty(HighPassband)
    HighPassband = 1;
end
if isempty(selechanns)
    selechanns= 'all';
end
if isempty(badEpochThreshold)
    badEpochThreshold = 0.4;
end
if isempty(robustDeviationThreshold)
    robustDeviationThreshold = 5;
end
if isempty(PowerFrequency)
    PowerFrequency = 50;
end
if isempty(FrequencyNoiseThreshold)
    FrequencyNoiseThreshold = 3;
end
if isempty(flagNotchFilter)
    flagNotchFilter = 0;
end
if isempty(correlationThreshold)
    correlationThreshold = 0.6;
end
if isempty(ransacChannelFraction)
    ransacChannelFraction = 0.3;
end
if isempty(ransacSampleSize)
    ransacSampleSize = 50;
end

% check sampling rate
try
    srate = EEG.srate; % sampling rate
    if isfinite(srate)
        disp(['sampling rate = ',num2str(srate)]);
        if isempty(epochlimits)
            disp('use default epoch range')
            epochlimits = [-0.2,0.8];
        end
        disp(['epoch range = [',num2str(epochlimits(1)),',',num2str(epochlimits(2)),'] s']);
        epochLenth1 = round(epochlimits * srate);
    else
        disp('sampling rate is invalide');
        error('sampling rate is invalide');
    end
catch
    disp('sampling rate is not found');
    error('sampling rate is not found');
end

% check EEG data
try
    if isempty(EEG.data)
        error('EEG.data is empty!!!!!');
    else
        if length(size(EEG.data)) == 3
            error('epoched EEG data is not supported, and the size of EEG.data must be channels X time points!');
        end
    end
catch
    error('EEG.data is not exist!!!!');
end

% check channs
if isequal(selechanns,'all')
    selechanns = 1:size(EEG.data,1);
end
Nchan = length(selechanns); % No. of selected channs
disp(['No. of selected channels: ',num2str(Nchan)]);

% check channel locations
chanlocsflag = 0;
try
    if isfield(EEG,'chanlocs')
        if ~(isfield(EEG.chanlocs,'X') && isfield(EEG.chanlocs,'Y') && isfield(EEG.chanlocs,'Z') && all([length([EEG.chanlocs.X]),length([EEG.chanlocs.Y]),length([EEG.chanlocs.Z])] > length(EEG.chanlocs)*0.5))
            chanlocsflag = 0;
            warning('because most of your channels do not have X,Y,Z location measurements, the RANSAC method is ignored');
        else
            % get the matrix of selected channel locations [3xN]
            [x,y,z] = deal({EEG.chanlocs.X},{EEG.chanlocs.Y},{EEG.chanlocs.Z});
            x = x(selechanns);
            y = y(selechanns);
            z = z(selechanns);
            usable_channels = find(~cellfun('isempty',x) & ~cellfun('isempty',y) & ~cellfun('isempty',z));
            chanlocsXYZ = [cell2mat(x(usable_channels));cell2mat(y(usable_channels));cell2mat(z(usable_channels))];
            chanlocsflag = 1;
            if size(chanlocsXYZ,2) ~= Nchan
                chanlocsflag = 0;
                warning('some selected channels do not have xyz coordinates, the RANSAC method is ignored');
            end
            
        end
    else
        chanlocsflag = 0;
        warning('channel location is not found, the RANSAC method is ignored');
    end
catch
    warning('there are some unknow errors of channel locations, the RANSAC method is ignored');
end

% check events and generate event list
flag2 = 0;
if ~isempty(event1)
    % find eventlabel and bad block
    if isfield(EEG,'event')
        allevents = EEG.event;
        if ~isempty(allevents)
            events1 = regexp(event1,',','split'); % split strings by comma
            Ne1 = length(events1); % number of event1
            disp('List of event types for assessing: ');
            disp(events1);
            IndexInd = [];
            for i1 = 1:Ne1
                tempInd = wb_findevent(events1{1,i1},allevents);
                IndexInd = [IndexInd,tempInd.index];
            end
            if ~isempty(IndexInd)
                eventlist1 = allevents(IndexInd);
                flag2 = 1; % flag1 = 1: event type is found in EEG events;
                disp(['event type: ',num2str(event1),' is found in events']);
            else
                flag2 = 0; % flag1 = 0: event type is not found in events.
                warning(['all event type (', num2str(event1),') is not found in EEG.event, NO data is assessed']);
            end
        else
            warning('events are empty in EEG, NO data is assessed');
            % error('events are empty in EEG, NO data is assessed');
        end
    else
        warning('events are not found in EEG, NO data is assessed');
        % error('events are not found in EEG, NO data is assessed');
    end
else
    warning('event1 is empty, NO data is assessed');
    % error('event1 is empty, NO data is assessed');
end

if flag2 == 1
    % =========================================================================
    % Detecting bad segements using several methods
    disp('------------');
    disp('Detecting bad epochs using several methods...');
    disp('------------');
    % --------------------------------------
    % high pass filtering
    disp('High Pass filtering...');
    EEG = pop_eegfiltnew(EEG,HighPassband,[],[],0);
    % --------------------------------------
    % get the data required
    Nt = size(EEG.data,2);
    Nepoch = length(eventlist1);
    epochdata = getepochdata(EEG,eventlist1,epochLenth1);
    epochdata = epochdata(selechanns,:,:);
    disp(['No. of time points (all data): ',num2str(Nt)]);
    disp(['No. of epochs: ',num2str(Nepoch)]);
    % --------------------------------------
    % Initialization
    % NoSignalMask = zeros(Nchan,Nwin);
    % HighAmpliMask = zeros(Nchan,Nwin);
    %
    % LowCorrelationMask = zeros(Nchan,Nwin);
    % --------------------------------------
    % Method 1:
    % Detect constant or NaN/Inf singals in each epoch
    disp('------------');
    disp('Detecting constant, Inf, or NaN channels......');
    median1 = reshape(mad(epochdata, 1, 2),Nchan,Nepoch);
    std1 = reshape(std(epochdata, 1, 2),Nchan,Nepoch);
    NanSignalMask = reshape(sum(~isfinite(epochdata),2),Nchan,Nepoch);
    NoSignalMask = double( median1 < 10e-10 | std1 < 10e-10) + NanSignalMask;
    % ---------------------------------------
    % Method 2:
    % Detect unusually high or low amplitude using robust STD
    disp('------------');
    disp('Detecting unusually high or low amplitude using robust STD......');
    disp(['Robust deviation threshold: ',num2str(robustDeviationThreshold)]);
    
    index1 = abs(epochdata) > 100;  % absolute amplitude > 100 ¦ÌV
    high1 = reshape(sum(index1,2),Nchan,Nepoch) > 0;

    channelDeviation = reshape(0.7413 *iqr(epochdata,2),Nchan,Nepoch); % Robust estimate of SD
    channelDeviationSD = 0.7413*iqr(channelDeviation(:));
    channelDeviationMedian = nanmedian(channelDeviation(:),1);
    robustChannelDeviation = (channelDeviation - channelDeviationMedian) / channelDeviationSD;
    HighAmpliMask = abs(robustChannelDeviation) > robustDeviationThreshold | isnan(robustChannelDeviation) | high1;
    % ----------------------------------------
    % Method 3: Compute the NSR (based on Christian Kothe's clean_channels)
    % Note: RANSAC and global correaltion uses the filtered values X of the data
    disp('------------');
    if flagNotchFilter == 1
        disp('Detecting high frequency noise and power frequency noise using noise-to-signal ratio......');
    else
        disp('Detecting high frequency noise using noise-to-signal ratio......');
    end
    
    disp(['Frequency noise threshold: ',num2str(FrequencyNoiseThreshold)]);
    % FrequencyNoiseMask = zeros(Nchan,Nwin);
    if srate > 2*PowerFrequency
        % Remove signal content above 40Hz/50Hz and below 1 Hz
        disp('low Pass filtering...');
        EEG1 = pop_eegfiltnew(EEG,[],PowerFrequency-10,[],0); % In Chinese, the power frequency is 50Hz, so set the high pass frequency as 50-10=40.
        if flagNotchFilter == 1
            disp('Notch filtering for 0.5*power frequency...');
            EEG1 = pop_eegfiltnew(EEG1,0.5*PowerFrequency - 5, 0.5*PowerFrequency + 5,[],1); % notch filtering for 0.5* power frequency
        end
        % checking high frequency noise
        % --------------
        % X = EEG1.data(selechanns,1:winlenth*Nepoch);
        % X = reshape(X,Nchan,winlenth,Nepoch);
        X = getepochdata(EEG1,eventlist1,epochLenth1);
        X = X(selechanns,:,:);
        % Determine z-scored level of EM noise-to-signal ratio for each channel
        noisiness = mad(epochdata - X, 1, 2)./mad(X, 1, 2);
        noisiness = reshape(noisiness,Nchan,Nepoch);
        
        noisinessMedian = nanmedian(noisiness(:));
        noisinessSD = mad(noisiness(:), 1)*1.4826;
        zscoreFreNoiseTemp = (noisiness - noisinessMedian) ./ noisinessSD;
        
        %     noisinessMedian = nanmedian(noisiness);
        %     noisinessSD = mad(noisiness, 1)*1.4826;
        %     zscoreFreNoiseTemp = bsxfun ( @minus, noisiness, noisinessMedian);
        %     zscoreFreNoiseTemp = bsxfun ( @rdivide, zscoreFreNoiseTemp,noisinessSD);
        
        FrequencyNoiseMask = (abs(zscoreFreNoiseTemp) > FrequencyNoiseThreshold) | isnan(zscoreFreNoiseTemp) | (abs(noisiness) > 0.5); % or the absolute noise-to-signal ratio > 0.5
        FrequencyNoiseMask = FrequencyNoiseMask .* (noisiness > 0.0075);  % the error between signals of twice low pass fitering is about 0.0075, so the noisiness < 0.0075 may be indistinguishable.
        
    else
        warning('The sampling rate is below 2*PowerFrequency (too low), detecting high frequency noise is skipped');
        X = getepochdata(EEG,eventlist1,epochLenth1);
        X = X(selechanns,:,:);
        FrequencyNoiseMask = zeros(Nchan,Nepoch);
    end
    
    % -----------------------------------------
    % Method 4: Global correlation criteria in time domain (from Nima Bigdely-Shamlo)
    disp('------------');
    disp('Detecting low correlation with other channels......');
    disp(['correlation threshold: ',num2str(correlationThreshold)]);
    
    channelCorrelations = zeros(Nchan,Nepoch);
    for k1 = 1:Nepoch
        eegPortion = squeeze(X(:, :, k1))'; % using filtered data X
        windowCorrelation = corrcoef(eegPortion);
        abs_corr = abs(windowCorrelation - eye(Nchan,Nchan));
        channelCorrelations(:,k1)  = quantile(abs_corr, 0.98); % approximate maximal correlation: quantile of 98%
    end;
    
    dropOuts = isnan(channelCorrelations) | isnan(noisiness);
    channelCorrelations(dropOuts) = 0;
    % noisiness(dropOuts) = 0;
    LowCorrelationMask = channelCorrelations < correlationThreshold;
    
    % -------------------------------------------------
    % Method 5: Detecting low correlation using RANSAC correlation (may not be performed if channel location is empty)
    if isempty(ransacCorrelationThreshold) || ~isfinite(ransacCorrelationThreshold)
      RansacBadEpochMask = zeros(Nchan,Nepoch);
    else
      if chanlocsflag == 1 % if have channel location
        disp('------------');
        disp('Detecting low correlation using RANSAC method......');
        disp(['RANSAC Correlation Threshold:',num2str(ransacCorrelationThreshold)]);
        
        subset_size = round(ransacChannelFraction * Nchan);
        
        % caculate all-channel reconstruction matrices from random channel subsets
        P = hlp_microcache('cleanchans',@calc_projector,chanlocsXYZ,ransacSampleSize,subset_size);
        RansacCorrelation = zeros(Nchan,Nepoch);
        
        % calculate each channel's correlation to its RANSAC reconstruction for each epoch
        % timePassedList = zeros(Nwin,1);
        for iw = 1:Nepoch
          % tic; % makoto
          XX = X(:,:,iw)';
          YY = sort(reshape(XX*P,size(X,2),Nchan,ransacSampleSize),3);
          YY = YY(:,:,round(size(YY,3)/2));
          RansacCorrelation(:,iw) = sum(XX.*YY)./(sqrt(sum(XX.^2)).*sqrt(sum(YY.^2)));
          %         timePassedList(iw) = toc; % makoto
          %         medianTimePassed = median(timePassedList(1:iw));
          %         disp(sprintf('clean_channel: %3.0d/%d, %.1f minutes remaining.', iw,Nwin, medianTimePassed*(Nwin-iw)/60)); % makoto
        end
        RansacBadEpochMask = RansacCorrelation < ransacCorrelationThreshold | isnan(RansacCorrelation);
      else
        RansacBadEpochMask = zeros(Nchan,Nepoch);
      end
    end
    
    % =========================================================================
    % quality assessment
    disp('------------');
    disp('Quality Assessment...');
    disp('Detecting bad channels...');
    disp(['Bad Epoch Threshold:',num2str(badEpochThreshold)]);
    OverallBadMask = NoSignalMask + HighAmpliMask + FrequencyNoiseMask + LowCorrelationMask + RansacBadEpochMask; % considering all methods
    OverallBadMask = OverallBadMask > 0;
    fractionBadEpochs = sum(OverallBadMask,2)/Nepoch;
    badChannelsFromAll = fractionBadEpochs > badEpochThreshold; % bad channels
    
    % Calculate the quality measures
    N_all = Nchan*Nepoch;
    % overall ratio of no signal epochs
    ONS = nansum(NoSignalMask(:))/N_all;
    
    % overall ratio of epochs of high amplitude
    OHA = nansum(HighAmpliMask(:))/N_all;
    
    % overall ratio of epochs of high frequency and power frequency noise
    OFN = nansum(FrequencyNoiseMask(:))/N_all;
    
    % overall ratio of epochs of low correlation
    OLC = nansum(LowCorrelationMask(:))/N_all;
    
    % overall ratio of epochs of low RANSAC correlation (optional)
    if chanlocsflag == 1 && ~isempty(ransacCorrelationThreshold) && isfinite(ransacCorrelationThreshold)
        OLRC = nansum(RansacBadEpochMask(:))/N_all;
    else
        OLRC = [];
    end
    
    % bad channels based on overall bad epochs
    badChannels = selechanns(badChannelsFromAll);
    
    % No. of bad channels
    NBC = nansum(badChannelsFromAll);
    
    % overall ratio of bad channels
    OBC = NBC/Nchan;
    
    % Overall data quality: overall ratio of epochs of good data
    ODQ = 100*(1 - (nansum(OverallBadMask(:))/N_all));
    
    % unthresholded mean absolute voltage
    M1 = reshape(nanmean(abs(epochdata),2),Nchan,Nepoch);
    allMAV = nanmean(abs(epochdata(:)));     % mean value of all epochs
    badMAV = nanmean(M1(OverallBadMask==1));   % mean value of bad epochs
    goodMAV = nanmean(M1(OverallBadMask==0));  % mean value of good epochs
    
    % --------------------------------
    % data quality rating
    DataQualityRating = [];
    if ODQ < 60
        DataQualityRating = 'D';
    elseif ODQ >= 60 && ODQ < 80
        DataQualityRating = 'C';
    elseif ODQ >= 80 && ODQ < 90
        DataQualityRating = 'B';
    elseif ODQ >= 90
        DataQualityRating = 'A';
    end
    
    % % plot check
    % figure;
    % subplot(3,3,1);imagesc(NoSignalMask);title('NoSignalMask');xlabel('epochs');ylabel('channels');
    % subplot(3,3,2);imagesc(HighAmpliMask);title('HighAmplitudeMask');xlabel('epochs');ylabel('channels');
    % subplot(3,3,3);imagesc(FrequencyNoiseMask);title('FrequencyNoiseMask');xlabel('epochs');ylabel('channels');
    % subplot(3,3,4);imagesc(LowCorrelationMask);title('LowCorrelationMask');xlabel('epochs');ylabel('channels');
    % subplot(3,3,5);imagesc(RansacBadEpochMask);title('RansacBadEpochMask');xlabel('epochs');ylabel('channels');
    % subplot(3,3,6);imagesc(OverallBadMask);title('OverallBadMask');xlabel('epochs');ylabel('channels');
    %
    % subplot(3,3,7);bar(fractionBadEpochs);grid on;title('FractionOfBadEpochs');xlabel('channels');ylabel('raito');
    % hold on; plot(0:length(fractionBadEpochs)+2,ones(length(fractionBadEpochs)+3)*badEpochThreshold,'--r');hold off;
    % subplot(3,3,8);bar(double(badChannelsFromAll));grid on;title('OverallBadChannels');xlabel('channels');ylabel('values');
    % subplot(3,3,9);bar([allMAV,badMAV,goodMAV]);grid on;title('Mean Absolute Values');ylabel('values');set(gca,'XTickLabel',{'allMAV','badMAV','goodMAV'});
    % -------------------------------------------------------------------------
    % save quality measures and parameters
    
    % qulaity measures
    results.ONS = ONS;  % Overall ratio of No Signal epochs
    results.OHA = OHA;  % Overall ratio of epochs of High Amplitudes
    results.OFN = OFN;  % Overall ratio of epochs of high Frequency and power frequency Noise
    results.OLC = OLC;  % Overall ratio of epochs of Low Correlation
    results.OLRC = OLRC; % Overall ratio of epochs of Low RANSAC Correlation (optional)
    results.badChannels = badChannels;  % Bad channels based on overall bad epochs
    results.NBC = NBC;                  % No. of bad channels
    results.OBC = OBC;                  % Overall ratio of Bad Channels
    results.ODQ = ODQ;                  % Overall Data Quality: overall ratio of epochs of good data
    results.DataQualityRating = DataQualityRating; % Overall Data Quality Rating.
    % A: ODQ >= 90
    % B: ODQ >= 80 && ODQ < 90
    % C: ODQ >= 60 && ODQ < 80
    % D: ODQ < 60
    
    results.allMAV = allMAV;     % mean value of all epochs
    results.badMAV = badMAV;     % mean value of bad epochs
    results.goodMAV = goodMAV;   % mean value of good epochs
    
    results.NoSignalMask = NoSignalMask;                % mask of epochs with no signals
    results.HighAmpliMask = HighAmpliMask;              % mask of epochs with high amplitudes
    results.FrequencyNoiseMask = FrequencyNoiseMask;    % mask of epochs with high amplitudes
    results.LowCorrelationMask = LowCorrelationMask;    % mask of epochs with low correlations
    results.RansacBadEpochMask = RansacBadEpochMask;  % mask of epochs with RANSAC low correlations
    results.OverallBadMask = OverallBadMask;            % mask of epochs with overall bad signals
    results.fractionBadEpochs = fractionBadEpochs;    % fractions of bad epochs for each channel
    results.badChannelsFromAll = badChannelsFromAll;    % bad channels from all methods.
    
    % paramerters
    results.parameters.event = event1;                  % event1
    results.parameters.eventlist = eventlist1;          % event list of event1
    results.parameters.Nepoch = Nepoch;                 % No. of epochs
    results.parameters.srate = srate;                   % sampling rate
    results.parameters.epochlimits = epochlimits;       % epoch latency range [start, end] in seconds
    results.parameters.HighPassband = HighPassband;         % lower edge of the frequency for high pass filtering, Hz
    results.parameters.selechanns = selechanns;             % number with indices of the selected channels (e.g. [1:4,7:30] or 'all').Default is 'all';
    results.parameters.badEpochThreshold = badEpochThreshold;  % cutoff fraction of bad epochs (default = 0.4)
    results.parameters.PowerFrequency = PowerFrequency;          % power frequency. default is 50 Hz (in Chinese). Noting that in USA, power frequency is 60Hz
    
    results.parameters.robustDeviationThreshold = robustDeviationThreshold;    % Z-score cutoff for robust channel deviation (default = 4)
    results.parameters.FrequencyNoiseThreshold = FrequencyNoiseThreshold;      % Z-score cutoff for NSR (signal above 40 Hz).
    results.parameters.correlationThreshold = correlationThreshold;            % correlation below which epoch is bad (range is (0,1), default = 0.4)
    
    results.parameters.chanlocsflag = chanlocsflag;
    try results.parameters.chanlocsXYZ = chanlocsXYZ; catch;end;
    results.parameters.chanlocs = EEG.chanlocs(1,selechanns);          % channel locations of selected channels
    results.parameters.ransacSampleSize = ransacSampleSize;            % samples for computing ransac (default = 50)
    results.parameters.ransacChannelFraction = ransacChannelFraction;      % fraction of channels for robust reconstruction (default = 0.25)
    results.parameters.ransacCorrelationThreshold = ransacCorrelationThreshold; % cutoff correlation for abnormal wrt neighbors(default = [] | --> not performed)
else
    results = [];
end
% -------------------------------------------------------------------------
% sub functions

    function epochdata = getepochdata(EEG,eventlist2,epochLenth2)
        % get epoched data of event list
        % Input:
        %     EEG: EEG structure loaded by EEGLAB (EEG data is raw data).
        %     eventlist2: event list generated from EEG.event
        %     epochLenth2: epoch limits. unit is time points
        % output: epoched data. channels X time points X epochs
        N_epochs = length(eventlist2);  % No. of epochs
        Nt1 = size(EEG.data,2);
        for i2 = 1:N_epochs
            epochdata(:,:,i2) = EEG.data(:,max(1,eventlist2(i2).latency + epochLenth2(1)):min(Nt1,eventlist2(i2).latency + epochLenth2(2)));
        end
        
    end
end
