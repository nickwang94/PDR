%%使用泰勒公式近似表示正弦函数
syms x; %定义符号变量为x
y = sin(x);
ploty = ezplot(y); %隐函数作图
set(ploty, 'color', 'r');
dy = taylor(y, 'order', 10); %高阶无穷小为10阶，展开到9阶
%dy = taylor(y,x,1); %在1处展开泰勒级数

hold on;
plotdy = ezplot(dy);
set(plotdy, 'color', 'b');