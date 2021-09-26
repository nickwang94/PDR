/*
 程序功能：数据采集文件
 修改人员：Nick Wang
 修改时间：2018.01.17
 使用说明：1.可以通过修改#define的内容来控制所需要的数据内容
          例如：需要加速度和陀螺仪，但是不需要磁力计，
               AccDataRequest = true; GyroDataRequest = true; MagDataRequest = false;
          2.如果你需要输出一些传感器连接、校准的信息在文件的头部，就令OutputDescription为true
 
 硬件连线如下：
 MPU9250传感器 --------- Arduino uno
 VDD ---------------------- 3.3V
 GND ---------------------- GND
 SDA ----------------------- A4
 SCL ----------------------- A5
 */

#include "quaternionFilters.h"
#include "MPU9250.h"


#define AHRS false         // Set to false for basic data read
#define SerialDebug true  // Set to true to get Serial output for debugging

// 你可以根据你的需求在这里对采集数据进行修改，而不需要修改程序本身
#define OutputDescription false // 程序说明
#define AccDataRequest true //加速度数据
#define GyroDataRequest true // 陀螺仪数据
#define MagDataRequest false // 磁力计数据

MPU9250 myIMU;

void setup()
{
  Wire.begin();
  // TWBR = 12;  // 400 kbit/sec I2C speed
  Serial.begin(115200);

  byte c = myIMU.readByte(MPU9250_ADDRESS, WHO_AM_I_MPU9250);
  /*
   * 传感器连接、校准信息部分
   */
  if(OutputDescription)
  {
    
    Serial.print("MPU9250 "); Serial.print("I AM "); Serial.print(c, HEX);
    Serial.print(" I should be "); Serial.println(0x71, HEX);   
  }
  if (c == 0x71)
  {
    myIMU.MPU9250SelfTest(myIMU.SelfTest);
    if(OutputDescription)
    {
      Serial.println("MPU9250 is online...");
      Serial.print("x-axis self test: acceleration trim within : ");
      Serial.print(myIMU.SelfTest[0],1); Serial.println("% of factory value");
      Serial.print("y-axis self test: acceleration trim within : ");
      Serial.print(myIMU.SelfTest[1],1); Serial.println("% of factory value");
      Serial.print("z-axis self test: acceleration trim within : ");
      Serial.print(myIMU.SelfTest[2],1); Serial.println("% of factory value");
      Serial.print("x-axis self test: gyration trim within : ");
      Serial.print(myIMU.SelfTest[3],1); Serial.println("% of factory value");
      Serial.print("y-axis self test: gyration trim within : ");
      Serial.print(myIMU.SelfTest[4],1); Serial.println("% of factory value");
      Serial.print("z-axis self test: gyration trim within : ");
      Serial.print(myIMU.SelfTest[5],1); Serial.println("% of factory value");
    }
    
    myIMU.calibrateMPU9250(myIMU.gyroBias, myIMU.accelBias);
    myIMU.initMPU9250();
   
    byte d = myIMU.readByte(AK8963_ADDRESS, WHO_AM_I_AK8963);
    if(OutputDescription)
    {
      Serial.print("AK8963 "); Serial.print("I AM "); Serial.print(d, HEX);
      Serial.print(" I should be "); Serial.println(0x48, HEX);
    }
    
    myIMU.initAK8963(myIMU.magCalibration);
    if (OutputDescription)
    {
      Serial.println("Calibration values: ");
      Serial.print("X-Axis sensitivity adjustment value ");
      Serial.println(myIMU.magCalibration[0], 2);
      Serial.print("Y-Axis sensitivity adjustment value ");
      Serial.println(myIMU.magCalibration[1], 2);
      Serial.print("Z-Axis sensitivity adjustment value ");
      Serial.println(myIMU.magCalibration[2], 2);
    }

  } // if (c == 0x71)
  else
  {
    Serial.print("Could not connect to MPU9250: 0x");
    Serial.println(c, HEX);
    while(1) ; // Loop forever if communication doesn't happen
  }
}

void loop()
{
  if (myIMU.readByte(MPU9250_ADDRESS, INT_STATUS) & 0x01)
  {  
    if(AccDataRequest)
    {
      myIMU.readAccelData(myIMU.accelCount);  
      myIMU.getAres();
 
      myIMU.ax = (float)myIMU.accelCount[0]*myIMU.aRes; // - accelBias[0];
      myIMU.ay = (float)myIMU.accelCount[1]*myIMU.aRes; // - accelBias[1];
      myIMU.az = (float)myIMU.accelCount[2]*myIMU.aRes; // - accelBias[2];
    }
    
    if(GyroDataRequest)
    {
      myIMU.readGyroData(myIMU.gyroCount);  
      myIMU.getGres();
  
      myIMU.gx = (float)myIMU.gyroCount[0]*myIMU.gRes;
      myIMU.gy = (float)myIMU.gyroCount[1]*myIMU.gRes;
      myIMU.gz = (float)myIMU.gyroCount[2]*myIMU.gRes;
    }
    
    if(MagDataRequest)
    {
      myIMU.readMagData(myIMU.magCount);  
      myIMU.getMres();
       
      myIMU.magbias[0] = +470.;
      myIMU.magbias[1] = +120.;
      myIMU.magbias[2] = +125.;  
      
      myIMU.mx = (float)myIMU.magCount[0]*myIMU.mRes*myIMU.magCalibration[0] - myIMU.magbias[0];
      myIMU.my = (float)myIMU.magCount[1]*myIMU.mRes*myIMU.magCalibration[1] - myIMU.magbias[1];
      myIMU.mz = (float)myIMU.magCount[2]*myIMU.mRes*myIMU.magCalibration[2] - myIMU.magbias[2];
    } 
  } // if (readByte(MPU9250_ADDRESS, INT_STATUS) & 0x01)

  // Must be called before updating quaternions!
  myIMU.updateTime();

  // Sensors x (y)-axis of the accelerometer is aligned with the y (x)-axis of
  // the magnetometer; the magnetometer z-axis (+ down) is opposite to z-axis
  // (+ up) of accelerometer and gyro! We have to make some allowance for this
  // orientationmismatch in feeding the output to the quaternion filter. For the
  // MPU-9250, we have chosen a magnetic rotation that keeps the sensor forward
  // along the x-axis just like in the LSM9DS0 sensor. This rotation can be
  // modified to allow any convenient orientation convention. This is ok by
  // aircraft orientation standards! Pass gyro rate as rad/s
  //  MadgwickQuaternionUpdate(ax, ay, az, gx*PI/180.0f, gy*PI/180.0f, gz*PI/180.0f,  my,  mx, mz);
  //MahonyQuaternionUpdate(myIMU.ax, myIMU.ay, myIMU.az, myIMU.gx*DEG_TO_RAD,
  //                       myIMU.gy*DEG_TO_RAD, myIMU.gz*DEG_TO_RAD, myIMU.my,
  //                       myIMU.mx, myIMU.mz, myIMU.deltat);

  if (!AHRS)
  {
    myIMU.count = micros();
    if(SerialDebug)
    {
      Serial.print(myIMU.count/1000000.0, 5);Serial.print(";");
      if(AccDataRequest)
      {
        Serial.print(myIMU.ax*9.81, 5);Serial.print(";");
        Serial.print(myIMU.ay*9.81, 5);Serial.print(";");
        Serial.print(myIMU.az*9.81, 5);Serial.print(";");
      }
      
      if(GyroDataRequest)
      {
        Serial.print(myIMU.gx*3.1415/180, 5);Serial.print(";");
        Serial.print(myIMU.gy*3.1415/180, 5);Serial.print(";");
        Serial.print(myIMU.gz*3.1415/180, 5);Serial.print(";");
      }
      

      if(MagDataRequest)
      {
        Serial.print(myIMU.mx, 5);Serial.print(";");
        Serial.print(myIMU.my, 5);Serial.print(";");
        Serial.print(myIMU.mz, 5);Serial.print(";");
      }

      Serial.print("\n");
    }
    
  } // if (!AHRS)
  else
  {
    // Serial print and/or display at 0.5 s rate independent of data rates
    myIMU.count = micros();
    if(SerialDebug)
    {
      Serial.print("ax = "); Serial.print((int)1000*myIMU.ax);
      Serial.print(" ay = "); Serial.print((int)1000*myIMU.ay);
      Serial.print(" az = "); Serial.print((int)1000*myIMU.az);
      Serial.println(" mg");

      Serial.print("gx = "); Serial.print( myIMU.gx, 2);
      Serial.print(" gy = "); Serial.print( myIMU.gy, 2);
      Serial.print(" gz = "); Serial.print( myIMU.gz, 2);
      Serial.println(" deg/s");

      Serial.print("mx = "); Serial.print( (int)myIMU.mx );
      Serial.print(" my = "); Serial.print( (int)myIMU.my );
      Serial.print(" mz = "); Serial.print( (int)myIMU.mz );
      Serial.println(" mG");

      Serial.print("q0 = "); Serial.print(*getQ());
      Serial.print(" qx = "); Serial.print(*(getQ() + 1));
      Serial.print(" qy = "); Serial.print(*(getQ() + 2));
      Serial.print(" qz = "); Serial.println(*(getQ() + 3));
    }


    // http://en.wikipedia.org/wiki/Conversion_between_quaternions_and_Euler_angles
    myIMU.yaw   = atan2(2.0f * (*(getQ()+1) * *(getQ()+2) + *getQ() *
                  *(getQ()+3)), *getQ() * *getQ() + *(getQ()+1) * *(getQ()+1)
                  - *(getQ()+2) * *(getQ()+2) - *(getQ()+3) * *(getQ()+3));
    myIMU.pitch = -asin(2.0f * (*(getQ()+1) * *(getQ()+3) - *getQ() *
                  *(getQ()+2)));
    myIMU.roll  = atan2(2.0f * (*getQ() * *(getQ()+1) + *(getQ()+2) *
                  *(getQ()+3)), *getQ() * *getQ() - *(getQ()+1) * *(getQ()+1)
                  - *(getQ()+2) * *(getQ()+2) + *(getQ()+3) * *(getQ()+3));
    myIMU.pitch *= RAD_TO_DEG;
    myIMU.yaw   *= RAD_TO_DEG;
    // 你需要根据下面的网站计算你所在地区当前时间的磁偏角
    // http://www.ngdc.noaa.gov/geomag-web/#declination
    // Model Used:  WMM2015 Help
    // Latitude: 34° 15' 57" N
    // Longitude:  108° 53' 0" E
    // Date  Declination
    // 2018-01-17  3° 36' W  ± 0° 18'  changing by  0° 2' W per year
    myIMU.yaw   -= 3.54;
    myIMU.roll  *= RAD_TO_DEG;

    if(SerialDebug)
    {
      Serial.print("Yaw, Pitch, Roll: ");
      Serial.print(myIMU.yaw, 2);
      Serial.print(", ");
      Serial.print(myIMU.pitch, 2);
      Serial.print(", ");
      Serial.println(myIMU.roll, 2);

      Serial.print("rate = ");
      Serial.print((float)myIMU.sumCount/myIMU.sum, 2);
      Serial.println(" Hz");
    }

    myIMU.sumCount = 0;
    myIMU.sum = 0;
  } // if (AHRS)
}
