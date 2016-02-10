function displayAverageSensitivityImpactPlot(results_all, titlename)

close all

fs = 12;

fnames = {'occ', 'truncated', 'area', 'aspect', 'side', 'part'};
xticklab = {'occ', 'trn', 'size', 'asp', 'view', 'part'};

valid = true(size(fnames));
for f = 1:numel(fnames)
  if ~isfield(results_all(1), fnames{f}) 
      valid(f) = false;
      continue;
  end    
%   for o = 1:numel(results_all)
%     if isfield(results_all(o).(fnames{f}), 'apn') && ...
%         any(isnan([results_all(o).(fnames{f}).apn]))
%       valid(f) = false; % at least one category is missing, so ignore
%       continue;
%     end
%   end    
  for o = 1:numel(results_all)
    maxval(o,f) = getMaxVal([results_all(o).(fnames{f})], 'apn');
    minval(o,f) = getMinVal([results_all(o).(fnames{f})], 'apn');
  end    
end
maxval = maxval(:, valid); minval = minval(:, valid); 
fnames = fnames(valid); xticklab = xticklab(valid);

maxval = mean(maxval, 1);
minval = mean(minval, 1);
tmp = [results_all.all];
avgval = mean([tmp.apn]);

figure(1), hold off;
plot([1 numel(fnames)], [avgval avgval], 'k--', 'linewidth', 1);
hold on;
errorbar(1:numel(fnames), avgval*ones(1, numel(fnames)), avgval-minval, maxval-avgval, 'r+', 'linewidth', 1);    
for x = 1:numel(fnames)  
  text(x+0.12, minval(x), sprintf('%0.3f', minval(x)), 'fontsize', fs-2);  
  text(x+0.12, maxval(x), sprintf('%0.3f', maxval(x)), 'fontsize', fs-2);    
end
text(0.1, avgval, sprintf('%0.3f', avgval), 'fontsize', fs-2);

ymax = min(round((max(maxval)+0.15)*10)/10,1);
axis([0 numel(fnames)+1 0 ymax]);

set(gca, 'xtick', 1:numel(fnames)); 
set(gca, 'xticklabel', xticklab);
set(gca, 'ygrid', 'on')
set(gca, 'xgrid', 'on')
set(gca, 'fontsize', fs);
set(gca, 'ticklength', [0.001 0.001]);
title([titlename ': Sensitivity and Impact'])




%% Gets the maximum value of a particular variable name for any field in the structure
function maxy = getMaxVal(s, fname, maxy)
if ~exist('maxy', 'var') || isempty(maxy)
  maxy = -Inf;
end
if numel(s)>1
  for k = 1:numel(s)
    maxy = max(maxy, getMaxVal(s(k), fname, maxy));
  end
  return;
end
names = fieldnames(s);
for k = 1:numel(names)
  if ~isstruct(s.(names{k})) && ~strcmp(names{k}, fname)
    continue;
  end
  for j = 1:numel(s.(names{k}))    
    if strcmp(names{k}, fname)
      if s.npos>=5  % special case
        maxy = max(maxy, s.(fname)(j));
      end
    else
      maxy = max(maxy, getMaxVal(s.(names{k})(j), fname, maxy));
    end
  end
end
      

function miny = getMinVal(s, fname, miny)
if ~exist('miny', 'var') || isempty(miny)
  miny = Inf;
end
if numel(s)>1
  for k = 1:numel(s)
    miny = min(miny, getMinVal(s(k), fname, miny));
  end
  return;
end
names = fieldnames(s);
for k = 1:numel(names)
  if ~isstruct(s.(names{k})) && ~strcmp(names{k}, fname)
    continue;
  end
  for j = 1:numel(s.(names{k}))    
    if strcmp(names{k}, fname)
      if s.npos>=5 % special case
        miny = min(miny, s.(fname)(j));
      end
    else
      miny = min(miny, getMinVal(s.(names{k})(j), fname, miny));
    end
  end
end


%% Removes vowels from a string
function str = removeVowels(str)
for v = 'aeiou'
  str(str==v) = [];
end

