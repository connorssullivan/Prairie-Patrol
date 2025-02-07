#include "secrets.h"
#include <SPI.h>
#include <WiFi.h>
#include <ArduinoBLE.h>
#include <Firebase.h>


BLEService connectionService("19B10000-E8F2-537E-4F6C-D104768A1214"); // Bluetooth® Low Energy LED Service 
BLEStringCharacteristic  connectionCharacteristic("19B10001-E8F2-537E-4F6C-D104768A1214", BLERead | BLEWrite, 30);


void setup() {
  Serial.begin(9600);
  Serial.println("Starting setup...");

  if (!BLE.begin()) {
    Serial.println("starting Bluetooth® Low Energy module failed!");
    while (1);
  }
  BLE.setLocalName("Trap1");
  BLE.setAdvertisedService(connectionService);
  connectionService.addCharacteristic(connectionCharacteristic);
  BLE.addService(connectionService);
  BLE.advertise();
}

void loop() {
  bluetoothConnect();
  delay(500);
}

void bluetoothConnect() {
  BLEDevice device = BLE.central();
  if (device) {
    Serial.println("Device connected");
    while(device.connected()) {
      if (connectionCharacteristic.written()) {
        if (connectionCharacteristic.value()) { 
          String value = String(connectionCharacteristic.value());
          Serial.println(value);

          int pos = value.indexOf(',');
          if (pos == -1) {
            Serial.println("Invalid format. Expected SSID,PASSWORD.");
            return;
          }
          
          String WIFI_SSIDtest = value.substring(0,pos);
          String  WIFI_PASSWORDtest = value.substring(pos+1);
          Serial.println("Received SSID: " + WIFI_SSIDtest);
          Serial.println("Received Password: " + WIFI_PASSWORDtest);
          
          WiFi.begin(WIFI_SSIDtest.c_str(), WIFI_PASSWORDtest.c_str());

          for(int i = 0; i < 4;i++){
            if(WiFi.status() != WL_CONNECTED) {
              Serial.print("-");
              delay(250);
            } else {
              Serial.println("WiFi Connected");
              break;
            }
          }
        }
      }
    }
  } else {
    Serial.println("Failed to connect to device!2");
  }
}
