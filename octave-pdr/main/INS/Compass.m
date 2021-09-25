% 3.Compass(电子指南针)：通过磁力计读数来计算此时的yaw角，这个角度是不受积分误差影响的
function ret = Compass(yaw, mag_data, acc_data)
    yaw_com = get_the_north_angle(mag_data ,acc_data);
    ret = yaw - yaw_com;
end