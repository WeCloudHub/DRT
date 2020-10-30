function EEG = wb_loadEEG(EEGfile,unzip_dir)
% loading EEG data. This function will scan all files in folders with its
% subfolders (3 layer max), and load one sample data only (last one).
% Input:
%      EEGfile: Folder or zip file of EEG data (only for one subject/sample).
%               If it is a zip file, EEG data will be unzipped to the data path.
%      unzip_dir: temp folder to unzip EEG data. It is required if
%               'EEGfile' is zip file.
% Output:
%      EEG: EEGLAB data structure
% --------------
% Written by Li Dong (Lidong@uestc.edu.cn) $ 2018.1.8
% Revised:
%      can load MATLAB .dat file. $ 20180802 Li Dong
%      can load BIDS-EEG.         $ 20200217 Li Dong
% -------------------------------------------------------------------------
if nargin == 1
    unzip_dir = [];
end

EEG = []; % EEGLAB data structure

% scan foulders and load EEG data

if exist(EEGfile,'dir') == 7 % is folder and exist
    % -----------------------------
    listing1 = dir(EEGfile);
    % ----
    for i = 3:length(listing1)
        cur_file = listing1(i).name;
        if exist(fullfile(EEGfile,cur_file),'dir') == 7 % is folder and exist
            listing2 = dir(fullfile(EEGfile,cur_file));
            EEGfile2 = fullfile(EEGfile,cur_file);
            for j = 3:length(listing2)
                cur_file2 = listing2(j).name;
                if exist(fullfile(EEGfile,cur_file,cur_file2),'dir') == 7 % is folder and exist
                    listing3 = dir(fullfile(EEGfile,cur_file,cur_file2));
                    EEGfile3 = fullfile(EEGfile,cur_file,cur_file2);
                    for k = 3:length(listing3)
                        cur_file3 = listing3(k).name;
                        try EEG = readEEG(EEGfile3,cur_file3);catch;end
                    end
                else
                    try EEG = readEEG(EEGfile2,cur_file2);catch;end
                end
            end
        else
            try EEG = readEEG(EEGfile,cur_file);catch;end
        end
    end
    % ------------------------------
else   % is zip file
    if ~isempty(unzip_dir) % if unzip direction is not empty
        [~,name1,ext2] = fileparts(EEGfile); % get filename extension
        if isequal(ext2,'.zip') % is .zip?
            unzip_temp_path = fullfile(unzip_dir,filesep,['unzip_temp_',name1]);
            unzip(EEGfile,unzip_temp_path); % unzip data
            % -----------------------------
            listing1 = dir(unzip_temp_path);
            % ----
            for i = 3:length(listing1)
                cur_file = listing1(i).name;
                if exist(fullfile(unzip_temp_path,cur_file),'dir') == 7 % is folder and exist
                    listing2 = dir(fullfile(unzip_temp_path,cur_file));
                    EEGfile2 = fullfile(unzip_temp_path,cur_file);
                    for j = 3:length(listing2)
                        cur_file2 = listing2(j).name;
                        if exist(fullfile(unzip_temp_path,cur_file,cur_file2),'dir') == 7 % is folder and exist
                            listing3 = dir(fullfile(unzip_temp_path,cur_file,cur_file2));
                            EEGfile3 = fullfile(unzip_temp_path,cur_file,cur_file2);
                            for k = 3:length(listing3)
                                cur_file3 = listing3(k).name;
                                try EEG = readEEG(EEGfile3,cur_file3);catch;end
                            end
                        else
                            try EEG = readEEG(EEGfile2,cur_file2);catch;end
                        end
                    end
                else
                    try EEG = readEEG(unzip_temp_path,cur_file);catch;end
                end
            end
            % ------------------------------
            % remove temp zip folder
            try rmdir(unzip_temp_path,'s'); catch;end;
        end
    else
        error(' Input ''unzip_dir'' is required, if ''EEGfile'' is zip file.');
    end
end

if ~isempty(EEG)
    % check and empty some EEG fields for information safty
    [~,EEG.filename,~] = fileparts(EEG.filename);
    EEG.filepath = [];
    EEG.comments = [];
    EEG.history = [];
else
    warning('failed to load EEG data, please check the EEG file...');
end
% -------------------------------------------------------------------------
% subfunctions

    function EEG = readEEG(EEGfile5,cur_file5)
        % read EEG files using EEGLAB functions
        % Input:
        %    EEGfile5: input path
        %    cur_file5: EEG file name
        % output:
        %    EEG: EEG structrue
        [~, ~, ext1] = fileparts(cur_file5);
        % disp(cur_file5);  % disp file scaned, for test only
        try
            switch ext1
                case '.set' % EEGLAB .set
                    EEG = pop_loadset('filename',cur_file5,'filepath',EEGfile5);
                case '.cnt' % neuroscan .cnt
                    EEG = pop_loadcnt(fullfile(EEGfile5,cur_file5));
                case '.mat' % MATLAB .mat
                    EEG = pop_importdata('data',fullfile(EEGfile5,cur_file5),'dataformat','matlab');
                case '.vhdr'% Brain Product .vhdr
                    EEG = pop_loadbv(EEGfile5, cur_file5);
                case '.EEG' % NeuroScan .eeg (epoch)
                    EEG = pop_loadeeg(cur_file5,fullfile(EEGfile5,filesep));
                case '.txt' % ASCII .txt
                    EEG = pop_importdata('data',fullfile(EEGfile5,cur_file5),'dataformat','ascii');
                case '.dap'  % Curry7 .dap
                    EEG = pop_loadcurry(fullfile(EEGfile5,filesep,cur_file5));
                case '.bdf' % Biosemi BDF File .bdf
                    EEG = pop_readbdf(fullfile(EEGfile5,filesep,cur_file5));
                case '.EDF' % Biosemi EDF File .EDF
                    EEG = pop_readbdf(fullfile(EEGfile5,filesep,cur_file5));
                case '.dat' % MATLAB .dat file
                    try EEG = pop_importdata('data',fullfile(EEGfile5,cur_file5),'dataformat','matlab');catch;end;
            end
        catch
        end;
    end

end


