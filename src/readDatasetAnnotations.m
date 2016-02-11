function ann = readDatasetAnnotations(dataset, dataset_params)
% ann = readDatasetAnnotations(dataset, dataset_params)
%
% Dataset-specific function to read and process annotations

switch lower(dataset)
case 'voc'
    outfn = fullfile(dataset_params.annotationdir, ...
    sprintf('%s_annotations_%s.mat', dataset_params.VOCset, dataset_params.imset));
    if ~exist(outfn, 'file')
      rec = PASreadAllRecords(dataset_params.imset, 'main');
      for o = 1:numel(dataset_params.objnames_extra)    
        annotationpath = fullfile(dataset_params.annotationdir, 'gt_ved_%s.txt');
        rec = updateRecordAnnotations(rec, annotationpath, dataset_params.objnames_extra{o});
      end
      for r = 1:numel(rec)
        for n = 1:numel(rec(r).objects)
          if isfield(rec(r).objects(n), 'details') && ~isempty(rec(r).objects(n).details)
            rec(r).objects(n).detailedannotation = 1;
          else
            rec(r).objects(n).details = [];
            rec(r).objects(n).detailedannotation = 0;        
          end
        end
      end

      % processes the annotations into a more easily usable form for ground
      % truth
      usediff = true;
      for o = 1:numel(dataset_params.objnames_all)
        objname = dataset_params.objnames_all{o}; 
        [gt(o).ids, gt(o).bbox, gt(o).isdiff, gt(o).istrunc, gt(o).isocc, ...
        gt(o).details, gt(o).rnum, gt(o).onum] = PASgetObjects(rec, objname, usediff, VOCopts.classes);
        gt(o).N = size(gt(o).bbox, 1);
      end   

      ann.rec = rec;
      ann.gt = gt;      

      save(outfn, 'ann'); 
    else
      load(outfn, 'ann');
    end
  case 'ilsvrc'
    outfn = fullfile(dataset_params.annotationdir, ...
    sprintf('%s_annotations_%s.mat', dataset_params.VOCset, dataset_params.imset));
    if ~exist(outfn, 'file')
      imgset_file = sprintf('%s/%s_%s.txt', dataset_params.annotationdir, dataset_params.VOCset, dataset_params.imset);
      if ~exist(imgset_file, 'file')
        fprintf('%s does not exist\n', imgset_file);
        return;
      end
      ids = textread(imgset_file, '%s');
      objcount = zeros(numel(ids), numel(dataset_params.objnames_all), 'uint8');
      for i=1:numel(ids)
        % read annotation
        rec(i) =PASreadrecord(sprintf('%s/%s.xml', dataset_params.annotationsrcdir, ids{i}));
        if i == 1
          rec(numel(ids)) = rec(i);
        end

        for k = 1:numel(rec(i).objects)
            c = strcmp(rec(i).objects(k).class, dataset_params.objnames_all);
            objcount(i, c) = objcount(i, c) + 1;
        end

      end
      for r = 1:numel(rec)
        for n = 1:numel(rec(r).objects)
          if isfield(rec(r).objects(n), 'details') && ~isempty(rec(r).objects(n).details)
            rec(r).objects(n).detailedannotation = 1;
          else
            rec(r).objects(n).details = [];
            rec(r).objects(n).detailedannotation = 0;        
          end
        end
      end

      % processes the annotations into a more easily usable form for ground
      % truth
      usediff = true;
      for o = 1:numel(dataset_params.objnames_all)
        objname = dataset_params.objnames_all{o}; 
        [gt(o).ids, gt(o).bbox, gt(o).isdiff, gt(o).istrunc, gt(o).isocc, ...
        gt(o).details, gt(o).rnum, gt(o).onum] = PASgetObjects(rec, objname, usediff, dataset_params.objnames_all);
        gt(o).N = size(gt(o).bbox, 1);
      end   

      ann.rec = rec;
      ann.gt = gt;      

      save(outfn, 'ann'); 
    else
      load(outfn, 'ann');
    end
  otherwise 
    error('dataset %s is unknown\n', dataset);
end
