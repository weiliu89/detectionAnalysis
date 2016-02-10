function writeMissedObjectCharacteristics(result, detname, fn)

fid = fopen(fn, 'w');
fprintf(fid, sprintf('Characteristics of missed objects: %s\n', detname));
fprintf(fid, sprintf('%s\n', date));

% per object
for o = 1:numel(result)
  fprintf(fid,'\n');
  fprintf(fid, '%s\n', upper(result(o).name));
  all =result(o).counts.all;
  missed =result(o).counts.missed;
  fnames = fieldnames(all);    
  for p = 1:numel(fnames)
    n = fnames{p};
    mi = mutualinfo_ratio(all.(n)(:), missed.(n)(:));
    for v = 1:numel(missed.(n))
      fprintf(fid, '%s %d:\t missed = %d (%0.3f); \t total = %d (%0.3f); \t %% missed = %0.3f\n', n, v, missed.(n)(v), ...
        missed.(n)(v) ./ missed.total, all.(n)(v), all.(n)(v)./all.total, missed.(n)(v)./all.(n)(v));  
    end
    fprintf(fid, '%s\tmutual information ratio=%0.3f\n', n, mi);
  end
end
fclose(fid);
  
  
function mi = mutualinfo_ratio(all_counts, missed_counts)
% sum_(x,y) P(x,y) log [P(x,y)/(P(x)P(y))]
%
% sum_(i in ismissed, j in label) log P(ismissed=i, label=j) /(P(ismissed=i)P(label=j))

found_counts = all_counts - missed_counts;

Pxy = [found_counts(:) missed_counts(:)] ./ sum(all_counts(:));
Px = sum(Pxy, 1);
Py = sum(Pxy, 2);
mi = 0;
for i = 1:size(Pxy, 1)
  for j = 1:size(Pxy, 2)
    if Pxy(i, j) > 0
      mi = mi + Pxy(i, j)*log(Pxy(i, j)./(Px(j).*Py(i)));
    end
  end
end

p1 = sum(found_counts) / sum(all_counts);
p0 = 1-p1;
entropy = -sum(p0).*log(p0) - sum(p1).*log(p1);
mi = mi / entropy;
