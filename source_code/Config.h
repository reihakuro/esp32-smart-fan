#ifndef CONFIG_H
#define CONFIG_H

// định dạng chân trên esp32
#define DHTPIN      14  // chân đọc dữ liệu từ cảm biến DHT-11 //READ
#define LED         4   // led tín hiệu bluetooth kết nối     //WRITE
#define LED_1       17  // led cảm biến trạng thái đọc       //WRITE
#define LED_2       5   // led tín hiệu gửi qua điện thoại   //WRITE
#define LED_3       18  // led hiển thị chế độ               //WRITE
#define PWM         16  // chân điều khiển motor             //WRITE
#define BUTTON_1    33  // nút nhấn điều chỉnh pwm           //READ
#define BUTTON_2    32  // nút nhấn chuyển chế độ điều khiển //READ
// Settings
#define DHT_TYPE    DHTesp::DHT11 //  loại cảm biến sử dụng
#define BT_NAME     "ESP32-Bluetooth" // tên nhận diện

#endif