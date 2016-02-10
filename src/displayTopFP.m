function displayTopFP(dataset, dataset_params, ann, objname, result, det, outdir, N) 
% displayTopFP(imdir, rec, result, det, gt, outdir, N) 
%
% Displays N of the top false positives.  Images are saved if outdir is
% set. Otherwise, pause is called after each image.

switch lower(dataset)
  case 'voc'
    displayTopFP_VOC(dataset, dataset_params, ann, objname, result, det, outdir, N);
  otherwise
    error('unknown datset: %s', dataset); 
end

function displayTopFP_VOC(dataset, dataset_params, ann, objname, result, det, outdir, N) 

rec = ann.rec;

close all
for o = 1:numel(result)
       
  [sv, si] = sort(det(o).conf, 'descend');
  det(o).conf = det(o).conf(si);  
  det(o).rnum = det(o).rnum(si);
  det(o).bbox = det(o).bbox(si, :);
  
  det2 = matchDetectionsWithGroundTruth(dataset, dataset_params, objname, ann, det, 'strong');  
  
  pi = result(o).all.pi;
  recall = result(o).all.r;
  
  isbg = result(o).isbg & ~result(o).isother;
  isoth = result(o).isother;
  isloc = result(o).isloc;
  issim = result(o).issim;
  indfp = find(isbg | isloc | issim | isoth);
        
  %[sv, si] = sort(pi(indfp), 'descend');    
  %indfp = indfp(si);  
    
  for k = 1:numel(indfp)
    
    if exist('N', 'var') && ~isempty(N)
      if k>N
        break;
      end
    end
    
    
    i = indfp(k);            
    
    im = imread(fullfile(dataset_params.imdir, rec(det(o).rnum(i)).filename));
    bbox = round(det(o).bbox(i, :));
    
    figure(1), hold off, imagesc(im); axis image, axis off;
    hold on, plot(bbox([1 1 3 3 1]), bbox([2 4 4 2 2]), 'g-', 'linewidth', 4.5);  
    hold on, plot(bbox([1 1 3 3 1]), bbox([2 4 4 2 2]), 'k-', 'linewidth', 1.5);    
    
    typestr = '';
    if isbg(i), typestr = 'bg'; end
    if issim(i), typestr = 'sim'; end
    if isloc(i), typestr = 'loc'; end    
    if isoth(i), typestr = 'oth'; end   
    
    [imh, imw, imb] = size(im);
    text(1, imh-11, sprintf('%s (%s): ov=%0.2f  1-r=%0.2f',result(o).name, typestr, det2.ov(i), 1-recall(i)), 'backgroundcolor', [1 1 1], 'fontsize', 22);    
    
    if exist('outdir', 'var') && ~isempty(outdir)
      numstr = num2str(k+10000); 
      print('-f1', '-dpdf', fullfile(outdir, [result(o).name '_fp_' numstr(2:end) '.pdf']));
      imwrite(im(bbox(2):bbox(4), bbox(1):bbox(3), :), fullfile(outdir, [result(o).name '_fpwindow_' typestr '_' numstr(2:end) '.jpg']));
    else
      pause;
    end
  end
end