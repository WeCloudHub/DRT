function FolderName=wb_EEGfiles_NamePattern(original_InputPath,current_InputPath)

if original_InputPath(end) == filesep
    original_InputPath = original_InputPath(1:end-1);     
end;

if current_InputPath(end) == filesep
    current_InputPath = current_InputPath(1:end-1);     
end;

original=regexp(original_InputPath, filesep, 'split');
current=regexp(current_InputPath, filesep, 'split');

FolderName=char(original(end));

if length(original) == length(current)
    return
else
    for i=1:1:(length(current)-length(original))
        %FolderName=[FolderName,'_',current{length(original)+i}];
        FolderName=[current{length(original)+i}];
    end
end

end