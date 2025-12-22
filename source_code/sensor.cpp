//block nhận giá trị từ cảm biến DHT và gán giá trị
#include "sensor.h" 
#include "Config.h"
#include "Globals.h"

 void sensors(void *parameter) {
    for (;;) {
    // Đọc nhiệt độ và độ ẩm vào struct
    TempAndHumidity newValues = dht.getTempAndHumidity();
    // Kiểm tra trạng thái cảm biến
    if (dht.getStatus() == 0) {         // GIÁ TRỊ 0 = ỔN
      float t = newValues.temperature;  // ghi giá trị 
      float h = newValues.humidity;     // ghi giá trị
      
      // Update & gửi cho điện thoại dữ liệu đo được
      pass1 = true;
      if (t > 0 && h < 100) { // lọc giá trị nhiễu 
        temper = t; // gán biến toàn cục
        humid  = h; // gán biến toàn cục
        send = true;
      }
    } else {
      pass2 = true; // Báo ghi chưa thành công, lần sau ghi lại
    }
    
    // DHT11 cần nghỉ tối thiểu 2s
    vTaskDelay(5000 / portTICK_PERIOD_MS); 
  }
}