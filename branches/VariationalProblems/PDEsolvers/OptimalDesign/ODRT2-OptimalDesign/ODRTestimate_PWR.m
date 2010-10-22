function p = ODRTestimate_PWR(p)
%author: Lena Noack

%% INPUT
n4e = p.level(end).geom.n4e;
lvl = size(p.level,2);
degree = loadField('p.params','nonLinearExactIntegrateDegree',p,19);
nrElems = p.level(end).nrElems;
%dofU4e = p.level(end).enum.dofU4e;
%f4e = p.level(end).f4e;
DWRbool = loadField('p.params','DWRbool',p,0);
if DWRbool == 1
      GOAL = p.params.GOAL;

      %GOAL_IM: mean integral:   J(tau,v) = 1/|Omega1|  int_Omega1 tau dx
      if strcmp(GOAL,'GOAL_IM')
        GoalFunc = integrate(n4e,lvl,degree,@integrandJMid,p);

      %GOAL_DP: dual problem:      J(tau,v) = int_Omega W*_epsilon(tau) dx
      elseif strcmp(GOAL,'GOAL_DP')
        GoalFunc = integrate(n4e,lvl,degree,@integrandJDW,p);

      else

      end
      
      
      D2W = integrate(n4e,lvl,degree,@integrandD2W,p);
%      Alpha = integrate(n4e,lvl,degree,@integrandAlpha,p); %only for 2-Well Benchmark
      DW = integrate(n4e,lvl,degree,@integrandDW,p);
%      Alpha2 = integrate(n4e,lvl,degree,@integrandAlpha2,p); %only for 2-Well Benchmark
      RHS = integrate(n4e,lvl,degree,@integrandF,p);

%      eta4T = GoalFunc - D2W + Alpha - DW - Alpha2 + RHS; %only for 2-Well Benchmark
%      eta4T = GoalFunc - D2W - DW + RHS;
      eta4T = GoalFunc;
else
    fprintf('No dual estimator calculated, select goal function and set DWRbool=1.');
    eta4T = zeros(nrElems,1);
end

%% OUTPUT
p.level(end).etaT = sqrt(abs(eta4T));
p.level(end).estimatedError = sqrt(abs(sum(eta4T)));  %est. for ||sigma-sigma_h||

function val = integrandJMid(x,y,curElem,lvl,p)

%basis = p.statics.u_h;
basis = p.statics.basisU;
%Abasis = p.statics.Au_h; 
Abasis = p.statics.Aw_h; 

evalBasis = basis(x,y,curElem,lvl,p);
%size(evalBasis)
evalABasis = Abasis(x,y,curElem,lvl,p);
evalBasis = evalABasis'*ones(1,3) - evalBasis;
nrBasis = size(evalBasis,2);

evalF = zeros(size(x,1),nrBasis);
%f=1 on Omega2 (Lshape domain) and 0 on O1,O3:
%  _________
% |    |    |
% | O1 | O2 |
% |____|____|
% |    |
% | O3 |
% |____|
%
%index1 = find( x >= 0 );
%evalF(index1,:) = 1*C;

%f=1 on Omega2 (SquareSlit domain) and 0 on O1:
%  _____
% |  |  |
% |O1|O2|
% |__|__|
%
index1 = find( x >= 0 );
evalF(index1,:) = 0.5;

val = reshape(evalF'.*evalBasis',[nrBasis 1 length(x)]);
val = sum(val,1);

% supply integrand int_O1 DW*_varepsilon(sigma_h,tau_h)
function val = integrandJDW(x,y,curElem,lvl,p)

grad_h = p.statics.GradU_h;
basis = p.statics.stressBasis;
Abasis = p.statics.AGrad_wh; 

evalGrad = grad_h(x,y,curElem,lvl,p);
evalBasis = basis(x,y,curElem,lvl,p);
evalABasis = Abasis(x,y,curElem,lvl,p);
evalABasis = reshape(evalABasis,[1 2 length(x)]);
evalABasis = matMul(reshape(ones(3,length(x)),[3 1 length(x)]),evalABasis);
evalBasis = evalABasis - evalBasis;
nrBasis = size(evalBasis,2);

evalF = zeros(size(x,1),3);
index1 = find( x <= -0.5 );
evalF(index1,:) = 1;

evalGrad = reshape(evalGrad,[1 2 length(x)]);   
evalF = reshape(evalF,[1 3 length(x)]);   
val = matMul(evalGrad,permute(evalBasis,[2 1 3])); 
val = matMul(evalF,permute(val,[2 1 3])); 

%% supply integrand: D2W(\nabla u_h)*\nabla u_h\nabla q_h
function val = integrandD2W(x,y,curElem,lvl,p)

% W''(|X|)/|X|^2*(X*Y)(X*Z) + W'(|X|)/|X|^3*( Y*Z*|X|^2 - (X*Y)(X*Z) )

DW = p.problem.nonLinearExactDer;
D2W = p.problem.nonLinearExactSecDer;
grad_h = p.statics.GradU_h;
stressBasis = p.statics.stressBasis;
%stressABasis = p.statics.AGrad_h; 
stressABasis = p.statics.AGrad_wh; 

evalGrad = grad_h(x,y,curElem,lvl,p);
evalBasis = stressBasis(x,y,curElem,lvl,p);

evalABasis = stressABasis(x,y,curElem,lvl,p);
evalABasis = reshape(evalABasis,[1,2,length(x)]);
evalABas(1,:,:) = evalABasis;
evalABas(2,:,:) = evalABasis;
evalABas(3,:,:) = evalABasis;

evalBasis = evalABas-evalBasis;

absGrad = ( evalGrad(:,1).^2 + evalGrad(:,2).^2 ).^(1/2);
evalDW = DW(absGrad,curElem,lvl,p);
evalD2W = D2W(absGrad,curElem,lvl,p);

evalGrad = reshape(evalGrad',[1 2 length(x)]);
YZ = matMul(evalGrad,permute(evalBasis,[2 1 3]));
XY = matMul(evalGrad,permute(evalGrad,[2 1 3]));
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
val = reshape(val,[3 1 length(x)]);
val = sum(val,1);

%% supply integrand: DW(\nabla u_h)*(A(\nabla w_h) - \nabla w_h)
function val = integrandDW(x,y,curElem,lvl,p)

sigma_h = p.statics.sigma_h;
stressBasis = p.statics.stressBasis;
%stressABasis = p.statics.AGrad_h; 
stressABasis = p.statics.AGrad_wh; 

evalSigma = sigma_h(x,y,curElem,lvl,p);
evalBasis = stressBasis(x,y,curElem,lvl,p);
evalABasis = stressABasis(x,y,curElem,lvl,p);
evalABasis = reshape(evalABasis,[1,2,length(x)]);
evalABas(1,:,:) = evalABasis;
evalABas(2,:,:) = evalABasis;
evalABas(3,:,:) = evalABasis;

evalBasis = evalABas-evalBasis;

evalSigma = reshape(evalSigma',[2 1 length(x)]);

val = matMul(evalBasis,evalSigma); 
val = sum(val,1);

%% supply integrand: f(Av-v)
function val = integrandF(x,y,curElem,lvl,p)
f = p.problem.f;
%basis = p.statics.u_h;
basis = p.statics.basisU;
%Abasis = p.statics.Au_h; 
Abasis = p.statics.Aw_h; 

evalBasis = basis(x,y,curElem,lvl,p);
evalABasis = Abasis(x,y,curElem,lvl,p);
evalABasis = evalABasis'*ones(1,3);
nrBasis = size(evalBasis,2);

evalF = f(x,y,curElem,lvl,p)*ones(1,nrBasis);
val = reshape(evalF'.*(evalABasis-evalBasis)',[nrBasis 1 length(x)]);
val = sum(val,1);
