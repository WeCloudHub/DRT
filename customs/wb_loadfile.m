function data = wb_loadfile(file)

% load MATLAB .*mat or ASCII .*txt file (e.g. results calculated by WeBrain, 
%  connection matrix of network, or features/measures etc).

% Input: a MATLAB .*mat or ASCII .*txt file.
% Output: a data structure or array.

% Written by Li Dong (Lidong@uestc.edu.cn)
% $ 2018.1.8
% -------------------------------------------------------------------------
[~, ~,ext] = fileparts(file);

switch ext
    case '.txt'
        try data = load(file, '-ascii');
        catch
            error('cannot read the ascii txt file');
        end;
    case '.mat'
        try
            x = whos('-file', file);
            if length(x) > 1,
                error(' .mat file must contain a single variable');
            end;
            tmpdata = load(file, '-mat');
            data = getfield(tmpdata,{1},x(1).name);
            clear tmpdata;
        catch, error('cannot read the .mat file');
        end;
    otherwise
        error('unrecognized file format');
end;