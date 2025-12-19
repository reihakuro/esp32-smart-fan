//block điều khiển pwm ra quạt
//non-blocking
#include "pwm_driver.h" 
#include "Config.h"
#include "Globals.h"

 void pwmdriver(void *parameter) {
    static int last_pwm = 0; // giá trị pwm trước
    int pwm = 0;
    analogWrite(PWM, pwm);
    for (;;) {
       if (state == 0) { 
        if (digitalRead(BUTTON_1) == LOW) { // Phát hiện nhấn
        vTaskDelay(20 / portTICK_PERIOD_MS); 
        if (digitalRead(BUTTON_1) == LOW) {
          level++;
          if (level > 3) {
            level = 0;
          }
          //Serial.printf("LEVEL CHANGE: %d\n", level);
          while (digitalRead(BUTTON_1) == LOW) {
            vTaskDelay(10 / portTICK_PERIOD_MS); 
          }//
        }//
      }//
    }// 
    if (digitalRead(BUTTON_2) == LOW) { //
      vTaskDelay(20 / portTICK_PERIOD_MS); //
      //
      if (digitalRead(BUTTON_2) == LOW) {//
        state = !state; // Đảo trạng thái//
        level = 0;//
        Serial.println("STATE CHANGE");
        
        while (digitalRead(BUTTON_2) == LOW) {
          vTaskDelay(10 / portTICK_PERIOD_MS); 
        };
      }
    }
      if (state == 0) {  // quạt chỉnh theo mức độ
      switch (level) { // phân loại level
        case 0:
          pwm = 0; // quạt dừng
          break;
        case 1:
          pwm = 60;
          break;
        case 2:
          pwm = 110;
          break;
        case 3:
          pwm = 180;
          break;
        default: 
          //Serial.println("Unavaible");
          break;
      }
      } else { // chế độ tự động
          if (temper >= 33) pwm = 200;
          else if (temper >= 30) pwm = 170;
          else if (temper >= 27) pwm = 130;
          else if (temper >= 25) pwm = 100;
          else if (temper >= 22) pwm = 70;
          else pwm = 0;
      }
    // nếu pwm được cập nhật thì mới analogWrite
    if (pwm != last_pwm) {
      analogWrite(PWM, pwm);
      last_pwm = pwm;
      }
      vTaskDelay(50 / portTICK_PERIOD_MS);
      }
  }