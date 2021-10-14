%% º∆À„gyro_bias
clear;clc;
path = "data/state1.txt";
data = load(path);
timestamp = data(:,1);
datasize = length(timestamp);
acc_s = data(:,2:4)';
gyro_s = data(:,5:7)';

mean_acc = mean(acc_s,2)
mean_gyro = mean(gyro_s,2)