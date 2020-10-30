function wb_EEGfiles_CaptureFilter(InputPath,OutputPath,QA_table,ArrangeFlag,KeyWord)

if InputPath(end) ~= '\'
	InputPath = [InputPath, '\'];     
end;

QA_var=importdata(QA_table);
if ArrangeFlag == '0'
    for i_file=1:1:length(QA_var.filename)  
        if QA_var.DataQualityRating{i_file} == KeyWord
            RawFile=[InputPath,QA_var.filename{i_file},'.zip'];  % RawFile path
            fprintf('%s\n',RawFile);    
            copyfile(RawFile,OutputPath);  
        end
    end
elseif ArrangeFlag == '1'
    for i_file=1:1:length(QA_var.filename)  
        if QA_var.DataQualityRating{i_file} ~= KeyWord
            RawFile=[InputPath,QA_var.filename{i_file},'.zip'];  % RawFile path
            fprintf('%s\n',RawFile);    
            copyfile(RawFile,OutputPath);  
        end
    end    
end

copyfile([InputPath,'subjects_info.csv'],OutputPath);  
copyfile([InputPath,'datasets_info.json'],OutputPath);  
rmdir(InputPath,'s');
disp('********SUCCESS********');
end