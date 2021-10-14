clear;
data = load('data/line1.txt');
datasize = length(data);
timestamp = data(:,1);
acc_s = data(:,2:4)';
gyro_s = data(:,5:7)';

c1_condition = zeros(1,datasize);
c2_condition = zeros(1,datasize);
c3_condition = zeros(1,datasize);
condition = zeros(1,datasize);
condition_madfilt = zeros(1,datasize);

%C1
for i = 1:datasize
    if(C1(acc_s(:,i)) == 1)
        c1_condition(i) = 1;
    end
end

%C2
for i = 1:datasize
    if(C2(acc_s,i, datasize) == 1)
        c2_condition(i) = 1;
    end
end

%C3
for i = 1:datasize
    if(C3(gyro_s(:,i)) == 1)
        c3_condition(i) = 1;
    end
end

%C1 && C2 && C3
for i = 1:datasize
    if(c1_condition(i) == 1 && c2_condition(i) == 1 && c3_condition(i) == 1)
        condition(i) = 1;
    end
end

condition_medfilt1 = medfilt1(condition, 11);

subplot(5,1,1);
plot(c1_condition, 'r-x');
title('C1');

subplot(5,1,2);
plot(c2_condition, 'b-x');
title('C2');

subplot(5,1,3);
plot(c3_condition, 'g-x');
title('C3');

subplot(5,1,4);
plot(condition, 'b-x');
title('C1&&C2&&C3');

subplot(5,1,5);
plot(condition_medfilt1, 'r-x');
title('medfilt');

