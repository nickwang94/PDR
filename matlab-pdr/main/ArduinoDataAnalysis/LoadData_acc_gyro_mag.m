function [timestamp,data_acc,data_gyro,data_mag] = LoadData_acc_gyro_mag(path)
    data = load(path);
    timestamp = data(:,1);
    data_acc = data(:,2:4);
    data_gyro = data(:,5:7);
    data_mag = data(:,8:10);
end