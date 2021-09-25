clear;
data_acc = load('acc.txt');
data_gyro = load('gyro.txt');
datasize_acc = length(data_acc);
timestamp_acc = data_acc(:,1);
timestamp_gyro = data_gyro(:,1);
acc_s = data_acc(:,2:4)';
gyro_s = data_gyro(:,2:4);
gyro_s = interp1(timestamp_gyro, gyro_s, timestamp_acc, 'spline' ,'extrap')';

c1_condition = zeros(1,datasize_acc);
c2_condition = zeros(1,datasize_acc);
c3_condition = zeros(1,datasize_acc);
condition = zeros(1,datasize_acc);
condition_madfilt = zeros(1,datasize_acc);

%C1
for i=1:datasize_acc
    if(C1(acc_s(:,i)) == 1)
        c1_condition(i) = 1;
    end
end

%C2
for i=1:datasize_acc
    if(C2(acc_s,i, datasize_acc) == 1)
        c2_condition(i) = 1;
    end
end

%C3
for i=1:datasize_acc
    if(C3(gyro_s(:,i)) == 1)
        c3_condition(i) = 1;
    end
end

%C1&&C2&&C3
for i=1:datasize_acc
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

