function displayRankedPositives(imdir, rec, result)
% displayRankedPositives(imdir, rec, gt)
% 
% Sorts objects within a subset (defined by parameters within the code)
% according to their normalized precision and display
%
% Input:
%   imdir: the directory of images
%   rec: the PASCAL annotations structure
%   result: output of the analyzeTrueDetections function

% Sets which subset of positive examples to consider
occ_range = (0:4);
area_range = 5;
truncated_range = (0:1);
aspect_range = (0:5);
difficult_range = 0;

for o = 1:numel(result)
  gt = result(o).gt;
  pn = gt.pn;
    
  keep = true(gt.N, 1);
  for k = 1:gt.N        
    keep(k) = any(gt.isdiff(k)==difficult_range) & any(gt.occ_level(k)==occ_range) & ...
      any(gt.truncated(k)==truncated_range) & any(gt.area(k)==area_range) & ...
      any(gt.aspect(k)==aspect_range);
  end

  disp([result.name ' ' num2str(mean(pn(keep)))])
  [sv, si] = sort(pn, 'descend');
  
  for k = 1:gt.N
    i = si(k);
    if ~keep(i), continue; end;           
    im = imread(fullfile(imdir, rec(gt.rnum(si(k))).filename));
    bbox = rec(gt.rnum(si(k))).objects(gt.onum(si(k))).bbox;
    figure(1), hold off, imagesc(im); axis image, axis off;
    hold on, plot(bbox([1 1 3 3 1]), bbox([2 4 4 2 2]), 'r', 'linewidth', 3);  

    bbox = gt.bbox_ov(si(k), :);
    hold on, plot(bbox([1 1 3 3 1]), bbox([2 4 4 2 2]), 'b-', 'linewidth', 3);
    text(bbox(1)+3, bbox(2)+15, sprintf('%0.3f',gt.pn_ov(si(k))), 'backgroundcolor', [1 1 1], 'fontsize', 10);
    %title(sprintf('%s: pred=%0.3f, actual=%0.3f, bestov=%0.3f', result(o).name, predpn(si(k)), pn(si(k)), gt.pn_ov(si(k))));        

    bbox = gt.bbox_conf(si(k), :);
    if ~all(bbox==0)
      hold on, plot(bbox([1 1 3 3 1]), bbox([2 4 4 2 2]), 'g--', 'linewidth', 3);
      text(bbox(1)+3, bbox(2)+15, sprintf('%0.3f',pn(si(k))), 'backgroundcolor', [1 1 1], 'fontsize', 10);
    end        
    pause;
  end
end


