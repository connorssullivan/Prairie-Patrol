#include <Rfid134.h>

String scannedTag = "";

// Converts a long long to String
String ll_toString(long long long_Num) {
  String numString = "";
  do {
    numString = int(long_Num % 10) + numString;
    long_Num /= 10;
  } while (long_Num != 0);
  return numString;
}

// Callback class to handle RFID scanner events
class rfidScan {
  public: 
    static void OnError(Rfid134_Error code) {
      Serial.print("Error Code: ");
      Serial.println(code);
    }

    static void OnPacketRead(const Rfid134Reading& reading) {
      long long tempScanned = (reading.country * 1000000000000LL) + reading.id;
      scannedTag = ll_toString(tempScanned);
      Serial.println("Scanned RFID Tag: " + scannedTag);
    }
};

// Setup RFID on Serial1 (adjust to your wiring)
Rfid134<HardwareSerial, rfidScan> rfid(Serial1);

void setup() {
  Serial.begin(9600);
  Serial1.begin(9600, SERIAL_8N2); // 8 data bits, no parity, 2 stop bits
  rfid.begin(); // Initialize RFID reader
}

void loop() {
  rfid.loop(); // Continuously check for RFID scans

  // Example use of the tag
  if (scannedTag != "") {
    Serial.println("RFID Tag Detected: " + scannedTag);
    scannedTag = ""; // Clear tag after reading
  }
}
