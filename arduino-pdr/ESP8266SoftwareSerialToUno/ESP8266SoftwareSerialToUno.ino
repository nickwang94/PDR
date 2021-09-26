/**
 * ESP8266通过软串口实现数据获取并在硬串口中输出
 * @author：nickwang
 * @date: 2021-09-26
 */

#include <SoftwareSerial.h>

/** 
 * 创建软串口对象
 * 其中D8为RX，与Arduino的TX连接
 * D7为TX，与Arduino的RX连接
 */
SoftwareSerial softSerial(D8, D7);
String comdata="";

void setup() {
  Serial.begin(115200);
  Serial.println("ESP8266 Hardware Serial set well");
  softSerial.begin(115200);
  Serial.println("ESP8266 Software Serial set well");
}

void loop() {
  if (softSerial.available()){
      comdata = softSerial.read();
      Serial.print(comdata);
  }
}
