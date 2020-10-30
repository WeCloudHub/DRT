function channlocs = wb_loadChannlocs(elecfile,unzip_dir)
% loading EEG channel locations. This function will scan all files in folders with its
% subfolders (3 layer max), and load one sample data only (last one).
% Input:
%      elecfile: folder, eletrode file or zip file of channel location file (only for one subject/sample).
%               If it is a zip file, eletrode location file will be unzipped to the data path.
%               If it is a eletrode file, it will be readed directly.
%      unzip_dir: temp folder to unzip location data. It is required if
%               'elecfile' is zip file.
% Output:
%      channlocs: channel locations as EEGLAB data structure
% -------------------------------------------------------------------------
% Electrode location file formats:
% The file extension determines its type.
%
%   '.loc' or '.locs' or '.eloc':
%               polar coordinates. Notes: angles in degrees:
%               right ear is 90; left ear -90; head disk radius is 0.5.
%               Fields:   N    angle  radius    label
%               Sample:   1    -18    .511       Fp1
%                         2     18    .511       Fp2
%                         3    -90    .256       C3
%                         4     90    .256       C4
%                           ...
%               Note: In previous releases, channel labels had to contain exactly
%               four characters (spaces replaced by '.'). This format still works,
%               though dots are no longer required.
%   '.sph':
%               Matlab spherical coordinates. Notes: theta is the azimuthal/horizontal angle
%               in deg.: 0 is toward nose, 90 rotated to left ear. Following this, performs
%               the elevation (phi). Angles in degrees.
%               Fields:   N    theta    phi    label
%               Sample:   1      18     -2      Fp1
%                         2     -18     -2      Fp2
%                         3      90     44      C3
%                         4     -90     44      C4
%                           ...
%   '.elc':
%               Cartesian 3-D electrode coordinates scanned using the EETrak software.
%               See readeetraklocs().
%   '.elp':
%               Polhemus-.'elp' Cartesian coordinates. By default, an .elp extension is read
%               as PolhemusX-elp in which 'X' on the Polhemus sensor is pointed toward the
%               subject. Polhemus files are not in columnar format (see readelp()).
%   '.elp':
%               BESA-'.elp' spherical coordinates: Need to specify 'filetype','besa'.
%               The elevation angle (phi) is measured from the vertical axis. Positive
%               rotation is toward right ear. Next, perform azimuthal/horizontal rotation
%               (theta): 0 is toward right ear; 90 is toward nose, -90 toward occiput.
%               Angles are in degrees.  If labels are absent or weights are given in
%               a last column, readlocs() adjusts for this. Default labels are E1, E2, ...
%               Fields:   label      phi  theta
%               Sample:   Fp1        -92   -72
%                         Fp2         92    72
%                         C3         -46    0
%                         C4          46    0
%                           ...
%   '.xyz':
%               Matlab/EEGLAB Cartesian coordinates. Here. x is towards the nose,
%               y is towards the left ear, and z towards the vertex.
%               Fields:   channum   x           y         z     label
%               Sample:   1       .950        .308     -.035     Fp1
%                         2       .950       -.308     -.035     Fp2
%                         3        0           .719      .695    C3
%                         4        0          -.719      .695    C4
%                           ...
%   '.asc', '.dat':
%               Neuroscan-.'asc' or '.dat' Cartesian polar coordinates text file.
%   '.sfp':
%               BESA/EGI-xyz Cartesian coordinates. Notes: For EGI, x is toward right ear,
%               y is toward the nose, z is toward the vertex. EEGLAB converts EGI
%               Cartesian coordinates to Matlab/EEGLAB xyz coordinates.
%               Fields:   label   x           y          z
%               Sample:   Fp1    -.308        .950      -.035
%                         Fp2     .308        .950      -.035
%                         C3     -.719        0          .695
%                         C4      .719        0          .695
%                           ...
%   '.ced':
%               ASCII file saved by pop_chanedit(). Contains multiple MATLAB/EEGLAB formats.
%               Cartesian coordinates are as in the 'xyz' format (above).
%               Fields:   channum  label  theta  radius   x      y      z    sph_theta   sph_phi  ...
%               Sample:   1        Fp1     -18    .511   .950   .308  -.035   18         -2       ...
%                         2        Fp2      18    .511   .950  -.308  -.035  -18         -2       ...
%                         3        C3      -90    .256   0      .719   .695   90         44       ...
%                         4        C4       90    .256   0     -.719   .695  -90         44       ...
%                           ...
%               The last columns of the file may contain any other defined fields (gain,
%               calib, type, custom).
% -------------------------------------------------------------------------
% Written by Li Dong (Lidong@uestc.edu.cn) $ 2020.3.3
% -------------------------------------------------------------------------
if nargin == 1
    unzip_dir = [];
end

channlocs = []; % EEGLAB data structure

try
    channlocs = readlocs(elecfile);
catch
    % scan foulders and load EEG data
    
    if exist(elecfile,'dir') == 7 % is folder and exist
        % -----------------------------
        listing1 = dir(elecfile);
        % ----
        for i = 3:length(listing1)
            cur_file = listing1(i).name;
            if exist(fullfile(elecfile,cur_file),'dir') == 7 % is folder and exist
                listing2 = dir(fullfile(elecfile,cur_file));
                elecfile2 = fullfile(elecfile,cur_file);
                for j = 3:length(listing2)
                    cur_file2 = listing2(j).name;
                    if exist(fullfile(elecfile,cur_file,cur_file2),'dir') == 7 % is folder and exist
                        listing3 = dir(fullfile(elecfile,cur_file,cur_file2));
                        elecfile3 = fullfile(elecfile,cur_file,cur_file2);
                        for k = 3:length(listing3)
                            cur_file3 = listing3(k).name;
                            try channlocs = readchannlocs(elecfile3,cur_file3);catch;end
                        end
                    else
                        try channlocs = readchannlocs(elecfile2,cur_file2);catch;end
                    end
                end
            else
                try channlocs = readchannlocs(elecfile,cur_file);catch;end
            end
        end
        % ------------------------------
    else   % is zip file
        if ~isempty(unzip_dir) % if unzip direction is not empty
            [~,name1,ext2] = fileparts(elecfile); % get filename extension
            if isequal(ext2,'.zip') % is .zip?
                unzip_temp_path = fullfile(unzip_dir,filesep,['unzip_temp_',name1]);
                unzip(elecfile,unzip_temp_path); % unzip data
                % -----------------------------
                listing1 = dir(unzip_temp_path);
                % ----
                for i = 3:length(listing1)
                    cur_file = listing1(i).name;
                    if exist(fullfile(unzip_temp_path,cur_file),'dir') == 7 % is folder and exist
                        listing2 = dir(fullfile(unzip_temp_path,cur_file));
                        elecfile2 = fullfile(unzip_temp_path,cur_file);
                        for j = 3:length(listing2)
                            cur_file2 = listing2(j).name;
                            if exist(fullfile(unzip_temp_path,cur_file,cur_file2),'dir') == 7 % is folder and exist
                                listing3 = dir(fullfile(unzip_temp_path,cur_file,cur_file2));
                                elecfile3 = fullfile(unzip_temp_path,cur_file,cur_file2);
                                for k = 3:length(listing3)
                                    cur_file3 = listing3(k).name;
                                    try channlocs = readchannlocs(elecfile3,cur_file3);catch;end
                                end
                            else
                                try channlocs = readchannlocs(elecfile2,cur_file2);catch;end
                            end
                        end
                    else
                        try channlocs = readchannlocs(unzip_temp_path,cur_file);catch;end
                    end
                end
                % ------------------------------
                % remove temp zip folder
                try rmdir(unzip_temp_path,'s'); catch;end;
            end
        else
            error(' Input ''unzip_dir'' is required, if ''elecfile'' is zip file.');
        end
    end
end
if isempty(channlocs)
    warning('failed to load channel locations, please check the elec file...');
end
% -------------------------------------------------------------------------
% subfunctions
    function locs = readchannlocs(EEGfile5,cur_file5)
        try locs = readlocs(fullfile(EEGfile5,cur_file5));catch;locs = [];end;
    end
end


