function str=wb_EEGfiles_AddSub(Count)         
    if Count < 10
        str=['sub-0000',num2str(Count)];  
    elseif Count >= 10 && Count < 100
        str=['sub-000',num2str(Count)];  
    elseif Count >= 100 && Count < 1000
        str=['sub-00',num2str(Count)]; 
    elseif Count >= 1000 && Count < 10000
        str=['sub-0',num2str(Count)];  
    else Count >= 10000 
        str=['sub-',num2str(Count)];  
    %fprintf('%s\n',str); 
    end;
end