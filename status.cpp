//block hiển thị led
#include "status.h" 
#include "Config.h"
#include "Globals.h"

void status(void *parameter) {
  for (;;) { //LED TRẠNG THÁI ESP PAIR VỚI ĐIỆN THOẠI
    if (available) { 
      digitalWrite(LED, HIGH); // TRẠNG THÁI ĐÃ KẾT NỐI
      } else {
        digitalWrite(LED, HIGH); // TRẠNG THÁI TREO MÁY, KHÔNG KẾT NỐI // blink
        vTaskDelay(500 / portTICK_PERIOD_MS);
        digitalWrite(LED, LOW); 
        vTaskDelay(200 / portTICK_PERIOD_MS);
      }
      if (state == 0) {
        digitalWrite(LED_3, HIGH); //led 3
        vTaskDelay(200 / portTICK_PERIOD_MS);
      }
      else {
        digitalWrite(LED_3, LOW);
        vTaskDelay(200 / portTICK_PERIOD_MS);
      }
      if (pass1) {
        digitalWrite(LED_1, HIGH);
        vTaskDelay(300 / portTICK_PERIOD_MS);
        digitalWrite(LED_1, LOW);  
        vTaskDelay(300 / portTICK_PERIOD_MS);
        pass1 = false;
      } else if (pass2) {
        digitalWrite(LED_1, HIGH);
        vTaskDelay(100 / portTICK_PERIOD_MS);
        digitalWrite(LED_1, LOW);
        vTaskDelay(100 / portTICK_PERIOD_MS);
        digitalWrite(LED_1, HIGH);
        vTaskDelay(100 / portTICK_PERIOD_MS);
        digitalWrite(LED_1, LOW);
        pass2 = false;
      }
  }
}