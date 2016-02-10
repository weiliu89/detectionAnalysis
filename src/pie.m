function hh = pie(varargin)
%PIE    Pie chart.
%   PIE(X) draws a pie plot of the data in the vector X.  The values in X
%   are normalized via X/SUM(X) to determine the area of each slice of pie.
%   If SUM(X) <= 1.0, the values in X directly specify the area of the pie
%   slices.  Only a partial pie will be drawn if SUM(X) < 1.
%
%   PIE(X,EXPLODE) is used to specify slices that should be pulled out from
%   the pie.  The vector EXPLODE must be the same size as X. The slices
%   where EXPLODE is non-zero will be pulled out.
%
%   PIE(...,LABELS) is used to label each pie slice with cell array LABELS.
%   LABELS must be the same size as X and can only contain strings.
%
%   PIE(AX,...) plots into AX instead of GCA.
%
%   H = PIE(...) returns a vector containing patch and text handles.
%
%   Example
%      pie([2 4 3 5],{'North','South','East','West'})
%
%   See also PIE3.

%   Clay M. Thompson 3-3-94
%   Copyright 1984-2005 The MathWorks, Inc.
%   $Revision: 1.16.4.8 $  $Date: 2005/10/28 15:54:38 $

% Parse possible Axes input
[cax,args,nargs] = axescheck(varargin{:});
error(nargchk(1,3,nargs,'struct'));

x = args{1}(:); % Make sure it is a vector
args = args(2:end);

nonpositive = (x <= 0);
if all(nonpositive)
    error('MATLAB:pie:NoPositiveData',...
        'Must have positive data in the pie chart.');
end
if any(nonpositive)
  warning('MATLAB:pie:NonPositiveData',...
          'Ignoring non-positive data in pie chart.');
  x(nonpositive) = [];
end
xsum = sum(x);
if xsum > 1+sqrt(eps), x = x/xsum; end

% Look for labels
if nargs>1 && iscell(args{end})
  txtlabels = args{end};
  if any(nonpositive)
    txtlabels(nonpositive) = [];
  end
  args(end) = [];
else
  for i=1:length(x)
    if x(i)<.01,
      txtlabels{i} = '< 1%';
    else
      txtlabels{i} = sprintf('%d%%',round(x(i)*100));
    end
  end
end

% Look for explode
if isempty(args),
   explode = zeros(size(x)); 
else
   explode = args{1};
   if any(nonpositive)
     explode(nonpositive) = [];
   end
end

explode = explode(:); % Make sure it is a vector

if length(txtlabels)~=0 && length(x)~=length(txtlabels),
  error(id('StringLengthMismatch'),'Cell array of strings must be the same length as X.');
end

if length(x) ~= length(explode),
  error(id('ExploreLengthMismatch'),'X and EXPLODE must be the same length.');
end

cax = newplot(cax);
next = lower(get(cax,'NextPlot'));
hold_state = ishold(cax);

theta0 = pi/2;
maxpts = 100;
inside = 1;

h = [];
for i=1:length(x)
  n = max(1,ceil(maxpts*x(i)));
  r = [0;ones(n+1,1);0];
  theta = theta0 + [0;x(i)*(0:n)'/n;0]*2*pi;
  if inside,
    [xtext,ytext] = pol2cart(theta0 + x(i)*pi,.5);
  else
    [xtext,ytext] = pol2cart(theta0 + x(i)*pi,1.2);
  end
  [xx,yy] = pol2cart(theta,r);
  if explode(i),
    [xexplode,yexplode] = pol2cart(theta0 + x(i)*pi,.1);
    xtext = xtext + xexplode;
    ytext = ytext + yexplode;
    xx = xx + xexplode;
    yy = yy + yexplode;
  end
  theta0 = max(theta);
  h = [h,patch('XData',xx,'YData',yy,'CData',i*ones(size(xx)), ...
               'FaceColor','Flat','parent',cax), ...
         text(xtext,ytext,txtlabels{i},...
              'HorizontalAlignment','center','parent',cax, 'Fontsize', 10, 'Fontweight', 'bold')];
end

if ~hold_state, 
  view(cax,2); set(cax,'NextPlot',next); 
  axis(cax,'equal','off',[-1.2 1.2 -1.2 1.2])
end

if nargout>0, hh = h; end

% Register handles with m-code generator
% if ~isempty(h)
%   mcoderegister('Handles',h,'Target',h(1),'Name','pie');
% end

function str=id(str)
str = ['MATLAB:pie:' str];
