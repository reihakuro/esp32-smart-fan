//block nhận và gửi dữ liệu Bluetooth qua lại giữa module và điện thoại
#include "bluetooth.h" 
#include "Config.h"
#include "Globals.h"

void BTh(void *parameter) { // chương trình điều khiển nhận và gửi tín hiệu qua điện thoại bằng Bluetooth
    // Cấp phát bộ nhớ đệm tạm thời nếu cần xử lý chuỗi
    // char buffer[128]; 
    for (;;) {
      bool hasActivity = false; // trạng thái hoạt động
      uint8_t value = 0; // biến gán giá trị cho level
      if (SerialBT.available()) {
        hasActivity = true; // điều khiển delay
        //-----------------NHẬN DATA TỪ ĐIỆN THOẠI---------------------//
        String data = SerialBT.readStringUntil('\n'); // đọc giá trị nhận đc từ Bluetooth tới khi gặp \n
        vTaskDelay(5 / portTICK_PERIOD_MS);
        data.trim(); // cắt dữ liệu nhận được
        if (data.length() > 0) {
          char commandChar = data.charAt(0); //Lấy chữ đầu
          String valueString = data.substring(1); // Cắt chuỗi số
          value = valueString.toInt(); // Giá trị số, data
          // ----------PHÂN LOẠI LỆNH ĐIỀU KHIỂN trên điện thoại-----------//
          switch (commandChar) {
            case 'M': // Lệnh cho Motor
              if (state == 0 && level <= 3) // state = 0 -> chỉnh bằng nút nhấn trên module/ điện thoại
              {
                level = value; //
                Serial.printf("Set Motor at: %d\n", level); 
                vTaskDelay(5 / portTICK_PERIOD_MS);
              }
              break;
            case 'P': // chuyển chế độ
              state = !state; //IF STATE = 1 -> điều chỉnh theo nhiệt độ
              Serial.println("Switch Motor Mode\n");
              vTaskDelay(5 / portTICK_PERIOD_MS);
              break;
            default:
              Serial.println("-\n");
              break;
          //-------------------------//---------------------//
          //
          }
        }
        //--------------------------//---------------------------------//
      }
      available = SerialBT.hasClient(); // báo hiệu đèn led
      if (SerialBT.hasClient() && send) {
            SerialBT.print("Temperature: ");
            SerialBT.println(temper);
            SerialBT.print("Humidity: ");
            SerialBT.println(humid);
            send = false;
            digitalWrite(LED_2, HIGH);
            vTaskDelay(300 / portTICK_PERIOD_MS);
            digitalWrite(LED_2, LOW);
          }
      if (SerialBT.hasClient()) {
        if (state) {
        SerialBT.println("POWER:1"); // gửi trạng thái nút bấm động trên app
        } else {
        SerialBT.println("POWER:0"); // gửi trạng thái nút bấm động trên app
        }
      }
      // DELAY TASK SWITCH linh hoạt
      if (hasActivity) {
        vTaskDelay(5 / portTICK_PERIOD_MS); 
      } else {
        vTaskDelay(50 / portTICK_PERIOD_MS); 
      }
    }
  }