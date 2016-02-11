function det = readDetections(dataset, dataset_params, ann, objname)
% det = readDetections(dataset, dataset_params, ann, objname)
% 
% Reads object detections for class objname to be analyzed

switch lower(dataset)

case 'voc'

    rec = ann.rec;

    % reads detection results in format (file_id conf x1 y1 x2 y2) and outputs
    % the bounding box, confidence, and corresponding record index    
    detfn = sprintf(dataset_params.detpath, objname);
    [ids,conf,x1,y1,x2,y2]=textread(detfn,'%s %f %f %f %f %f');

    bbox = [x1 y1 x2 y2];

    ind = conf >= dataset_params.confidence_threshold;
    bbox = bbox(ind, :);
    ids = ids(ind);
    conf = conf(ind);


    % constrain the bounding box to lie within the image and get the record
    % number
    bbox = max(bbox, 1);
    if exist('rec', 'var')
      recnum = zeros(size(conf));
      for r = 1:numel(rec)
        ind = strcmp(ids, strtok(rec(r).filename, '.'));
        recnum(ind) = r;
        bbox(ind, 3) = min(bbox(ind, 3), rec(r).imgsize(1));
        bbox(ind, 4) = min(bbox(ind, 4), rec(r).imgsize(2));
      end
    end

    [det.bbox, det.conf, det.rnum] = deal(bbox, conf, recnum);
    det.nimages = numel(rec);
    det.N  =size(det.bbox, 1);
  case 'ilsvrc'

    rec = ann.rec;

    % reads detection results in format (file_id conf x1 y1 x2 y2) and outputs
    % the bounding box, confidence, and corresponding record index
    detfn = sprintf(dataset_params.detpath, objname);
    [ids,conf,x1,y1,x2,y2]=textread(detfn,'%s %f %f %f %f %f');

    bbox = [x1 y1 x2 y2];

    ind = conf >= dataset_params.confidence_threshold;
    bbox = bbox(ind, :);
    ids = ids(ind);
    conf = conf(ind);


    % constrain the bounding box to lie within the image and get the record
    % number
    bbox = max(bbox, 1);
    if exist('rec', 'var')
      recnum = zeros(size(conf));
      for r = 1:numel(rec)
        ind = strcmp(ids, strtok(rec(r).filename, '.'));
        recnum(ind) = r;    
        bbox(ind, 3) = min(bbox(ind, 3), rec(r).imgsize(1));
        bbox(ind, 4) = min(bbox(ind, 4), rec(r).imgsize(2));
      end
    end

    [det.bbox, det.conf, det.rnum] = deal(bbox, conf, recnum);
    det.nimages = numel(rec);
    det.N  =size(det.bbox, 1);
  otherwise 
    error('dataset %s unknown', dataset);
end
