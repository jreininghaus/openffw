function p = TWP1estimateH2(p)

% Copyright 2008 Joscha Gedicke, Lena Noack
%
% This file is part of FFW.
%
% FFW is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 3 of the License, or
% (at your option) any later version
%
% FFW is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.

%% INPUT
length4ed = p.level(end).enum.length4ed;
n4e = p.level(end).geom.n4e;
n4ed = p.level(end).enum.n4ed;
ed4e = p.level(end).enum.ed4e;
curLvl = length(p.level);
degree = 19;
nrNodes = p.level(end).nrNodes;


%% ESTIMATE
h_T = max(length4ed(ed4e),[],2);

nu_T = integrate(n4e,curLvl,2*degree,@Residuum,p);
nu_E = integrate(n4ed,curLvl,degree,@NormalJumpSigma,p);
primalResiduum = sqrt( nu_T + 1/4*1./h_T.*sum(nu_E(ed4e),2) );

% dual jumps
dnu_E = integrate(n4ed,curLvl,degree,@NormalJumpGradZ,p);
dualWeight = sqrt(h_T.^3.*sum(dnu_E(ed4e),2));

nu = primalResiduum.*dualWeight;


%% OUTPUT
p.level(end).etaT = nu;
p.level(end).estimatedError = sum(nu);

function val = Residuum(x,y,curElem,curLvl,p)
f = p.problem.f;
curf     = f(x,y,curElem,curLvl,p);

residuum = - curf(:);
val(1,:,:) = (residuum.^2)';


function val = NormalJumpSigma(x,y,curEdge,lvl,p)
%sigma_h = p.statics.grad_h;
sigma_h = p.statics.sigma_h;
e4ed = p.level(lvl).enum.e4ed;
normals4ed = p.level(lvl).enum.normals4ed;

elems = e4ed(curEdge,:);
normal = normals4ed(curEdge,:);

evalSigma1 = sigma_h(x,y,elems(1),lvl,p)*normal';

if elems(2) ~= 0
    % E is an interior edge
    evalSigma2 = sigma_h(x,y,elems(2),lvl,p)*normal';
else
    % E is a Dirichlet Edge
    evalSigma2 = evalSigma1;
end

val = zeros(1,1,length(x));
val(1,1,:) = sum((evalSigma1 - evalSigma2).^2,2);


function val = NormalJumpGradZ(x,y,curEdge,lvl,p)
%grad_h = p.statics.DWRGradU_h;
grad_h = p.statics.DWRgrad_h;
e4ed = p.level(lvl).enum.e4ed;
normals4ed = p.level(lvl).enum.normals4ed;

elems = e4ed(curEdge,:);
normal = normals4ed(curEdge,:);

evalG1 = grad_h(x,y,elems(1),lvl,p)*normal';

if elems(2) ~= 0
    % E is an interior edge
    evalG2 = grad_h(x,y,elems(2),lvl,p)*normal';
else
    % E is a Dirichlet Edge
    evalG2 = evalG1;
end

val = zeros(1,1,length(x));
val(1,1,:) = sum((evalG1 - evalG2).^2,2);