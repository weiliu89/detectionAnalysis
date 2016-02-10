function displayFalsePositiveImpactPlot(resultfp, titlename_bar, titlename_pie)

close all

%% Impact Bar Chart

fs = 16;
xticklab = {'L', 'S', 'B', 'LS', 'LB', 'SB'};

figure(1), hold off;

tmp = [resultfp.all];
AP = mean([tmp.ap]);

R = 0; 
for k = 1:numel(resultfp)
  R = R+tmp(k).r(end)/numel(resultfp);
end

tmp = [resultfp.ignoreloc];
L = mean([tmp.ap]);
tmp = [resultfp.ignoresimilar];
S = mean([tmp.ap]);
tmp = [resultfp.ignorebg];
B = mean([tmp.ap]);
tmp = [resultfp.fixloc];
Lfix = mean([tmp.ap]);
tmp = [resultfp.onlyloc];
SB = mean([tmp.ap]);
tmp = [resultfp.onlysimilar];
LB = mean([tmp.ap]);
tmp = [resultfp.onlybg];
LS = mean([tmp.ap]);


%plot([1 3], [AP AP], 'k--', 'linewidth', 1);

hold on

barh(3, max(Lfix-AP,0), 'FaceColor', [79 129 189]/255);
barh(3, max(L-AP,0), 'FaceColor', [79 129 189]/255*0.8);
barh(2, max(S-AP,0), 'FaceColor', [192 80 77]/255);
barh(1, max(B-AP,0), 'FaceColor', [128 100 162]/255);

xlim = [0 ceil((max([Lfix L S B]-AP)+0.005)*20)/20];
set(gca, 'xlim', xlim);
%set(gca, 'xtick', 0:0.05:xlim(2));
set(gca, 'xminortick', 'on');
set(gca, 'ticklength', get(gca, 'ticklength')*4);

set(gca, 'ytick', 1:3)
set(gca, 'yticklabel', {'B', 'S', 'L'});
set(gca, 'fontsize', fs);

title(titlename_bar)


%% FP Count Pie Chart

figure(2), hold off;


tmp =[resultfp.confuse_count];
total = sum(cat(1, tmp.total));
N = numel(total);
total = total(N);

correct = sum(cat(1, tmp.correct));
correct = correct(N)/total;

sim = sum(cat(1, tmp.similarobj));
sim = sim(N)/total;

oth = sum(cat(1, tmp.otherobj));
oth = oth(N)/total;

loc = sum(cat(1, tmp.loc));
loc = loc(N)/total;

bg = sum(cat(1, tmp.bg));
bg = bg(N)/total;


pie([correct loc sim oth bg], ...
  {['Cor: ' num2str(round(correct*100)) '%'], ...
   ['Loc: ' num2str(round(loc*100)) '%'], ...
   ['Sim: ' num2str(round(sim*100)) '%'], ...
   ['Oth: ' num2str(round(oth*100)) '%'], ...   
   ['BG: ' num2str(round(bg*100)) '%']}); %, 'fontsize', fs+16, 'fontweight', 'bold');
title(titlename_pie, 'fontsize', 12, 'fontweight', 'bold')


%  barh(3, max(Lfix-AP,0), 'FaceColor', [79 129 189]/255);
% barh(3, max(L-AP,0), 'FaceColor', [79 129 189]/255*0.8);
% barh(2, max(S-AP,0), 'FaceColor', [192 80 77]/255);
% barh(1, max(B-AP,0), 'FaceColor', [128 100 162]/255);
 
colormap([1 1 1 ; [79 129 189]/255 ; [192 80 77]/255 ; [77 192 80]/255*1.2 ; [128 100 162]/255]);
 
% 
% tmp = 
% L = mean([tmp.ap]);
% tmp = [resultfp.ignoresimilar];
% S = mean([tmp.ap]);
% tmp = [resultfp.ignorebg];
% B = mean([tmp.ap]);
% tmp = [resultfp.fixloc];
% Lfix = mean([tmp.ap]);
% tmp = [resultfp.onlyloc];
% SB = mean([tmp.ap]);
% tmp = [resultfp.onlysimilar];
% LB = mean([tmp.ap]);
% tmp = [resultfp.onlybg];
% LS = mean([tmp.ap]);
% 
% for k = numel(resultfp(1).confuse_count.total) %only writing out last case
%   for o = 1:numel(result)  
%     count = resultfp(o).confuse_count;  
%     name = repmat(' ', [1 15]); name(1:numel(result(o).name)) = upper(result(o).name);  
%     total = count.total(k) - count.correct(k);
%     nfp(o, 1:5) = [total [count.loc(k) count.similarobj(k) count.otherobj(k) count.bg(k)]./total];
%     fprintf(fid, ['%s\t%d\t' repmat('%0.3f\t', [1 4]) '\n'], name, nfp(o, 1), nfp(o, 2:end));    
%   end
%   fprintf(fid, ['%s        \t%d\t' repmat('%0.3f\t', [1 4]) '\n'], 'animals', round(mean(nfp(animals, 1))), mean(nfp(animals, 2:end)));  
%   fprintf(fid, ['%s       \t%d\t' repmat('%0.3f\t', [1 4]) '\n'], 'vehicles', round(mean(nfp(vehicles, 1))), mean(nfp(vehicles, 2:end)));  
%   fprintf(fid, ['%s      \t%d\t' repmat('%0.3f\t', [1 4]) '\n'], 'furniture', round(mean(nfp(furniture, 1))), mean(nfp(furniture, 2:end)));
%   
%   fprintf(fid, [repmat(' ', [1 15]) repmat('%s\t', [1 numel(allnames)]) '\n'], allnames{:});
%   for o = 1:numel(result)
%     count = result(o).confuse_count;  
%     total = count.total(k) - count.correct(k);
%     name = repmat(' ', [1 15]); name(1:numel(result(o).name)) = upper(result(o).name);  
%     fprintf(fid, ['%s\t' repmat('%0.3f\t', [1 numel(count.object(:, k))]) '\n'], name, count.object(:, k)'./total);
%   end
%       
% end


% bar(1, L, 'r');
% bar(2, S, 'g');
% bar(3, B, 'b');
% 
% bar(4, LS, 'y');
% bar(5, LB, 'm');
% bar(6, SB, 'c');

%plot([1 3], [R R], 'k-', 'linewidth', 1);

% axis([0.5 6.5 AP  R]);
% 
% yticklab = {sprintf('%0.2f', AP), sprintf('%0.2f', R)};
% set(gca, 'ytick', sort([AP R]));
% set(gca, 'yticklabel', {yticklab{1}(2:end), yticklab{2}(2:end)});
% set(gca, 'xtick', 1:6); 
% set(gca, 'xticklabel', xticklab);
% set(gca, 'fontsize', fs);
% title(titlename)
