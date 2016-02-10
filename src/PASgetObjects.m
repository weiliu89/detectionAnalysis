function [ids, bbox, isdiff, istrunc, isocc, details, rnum, onum, classnum] = ...
    PASgetObjects(rec, objname, usediff)
% [ids, bbox, isdiff, istrunc, isocc, details, rnum, objnum, classnum] = getObjectBBoxes(rec, objname, usediff)

if ~exist('usediff', 'var') % whether to include difficult variables
  usediff = 1;
end

n = 0;

maxdata = 100000;
bbox = zeros(maxdata, 4);
ids = cell(maxdata, 1);
istrunc = false(maxdata, 1);
isdiff = false(maxdata, 1);
isocc = false(maxdata, 1);
rnum = zeros(maxdata, 1);
onum = zeros(maxdata, 1);
classnum = zeros(maxdata, 1);
details = cell(maxdata, 1);

VOCinit;
for k = 1:numel(rec)
  id = strtok(rec(k).filename, '.');
  for k2 = 1:numel(rec(k).objects)    
    if (isempty(objname) || strcmp(rec(k).objects(k2).class, objname)) && ...
        (usediff || ~rec(k).objects(k2).difficult)
      n = n+1;      
      bbox(n, :) = rec(k).objects(k2).bbox;
       % extend box by 10%  
      bbox(n, :) = round(bbox(n, :)); % + [-0.1*bw -0.1*bh 0.1*bw 0.1*bh]);
      ids{n} = id;      
      istrunc(n) = logical(rec(k).objects(k2).truncated);
      isdiff(n) = logical(rec(k).objects(k2).difficult);
      isocc(n) = logical(rec(k).objects(k2).occluded);      
      details{n} = rec(k).objects(k2).details;
      rnum(n) = k;
      onum(n) = k2;
      classnum(n) = find(strcmp(rec(k).objects(k2).class, VOCopts.classes));
    end
  end
end
    
bbox = bbox(1:n, :);
ids = ids(1:n);
istrunc = istrunc(1:n);
isdiff = isdiff(1:n);
isocc = isocc(1:n);
details = details(1:n);
rnum = rnum(1:n);
onum = onum(1:n);
classnum = classnum(1:n);
