# 文件夹说明
## 数据文件
数据文件存放在“DataCollection”文件夹中，以采集人的名字命名    
## 计算bias文件
"ArduinoDataAnalysis"文件夹中的“analysis.m”文件会计算静止时的陀螺仪和加速度偏差，并将数据以文件的形式保存在根目录“INS”文件夹下“bias.txt”文件中，程序会在初始化卡尔曼滤波状态变量时，对该数据进行读取。    
## 主程序
“INS”文件夹存放主程序，运行“IndoorPedestrainNavigation_with_MPU9250.m”即可。    

# 使用说明
（1）连接好数据，将传感器固定于脚部，采集静止一分钟的数据，放置“DataCollection/name/Data/static”文件夹    
（2）按照规定路线进行数据采集（如走直线），并将数据存放在“DataCollection/name/Data/line”文件夹    
（3）在matlab中，点开“ArduinoDataAnalysis/analysis.m”运行，计算并存储偏差    
（4）点开“INS/IndoorPedestrainNavigation_with_MPU9250.m”运行并得到结果    
