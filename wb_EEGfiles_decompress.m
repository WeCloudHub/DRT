function [DecompressFileCount,DecompressFileName]=wb_EEGfiles_decompress(InputPath,DecompressFileCount,DecompressFileName)

if InputPath(end) ~= filesep
    InputPath = [InputPath, filesep];     
end;

%fprintf('Start to check for compressed files, please wait...\n');
RootDir=dir(InputPath);
for i_file=1:1:length(RootDir)   % first search current dir 
    if RootDir(i_file).isdir & (~strcmp(RootDir(i_file).name,'.')) & (~strcmp(RootDir(i_file).name,'..'))  %check isDir
        SubDir=[InputPath,RootDir(i_file).name];
        [DecompressFileCount,DecompressFileName]=wb_EEGfiles_decompress(SubDir,DecompressFileCount,DecompressFileName);
    elseif RootDir(i_file).isdir == 0  
        FileName=RootDir(i_file).name;
        %disp(FileName);
        Suffix=FileName(end-3:end);
        RawFile=[InputPath,RootDir(i_file).name] ;
        
        if strcmp(Suffix,'.zip')
            DecompressFileCount=DecompressFileCount+1;
            DecompressFileName{DecompressFileCount}=RawFile(1:end-4);
            unzip(RawFile,InputPath); % unzip 
        end
    end;     
end

end