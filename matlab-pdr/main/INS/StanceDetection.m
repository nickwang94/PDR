%%该函数用来判断此时是否在静止状态
function retArray = StanceDetection(acc_s, gyro_s, datasize_acc)
    retTemp = zeros(1,datasize_acc);
    for i = 1 : datasize_acc
        if(C1(acc_s(:,i)) == 1 && C2(acc_s, i, datasize_acc) == 1 && C3(gyro_s(:,i)) == 1)
            retTemp(i) = 1;
        end
    end
    %对三个条件与运算的结果进行中值滤波,窗口大小为11
    retArray = medfilt1(retTemp,11);
end