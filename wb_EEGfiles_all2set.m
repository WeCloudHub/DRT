function Fail_Flag=wb_EEGfiles_all2set(IO_Path,FileName,srate,ChanlocsFile)
% Description: convert EEG files of other formats to '*.set'
% Param:
%   IO_Path : input and output path 
%   FileName: EEG data file name
% Note: supporting the EEG files format including '.set','.mat','.vmrk','.cnt','.EEG','.bdf','.EDF'
%
% Written by Yufan Zhang (zyf15816794709@163.com)
% $ 2020.2.25 first version
% $ 2020.3.17 add srate for '.mat'
% -------------------------------------------------------------------------

Fail_Flag = 0 ;  % 0:success  1:fail  2:not supportive fomrat

%delete Suffix
file_count=find('.'==FileName);
Suffix=FileName(file_count:end);
FileName_NoSuffix=FileName(1:file_count-1);

EEGfile_Path=[IO_Path,FileName]; %gain the path of original file
try
    switch Suffix
        case '.cnt'
            cntfile = pop_loadcnt(EEGfile_Path);
            setfile = pop_saveset(cntfile,FileName_NoSuffix,IO_Path,'onefile');
            delete(EEGfile_Path); 
        case '.EEG'
            EEGfile = pop_loadeeg(EEGfile_Path); 
            setfile = pop_saveset(EEGfile,FileName_NoSuffix,IO_Path,'onefile');
            delete(EEGfile_Path); 
        case {'.bdf','.edf'}
            bdffile = pop_readbdf(EEGfile_Path);
            setfile = pop_saveset(bdffile,FileName_NoSuffix,IO_Path,'onefile');
            fclose all;
            delete(EEGfile_Path); 
        case '.gdf'
            gdffile = pop_biosig(EEGfile_Path);
            setfile = pop_saveset(gdffile,FileName_NoSuffix,IO_Path,'onefile');
            delete(EEGfile_Path);             
        case '.vhdr'
            vhdrfile=pop_loadbv(IO_Path,FileName); 
            setfile=pop_saveset(vhdrfile,FileName_NoSuffix,IO_Path,'onefile');
            delete(EEGfile_Path);
            delete([IO_Path,FileName_NoSuffix,'.vmrk']);
        case '.mat'
            matfile = pop_importdata('data',EEGfile_Path,'srate',str2num(srate),'dataformat','matlab');
            setfile = pop_saveset(matfile,FileName_NoSuffix,IO_Path,'onefile');
            delete(EEGfile_Path);
        case '.txt' % ASCII .txt
            txtfile=pop_importdata('data',EEGfile_Path,'srate',str2num(srate),'dataformat','ascii');  
            setfile=pop_saveset(txtfile,FileName_NoSuffix,IO_Path,'onefile');
            delete(EEGfile_Path);       
        
            %[~,labels,Th,Rd,~] = readlocs(locFile);
        otherwise
            Fail_Flag = 2; % 0:success  1:fail  2:not supportive fomrat
    end
catch
    warning('Failed to convert into EEGLAB files(*set and *fdt)');
    disp(['Failed: ',FileName]);
	Fail_Flag = 1 ; % 0:success  1:fail  2:not supportive fomrat
end

if Fail_Flag == 0 
    if ~isempty(ChanlocsFile) 
        new_setfile=pop_chanedit(setfile,'load',ChanlocsFile);
        pop_saveset(new_setfile,FileName_NoSuffix,IO_Path,'onefile');
    end
end

end