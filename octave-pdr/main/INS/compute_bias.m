%% º∆À„gyro_bias
data = load('../DATA/MPU9250/motionless_data.txt');
timestamp = data(:,1);
datasize = length(timestamp);
acc_s = data(:,2:4)' .* 9.8;
gyro_s = data(:,5:7)' .* (pi/180);

mean_acc = mean(acc_s,2)
mean_gyro = mean(gyro_s,2)