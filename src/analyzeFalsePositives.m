function result = analyzeFalsePositives(dataset, dataset_params, ann, objind, similar_ind, det, normalizedCount)
% result = analyzeFalsePositives(dataset, dataset_params, ann, objind, similar_ind, det, normalizedCount)

switch lower(dataset)
  case {'voc', 'voc_compatible'}
                         
    result = analyzeFalsePositives_VOC(dataset, dataset_params, ann, objind, similar_ind, det, normalizedCount);
        
  otherwise
    error('dataset %s is unknown\n', dataset);
end  

function result = analyzeFalsePositives_VOC(dataset, dataset_params, ann, objind, similar_ind, det, normalizedCount)

[sv, si] = sort(det.conf, 'descend');
det.bbox = det.bbox(si, :);
det.conf = det.conf(si);
det.rnum = det.rnum(si);

objname = dataset_params.objnames_all{objind};

% Regular
[det, gt] = matchDetectionsWithGroundTruth(dataset, dataset_params, objname, ann, det, 'strong');
npos = sum(~[gt.isdiff]);
result.all = averagePrecisionNormalized(det.conf, det.label, npos, normalizedCount);
result.iscorrect = (det.label>=0);

% Ignore localization error: remove detections that are duplicates or have
% poor localization
det2 = matchDetectionsWithGroundTruth(dataset, dataset_params, objname, ann, det, 'weak');
result.isloc = (det.label==-1) & (det2.label>=0);

% Code below sets confidence of localization errors to -Inf
conf = det.conf;
conf(result.isloc) = -Inf;
result.ignoreloc = averagePrecisionNormalized(conf, det.label, npos, normalizedCount);

% Code below reassigns poor localizations to correct detections
det2.conf(det2.isduplicate) = -Inf;
result.fixloc = averagePrecisionNormalized(det2.conf, det2.label, npos, normalizedCount);

conf = det.conf;
conf(~result.isloc & (det.label==-1)) = -Inf;
result.onlyloc = averagePrecisionNormalized(conf, det.label, npos, normalizedCount);

% Ignore similar objects
confuse_sim = false(det.N, 1);
if ~isempty(similar_ind)
  for o2 = 1:numel(similar_ind)
    sim_name = dataset_params.objnames_all{similar_ind(o2)};
    det2_s(o2) = matchDetectionsWithGroundTruth(dataset, dataset_params, ...
      sim_name, ann, det, 'weak');
  end
  conf = det.conf;
  confuse_sim = (any(cat(2, det2_s.label)>=0, 2)) & (det.label==-1) & (~result.isloc);  
  conf(confuse_sim) = -Inf;
  result.ignoresimilar = averagePrecisionNormalized(conf, det.label, npos, normalizedCount);
  conf = det.conf;
  conf(~confuse_sim & (det.label==-1)) = -Inf;
  result.onlysimilar = averagePrecisionNormalized(conf, det.label, npos, normalizedCount);
end
result.issim = confuse_sim;

% Ignore background detections (all other false positives)
bg_error = (~result.isloc) & (det.label==-1) & (~result.issim);
result.isbg = bg_error;
conf = det.conf;
conf(bg_error) = -Inf;
result.ignorebg = averagePrecisionNormalized(conf, det.label, npos, normalizedCount);
conf = det.conf;
conf(~bg_error & (det.label==-1)) = -Inf;
result.onlybg = averagePrecisionNormalized(conf, det.label, npos, normalizedCount);

% Record false positives with other (non-similar) objects
isother = zeros(size(result.isbg));
for k = setdiff(1:numel(dataset_params.objnames_all), [similar_ind objind])  
  other_name = dataset_params.objnames_all{k};
  detk = matchDetectionsWithGroundTruth(dataset, dataset_params, other_name, ann, det, 'weak');      
  isother = isother | (~result.iscorrect & ~result.issim & ~result.isloc & detk.label>=0);
end
result.isother = isother;
result.isbg_notobj = result.isbg & ~result.isother;

% Ignore localization error and similar objects
conf = det2.conf;
conf(confuse_sim) = -Inf;
result.ignorelocsim = averagePrecisionNormalized(conf, det2.label, npos, normalizedCount);

% Get counts of types of false positives for topN detections
nclasses = numel(dataset_params.objnames_all);
topN = [-100 sum(~[gt.isdiff])];  % topN: -X means top X false positives; +X means top X of all detections
result.confuse_count.object = zeros(nclasses, numel(topN));
result.confuse_count.correct = zeros(1, numel(topN));
result.confuse_count.loc = zeros(1, numel(topN));
result.confuse_count.bg = zeros(1, numel(topN));
for n = 1:numel(topN)
  if topN(n)<0
    topN(n) = find(cumsum(det.label==-1)==-topN(n), 1, 'first');
  end
  detn.bbox = det.bbox(1:topN(n), :);
  detn.conf = det.conf(1:topN(n));
  detn.rnum = det.rnum(1:topN(n));  
  det2 = matchDetectionsWithGroundTruth(dataset, dataset_params, objname, ann, detn, 'strong');  
  iscorrect = det2.label>=0;
  det2 = matchDetectionsWithGroundTruth(dataset, dataset_params, objname, ann, detn, 'weak');  
  isloc = (det2.label>=0) & ~iscorrect;    
  isobj = false(topN(n), nclasses);
  objov = zeros(topN(n), nclasses);
  for k = setdiff(1:nclasses, objind)
    name = dataset_params.objnames_all{k};
    det2 = matchDetectionsWithGroundTruth(dataset, dataset_params, name, ann, detn, 'weak');  
    isobj(:, k) = (det2.label>=0) & ~isloc & ~iscorrect;
    objov(isobj(:, k), k) = det2.ov(isobj(:, k));
  end
  [mv, mi] = max(objov, [], 2);
  mi(mv==0) = 0;  
  isobj = false(topN(n), 1);
  isobj(mi>0) = true;
  isbg = ~iscorrect & ~isloc & ~isobj;
  for k = setdiff(1:nclasses, objind)
    result.confuse_count.object(k, n) = sum(mi==k);
  end  
  result.confuse_count.total(n) = topN(n);
  result.confuse_count.correct(n) = sum(iscorrect);
  result.confuse_count.loc(n) = sum(isloc);
  result.confuse_count.bg(n) = sum(isbg);  
  result.confuse_count.similarobj(n) = sum(result.confuse_count.object(similar_ind, n));
  result.confuse_count.otherobj(n) = topN(n)-sum(iscorrect)-sum(isloc)-sum(isbg)-result.confuse_count.similarobj(n);
end 
    
        
    
