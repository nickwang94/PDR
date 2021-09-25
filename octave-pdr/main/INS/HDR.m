% 2.HDR(启发式偏航角校正)：当检测到人在走直线的时候进行陀螺仪偏差校正
function ret_yaw = HDR(yaw, yawArray, t)
    if(t <= 2)
        ret_yaw = yaw - yawArray(t-1);
    else
        ret_yaw = yaw - (yawArray(t-1) + yawArray(t-2))/2;
    end
end