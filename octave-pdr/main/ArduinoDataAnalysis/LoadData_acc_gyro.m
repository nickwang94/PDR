function [timestamp,data_acc,data_gyro] = LoadData_acc_gyro(path)
    data = load(path);
    timestamp = data(:,1);
    data_acc = data(:,2:4);
    data_gyro = data(:,5:7);
end