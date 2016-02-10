for v = ['4']
  fnpath = ['/mnt/disk2/datasets/pascal2010/detections_dpm_v' v '/%s_final_VOC2007_fgmr' v '/%sfgmr' v '.mat'];
  outpath = ['/home/dhoiem/src/detectionAnalysis/detections/felzenszwalb_v' v '/fel_v' v '_VOC2007_%s_det.txt'];

  allnames = {'aeroplane', 'bicycle', 'bird', 'boat', 'bottle', 'bus', 'car', ...
       'cat', 'chair', 'cow', 'diningtable', 'dog', 'horse', 'motorbike', 'person', ...
       'pottedplant', 'sheep', 'sofa', 'train', 'tvmonitor'};  

  for o = 1:numel(allnames)
    objname = allnames{o};
    disp(objname)
    fid = fopen(sprintf(outpath, objname), 'w');    

    for r = 1:numel(rec)
      id = strtok(rec(r).filename, '.');
      fn = sprintf(fnpath, objname, id);
      load(fn, 'detections');
      if isempty(detections), continue; end;
      bbox = detections(:, 1:4);
      conf = detections(:, end);   

      bbox(:, [1 2]) = max(bbox(:, [1 2]), 1);
      bbox(:, [3 4]) = min(bbox(:, [3 4]), repmat(rec(r).imgsize(1:2), [size(bbox, 1) 1]));

      maxov = 0.5;
      [bbox, conf] = pruneBBox(bbox, conf, [], [], maxov);            

      for j=1:numel(conf)
        fprintf(fid,'%s %f %f %f %f %f\n',id,conf(j),bbox(j, :));
      end
    end
    fclose(fid);
  end
end