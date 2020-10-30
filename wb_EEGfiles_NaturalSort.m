function [X,ndx,dbg] = wb_EEGfiles_NaturalSort(X,rgx,varargin)

assert(iscell(X),'First input <X> must be a cell array.')
tmp = cellfun('isclass',X,'char') & cellfun('size',X,1)<2 & cellfun('ndims',X)<3;
assert(all(tmp(:)),'First input <X> must be a cell array of char row vectors (1xN char).')

if nargin<2 || isnumeric(rgx)&&isempty(rgx)
    rgx = '\d+';
else
    assert(ischar(rgx)&&ndims(rgx)<3&&size(rgx,1)==1,...
        'Second input <rgx> must be a regular expression (char row vector).') %#ok<ISMAT>
end

% Optional arguments:
tmp = cellfun('isclass',varargin,'char') & cellfun('size',varargin,1)<2 & cellfun('ndims',varargin)<3;
assert(all(tmp(:)),'All optional arguments must be char row vectors (1xN char).')
% Character case:
ccm = strcmpi(varargin,'matchcase');
ccx = strcmpi(varargin,'ignorecase')|ccm;
% Sort direction:
sdd = strcmpi(varargin,'descend');
sdx = strcmpi(varargin,'ascend')|sdd;
% Char/num order:
chb = strcmpi(varargin,'char<num');
chx = strcmpi(varargin,'num<char')|chb;
% NaN/num order:
nab = strcmpi(varargin,'NaN<num');
nax = strcmpi(varargin,'num<NaN')|nab;
% SSCANF format:
sfx = ~cellfun('isempty',regexp(varargin,'^%([bdiuoxfeg]|l[diuox])$'));

nsAssert(1,varargin,sdx,'Sort direction')
nsAssert(1,varargin,chx,'Char<->num')
nsAssert(1,varargin,nax,'NaN<->num')
nsAssert(1,varargin,sfx,'SSCANF format')
nsAssert(0,varargin,~(ccx|sdx|chx|nax|sfx))

% SSCANF format:
if nnz(sfx)
    fmt = varargin{sfx};
    if strcmpi(fmt,'%b')
        cls = 'double';
    else
        cls = class(sscanf('0',fmt));
    end
else
    fmt = '%f';
    cls = 'double';
end


[mat,spl] = regexpi(X(:),rgx,'match','split',varargin{ccx});

% Determine lengths:
nmx = numel(X);
nmn = cellfun('length',mat);
nms = cellfun('length',spl);
mxs = max(nms);

% Preallocate arrays:
bon = bsxfun(@le,1:mxs,nmn).';
bos = bsxfun(@le,1:mxs,nms).';
arn = zeros(mxs,nmx,cls);
ars =  cell(mxs,nmx);
ars(:) = {''};
ars(bos) = [spl{:}];


if nmx
    tmp = [mat{:}];
    if strcmp(fmt,'%b')
        tmp = regexprep(tmp,'^0[Bb]','');
        vec = cellfun(@(s)sum(pow2(s-'0',numel(s)-1:-1:0)),tmp);
    else
        vec = sscanf(sprintf(' %s',tmp{:}),fmt);
    end
    assert(numel(vec)==numel(tmp),'The %s format must return one value for each input number.',fmt)
else
    vec = [];
end


if nmx && nargout>2
    dbg = cell(mxs,nmx);
    dbg(:) = {''};
    dbg(bon) = num2cell(vec);
    dbg = reshape(permute(cat(3,ars,dbg),[3,1,2]),[],nmx).';
    idf = [find(~all(cellfun('isempty',dbg),1),1,'last'),1];
    dbg = dbg(:,1:idf(1));
else
    dbg = {};
end


if ~any(ccm) % ignorecase
    ars = lower(ars);
end

if nmx && any(chb) % char<num
    boe = ~cellfun('isempty',ars(bon));
    for k = reshape(find(bon),1,[])
        ars{k}(end+1) = char(65535);
    end
    [idr,idc] = find(bon);
    idn = sub2ind(size(bon),boe(:)+idr(:),idc(:));
    bon(:) = false;
    bon(idn) = true;
    arn(idn) = vec;
    bon(isnan(arn)) = ~any(nab);
    ndx = 1:nmx;
    if any(sdd) % descending
        for k = mxs:-1:1
            [~,idx] = sort(nsGroup(ars(k,ndx)),'descend');
            ndx = ndx(idx);
            [~,idx] = sort(arn(k,ndx),'descend');
            ndx = ndx(idx);
            [~,idx] = sort(bon(k,ndx),'descend');
            ndx = ndx(idx);
        end
    else % ascending
        for k = mxs:-1:1
            [~,idx] = sort(ars(k,ndx));
            ndx = ndx(idx);
            [~,idx] = sort(arn(k,ndx),'ascend');
            ndx = ndx(idx);
            [~,idx] = sort(bon(k,ndx),'ascend');
            ndx = ndx(idx);
        end
    end
else % num<char
    arn(bon) = vec;
    bon(isnan(arn)) = ~any(nab);
    if any(sdd) % descending
        [~,ndx] = sort(nsGroup(ars(mxs,:)),'descend');
        for k = mxs-1:-1:1
            [~,idx] = sort(arn(k,ndx),'descend');
            ndx = ndx(idx);
            [~,idx] = sort(bon(k,ndx),'descend');
            ndx = ndx(idx);
            [~,idx] = sort(nsGroup(ars(k,ndx)),'descend');
            ndx = ndx(idx);
        end
    else % ascending
        [~,ndx] = sort(ars(mxs,:));
        for k = mxs-1:-1:1
            [~,idx] = sort(arn(k,ndx),'ascend');
            ndx = ndx(idx);
            [~,idx] = sort(bon(k,ndx),'ascend');
            ndx = ndx(idx);
            [~,idx] = sort(ars(k,ndx));
            ndx = ndx(idx);
        end
    end
end

ndx  = reshape(ndx,size(X));
X = X(ndx);

end

function nsAssert(val,inp,idx,varargin)
% Throw an error if an option is overspecified.
if nnz(idx)>val
    tmp = {'Unknown input arguments',' option may only be specified once. Provided inputs'};
    error('%s:%s',[varargin{:},tmp{1+val}],sprintf('\n''%s''',inp{idx}))
end
end

function grp = nsGroup(vec)
% Groups of a cell array of strings, equivalent to [~,~,grp]=unique(vec);
[vec,idx] = sort(vec);
grp = cumsum([true,~strcmp(vec(1:end-1),vec(2:end))]);
grp(idx) = grp;
end
