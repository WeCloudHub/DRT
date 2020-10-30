function Fail_Flag=wb_EEGfiles_dat2set(IO_Path,FileName,srate,ChanlocsFile)
% Description: convert '.dat' files of other formats to '*.set'
% Param:
%   IO_Path : input and output path 
%   FileName: EEG data file name
% Note: supporting the EEG files format including '.dat'
%
% Written by Yufan Zhang (zyf15816794709@163.com)
% $ 2020.6.28 first version
% -------------------------------------------------------------------------

Fail_Flag = 0 ;  % 0:success  1:fail  2:not supportive fomrat

%delete Suffix
file_count=find('.'==FileName);
Suffix=FileName(file_count:end);
FileName_NoSuffix=FileName(1:file_count-1);

EEGfile_Path=[IO_Path,FileName]; %gain the path of original file
try
    switch Suffix
        case '.dat'
            matfile = pop_importdata('data',EEGfile_Path,'srate',str2num(srate),'dataformat','matlab');
            setfile = pop_saveset(matfile,FileName_NoSuffix,IO_Path,'onefile');           
            delete(EEGfile_Path);
        otherwise
            Fail_Flag = 2; % 0:success  1:fail  2:not supportive fomrat
    end
catch
    warning('Failed to convert into EEGLAB files(*set and *fdt)');
    if isempty(srate)
        warning('Requiring to import srate');
    end
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