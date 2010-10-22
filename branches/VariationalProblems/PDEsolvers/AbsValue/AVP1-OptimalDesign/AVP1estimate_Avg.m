function p = P1estimate_Avg(p)
%author: Lena Noack

%% INPUT
n4e = p.level(end).geom.n4e;
lvl = size(p.level,2);

degree = loadField('p.params','nonLinearExactIntegrateDegree',p,19);
%% compute the average error 
eta4T = integrate(n4e,lvl,degree,@integrand,p);

%% OUTPUT
p.level(end).etaT = sqrt(eta4T);
p.level(end).estimatedError = sqrt(sum(eta4T));

%% supply the integrand ||p_h - Ap_h||_L^2, p_h=grad Uh
function val = integrand(x,y,curElem,lvl,p)

AvP_h = p.statics.AvP_h;
AvPh = AvP_h(x,y,curElem,lvl,p);
%grad4e = p.level(lvl).grad4e;
%curGrad = grad4e(curElem,:);
grad_h = p.statics.grad_h;
curGrad = grad_h(x,y,curElem,lvl,p);

val = sum((AvPh - curGrad).*(AvPh - curGrad),2);

val = reshape(val,[1 1 length(x)]);
    