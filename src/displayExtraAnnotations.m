function displayExtraAnnotations(imdir, rec, cls)

for r = 1:numel(rec)
  for o = 1:numel(rec(r).objects)
    if rec(r).objects(o).detailedannotation && ...
        (strcmpi(rec(r).objects(o).class, cls) || strcmpi(cls, 'all'))
      details = rec(r).objects(o).details;
      im = imread(fullfile(imdir, rec(r).filename));
      figure(1), hold off, imshow(im)
      bbox = rec(r).objects(o).bbox;
      hold on, plot(bbox([1 1 3 3 1]), bbox([2 4 4 2 2]), 'r', 'linewidth', 3);
      
      fprintf('%s: %d %d\n', rec(r).objects(o).class, r, o);      
      fprintf('Occlusion:    %d\n', details.occ_level);
      fprintf('Area:         %d\n', details.bbox_area);
      fprintf('Aspect Ratio: %0.2f\n', details.bbox_aspectratio);
      fprintf('Parts Visible: \n');
      pnames = fieldnames(details.part_visible);
      for p = 1:numel(pnames)
        fprintf('  %s: %d \n', pnames{p}, details.part_visible.(pnames{p}));
      end
      snames = fieldnames(details.side_visible);
      for p = 1:numel(snames)
        fprintf('  %s: %d \n', snames{p}, details.side_visible.(snames{p}));
      end      
      fprintf('\n');
      pause;
    end
  end
end