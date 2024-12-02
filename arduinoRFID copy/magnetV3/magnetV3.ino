#include "secrets.h"
#include <Firebase.h>
#include <SPI.h>
#include <MFRC522.h>
#include <ArduinoBLE.h>

BLEService customService("12345678-1234-1234-1234-123456789abc");
BLEStringCharacteristic customCharacteristic("abcd1234-5678-5678-5678-123456789abc", BLERead | BLEWrite, 20);

#define MAGNET_LOCK 5
#define RST_PIN 9
#define SS_PIN 10

MFRC522 rfid(SS_PIN, RST_PIN);
MFRC522::MIFARE_Key key;
Firebase fb(REFERENCE_URL);

void setup() {
  Serial.begin(9600);
  Serial.println("Setting Up Stuff");

  if (!BLE.begin()) {
    Serial.println("Starting BLE failed!");
    while (1);
  }

  BLE.setLocalName("Prairie Patrol Trap");
  BLE.setAdvertisedService(customService);

  BLE.setLocalName("ArduinoR4");          // Set device name
  BLE.setAdvertisedService(customService); // Set the service to advertise
}

void loop() {
  BLEDevice central = BLE.central();

  // If a central device connects
  if (central) {
    Serial.print("Connected to central: ");
    Serial.println(central.address());

    while (central.connected()) {
      // If data is written to the characteristic
      if (customCharacteristic.written()) {
        String receivedData = customCharacteristic.value();
        Serial.print("Received: "+receivedData);

        // Optionally, respond back
        customCharacteristic.writeValue("Got: " + receivedData);
      }
    }

    Serial.print("Disconnected from central: ");
    Serial.println(central.address());
  }
}

void RFIDSetup(){
  SPI.begin();
  rfid.PCD_Init();
}

void printHex(byte *buffer, byte bufferSize) {
    for (byte i = 0; i < bufferSize; i++) {
        Serial.print(buffer[i] < 0x10 ? " 0" : " ");
        Serial.print(buffer[i], HEX);
    }
}