% calculate a bag of reconstruction matrices from random channel subsets
function P = calc_projector(locs,num_samples,subset_size)
stream = RandStream('mt19937ar','Seed',435656);
rand_samples = {};
for k=num_samples:-1:1
    tmp = zeros(size(locs,2));
    subset = randsample(1:size(locs,2),subset_size,stream);
    tmp(subset,:) = real(sphericalSplineInterpolate(locs(:,subset),locs))';
    rand_samples{k} = tmp;
end
P = horzcat(rand_samples{:});


function Y = randsample(X,num,stream)
Y = [];
while length(Y)<num
    pick = round(1 + (length(X)-1).*rand(stream));
    Y(end+1) = X(pick);
    X(pick) = [];
end