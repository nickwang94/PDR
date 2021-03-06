%% 
% 时间：2017-03-20
% 功能：通过卡尔曼滤波+零速率更新实现行人追踪系统
%      使用三个条件同时判断是否静止
%      同时使用ZARU+HDR+Compass进行偏航角矫正
%
% 模型建立：
% 误差状态矩阵 : delta_x = [delta_fai,  delta_w,   delta_r,   delta_v,  delta_a];
%                          姿态误差    加速度偏差   位置误差    速度误差    陀螺仪偏差

%清空内存数据
clear;clc;

%%读取数据
path = "data/angle_back1.txt";
data = load(path);
timestamp = data(:,1);
datasize = length(timestamp);

acc_s = data(:,2:4)';
gyro_s = data(:,5:7)';

%%参数设定
g0 = 9.78049; %赤道重力加速度
U = 34; %纬度
h = 420; %海拔
g = g0*(1+0.0052884*sin(U)^2 - h*3.14e-7) - 0.0000059*sin(2*U)^2; %计算重力

%方向角初始化
pitch = -asin(acc_s(1,1)/g);
roll = atan(acc_s(2,1)/acc_s(3,1));
yaw = 0;

% C为转换矩阵，用来将数据点从传感器框架转换到追踪框架
C = [cos(pitch)*cos(yaw)    (sin(roll)*sin(pitch)*cos(yaw))-(cos(roll)*sin(yaw))    (cos(roll)*sin(pitch)*cos(yaw))+(sin(roll)*sin(yaw));
     cos(pitch)*sin(yaw)    (sin(roll)*sin(pitch)*sin(yaw))+(cos(roll)*cos(yaw))    (cos(roll)*sin(pitch)*sin(yaw))-(sin(roll)*cos(yaw));
    -sin(pitch)              sin(roll)*cos(pitch)                                    cos(roll)*cos(pitch)];
C_pre = C;

% 从文件中读取bias
% fid = load('bias.txt');
% bias_data(1:3) = fid(1,:);
% bias_data(4:6) = fid(2,:);
bias_data = [0, 0, 0, 0, 0, 9.8];

% 卡尔曼矩阵参数
delta_x = zeros(15,1);
delta_x(4:6) = [bias_data(1); bias_data(2); bias_data(3);];
delta_x(13:15) = [bias_data(4); bias_data(5); bias_data(6) - g;];

%误差矩阵，diagonal 15x15 matrix
%如果P为1，则Gk为1，使用观测值来代表当前的预测值
%如果P为0，则Gk为0，使用上一次的预测值来代表当前的预测值
%因为陀螺仪(4：6)和加速度计(13：15)的数值是有噪声的，所以使用预测值而不是带有噪声的观测值
P = diag([1 1 1     0 0 0     1 1 1     1 1 1     0 0 0]);

%观测噪声协方差矩阵 Compass(1),HDR(1),ZARU(3),ZUPT(3)
%R为0，则Gk为1，使用观测值来代表当前的预测
%磁力计由于容易受外界影响，所以方差给的大，表示不是很相信他所得的数据
R = diag([ 0 0.01 0.01 0.01 0.01 0.01 0.01]); %使用0表示完全相信HDR的值

% 系统过程噪声协方差矩阵，表示预测模型本身的噪声，初值给的很小
Q = diag([0.0001 0.0001 0.0001 zeros(1,3) zeros(1,3) 0.0001 0.0001 0.0001  zeros(1,3)]);

% IEZ + HDR + ZARU
H = [[0 0 1]  zeros(1,3) zeros(1,3) zeros(1,3) zeros(1,3);
    zeros(3)  eye(3) zeros(3) zeros(3) zeros(3);
    zeros(3) zeros(3) zeros(3) eye(3) zeros(3)];

% 记录导航框架的加速度
acc_n = nan(3,datasize);
acc_n(:,1) = C*acc_s(:,1);

%速度
vel_n = nan(3,datasize);
vel_n(:,1) = [0 0 0]';

%位置
pos_n = nan(3,datasize);
pos_n(:,1) = [0 0 0]';

%距离
distance = nan(1,datasize-1);
distance(1) = 0;

%记录yaw角
heading = nan(1,datasize);
heading(1) = yaw;

%噪声
sigma_noise = 1e-4;

%阈值
yaw_threshold = deg2rad(4);

%计算静止
isStance = StanceDetection(acc_s, gyro_s, datasize);

%% 主循环
for t = 2:datasize
    dt = timestamp(t) - timestamp(t-1); %将纳秒换算成秒
    
    % first phase:陀螺仪、加速度去除零偏差
    gyro_s1 = gyro_s(:,t) - delta_x(4:6);
    
    % second phase:角速率反对称矩阵
    delta_omiga = [0           -gyro_s1(3)     gyro_s1(2);
                   gyro_s1(3)   0             -gyro_s1(1);
                  -gyro_s1(2)   gyro_s1(1)     0];
    
    % 方向转换矩阵的计算
    C = C_pre*(2*eye(3)+(delta_omiga*dt))/(2*eye(3)-(delta_omiga*dt));
    
    %更新方向角
    pitch = -asin(C(3,1));
    roll = atan(C(3,2)/C(3,3));
    yaw = atan(C(2,1)/C(1,1));
    
    %third phase:加速度转换框架
    acc_n(:,t) = 0.5*(C + C_pre) * (acc_s(:,t) - delta_x(13:15));
    
    %fourth phase:加速度积分获得速度
    vel_n(:,t) = vel_n(:,t-1) + (acc_n(:,t) - [0; 0; g] )*dt;
    pos_n(:,t) = pos_n(:,t-1) + vel_n(:,t)*dt;
    
    % 加速度导航框架下反对称向量积操作矩阵
    S = [0         -acc_n(3)   acc_n(2);
         acc_n(3)   0         -acc_n(1);
        -acc_n(2)   acc_n(1)   0];
    
    % 状态转移矩阵，描述如何从上一个状态推测出当前状态
    F = [eye(3)        dt*C    zeros(3)  zeros(3)   zeros(3);
        zeros(3)      eye(3)        zeros(3)  zeros(3)   zeros(3);
        zeros(3)      zeros(3)     eye(3)     dt*eye(3) zeros(3)
        -dt*S          zeros(3)     zeros(3)   eye(3)     dt*C
        zeros(3)      zeros(3)     zeros(3)   zeros(3)  eye(3)];
    
    % 预测
    delta_x = F*delta_x;
    P = F*P*F' + Q;
    
    %%HDR
    %判断行人此时是否在走直线,计算yaw角的偏差
    %如果偏差小于4deg，我们认为行人在走直线，将这个偏差输入EKF中进行校正
    %如果偏差大于4deg，我们认为行人没有走直线，此时不需要进行校准
    ret_yaw = HDR(yaw, heading,t);
    
    if(abs(ret_yaw) < yaw_threshold)
        delta_yaw_hdr = ret_yaw;
    else
        delta_yaw_hdr = 0;
    end
    
    % 判断站立相位
    if(isStance(t) == 1)
        K = (P*(H)')/((H)*P*(H)' + R); %计算卡尔曼系数
        
        m = [delta_yaw_hdr;
            ZARU(gyro_s(:,t));
            (vel_n(:,t) - [0 0 0]')];
        
        delta_x = delta_x + K * (m - H * delta_x);
        
        % 更新噪声协方差矩阵
        P = (eye(15) - K * H) * P;
        
        %%更新姿态
        ang_matrix = -[0           -delta_x(3)    delta_x(2);
                       delta_x(3)   0            -delta_x(1);
                      -delta_x(2)   delta_x(1)    0];
        
        C = (2*eye(3)+(ang_matrix))/(2*eye(3)-(ang_matrix))*C;
        
        %fifth phase:使用卡尔曼误差估计来修正速度和位置
        vel_n(:,t) = vel_n(:,t) - delta_x(10:12);
        pos_n(:,t) = pos_n(:,t) - delta_x(7:9);
        
        %恢复误差状态
        delta_x(1:3) = zeros(3,1);
        delta_x(7:9) = zeros(3,1);
        delta_x(10:12) = zeros(3,1); 
    end
    
    
    heading(t) = yaw; %保存yaw角
    C_pre = C; % 保存方向
    % 计算距离
    distance(1,t) = distance(1,t-1) + sqrt((pos_n(1,t)-pos_n(1,t-1))^2 + (pos_n(2,t)-pos_n(2,t-1))^2);
end

%% 绘制第一幅图
%绘制图一
figure;
box on;
hold on;
angle = 180; %要求达到图片审美对齐的角度
rotation_matrix = [cosd(angle)  -sind(angle);
    sind(angle)   cosd(angle)];

pos_r = zeros(2,datasize);

%将图形进行一个角度旋转
for idx = 1:datasize
    pos_r(:,idx) = rotation_matrix*[pos_n(1,idx) pos_n(2,idx)]';
end
%绘制路线
plot(pos_r(1,:),pos_r(2,:),'LineWidth',2,'Color','r');
%绘制开始符号
start = plot(pos_r(1,1),pos_r(2,1),'Marker','^','LineWidth',1,'LineStyle','none');
%绘制结束符号
stop = plot(pos_r(1,end),pos_r(2,end),'Marker','o','LineWidth',1,'LineStyle','none');

xlabel('x (m)');
ylabel('y (m)');
title('平面路线估计');
legend([start;stop],'开始','结束');
axis equal;
grid;
hold off;


%% 绘制第二幅图
figure;
box on; %坐标系的右边和上边有边框
hold on;
plot(distance,pos_n(3,:),'Linewidth',2, 'Color','b'); %横轴是所行走的距离，纵轴是高度
xlabel('所有的距离(m)');
ylabel('高度(m)');
title('高度估计');
grid;

% 绘制每一层楼的高度线
floor_colour = [0 0.5 0]; % 设定线条颜色
floor_heights = [0 3.6 7.2 10.8]; %设定楼层高度
floor_names = {'A' 'B' 'C' 'D'}; %设定楼层名称
lim = xlim; %获取横轴上线限，得到的是1*2的矩阵
for floor_idx = 1:length(floor_heights)
    line(lim, [floor_heights(floor_idx) floor_heights(floor_idx)], 'LineWidth', 2, 'LineStyle', '--', 'Color', floor_colour);
end
hold off;