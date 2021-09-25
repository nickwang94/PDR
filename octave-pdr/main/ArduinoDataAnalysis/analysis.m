%% 对arduino的数据进行分析
DataRoot = '../DataCollection/';
Operator = {'Chongshuai R/Data/';'Wenkun W/Data/';'Wu L/Data/'};
Shapes = {'line'; 'rightAngle'; 'static'}; 
Path = [DataRoot, char(Operator(2)), char(Shapes(3)), '/static.txt']
[timestamp,data_acc,data_gyro] = LoadData_acc_gyro(Path);
% 计算均值
mean_acc = mean(data_acc, 1)
std_acc = std(data_acc, 1)

mean_gyro = mean(data_gyro, 1)
std_gyro = std(data_gyro, 1)

% 将均值写入文件
fid=fopen('../INS/bias.txt','w+');
fprintf(fid,'%f;%f;%f\n%f;%f;%f',mean_gyro(1), mean_gyro(2), mean_gyro(3), ...
    mean_acc(1),mean_acc(2),mean_acc(3));
fclose(fid);


% 绘制图形
figure;
plot(timestamp, data_acc(:,1));
title('accDataX');
figure;
plot(timestamp, data_acc(:,2));
title('accDataY');
figure;
plot(timestamp, data_acc(:,3));
title('accDataZ');

figure;
plot(timestamp, data_gyro(:,1));
title('gyroDataX');
figure;
plot(timestamp, data_gyro(:,2));
title('gyroDataY');
figure;
plot(timestamp, data_gyro(:,3));
title('gyroDataZ');


% mean_acc = [0.0145    0.0080    9.8105]
% mean_gyro = 1.0e-03 .* [-0.3748   -0.9587    0.7965]