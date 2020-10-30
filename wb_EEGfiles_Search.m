function QA_InputFile=wb_EEGfiles_Search(InputPath)
%返回一个文件夹内所有的zip文件（包括子目录下）

if InputPath(end) ~= filesep
    InputPath = [InputPath, filesep];     
end;

QA_InputFile=[];
RootDir=dir(InputPath);
for i_file=1:1:length(RootDir)  
    if RootDir(i_file).isdir & (~strcmp(RootDir(i_file).name,'.')) & (~strcmp(RootDir(i_file).name,'..'))  %check isDir
         FolderPath=[InputPath,RootDir(i_file).name];
         if isempty(QA_InputFile)
            QA_InputFile=wb_EEGfiles_Search(FolderPath); 
         else
            QA_InputFile=[QA_InputFile,',',wb_EEGfiles_Search(FolderPath)];
         end
    else
         RawFile=[InputPath,RootDir(i_file).name] ; % RawFile path
         
         [filepath,filename,Suffix] = fileparts(RawFile);

         switch Suffix
            case '.zip'
                if isempty(QA_InputFile)
                    QA_InputFile=RawFile;
                else
                    QA_InputFile=[QA_InputFile,',',RawFile];
                end
            otherwise
         end
    end;
end

end