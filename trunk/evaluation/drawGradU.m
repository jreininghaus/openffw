function p = drawGradU(p,lvl)
% draw the gradient of the solution u

% Copyright 2007 Jan Reininghaus, David Guenther, 
%                Andreas Byfut, Joscha Gedicke
%
% This file is part of FFW.
%
% FFW is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 3 of the License, or
% (at your option) any later version.
%
% FFW is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.


clf

pdeSolver = p.params.pdeSolver;
customDrawU = str2func([pdeSolver,'drawGradU']);

p = customDrawU(p,lvl);
