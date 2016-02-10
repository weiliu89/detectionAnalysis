function result = averagePrecisionNormalized(conf, label, npos, nnorm)
% result = averagePrecisionNormalized(conf, label, npos, nnorm)
%
% Computes full interpolated average precision, first normalizing the 
% precision values.  
% Normally, p = tp ./ (fp + tp), but this is sensitive to the density of
% positive examples.  For normalized precision, 
%   tp2 = (tp*N/Npos);  p_norm = tp2 ./ (fp + tp2);
%
% Input:
%   conf(ndet, 1): confidence of each detection
%   label(ndet, 1): label of each detection (-1, 1; 0=don't care)
%   npos: the number of ground truth positive examples
%   nnorm: the normalized value for number of positives (for normalized AP)
%
% Output:
%   result.(labels, conf, npos, nnorm, r, p, pn, ap, apn, ap_std, apn_std):
%     the precision-recall and normalized precision-recall curves with AP
%     and standard error of AP
%

[sv, si] = sort(conf, 'descend');
label = label(si);

tp = cumsum(label==1);
fp = cumsum(label==-1);
conf = sv;

r = tp / npos;
p = tp ./ (tp + fp);

tpn = tp*nnorm/npos;
pn = tpn ./ (tpn + fp);

result = struct('labels', label, 'conf', conf, 'r', r, 'p', p, 'pn', pn);
result.npos = npos;
result.nnorm = nnorm;


% compute interpolated precision and normalized precision
istp = (label==1);
Np = numel(r);
for i = Np-1:-1:1
  p(i) = max(p(i), p(i+1));
  pn(i) = max(pn(i), pn(i+1));
end
result.pi = p;
result.pni = pn;
result.ap = mean(p(istp))*r(end);
result.apn = mean(pn(istp))*r(end);

missed = zeros(npos-sum(label==1),1);
result.ap_stderr = std([p(istp(:)) ; missed])/sqrt(npos);
result.apn_stderr = std([pn(istp(:)) ; missed])/sqrt(npos);
    