function [windata] = wb_slidewin(data,winLenth,proportion)
% Dividing EEG data into small segments with a percentage overlap using 
% sliding window method.
% Input:
%    data:  the EEG potentials,channels X time points. e.g. 
%           62 channels X 5000 time points.
%    winLenth: length of small windows/segments. Unit is time points.
%    proportion: overlapped percentage for each segments/sliding windows. It
%           should be [0,1). Default is 0.
% Output:
%    windata: small segments with a percentage overlap. Cell structure with 
%             channels X time points.
% -------------------------------------------------------------------------
% Written by Li Dong (UESTC, Li_dong729@163.com)
% $ 2018.2.27
% -------------------------------------------------------------------------
if nargin < 2
    error('Required two inputs at least.');
elseif nargin == 2
    proportion = 0;
end

Nt = size(data,2); % number of time points
% -----------------
windata = [];
if winLenth >= 1 && winLenth <= Nt
    if proportion == 0
        N_win = fix(Nt/winLenth);
        if N_win >=1
            for i = 1:N_win
                windata{1,i} = data(:,(winLenth*(i-1)+1:winLenth*i));
            end
        end
    elseif proportion > 0 && proportion < 1
        L1 = max(1,round((1-proportion)*winLenth));
        i = 1;
        if L1 >=1
            while winLenth+L1*(i-1) <= Nt
                windata{1,i} = data(:,(L1*(i-1)+1:winLenth+L1*(i-1)));
                i = i+1;
            end
        end
    else
        error('proportion is not correct.');
    end  
end


