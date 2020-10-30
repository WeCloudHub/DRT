function wb_EEGfiles_Standardization(InputPath,OutputPath,SubFlag,CompressFlag,All2setFlag,GenDescriptionFlag,SameFileNameFlag,ArrangeFlag,CaptureTypeFlag,KeyWord,srate,ChanlocsFile,ModeFlag)
% Description: standardize the EEG files 
% Param:
%   InputPath   : the original path of EEG Folder 
%   OutputPath  : the final path of EEG Folder with standardization
%   SubFlag     : add the sub-XXXXX in the front of filename or not
%   CompressFlag: compress the EEG files to zip or not
%   All2setFlag : transfrom EEG files of any formats into '.set' or not 
%   ArrangeFlag : filter or extract the EEG files or not
%   KeyWord     : the KeyWord is used to filter or extract the EEG files : 
%   srate       : fill this param when the file is '.mat' or '.txt'
%
% Written by Yufan Zhang (zyf15816794709@163.com)
% -------------------------------------------------------------------------
tic;
if nargin < 1 
    
    disp(datestr(now));
    fprintf('Welcome to Data Reconstruction toolbox (DRT). \n');   
    fprintf('The lastest version can be available from website. \n');  
    
    LoadInputPath = [ 'InputPath= uigetdir(''*'', ''Select the input path of EEG data files'');' ...
                    'if InputPath ~=0,' ...
                    '   set(findobj(''parent'', gcbf, ''tag'', tagInputPath), ''string'', InputPath);' ...
                    'end;' ...
                    'clear filename filepath tagInputPath;' ];    
                
    LoadOutputPath = [ 'OutputPath = uigetdir(''*'', ''Select the output path of EEG data files'');' ...
                    'if OutputPath ~=0,' ...
                    '   set(findobj(''parent'', gcbf, ''tag'', tagOutputPath), ''string'', OutputPath);' ...
                    'end;' ...
                    'clear filename filepath tagOutputPath;' ];  
    LoadChanlocsFile = [ '[filename, filepath] = uigetfile(''*'', ''Select a channels location file'');' ...
                    'if filename(1) ~=0,' ...
                    '   set(findobj(''parent'', gcbf, ''tag'', tagChanlocsFile), ''string'', [ filepath filename ]);' ...
                    'end;' ...
                    'clear filename filepath tagChanlocsFile;' ];                            
    callback_extract = 'set(findobj(gcbf, ''tag'', ''remove''), ''value'', ~get(gcbo, ''value''));';
    callback_remove = 'set(findobj(gcbf, ''tag'', ''extract''), ''value'', ~get(gcbo, ''value''));';
    uigeom       = { [1 1 0.5] [1 1 0.5] [1 0.13 0.4] [1 0.13 0.4] [1 0.13 0.4] [1 0.13 0.4] [1 0.13 0.4] [1 0.13 0.4] [1.3 0.5 0.5] [0.5 0.3] [0.5 0.3] [1 1 0.5] 0.5 } ;
    uilist       = { 
                     { 'style' 'text' 'string' 'InputPath' } ...   
                     { 'Style', 'edit', 'string', '', 'horizontalalignment', 'left', 'tag',  'InputPath' }, ...
                     { 'Style', 'pushbutton', 'string', 'Browse', 'callback', [ 'tagInputPath = ''InputPath'';' LoadInputPath ] }, ...
                     { 'style' 'text' 'string' 'OutputPath' } ...   
                     { 'Style', 'edit', 'string', '', 'horizontalalignment', 'left', 'tag',  'OutputPath' }, ...
                     { 'Style', 'pushbutton', 'string', 'Browse', 'callback', [ 'tagOutputPath = ''OutputPath'';' LoadOutputPath ] }, ...
                     { 'style' 'text' 'string' 'Add the sub-XXXXX in the front of filename' } ...      
                     { 'style' 'checkbox' 'string' '' } { } ...    
                     { 'style' 'text' 'string' 'Compress the EEG data files to *.zip' } ...      
                     { 'style' 'checkbox' 'string' '' } { } ...
                     { 'style' 'text' 'string' 'Convert EEG data format into .set' } ...       
                     { 'style' 'checkbox' 'string' '' } { } ...
                     { 'style' 'text' 'string' 'Generate descriptive files' } ...      
                     { 'style' 'checkbox' 'string' '' 'value' 1 } { } ...
                     { 'style' 'text' 'string' 'Same as the name of raw data files' } ...      
                     { 'style' 'checkbox' 'string' '' } { } ... 
                     { 'style' 'text' 'string' 'EEG-BIDS style' } ...      
                     { 'style' 'checkbox' 'string' '' } { } ...
                     { 'style' 'text' 'string' 'Extract or remove the EEG data files with KeyWord' } ...
                     { 'style' 'checkbox' 'tag' 'extract' 'string' 'extract' 'value' 1 'callback' callback_extract } ...
                     { 'style' 'checkbox' 'tag' 'remove' 'string' 'remove' 'value' 0 'callback' callback_remove } ... 
                     { 'style' 'text' 'string' 'KeyWord (default is all)' } ...
                     { 'style' 'edit' 'string' '' } ...
                     { 'style' 'text' 'string' 'srate (default is null)' } ...
                     { 'style' 'edit' 'string' '' } ...
                     { 'style' 'text' 'string' 'Select chanels location file' } ...   
                     { 'Style', 'edit', 'string', '', 'horizontalalignment', 'left', 'tag',  'ChanlocsFile' }, ...
                     { 'Style', 'pushbutton', 'string', 'Browse', 'callback', [ 'tagChanlocsFile = ''ChanlocsFile'';' LoadChanlocsFile ] }, ...
                     { 'style' 'text' 'string' 'Note: srate should be filled in when the file is .mat or .txt' } };                  
	result = inputgui( uigeom, uilist, 'pophelp(''wb_EEGfiles_Standardization'')', 'Data Reconstruction toolbox');    
    if length( result ) == 0 
        disp(datestr(now));
        fprintf('Operation has been cancelled\n'); 
        toc;
        return; 
    end;

    InputPath=result{1};
    OutputPath=result{2};
    SubFlag=num2str(result{3});
    CompressFlag=num2str(result{4});
    All2setFlag=num2str(result{5});
    GenDescriptionFlag=num2str(result{6});
    SameFileNameFlag=num2str(result{7});
    %EEGbidsFlag=num2str(result{8});
    ArrangeFlag=num2str(result{9});
    KeyWord=result{10};
    srate=result{11};
    ChanlocsFile=result{12};
    
elseif nargin==1 
    error('Too little input arguments'); 
elseif nargin==2  %input 2 param
    SubFlag='0';
    CompressFlag='0';
    All2setFlag='0';
    GenDescriptionFlag='0';
    SameFileNameFlag='0';
    ArrangeFlag='0';
    CaptureTypeFlag='2';
    KeyWord=[];
    srate=[];
    ChanlocsFile=[];
elseif nargin==3  %input 3 param
    CompressFlag='0';
    All2setFlag='0';
    GenDescriptionFlag='0';
    SameFileNameFlag='0';
    ArrangeFlag='0';
    CaptureTypeFlag='2';
    KeyWord=[];
    srate=[];
    ChanlocsFile=[];
elseif nargin==4  %input 4 param
    All2setFlag='0';
    GenDescriptionFlag='0';
    SameFileNameFlag='0';
    ArrangeFlag='0'; 
    CaptureTypeFlag='2';
    KeyWord=[];
    srate=[];
    ChanlocsFile=[];
elseif nargin==5  %input 5 param
    GenDescriptionFlag='0';
    SameFileNameFlag='0';
    ArrangeFlag='0';
    CaptureTypeFlag='2';
    KeyWord=[];
    srate=[];
    ChanlocsFile=[];
elseif nargin==6  %input 6 param
    SameFileNameFlag='0';
    ArrangeFlag='0';
    CaptureTypeFlag='2';
    KeyWord=[];
    srate=[];
    ChanlocsFile=[];
elseif nargin==7  %input 7 param
    ArrangeFlag='0';
    CaptureTypeFlag='2';
    KeyWord=[];
    srate=[];
    ChanlocsFile=[];
elseif nargin==8  %input 8 param
    CaptureTypeFlag='2';
    KeyWord=[];
    srate=[];   
    ChanlocsFile=[];
elseif nargin==9  %input 9 param
    KeyWord=' ';
    srate=[];
    ChanlocsFile=[];
elseif nargin==10  %input 10 param
    srate=[];   
    ChanlocsFile=[];
elseif nargin==11  %input 11 param
    ChanlocsFile=[];  
end

if ~isdir(InputPath) || ~isdir(OutputPath)  % Check InputPath and OutputPath
    error('InputPath or OutputPath not meet the standard'); 
end;

if SubFlag ~= '1' && SubFlag ~= '0' % Check SubFlag
    error('SubFlag not meet the standard'); 
end;

if CompressFlag ~= '1' && CompressFlag ~= '0' % Check CompressFlag 
    error('CompressFlag not meet the standard'); 
end

if All2setFlag ~= '1' && All2setFlag ~= '0' % Check All2setFlag 
    error('All2setFlag not meet the standard'); 
end;

if GenDescriptionFlag ~= '1' && GenDescriptionFlag ~= '0' % Check GenDiscriptionFlag 
    error('GenDiscriptionFlag not meet the standard'); 
end;

if SameFileNameFlag ~= '1' && SameFileNameFlag ~= '0' % Check SameFileNameFlag 
    error('SameFileNameFlag not meet the standard'); 
end;

if ArrangeFlag ~= '1' && ArrangeFlag ~= '0' % Check ArrangeFlag 
    error('ArrangeFlag not meet the standard'); 
end;

if ~isempty(KeyWord)
    if ~ischar(KeyWord)
        error('KeyWord need to be string'); 
    end;
end

if ~isempty(srate)
    if ~isstrprop(srate,'digit')
        error('srate need to be digit'); 
    end;
end

% try
% Ensure input path ends with ‘\’or '/' 
if InputPath(end) ~= filesep
    InputPath = [InputPath, filesep];     
end;

% Ensure output path ends with ‘\’or '/' 
if OutputPath(end) ~= filesep
    OutputPath = [OutputPath, filesep]; 
end;

%param
SuccessCount=0;
FailInfoCount=0;
FailChannCount=0;
FailEventCount=0;
FailZipCount=0;
FailConvertCount=0;
FailInfo_filename=[];
FailChann_filename=[];
FailEvent_filename=[];
FailZip_filename=[];
FailConvert_filename=[];

SubCount=0;
RestructFileName=[];

disp(datestr(now));

%----------------- Check compressed files-------------------
DecompressFileName=[];
DecompressFileCount=0;

fprintf('Start to check for compressed files, please wait...\n');
[DecompressFileCount,DecompressFileName]=wb_EEGfiles_decompress(InputPath,DecompressFileCount,DecompressFileName);

%----------------- Check OutputPath -------------------
LoadSubjectInfo_Flag=0;
fprintf('Start to check OutputPath, please wait...\n');  % Check existing file in OutputPath
MaxCount=0;
RootDir=dir(OutputPath);
for i_file=1:1:length(RootDir)   % first search current dir 
    if (~strcmp(RootDir(i_file).name,'.')) & (~strcmp(RootDir(i_file).name,'..'))  
        FileName=RootDir(i_file).name;
            
        if strcmp(FileName,'subjects_info.csv')
            LoadSubjectInfo_Flag=1;
        end
        
        if strcmp(FileName(1:4),'sub-')
            if ~isstrprop(str2num(FileName(9)),'digit') % & isstrprop(str2num(FileName(10)),'digit')
                if MaxCount < str2num(FileName(5:9)) 
                    MaxCount = str2num(FileName(5:9));
                end
            end
        end
    end
end    

if MaxCount ~=0
    LoadSubjectInfo_Flag=1;
end

fprintf('Start to restruct EEG data files, please wait...\n');
%----------------- EEGfile_Restruct -------------------
SubCount=MaxCount;
[SubCount,RestructFileName]=wb_EEGfiles_Restruct(InputPath,InputPath,OutputPath,SubFlag,SameFileNameFlag,ArrangeFlag,CaptureTypeFlag,KeyWord,SubCount,RestructFileName);

global bar bar_str;
if ModeFlag == 1 
    bar_str=['运行中...','40','%'];   
    waitbar(40/100,bar,bar_str);        % 更新进度条bar
elseif ModeFlag == 3
    bar_str=['运行中...','15','%'];   
    waitbar(15/100,bar,bar_str);        % 更新进度条bar    
end
    

%----------------- delete decompressed folders -------------------
fprintf('Start to delete decompressed folders, please wait...\n');
for i = 1:length(DecompressFileName)
    disp(DecompressFileName{i});
    rmdir(DecompressFileName{i},'s');
end

if All2setFlag == '1' 
    %--------------------- all2set ------------------------
    disp(datestr(now));
    fprintf('Start to convert EEG data files into *.set, please wait...\n');
    RootDir=dir(OutputPath);
    for i_file=1:1:length(RootDir)   % first search current dir 
        if RootDir(i_file).isdir & (~strcmp(RootDir(i_file).name,'.')) & (~strcmp(RootDir(i_file).name,'..'))  %check isDir
            SubFolder=[OutputPath,RootDir(i_file).name,filesep];  
            SubDir=dir([OutputPath,RootDir(i_file).name]);
            for j_file=1:1:length(SubDir)  % Second search current dir 
                if SubDir(j_file).isdir == 0 
                    FailState=wb_EEGfiles_all2set(SubFolder,SubDir(j_file).name,srate,ChanlocsFile);
                    if FailState == 1
                        FailConvertCount=FailConvertCount+1;
                        FailConvert_filename{FailConvertCount} = SubDir(j_file).name;
                    end
                end;
            end;
        end;
    end;   
end


if All2setFlag == '1' 
    %--------------------- dat2set ------------------------
    %disp(datestr(now));
    %fprintf('Start to convert EEG data files into *.set, please wait...\n');
    RootDir=dir(OutputPath);
    for i_file=1:1:length(RootDir)   % first search current dir 
        if RootDir(i_file).isdir & (~strcmp(RootDir(i_file).name,'.')) & (~strcmp(RootDir(i_file).name,'..'))  %check isDir
            SubFolder=[OutputPath,RootDir(i_file).name,filesep];  
            SubDir=dir([OutputPath,RootDir(i_file).name]);
            for j_file=1:1:length(SubDir)  % Second search current dir 
                if SubDir(j_file).isdir == 0
                    FailState=wb_EEGfiles_dat2set(SubFolder,SubDir(j_file).name,srate,ChanlocsFile);
                    if FailState == 1
                        FailConvertCount=FailConvertCount+1;
                        FailConvert_filename{FailConvertCount} = SubDir(j_file).name;
                    end
                end;
            end;
        end;
    end;   
end    

if ModeFlag == 1 
    bar_str=['运行中...','55','%'];   
    waitbar(55/100,bar,bar_str);        % 更新进度条bar
elseif ModeFlag == 3
    bar_str=['运行中...','25','%'];   
    waitbar(25/100,bar,bar_str);        % 更新进度条bar    
end


if GenDescriptionFlag == '1'   
    %-------------------- generate descripition ------------------------
    disp(datestr(now));
    fprintf('Start to generate descriptive files and list, please wait...\n');
    RootDir=dir(OutputPath);
    for i_file=1:1:length(RootDir)   % first search current dir 
        if RootDir(i_file).isdir & (~strcmp(RootDir(i_file).name,'.')) & (~strcmp(RootDir(i_file).name,'..'))  %check isDir
            SubFolder=[OutputPath,RootDir(i_file).name,filesep];
            SubDir=dir([OutputPath,RootDir(i_file).name]);
            for j_file=1:1:length(SubDir)  % Second search current dir 
                if SubDir(j_file).isdir == 0    %is file
                      fclose all;
                      FailState=wb_EEGfiles_GenerateDescription(SubFolder,SubDir(j_file).name);    

                      if FailState==1
                          FailInfoCount = FailInfoCount+1;
                          FailInfo_filename{FailInfoCount} = SubDir(j_file).name;
                      elseif FailState==2
                          FailChannCount = FailChannCount+1;
                          FailChann_filename{FailChannCount} = SubDir(j_file).name;
                      elseif FailState==3
                          FailEventCount = FailEventCount+1;
                          FailEvent_filename{FailEventCount} = SubDir(j_file).name;
                      end
                end;
            end;
            %-------------------- package to zip ------------------------
            if CompressFlag == '1' 
                try
                    fclose all;
                    zip([OutputPath,RootDir(i_file).name,'.zip'],RootDir(i_file).name,OutputPath);
                    rmdir([OutputPath,RootDir(i_file).name],'s');
                catch
                    warning('Failed to package into zip ');
                    disp(['Failed: ',RootDir(i_file).name]);
                    FailZipCount=FailZipCount+1;
                end;
            end;
        end;
    end;     
end;


if ModeFlag == 1 
    bar_str=['运行中...','70','%'];   
    waitbar(70/100,bar,bar_str);        % 更新进度条bar
elseif ModeFlag == 3
    bar_str=['运行中...','35','%'];   
    waitbar(35/100,bar,bar_str);        % 更新进度条bar    
end


if CompressFlag == '1' &&  GenDescriptionFlag == '0'  
     %-------------------- package to zip ------------------------
    disp(datestr(now));
    
    fprintf('Start to package EEG data files into *.zip, please wait...\n');
    RootDir=dir(OutputPath);
    for i_file=1:1:length(RootDir)   % first search current dir 
        if RootDir(i_file).isdir & (~strcmp(RootDir(i_file).name,'.')) & (~strcmp(RootDir(i_file).name,'..'))  %check isDir
            SubFolder=[OutputPath,RootDir(i_file).name,filesep];
            SubDir=dir([OutputPath,RootDir(i_file).name]);
            fclose all;
            zip([OutputPath,RootDir(i_file).name,'.zip'],RootDir(i_file).name,OutputPath);
            rmdir([OutputPath,RootDir(i_file).name],'s');
        end;
    end;     
end;

if ModeFlag == 1 
    bar_str=['运行中...','85','%'];   
    waitbar(85/100,bar,bar_str);        % 更新进度条bar
elseif ModeFlag == 3
    bar_str=['运行中...','45','%'];   
    waitbar(45/100,bar,bar_str);        % 更新进度条bar    
end


%generate datasets_description.json
fclose all;
JsonFile_Dir=[OutputPath,'datasets_info.json'];
fid = fopen(JsonFile_Dir, 'w+');
fprintf('Start to generate datasets_info.json...\n');
 
%fill the content in description.json
eeg_json.DataProvenance='download from public database or collect from experiment';

eeg_json.PublicDatabase.URL = 'website address of database';
eeg_json.PublicDatabase.PublishedTime = 'the time of release';
eeg_json.PublicDatabase.Version = 'version number';
eeg_json.PublicDatabase.Article = 'URL of article if any';

eeg_json.Experiment.Name = 'experiment name';
eeg_json.Experiment.Introduction = 'the introduction of experiment';
eeg_json.Experiment.Methods = 'describe the methods of experiment in detail';

eeg_json.DataInfo.Equipment = 'the manufacturer or model of data acquisition equipment';
eeg_json.DataInfo.Parameters = 'parameters configuration of equipment';
eeg_json.DataInfo.Description = 'describe the number and information of subjects';
eeg_json.DataInfo.Collector = 'the name of data collector';
eeg_json.DataInfo.Time = 'data acquisition time';

eeg_json.DataOwner= 'owner name';
eeg_json.Email= '*******@***.com';

SubJson = savejson('',eeg_json);
fprintf(fid, '%s',SubJson);

%generate subjects_info.csv
fclose all;
participants_filename = 'subjects_info.csv';
participants_Dir=[OutputPath,participants_filename];

if LoadSubjectInfo_Flag == 0
    fprintf('Start to generate subjects_info.csv... \n');
    fid = fopen(participants_Dir, 'w+');
    fprintf(fid, ['No.',',','Datafile',',','SubjectID',',','Age',',','Gender',',','Description',',','DataQuality',',','ModifyTime','\n']);
elseif LoadSubjectInfo_Flag == 1
    fid = fopen(participants_Dir, 'a');
    fprintf('Start to open existing subjects_info.csv... \n');
end;

for i=(MaxCount+1):length(RestructFileName)   
    %Subjects_id = wb_EEGfiles_AddSub(i) ;  
    SubjectNum=i;
    DatafileName=RestructFileName{i};
    Subjects_id='n/a';
    age = 'n/a';    
    gender = 'n/a';  
    Subject_Description = 'n/a';    
    DataQuality = 'n/a';
    ModifyTime = datestr(now);    
    fprintf(fid, ['%f',',','%s',',','%s',',','%s',',','%s',',','%s',',','%s',',','%s','\n'],SubjectNum,DatafileName,Subjects_id,age,gender,Subject_Description,DataQuality,ModifyTime);
end

fclose all;

if FailInfoCount ==0 && FailChannCount ==0 && FailEventCount == 0 && FailConvertCount == 0  && FailZipCount == 0
    disp('********finished files********');
    disp(['No. of finished files:',num2str(SubCount)]);
    disp('------------------------')
    disp('********Success********');
    disp(datestr(now));
else
%         disp('********finished files********');
%         disp(['No. of finished files:',num2str(SuccessCount)]);

    if FailInfoCount ~=0
        disp('********failed to generate info json files*********');
        disp(['No. of failed files:',num2str(length(FailInfo_filename))]);
        disp('failed files:');
        for i = 1:length(FailInfo_filename)
            disp(FailInfo_filename{i});
        end
    end;

    if FailChannCount ~=0
        disp('********failed to generate channel files***********');
        disp(['No. of failed files:',num2str(length(FailChann_filename))]);
        disp('failed files:');
        for i = 1:length(FailChann_filename)
            disp(FailChann_filename{i});
        end
    end

    if FailEventCount ~=0
        disp('********failed to generate event files*************');
        disp(['No. of failed files:',num2str(length(FailEvent_filename))]);
        disp('failed files:');
        for i = 1:length(FailEvent_filename)
            disp(FailEvent_filename{i});
        end
    end

    if FailConvertCount ~=0
        disp('********failed to convert into EEGLAB files********');
        disp(['No. of failed files:',num2str(FailConvertCount)]);
        disp('failed files:');
        for i = 1:length(FailConvert_filename)
            disp(FailConvert_filename{i});
        end
    end

    if FailZipCount ~=0
        disp('********failed to package into zip*****************');
        disp(['No. of failed files:',num2str(FailZipCount)]);
    end
end

toc;
end
