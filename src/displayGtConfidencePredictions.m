function displayGtConfidencePredictions(imdir, rec, result, outdir, N)
% displayGtConfidencePredictions(imdir, rec, gt, outdir)
% 
% Sorts objects by their normalized precision, minus the average of the
% average normalized precision for their characteristics.  For example, a
% medium-sized side-view of an airplane is likely to have a high APn.  
%
% Input:
%   imdir: the directory of images
%   rec: the PASCAL annotations structure
%   result: output of the analyzeTrueDetections function

for o = 1:numel(result)
  gt = result(o).gt;
  pn = gt.pn;
  
  predpn = zeros(size(pn));
  
  attributes = zeros(gt.N, 4);
  keep = true(gt.N, 1);
  for k = 1:gt.N    
    if rec(gt.rnum(k)).objects(gt.onum(k)).difficult, 
      keep(k) = false;
      continue; 
    end;
    attributes(k, :) = [result(o).occ(gt.occ_level(k)).apn  ...
      result(o).truncated(gt.truncated(k)+1).apn ...
      result(o).area(gt.area(k)).apn  ...
      result(o).aspect(gt.aspect(k)).apn];        
  end
    
  keep = find(keep);
  
  if 0 
  %attributes = gt2attributes(gt);
  attributes(:, end+1) = ones(gt.N, 1);
  keep = find(~gt.isdiff & (pn>0));
      
  lambda = 0.05;

  w = robust_lsqfit(attributes(keep(2:2:end), :), pn(keep(2:2:end)), lambda);  
  disp(num2str(w'))
  predpn = attributes*w;
  predpn = min(max(predpn, 0), 1);
  
  else
    attributes = gt2attributes(gt);
    %w = robustfit(attributes(keep, :), pn(keep));
    w = regress(pn(keep), [ones(numel(keep), 1) attributes(keep, :)]);
    disp(num2str(w(2:end)'))
    predpn = attributes*w(2:end)+w(1);
    predpn = min(max(predpn, 0), 1);
  end
  diffpn = predpn-pn;
  [sv, si] = sort(diffpn, 'descend');
  %si = keep(1:end)'; 
  
  for k = keep(:)'
    
    if exist('N', 'var') && ~isempty(N)
      if find(keep==k)>N
        break;
      end
    end
    
    if rec(gt.rnum(si(k))).objects(gt.onum(si(k))).difficult, continue; end;
    im = imread(fullfile(imdir, rec(gt.rnum(si(k))).filename));
    bbox = rec(gt.rnum(si(k))).objects(gt.onum(si(k))).bbox;
    figure(1), hold off, imagesc(im); axis image, axis off;
    hold on, plot(bbox([1 1 3 3 1]), bbox([2 4 4 2 2]), 'r', 'linewidth', 3);  
    hold on, plot(bbox([1 1 3 3 1]), bbox([2 4 4 2 2]), 'k-', 'linewidth', 1);
    bboxgt = bbox;
    
    if 1 || all(gt.bbox_conf(si(k), :)==0)
      bbox = gt.bbox_ov(si(k), :);
      hold on, plot(bbox([1 1 3 3 1]), bbox([2 4 4 2 2]), 'b--', 'linewidth', 3);
      hold on, plot(bbox([1 1 3 3 1]), bbox([2 4 4 2 2]), 'k--', 'linewidth', 1);
      text(bbox(1)+3, bbox(2), sprintf('%0.3f',gt.pn_ov(si(k))), 'backgroundcolor', [1 1 1], 'fontsize', 10);    
    end
    %title(sprintf('%s: pred=%0.3f, actual=%0.3f, bestov=%0.3f', result(o).name, predpn(si(k)), pn(si(k)), gt.pn_ov(si(k))));        

    bbox = gt.bbox_conf(si(k), :);
    if ~all(bbox==0)
      hold on, plot(bbox([1 1 3 3 1]), bbox([2 4 4 2 2]), 'g-', 'linewidth', 3);
      hold on, plot(bbox([1 1 3 3 1]), bbox([2 4 4 2 2]), 'k-', 'linewidth', 1);
      text(bbox(1)+3, bbox(2), sprintf('%0.3f',pn(si(k))), 'backgroundcolor', [1 1 1], 'fontsize', 10);
    end        
    
    text(bboxgt(3)-30, bboxgt(2), sprintf('%0.3f',predpn(si(k))), 'backgroundcolor', [1 1 1], 'fontsize', 10, 'fontangle', 'italic');

    if exist('outdir', 'var') && ~isempty(outdir)
      numstr = num2str(k+10000); 
      print('-f1', '-dpdf', fullfile(outdir, [result(o).name '_tp_' numstr(2:end) '.pdf']));
    else
      pause;
    end
  end
end

%% Get binary attributes of object 
function att = gt2attributes(gt)

att = [];
fnames = {'area', 'aspect', 'occ_level', 'truncated'}; %, 'occ_level', 'truncated', 'part', 'side'}; % 'height'};
for f = 1:numel(fnames)
  if ~isstruct(gt.(fnames{f}))
    na = max(gt.(fnames{f}));
    att(:, end+(1:na)) = repmat(gt.(fnames{f})(:), [1 na])==repmat(1:na, [gt.N 1]);
  else
    fnames2 = fieldnames(gt.(fnames{f}));
    for k = 1:numel(fnames2)
      na = max(gt.(fnames{f}).(fnames2{k}));
      att(:, end+(1:na)) = repmat(gt.(fnames{f}).(fnames2{k})(:), [1 na])==repmat(1:na, [gt.N 1]);      
    end
  end
end
%att = att - repmat(mean(att, 1), [gt.N 1]);
%att = att ./ repmat(std(att, 1), [gt.N 1]);

%% Robust least squares fit
function w = robust_lsqfit(x, y, lambda)
% find weih
w = zeros(size(x, 2), 1);
sigma = 0.01;
warning off;
for k = 1:5
    w = fminunc(@(w)regresscost(w, x, y, sigma,lambda), w);    
    pred = x*w;
    %pred = min(max(x*w,0),1);
    err = sqrt((y-pred).^2);    
    sigma = median(err)*1.5;       
end


function err = regresscost(w, x, y, sigma, lambda)
%pred = min(max(x*w,0),1);
pred = x*w;
err = (y-pred).^2;
err = sum(err ./ (err + sigma.^2));
err = err + sum(abs(w))*lambda;
