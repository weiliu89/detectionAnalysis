function [ap fraction] = computeAPForObjectSubset(result, varargin)
% [ap fraction] = computeAPForObjectSubset(result, varargin)
%
% Computes AP for the subset of objects specified.  Specify characteristics
% with triplets of type (e.g., area or truncated), possible range of values
% (e.g., 1:5 for size), and indices of selected values.  Requires that
% result.gt.(type) and result.(type) both exist. 
%
%   Format: computeAPForObjectSubset(result, type1, value_indices1,
%               possible_values1, type2, value_indices2, possible_values2, ...)
%
% Example: 
%  [ap, fraction] = computeAPForObjectSubset(result(1), 'area', 1:5, [3 4 5], 'truncated', [0:1], 0);
%    Returns AP for objects of area = 3-5 (med to large) and truncated=0.
%    Fraction is the % of objects that match that criterion.

conf = result.all.conf;
labels = result.all.labels;

fits = ~result.gt.isdiff;

for k = 1:3:numel(varargin)
  
  type = varargin{k};
  values = varargin{k+2};
  possible_values = varargin{k+1};
    
  tmplabels = [result.(type)(values).labels];
  labels(labels==1) = any(tmplabels(labels==1, :), 2);  
  
  tmp = result.gt.(type);
  fits = fits & any(repmat(tmp(:), [1 numel(values)])==repmat(possible_values(values), [numel(result.gt.(type)) 1]), 2);
  
end

pr = averagePrecisionNormalized(conf, labels, sum(fits), result(1).all.nnorm);
ap = pr.ap;

fraction = sum(fits)/result.all.npos;
disp(num2str([ap fraction]))