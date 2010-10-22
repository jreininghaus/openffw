function p = ODP1DWRgetFuncValDP(p)
%author: David Guenther, Lena Noack

%% INPUT
% load enumerated data
n4e = p.level(end).geom.n4e;
dofU4e = p.level(end).enum.dofU4e;
f4e = p.level(end).f4e;
lvl = size(p.level,2);
freeNodes = p.level(end).enum.freeNodes;
degree = loadField('p.params','nonLinearExactIntegrateDegree',p,5);

%% compute dual function value R(x)
ST = integrate(n4e,lvl,degree,@integrand,p);
Term_qh = integrate(n4e,lvl,degree,@integrandTerm2,p);

I = dofU4e;
S = accumarray(I(:),ST(:));
rhs = accumarray(I(:),Term_qh(:));

funcVal = rhs - S;

%% OUTPUT 
p.level(end).funcVal = funcVal(freeNodes);

%% supply integrand: D2W(\nabla u_h)*\nabla w_h*\nabla z_h
function val = integrand(x,y,curElem,lvl,p)
% W''(|X|)/|X|^2*(X*Y)(X*Z) + W'(|X|)/|X|^3*( Y*Z*|X|^2 - (X*Y)(X*Z) )

DW = p.problem.nonLinearExactDer;
D2W = p.problem.nonLinearExactSecDer;
grad_h = p.statics.grad_h;
DWRgrad_h = p.statics.DWRgrad_h;
stressBasis = p.statics.stressBasis;

evalGrad = grad_h(x,y,curElem,lvl,p);
evalDWRGrad = DWRgrad_h(x,y,curElem,lvl,p);
evalBasis = stressBasis(x,y,curElem,lvl,p);

absGrad = ( evalGrad(:,1).^2 + evalGrad(:,2).^2 ).^(1/2);
evalDW = DW(absGrad,curElem,lvl,p);
evalD2W = D2W(absGrad,curElem,lvl,p);

evalGrad = reshape(evalGrad',[1 2 length(x)]);
evalDWRGrad = reshape(evalDWRGrad',[1 2 length(x)]);
YZ = matMul(evalDWRGrad,permute(evalBasis,[2 1 3]));
XY = matMul(evalGrad,permute(evalDWRGrad,[2 1 3]));
XZ = matMul(evalGrad,permute(evalBasis,[2 1 3]));
XYXZ = matMul(permute(XY,[2 1 3]),XZ);

if norm(absGrad) > 0
    term1 = matMul(reshape(evalD2W./absGrad.^2,[1 1 length(x)]),XYXZ);
    term2 = -matMul(reshape(evalDW./absGrad.^2,[1 1 length(x)]),XYXZ);
else
    term1 = 0;
    term2 = 0;
end

term3 = matMul(reshape(evalDW,[1 1 length(x)]),YZ); %calculates elementwise matrix product

val = term1 + term2 + term3;





%% supply W*_epsilon(DW(Dv)) (goal function)
function val = integrandTerm(x,y,curElem,lvl,p)

stressBasis = p.statics.stressBasis; 
evalBasis = stressBasis(x,y,curElem,lvl,p);
f4e = p.level(end).DWRf4e; %0 or 1 depending on x
evalF4e = f4e(curElem);

DW = p.problem.nonLinearExactDer;
absBasis = ( evalBasis(:,1,:).^2 + evalBasis(:,2,:).^2 ).^(1/2);
for i=1:3
  evalDW(i,1,:) = DW(absBasis(i,:,:),curElem,lvl,p);
end
DW_eps = p.problem.conjNonLinearFuncDer;
for i=1:3
    evalDW_eps(i,1,:) = reshape(reshape(DW_eps(evalDW(i,:,:),curElem,lvl,p),[1 length(x)])./reshape(evalDW(i,:,:),[1 length(x)]),[1 1 length(x)]);
end
val = evalF4e*evalDW_eps;



%% supply Dv_h (goal function)
function val = integrandTerm2(x,y,curElem,lvl,p)

stressBasis = p.statics.stressBasis; 
evalBasis = stressBasis(x,y,curElem,lvl,p);
f4e = p.level(end).DWRf4e; %0 or 1 depending on x
evalF4e = f4e(curElem);

oneVec = ones(2,length(x));
oneVec = reshape(oneVec,[1 2 length(x)]);

val = matMul(oneVec,permute(evalBasis,[2 1 3]));
val = evalF4e*val;