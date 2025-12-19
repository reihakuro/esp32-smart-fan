#include "Globals.h"

// Parameters & Variable Initial

BluetoothSerial SerialBT;
DHTesp dht;
// gán giá trị khởi tạo ban đầu
volatile int    state = 0;
volatile int    level = 0;
volatile float  temper = 0;
volatile float  humid = 0;
volatile bool   available = false;
volatile bool   send = false;
volatile bool   pass1 = false;
volatile bool   pass2 = false;