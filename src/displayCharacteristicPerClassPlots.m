function displayCharacteristicPerClassPlots(results_all, titlename)

close all

fs = 8;

for o = 1:numel(results_all)
%   makeMultiCharacteristicPlot(o, results_all(o), ...
%     {'occ', 'truncated', 'area', 'aspect', 'p' ,'v'}, ...
%     [titlename ': ' results_all(o).name], ...
%     {'Occlusion', 'Truncation', 'Area', 'Aspect', 'Parts', 'Viewpoint'}, ...
%     
%     
  titlestr = [titlename ': ' results_all(o).name];  
  result = results_all(o);
  
  maxy = getMaxVal(result, 'apn');
  yrange = [0 min(round((maxy+0.15)*10)/10,1)];
  
  %maxy = max([result.occ.apn result.truncated.apn result.area.apn result.aspect.apn]);
  
  figure(o), hold off
  drawline = true;
  xrange = (1:4);
  makeMultiCharacteristicPlot(o, result, 'occ', 'Occlusn.', titlestr, xrange, yrange, {'N', 'L', 'M', 'H'}, drawline);
  hold on;  
  xrange = xrange(end)+1+(1:2);
  makeMultiCharacteristicPlot(o, result, 'truncated', 'Trnc.', titlestr, xrange, yrange, {'N', 'T'}, drawline);    
  xrange = xrange(end)+1+(1:5);
  makeMultiCharacteristicPlot(o, result, 'area', 'BBox Area', titlestr, xrange, yrange, {'XS', 'S', 'M', 'L', 'XL'}, drawline);
  xrange = xrange(end)+1+(1:5);
  makeMultiCharacteristicPlot(o, result, 'aspect', 'Aspect Rat.', titlestr, xrange, yrange, {'XT', 'T', 'M', 'W', 'XW'}, drawline);

  
  % visible side
  if isfield(result, 'side')
    pnames = fieldnames(result.side);
    for p = 1:numel(pnames)   
      result.s((p-1)*2+(1:2)) = result.side.(pnames{p});  
      if p==1
        xrange = [xrange(end)+1+(1:2)];
      else
        xrange = [xrange xrange(end)+0.5+(1:2)];
      end
    end   
    drawline = false;
    tickstr = repmat({' '}, 1, 2*numel(pnames));  
    makeMultiCharacteristicPlot(o, result, 's', 'Sides Visible', titlestr, xrange, yrange, tickstr, drawline);  
    for p = 1:numel(pnames)
      name = pnames{p}; if numel(name)>5, name = removeVowels(name); end;
      text(xrange((p-1)*2+1), -0.071*yrange(2), sprintf('%s\n0/1', name), 'fontsize', fs);
    end    
  end
  
  % parts
  if isfield(result, 'part')
    pnames = fieldnames(result.part);
    for p = 1:numel(pnames)   
      result.p((p-1)*2+(1:2)) = result.part.(pnames{p});  
      if p==1
        xrange = [xrange(end)+1+(1:2)];
      else
        xrange = [xrange xrange(end)+0.5+(1:2)];
      end
    end   
    drawline = false;
    tickstr = repmat({' '}, 1, 2*numel(pnames));  
    makeMultiCharacteristicPlot(o, result, 'p', 'Parts Visible', titlestr, xrange, yrange, tickstr, drawline);  
    for p = 1:numel(pnames)
      name = pnames{p}; if numel(name)>5, name = removeVowels(name); end;
      text(xrange((p-1)*2+1), -0.071*yrange(2), sprintf('%s\n0/1', name), 'fontsize', fs);
    end
  end  

  
end
  

return;

% Visible parts
f=f+1;
tickstr = {};
np=0;

for o = 1:numel(results_all)
  pnames = fieldnames(results_all(o).part);
  for p = 1:numel(pnames)
    np=np+1;
    results_all(o).tmp((p-1)*2+(1:2)) = results_all(o).part.(pnames{p});    
    %tickstr(end+1) = {sprintf('%s\non/off', pnames{p})};
  end  
end
drawline = false;
makeMultiCategoryPlot(f, results_all, 'tmp', [titlename ': Parts Visible'], 1, tickstr, drawline);
n=0;
for o = 1:numel(results_all)
  pnames = fieldnames(results_all(o).part);
  n=n+1;
  for p = 1:numel(pnames)
    name = pnames{p}; if numel(name)>5, name = removeVowels(name); end;
    text(n+1, -0.05, sprintf('%s\n0/1', name), 'fontsize', fs);
    n = n+2;
  end
end
results_all = rmfield(results_all, 'tmp');

% Visible sides
f=f+1;
tickstr = {};
np=0;
for o = 1:numel(results_all)
  pnames = fieldnames(results_all(o).side);
  for p = 1:numel(pnames)
    np=np+1;
    results_all(o).tmp((p-1)*2+(1:2)) = results_all(o).side.(pnames{p});    
    %tickstr(end+1) = {sprintf('%s\non/off', pnames{p})};
  end  
end
drawline = false;
makeMultiCategoryPlot(f, results_all, 'tmp', [titlename ': Sides Visible'], 1, tickstr, drawline);
n=0;
for o = 1:numel(results_all)
  pnames = fieldnames(results_all(o).side);
  n=n+1;
  for p = 1:numel(pnames)
    name = pnames{p}; if numel(name)>5, name = removeVowels(name); end;
    text(n+1, -0.05, sprintf('%s\n0/1', name), 'fontsize', fs);
    n = n+2;
  end
end
results_all = rmfield(results_all, 'tmp');



%% Extends current plot with given characteristic performance
function makeMultiCharacteristicPlot(f, result, rname, subtitle, title_str, xticks, yrange, xticklab, drawline)

fs = 10;
figure(f);


plotapnbars(result.(rname), xticks, drawline);

curraxis = axis;
maxy = max(curraxis(4), round(max(([result.(rname).apn]+0.15))*10)/10);
h=plot(xticks([1 end]), [1 1]*result.all.apn, 'k--', 'linewidth', 1);  
  
maxy = min(maxy, 1);
axis([0 xticks(end)+1 yrange]); % set to max of current maxy and new maxy
text(xticks(1), yrange(2)-0.05, subtitle, 'fontsize', fs);

title(title_str, 'fontsize', fs);

if xticks(1)>1
  xticks = cat(2, get(gca, 'xtick'), xticks);
  xticklab = cat(1, get(gca, 'xticklabel'), xticklab(:));
end

set(gca, 'xtick', xticks); 
%set(gca, 'ytick', 0:0.1:maxy); 
set(gca, 'xticklabel', xticklab);
set(gca, 'ygrid', 'on')
set(gca, 'xgrid', 'on')
set(gca, 'fontsize', fs);
set(gca, 'ticklength', [0.001 0.001]);


%% Gets the maximum value of a particular variable name for any field in the structure
function maxy = getMaxVal(s, fname, maxy)
if ~exist('maxy', 'var') || isempty(maxy)
  maxy = -Inf;
end
names = fieldnames(s);
for k = 1:numel(names)
  if ~isstruct(s.(names{k})) && ~strcmp(names{k}, fname)
    continue;
  end
  for j = 1:numel(s.(names{k}))    
    if strcmp(names{k}, fname)
      maxy = max(maxy, s.(fname)(j));
    else
      maxy = max(maxy, getMaxVal(s.(names{k})(j), fname, maxy));
    end
  end
end
      

%% Plots error bards for apn
function plotapnbars(resall, x, drawline)
for k = 1:numel(resall)
  res =resall(k);
  if isnan(res.apn), res.apn = 0; end
  if ~isnan(res.apn_stderr)
    errorbar(x(k), res.apn, res.apn_stderr, 'r', 'linewidth', 1);
  end
  hold on;
  plot(x(k), res.apn, '+', 'linewidth', 1, 'markersize', 5);  
  text(x(k)+0.12, res.apn, sprintf('%0.2f', res.apn), 'fontsize', 8);  
end
if drawline
  plot(x, [resall.apn], 'b-', 'linewidth', 1);
else % draw every other
  for i=1:2:numel(x)
    plot(x([i i+1]), [resall([i i+1]).apn], 'b-', 'linewidth', 1);
  end
end
%axis([0 x(end+1) numel(resall)+1 0 ceil(max([resall.apn]+[resall.apn_stderr]+0.1)*10)/10])


%% Removes vowels from a string
function str = removeVowels(str)
for v = 'aeiou'
  str(str==v) = [];
end

