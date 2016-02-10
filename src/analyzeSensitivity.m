function [res1, res2, base, attnames] = analyzeSensitivity(result, rec)
% Computes the residual in predicting object confidence
% (precision) given each set of 0, 1, or 2 attributes 

attnames = {'area', 'aspect', 'occ_level', 'truncated'};
for o = 1:numel(result)

  gt = result(o).gt;
  pn = gt.pn; % object confidence (normalized precision)
 
  keep = true(gt.N, 1);
  for k = 1:gt.N    
    if rec(gt.rnum(k)).objects(gt.onum(k)).difficult 
      keep(k) = false;
      continue; 
    end;       
  end  
  
  att = zeros(gt.N, numel(attnames));
  att_max = zeros(1, numel(attnames)); 
  for f = 1:numel(attnames)
    if ~isstruct(gt.(attnames{f}))
      att_max(f) = max(gt.(attnames{f}));
      att(:, f) = gt.(attnames{f})(:);
    end
    % below: not clear how to deal with attributes that are binary vectors
    %     else  
    %       attnames2 = fieldnames(gt.(attnames{f}));
    %       na = 1;
    %       for k = 1:numel(attnames2)
    %         na = na*max(gt.(attnames{f}).(attnames2{k})).^na;
    %         att(:, f) = att(:, f) + (k-1)
    %         binatt(k) = repmat(gt.(fnames{f}).(fnames2{k})(:), [1 na])==repmat(1:na, [gt.N 1]);
    %         att(:, end+(1:na)) = repmat(gt.(fnames{f}).(fnames2{k})(:), [1 na])==repmat(1:na, [gt.N 1]);      
    %       end
    %     end
  end

  [res1{o}, res2{o}, base{o}] = getAttributeResiduals(att(keep, :), pn(keep));

end


function [res1, res2, base] = getAttributeResiduals(att, pn)

N = numel(pn);
default = mean(pn);

% residual without attributes
base = sqrt(sum(getResidual(pn, default))/N);

% residual for each attribute by itself
res1 = zeros(N, size(att, 2));
for a = 1:size(att, 2);  
  vals = unique(att(:, a));
  for v = 1:numel(vals)
    ind = att(:, a)==vals(v);
    res1(ind, a) = getResidual(pn(ind), default);
  end
end
res1 = sqrt(sum(res1)/N);

% residual for pairs of attributes
res2 = zeros(N, size(att, 2), size(att, 2));
for a1 = 1:size(att, 2) 
  vals1 = unique(att(:, a1));
  for a2 = 1:size(att, 2)
    vals2 = unique(att(:, a2));
    for v1 = 1:numel(vals1)
      for v2 = 1:numel(vals2)
        ind = (att(:, a1)==vals1(v1)) &  (att(:, a2)==vals2(v2));
        if any(ind)
          res2(ind, a1, a2) = getResidual(pn(ind), default);
        end
      end
    end
  end
end
res2 = sqrt(sum(res2, 1)/N);
res2 = squeeze(res2);

function res = getResidual(pn, default)    
N = numel(pn);
if N == 1
  res = (default-pn).^2;
  return;
end

sum_pn = sum(pn);

res = zeros(size(pn));
for k =1:numel(pn)
  res(k) = (pn(k) - (sum_pn-pn(k))/(N-1)).^2;
end