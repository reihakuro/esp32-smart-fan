#include "Config.h"
#include "Globals.h"
#include "bluetooth.h"
#include "sensor.h"
#include "pwm_driver.h"
#include "status.h"
// import thư viện 
void setup() {
    // Khởi tạo IO
    pinMode(LED, OUTPUT);
    pinMode(LED_1, OUTPUT);
    pinMode(LED_2, OUTPUT);
    pinMode(LED_3, OUTPUT);
    pinMode(BUTTON_1, INPUT);
    pinMode(BUTTON_2, INPUT);
    analogReadResolution(8);

    // Khởi động Bluetooth
    Serial.begin(115200);
    SerialBT.begin(BT_NAME);
    Serial.printf("Device \"%s\" started.\n", BT_NAME);

    // Setup Sensor
    dht.setup(DHTPIN, DHT_TYPE);

    // Create Tasks
    xTaskCreatePinnedToCore(BTh, "BTh", 4096, NULL, 1, NULL, 1);
    xTaskCreatePinnedToCore(status, "status", 1024, NULL, 0, NULL, 0);
    xTaskCreatePinnedToCore(pwmdriver, "pwmdriver", 4096, NULL, 1, NULL, 0);
    xTaskCreatePinnedToCore(sensors, "sensors", 4096, NULL, 1, NULL, 1);

    Serial.println("RTOS Started...");
}

void loop() { 
    vTaskDelay(2000 / portTICK_PERIOD_MS);
} // main super loop
