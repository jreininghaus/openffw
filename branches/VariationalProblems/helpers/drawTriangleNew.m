function drawTriangle(problem,rate1,rate2)
%author: Lena Noack

if strcmp(problem,'Square') %&& rate == 0.5
%     rate = 1/2;
    format rat
    str_rate = num2str(rate1);
    orient = 0.5; %1; %orientation: 0.5 -> 180�; 1 -> 0�
    c = 3; %length of triangle sides
    yrate = 20; %80; %logarithmic transposition in y-direction
    xrate = 0.03;%0.003; %logarithmic transposition in x-direction
    a1 = 6 * 10^3*xrate;
    b1 = 3.5 * 10^(-3)*yrate;
    x1 = [xrate*1.3*10^4,yrate*3.1*10^(-3)];
    x2 = [xrate*4.1*10^3,yrate*5.3*10^(-3)];
    maleDreieck(rate1,str_rate,a1,b1,c,...
        x1(1),x1(2),x2(1),x2(2),orient,xrate,yrate);
% elseif strcmp(problem,'Square') && rate == 1
%     rate = 1/2;
%     str_rate = num2str(rate2);
%     orient = 1;
%     c = 5;
%     a1 = 6 * 10^3;
%     b1 = 2.5 * 10^(-6);
%     x1 = [1.3*10^4,2.1*10^(-6)];
%     x2 = [5.1*10^3,4.3*10^(-6)];
%     maleDreieck(rate2,str_rate,a1,b1,c,...
%         x1(1),x1(2),x2(1),x2(2),orient,xrate,yrate);
elseif strcmp(problem,'Lshape') %&& rate == 0.5
%     rate = 1/2;
    str_rate = num2str(rate1);
    orient = 1;
    c = 5;
    a1 = 5 * 10^3;
    b1 = 2.5 * 10^(-4);
    x1 = [4*10^3,2.1*10^(-4)];
    x2 = [6*10^2,3.3*10^(-4)];
    maleDreieck(rate1,str_rate,a1,b1,c,...
        x1(1),x1(2),x2(1),x2(2),orient,xrate,yrate)
    
%     str_rate = num2str(rate2);
%     orient = 1;
%     c = 5;
%     a1 = 6 * 10^2;
%     b1 = 2.5 * 10^(-4);
%     x1 = [1.3*10^4,2.1*10^(-4)];
%     x2 = [5.1*10^3,4.3*10^(-4)];
%     maleDreieck(rate2,str_rate,a1,b1,c,...
%         x1(1),x1(2),x2(1),x2(2),orient,xrate,yrate);
end

grid off

function maleDreieck(rate,str_rate,a1,b1,c,x1,y1,x2,y2,orient,xrate,yrate)
FontSize = 10;

if orient == 1
    a2 = c * a1; b2 = (c)^(rate) * b1;
    loglog([a1;a2;a1;a1],[b1;b1;b2;b1],'k');
else
    a2 = c * a1; b2 = (c)^(-rate) * b1;
    loglog([a1;a2;a2;a1],[b1;b1;b2;b1],'k');
end
x1
y1
text(x1,y1-0.001*yrate,'1','FontSize',FontSize)
text(x2,y2,str_rate,'FontSize',FontSize)

h = gca;
set(h,'FontSize',FontSize)