#ifndef GLOBALS_H
#define GLOBALS_H

#include <Arduino.h>
#include "BluetoothSerial.h" // thư viện Bluetooth
#include "DHTesp.h"          // thư viện cảm biến

// Chia sẻ đối tượng phần cứng
extern BluetoothSerial SerialBT;
extern DHTesp dht;

// Share biến trạng thái toàn cục share giữa các task với nhau
extern volatile int    state;     // biến gán chế độ điều khiển
extern volatile int    level;     // biến gán điều khiển tốc độ pwm
extern volatile float  temper;     // biến nhiệt độ
extern volatile float  humid;     // biến độ ẩm
extern volatile bool   available;     // biến trạng thái kết nối
extern volatile bool   send;     // biến trạng thái gửi data qua điện thoại
extern volatile bool   pass1;     // biến trạng thái đọc cảm biến thành công
extern volatile bool   pass2;     // biến trạng thái đọc cảm biến fail
#endif