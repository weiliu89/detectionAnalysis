function showSurprisingMisses(imdir, rec, result)
% showSurprisingMisses(imdir, rec, gt)
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
    
    %predpn(k) = (result(o).occ(gt.occ_level(k)).apn + ...
    %  result(o).truncated(gt.truncated(k)+1).apn + ...
    %  result(o).area(gt.area(k)).apn + ...
    %  result(o).aspect(gt.aspect(k)).apn)/4;
  end
    
  w = robustfit(attributes(keep, :), pn(keep));
  disp(num2str(w'))
  predpn = attributes*w(2:end) + w(1);
  
  diffpn = predpn-pn;
  [sv, si] = sort(diffpn, 'descend');
  
  for k = 1:gt.N
    if rec(gt.rnum(si(k))).objects(gt.onum(si(k))).difficult, continue; end;
    im = imread(fullfile(imdir, rec(gt.rnum(si(k))).filename));
    bbox = rec(gt.rnum(si(k))).objects(gt.onum(si(k))).bbox;
    figure(1), hold off, imagesc(im); axis image, axis off;
    hold on, plot(bbox([1 1 3 3 1]), bbox([2 4 4 2 2]), 'r', 'linewidth', 3);  
    text(bbox(1)+3, bbox(2)+15, sprintf('%0.3f',predpn(si(k))), 'backgroundcolor', [1 1 1], 'fontsize', 10, 'fontangle', 'italic');

    bbox = gt.bbox_ov(si(k), :);
    hold on, plot(bbox([1 1 3 3 1]), bbox([2 4 4 2 2]), 'b-', 'linewidth', 3);
    text(bbox(1)+3, bbox(2)+15, sprintf('%0.3f',gt.pn_ov(si(k))), 'backgroundcolor', [1 1 1], 'fontsize', 10);
    %title(sprintf('%s: pred=%0.3f, actual=%0.3f, bestov=%0.3f', result(o).name, predpn(si(k)), pn(si(k)), gt.pn_ov(si(k))));        

    bbox = gt.bbox_conf(si(k), :);
    if ~all(bbox==0)
      hold on, plot(bbox([1 1 3 3 1]), bbox([2 4 4 2 2]), 'g--', 'linewidth', 3);
      text(bbox(1)+3, bbox(2)+15, sprintf('%0.3f',pn(si(k))), 'backgroundcolor', [1 1 1], 'fontsize', 10);
    end        
    %pause;
  end
end

function att = gt2attributes(gt)

att = [];
fnames = {'area', 'aspect', 'occ_level', 'truncated', 'part', 'side', 'height'};
for f = 1:numel(fnames)
  if ~isstruct(fnames{f})
    na = max(gt.(fnames{f}));
    att(:, end+(1:na)) = repmat(gt.(fnames{f}), [1 na])==repmat(1:na, [gt.N 1]);
  else
    fnames2 = fieldnames(gt.(fnames{f}));
    for k = 1:numel(fnames2)
      na = max(gt.(fnames{f}).(fnames2{k}));
      att(:, end+(1:na)) = repmat(gt.(fnames{f}).(fnames2{k}), [1 na])==repmat(1:na, [gt.N 1]);      
    end
  end
end
