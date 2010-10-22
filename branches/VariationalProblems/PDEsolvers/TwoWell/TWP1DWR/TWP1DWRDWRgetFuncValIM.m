function p = TWP1DWRgetFuncValIM(p)
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
I = dofU4e;

%ST = integrate(n4e,lvl,degree,@integrandJacobi,p);
ST = integrate(n4e,lvl,degree,@integrand,p);
S = accumarray(I(:),ST(:));

F_qh = integrate(n4e,lvl,degree,@integrandFu,p);
rhs = accumarray(I(:),F_qh(:));

funcVal = rhs - S;

%% OUTPUT 
p.level(end).funcVal = funcVal(freeNodes);

%% supply integrand: D2W(\nabla u_h)*\nabla w_h*\nabla z_h + 2 z_h w_h
function val = integrand(x,y,curElem,lvl,p)
F1 = p.problem.F1;
F2 = p.problem.F2;
CONV = p.params.CONV;

if strcmp(CONV,'c')
%% D2W**(F)[G,H] = W''**1(F)(G,H) + W''**2(F)(F,G)(F,H) + W''**3(F)(F2,H)(F2,G)
D2W1 = p.problem.nonLinearRegSecDerA;
D2W2 = p.problem.nonLinearRegSecDerB;
D2W3 = p.problem.nonLinearRegSecDerC;
else
% D2W(F)[G,H] = W''1(F)(G,H) + W''2(F)((F-F1,G)*(F-F2,H) + (F-F1,H)*(F-F2,G))
D2W1 = p.problem.nonLinearExactSecDerA;
D2W2 = p.problem.nonLinearExactSecDerB;
end


grad_h = p.statics.grad_h;
DWRu_h = p.statics.DWRu_h;
DWRgrad_h = p.statics.DWRgrad_h;
stressBasis = p.statics.stressBasis;
basisU = p.statics.basisU;

evalGrad = grad_h(x,y,curElem,lvl,p);
evalDWRu_h = DWRu_h(x,y,curElem,lvl,p);
evalDWRGrad = DWRgrad_h(x,y,curElem,lvl,p);
evalBasis = stressBasis(x,y,curElem,lvl,p);
evalBasisU = basisU(x,y,curElem,lvl,p);

grad1 = evalGrad(:,1);
grad2 = evalGrad(:,2);

evalD2W1 = D2W1(grad1,grad2,curElem,lvl,p);
evalD2W2 = D2W2(grad1,grad2,curElem,lvl,p);
if strcmp(CONV,'c')
evalD2W3 = D2W3(grad1,grad2,curElem,lvl,p);
end

evalGrad = reshape(evalGrad',[1 2 length(x)]);
evalDWRGrad = reshape(evalDWRGrad',[1 2 length(x)]);

GH = matMul(evalBasis,permute(evalDWRGrad,[2 1 3]));
evalGrad1 = reshape([grad1-F1(1) grad2-F1(2)]',[1 2 length(x)]);
evalGrad2 = reshape([grad1-F2(1) grad2-F2(2)]',[1 2 length(x)]);
F2vec = reshape([F2(1)*ones(size(grad1,1),1) F2(2)*ones(size(grad1,1),1)]',[1 2 length(x)]);
F1G = matMul(evalGrad1,permute(evalBasis,[2 1 3]));
F2G = matMul(evalGrad2,permute(evalBasis,[2 1 3]));
F1H = matMul(evalGrad1,permute(evalDWRGrad,[2 1 3]));
F2H = matMul(evalGrad2,permute(evalDWRGrad,[2 1 3]));
FG = matMul(evalGrad,permute(evalBasis,[2 1 3]));
FH = matMul(evalGrad,permute(evalDWRGrad,[2 1 3]));
GF2 = matMul(F2vec,permute(evalBasis,[2 1 3]));
HF2 = matMul(F2vec,permute(evalDWRGrad,[2 1 3]));
F1GF2H = matMul(permute(F1G,[2 1 3]),F2H);
F1HF2G = matMul(permute(F1H,[2 1 3]),F2G);
FGFH = matMul(permute(FG,[2 1 3]),FH);
GF2HF2 = matMul(permute(GF2,[2 1 3]),HF2);

%% D2W**(F)[G,H] = W''**1(F)(G,H) + W''**2(F)(F,G)(F,H) + W''**3(F)(F2,G)(F2,H)
% D2W(F)[G,H] = W''1(F)(G,H) + W''2(F)((F-F1,G)*(F-F2,H) + (F-F1,H)*(F-F2,G))

if strcmp(CONV,'c')
term1 = matMul(reshape(evalD2W1,[1 1 length(x)]),GH)+matMul(reshape(evalD2W2,[1 1 length(x)]),FGFH);
term2 = matMul(reshape(evalD2W3,[1 1 length(x)]),GF2HF2);
else
term1 = matMul(reshape(evalD2W1,[1 1 length(x)]),GH);
term2 = matMul(reshape(evalD2W2,[1 1 length(x)]),F1GF2H+F1HF2G);
end

val = term1 + term2 + 2*matMul(reshape(evalBasisU,[3 1 length(x)]),reshape(evalDWRu_h,[1 1 length(x)]));


%% supply f_DWR * v_h (first goal function)
function val = integrandFu(x,y,curElem,lvl,p)

Basis = p.statics.basisU; 
evalBasis = Basis(x,y,curElem,lvl,p);

f4e = p.level(end).DWRf4e;
evalF4e = f4e(curElem);
%F4e = evalF4e*ones(1,length(x));
%F4e = reshape(F4e,[1 1 length(x)]);

evalBasis=reshape(evalBasis,[1 3 length(x)]);
%FQ = matMul(F4e,permute(evalBasis,[2 1 3]));
val = evalF4e*evalBasis;




























%% supply integrand: D2W(\nabla u_h)*\nabla w_h\nabla q_h
function val = integrandJacobi(x,y,curElem,lvl,p)

F1 = p.problem.F1;
F2 = p.problem.F2;
CONV = p.params.CONV;

if strcmp(CONV,'c')
%% D2W**(F)[G,H] = W''**1(F)(G,H) + W''**2(F)(F,G)(F,H) + W''**3(F)(F2,H)(F2,G)
D2W1 = p.problem.nonLinearRegSecDerA;
D2W2 = p.problem.nonLinearRegSecDerB;
D2W3 = p.problem.nonLinearRegSecDerC;
else
% D2W(F)[G,H] = W''1(F)(G,H) + W''2(F)((F-F1,G)*(F-F2,H) + (F-F1,H)*(F-F2,G))
D2W1 = p.problem.nonLinearExactSecDerA;
D2W2 = p.problem.nonLinearExactSecDerB;
end

grad_h = p.statics.grad_h;
stressBasis = p.statics.stressBasis;
basisU = p.statics.basisU;
DWRgrad_h = p.statics.DWRgrad_h;

evalGrad = grad_h(x,y,curElem,lvl,p);
evalBasis = stressBasis(x,y,curElem,lvl,p);
evalBasisU = basisU(x,y,curElem,lvl,p);
evalDWRGrad = DWRgrad_h(x,y,curElem,lvl,p);

evalBasisU=reshape(evalBasisU,[3 1 length(x)]);
evalBasisU2=permute(evalBasisU,[2 1 3]);
evalBasisU2=reshape(evalBasisU2,[1 3 length(x)]);

grad1 = evalGrad(:,1);
grad2 = evalGrad(:,2);
evalGrad = reshape(evalGrad',[1 2 length(x)]);
evalDWRGrad = reshape(evalDWRGrad',[1 2 length(x)]);

evalD2W1 = D2W1(grad1,grad2,curElem,lvl,p);
evalD2W2 = D2W2(grad1,grad2,curElem,lvl,p);
if strcmp(CONV,'c')
evalD2W3 = D2W3(grad1,grad2,curElem,lvl,p);
end

GH = matMul(evalBasis,permute(evalDWRGrad,[2 1 3]));
evalGrad1 = reshape([grad1-F1(1) grad2-F1(2)]',[1 2 length(x)]);
evalGrad2 = reshape([grad1-F2(1) grad2-F2(2)]',[1 2 length(x)]);
F2vec = reshape([F2(1)*ones(size(grad1,1),1) F2(2)*ones(size(grad1,1),1)]',[1 2 length(x)]);
F1G = matMul(evalGrad1,permute(evalBasis,[2 1 3]));
F2G = matMul(evalGrad2,permute(evalBasis,[2 1 3]));
F1H = matMul(evalGrad1,permute(evalDWRGrad,[2 1 3]));
F2H = matMul(evalGrad2,permute(evalDWRGrad,[2 1 3]));
FG = matMul(evalGrad,permute(evalBasis,[2 1 3]));
FH = matMul(evalGrad,permute(evalDWRGrad,[2 1 3]));
GF2 = matMul(F2vec,permute(evalBasis,[2 1 3]));
HF2 = matMul(F2vec,permute(evalDWRGrad,[2 1 3]));
F1GF2H = matMul(permute(F1G,[2 1 3]),F2H);
F1HF2G = matMul(permute(F1H,[2 1 3]),F2G);
FGFH = matMul(permute(FG,[2 1 3]),FH);
GF2HF2 = matMul(permute(GF2,[2 1 3]),HF2);

%% D2W**(F)[G,H] = W''**1(F)(G,H) + W''**2(F)(F,G)(F,H) + W''**3(F)(F2,G)(F2,H)
% D2W(F)[G,H] = W''1(F)(G,H) + W''2(F)((F-F1,G)*(F-F2,H) + (F-F1,H)*(F-F2,G))

if strcmp(CONV,'c')
term1 = matMul(reshape(evalD2W1,[1 1 length(x)]),GH)+matMul(reshape(evalD2W2,[1 1 length(x)]),FGFH);
term2 = matMul(reshape(evalD2W3,[1 1 length(x)]),GF2HF2);
else
term1 = matMul(reshape(evalD2W1,[1 1 length(x)]),GH);
term2 = matMul(reshape(evalD2W2,[1 1 length(x)]),F1GF2H+F1HF2G);
end

val = term1 + term2;
%val = matMul(val,ones(3,1,9));