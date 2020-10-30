function [RestructFile_Count,RestructFile_filename]=wb_EEGfiles_Restruct(rawInputPath,InputPath,OutputPath,SubFlag,SameFileNameFlag,ArrangeFlag,CaptureTypeFlag,KeyWord,StartCount,StartFileName)
% Description: restruct the EEG files of different formats 
% Param:
%   InputPath   : the original path of EEG Folder 
%   OutputPath  : the final path of EEG Folder with standardization
%   SubFlag     : add the Sub-XXXXX in the front of filename or not
%   ArrangeFlag : extract or remove the EEG files or not
%   KeyWord     : the KeyWord is used to filter or extract the EEG files
% Note: supporting the EEG files format including '.set','.mat','.vmrk','.cnt','.EEG','.bdf','.EDF'
%
% Written by Yufan Zhang (zyf15816794709@163.com)
% 2020.7.7
% -------------------------------------------------------------------------

% Global param
CreatFolder_Flag = 0 ;
OtherFile_Flag = 0 ;
RestructFile_Count = StartCount ;
RestructFile_filename = StartFileName;
                            
LastFileName=[];
LastFileSuffix=[];
LastNewFolder=[];

if InputPath(end) ~= filesep
    InputPath = [InputPath, filesep];     
end;

if rawInputPath(end) ~= filesep
    rawInputPath = [rawInputPath, filesep];     
end;

% Gain the name of RootFile 
S=regexp(InputPath, filesep, 'split');
RootFileName=char(S(end-1));

if length(rawInputPath) ~= length(InputPath)
    if CaptureTypeFlag== '1'
        if ~isempty(KeyWord) % ~= '' 
            if ArrangeFlag == '0' % extract specified folder
                if isempty(regexpi(RootFileName,KeyWord,'match')) % if not find the KeyWord of folder name, exit the step
                    return;
                end;    
            elseif ArrangeFlag == '1' % filter specified folder
                if ~isempty(regexpi(RootFileName,KeyWord,'match')) % if not find the KeyWord of folder name, exit the step    
                    return;
                end;  
            end;
        end;
    end   
end

RootDir=dir(InputPath);
DirCell=struct2cell(RootDir);
NaturalDir= wb_EEGfiles_NaturalSort(DirCell(1,:));

for i=1:1:length(NaturalDir)   % first search current dir 
    i_file = i ;
    for j=1:1:length(NaturalDir)
        if strcmp(RootDir(j).name,NaturalDir(i))
            i_file = j ;
            continue
        end
    end
    
	if RootDir(i_file).isdir & (~strcmp(RootDir(i_file).name,'.')) & (~strcmp(RootDir(i_file).name,'..'))  %check isDir
        SubDir=[InputPath,RootDir(i_file).name];
        [RestructFile_Count,RestructFile_filename]=wb_EEGfiles_Restruct(rawInputPath,SubDir,OutputPath,SubFlag,SameFileNameFlag,ArrangeFlag,CaptureTypeFlag,KeyWord,RestructFile_Count,RestructFile_filename);       
    elseif RootDir(i_file).isdir == 0  
        if CaptureTypeFlag=='1'
            if length(rawInputPath) == length(InputPath)
                continue
            end
        elseif CaptureTypeFlag=='2'     
            if ~isempty(KeyWord) %KeyWord ~= ' '
                if ArrangeFlag == '0' % extract specified files
                    if isempty(regexpi(RootDir(i_file).name,KeyWord,'match')) % if not find the KeyWord of file name, exit the step
                        continue
                    end;    
                elseif ArrangeFlag == '1' % filter specified files
                    if ~isempty(regexpi(RootDir(i_file).name,KeyWord,'match')) % if not find the KeyWord of file name, exit the step    
                        continue
                    end;  
                end;
            end; 
        end
          
        RawFile=[InputPath,RootDir(i_file).name] ; % RawFile path
        fprintf('%s\n',RawFile); 
        
        [filepath,filename,Suffix] = fileparts(RawFile); % Gain Suffix from RawFile
        
        OtherFile_Flag=0;
        switch Suffix
            case {'.set','.mat','.dat','.cnt','.EEG','.bdf','.gdf','.edf','.txt','.vhdr'}
                if strcmp(Suffix,'.txt')
                    try
                        pop_importdata('data',RawFile,'dataformat','ascii');
                    catch
                        warning('The txt file is not EEG data file ');
                        OtherFile_Flag = 1;
                    end;
                end
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                 if strcmp(Suffix,'.mat')
%                     try
%                         pop_importdata('data',RawFile,'dataformat','matlab');
%                     catch
%                         warning('The mat file is not EEG data file ');
%                         OtherFile_Flag = 1;
%                     end;
%                 end
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                if ~strcmp(Suffix,'.vhdr')
                    if OtherFile_Flag == 0
                        RestructFile_Count=RestructFile_Count+1; % count number of files
                        RestructFile_filename{RestructFile_Count}=filename;
                    end
                end
            otherwise
                OtherFile_Flag = 1;
        end
        
        % if the file format is not supported above, exit next steps
        if OtherFile_Flag == 1  
            OtherFile_Flag = 0 ;
            continue  
        end
              
        RootFileName=wb_EEGfiles_NamePattern(rawInputPath,InputPath);
        
        % check whether add the sub-XXXXX in the front of filename or not
        if SameFileNameFlag == '1'
            if SubFlag=='1'
                NewFolderName = [wb_EEGfiles_AddSub(RestructFile_Count),'_',filename];
            elseif SubFlag=='0'
                NewFolderName = filename;
            end                    
        elseif SameFileNameFlag == '0' 
            if SubFlag=='1' 
                NewFolderName = [wb_EEGfiles_AddSub(RestructFile_Count),'_',RootFileName,'_',filename];
            elseif SubFlag=='0'
                NewFolderName = [RootFileName,'_',filename];
            end
        end        
                                       
        switch Suffix
            case '.set'
                NewFolder=[OutputPath,NewFolderName];
                if ~isdir(NewFolder)   % not exist   
                    mkdir(NewFolder);  % create NewFolder in OutputPath     
                end;

                if strcmp(LastFileSuffix,'.dat')
                    LastFileSuffix = [];
                    copyfile(LastRawFile,LastNewFolder);                
                end     
                RawFile_set=[InputPath,filename,'.set'] ;
                RawFile_fdt=[InputPath,filename,'.fdt'] ;
                copyfile(RawFile_set,NewFolder);  
                copyfile(RawFile_fdt,NewFolder);
            case '.dat' 
                NewFolder=[OutputPath,NewFolderName];
                if ~isdir(NewFolder)   % not exist   
                    mkdir(NewFolder);  % create NewFolder in OutputPath     
                end;
                if strcmp(LastFileSuffix,'.dat')
                    LastFileSuffix = [];
                    copyfile(LastRawFile,LastNewFolder);                
                end                  
                LastNewFolder = NewFolder;
                LastRawFile = RawFile;
            case '.vhdr' 
                RawFile_dat=[InputPath,filename,'.dat'] ;
                RawFile_vhdr=[InputPath,filename,'.vhdr'] ;
                RawFile_vmrk=[InputPath,filename,'.vmrk'] ;
                copyfile(RawFile_dat,LastNewFolder);  
                copyfile(RawFile_vhdr,LastNewFolder); 
                copyfile(RawFile_vmrk,LastNewFolder); 
            case {'.cnt','.bdf','.gdf','.edf','.EEG','.mat','.txt'} 
                NewFolder=[OutputPath,NewFolderName];
                if ~isdir(NewFolder)   % not exist   
                    mkdir(NewFolder);  % create NewFolder in OutputPath     
                end
                if strcmp(LastFileSuffix,'.dat')
                    LastFileSuffix = [];
                    copyfile(LastRawFile,LastNewFolder);                
                end
                
                copyfile(RawFile,NewFolder); 
            otherwise
        end
        LastFileSuffix = Suffix;                                   
	end;
    
    if strcmp(LastFileSuffix,'.dat') % end with '.dat' 
        copyfile(LastRawFile,LastNewFolder);    
    end
end;

fclose all;

end


