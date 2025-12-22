# ESP32 Fan Controller with Flutter App 

An ESP32-based fan controller system for a DC motor (manual and automatic speed control) with a custom Android app built using Flutter.

## DC Motor Operation
- **PWM Mode**: Manual control of fan speed with 4 levels: OFF, Level 1, Level 2, Level 3.
- **Automation Mode**: Fan speed is automatically adjusted based on temperature data from the sensor.

## Features
- DC motor speed control using PWM
- Automatic control based on temperature thresholds
- Bluetooth Classic (BR/EDR) communication
- Temperature & humidity monitoring
- Custom Flutter Android app:
  - Bluetooth connection status
  - Fan mode and speed display
  - Real-time temperature and humidity
 
## Schematic
### Hardware components
- Mandatory:
  - Microcontroller: ESP-WROOM-32 (Wifi & Bluetooth Inside)
  - Sensor: DHT-11 Sensor
  - Motor: R140 DC motor
  - BJT: S8050-D 25V 1.5A with 220Ω Resistor 
  - 1N4007 Diode
  - 2 4-leg tactile switches, 2 22kΩ pull-up resistors 
  - 5VDC seperated source DC motor 
  - Some wires
- Optional:
  - LEDs and resistors for LEDs

### Pins 
| Pin | Connect | Usage |
|----------|-----------|--------|
| 16 | DC Motor | PWM control |
| 14 | DHT-11 Sensor | Received signal |
| 32 | Button | Mode switch |
| 33 | Button | PWM Level switch |

### 
