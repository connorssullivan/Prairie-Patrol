#include "secrets.h"
#include <SPI.h>
#include <WiFi.h>
#include <ArduinoBLE.h>
#include <Firebase.h>
#include <MFRC522.h>

#define MAGNET_LOCK 5
#define SS_PIN 10
#define RST_PIN 9

MFRC522 rfid(SS_PIN, RST_PIN);
MFRC522::MIFARE_Key key;
Firebase fb(REFERENCE_URL);

#define MAGNET_PIN 5

BLEService connectionService("19B10000-E8F2-537E-4F6C-D104768A1214");
BLEStringCharacteristic  connectionCharacteristic("19B10001-E8F2-537E-4F6C-D104768A1214", BLERead | BLEWrite, 30);

const String JUDES_FOLDER = "JudesFolder";

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

  RFIDSetup();
}

void loop() {
  bluetoothConnect();
  trapMode();
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

void trapMode() {
  bool tA = fb.getBool(getPath(JUDES_FOLDER, "selectedDog")+"/trapActive");
  bool tO = fb.getBool(getPath(JUDES_FOLDER, "selectedDog")+"/trapOpen");

  if(tA&&tO) {
    if(digitalRead(MAGNET_LOCK) == LOW){
      digitalWrite(MAGNET_LOCK, HIGH);
    }
    Serial.println("Active Trap");
    void RFIDSetup();
  } else  {
    digitalWrite(MAGNET_LOCK, LOW);
  }
}

void RFIDSetup() {
  if(rfid.PICC_IsNewCardPresent()) {
    Serial.println("test");
    if(rfid.PICC_ReadCardSerial())  {
      String scannedRFID = "";
      for(byte i = 0; i < rfid.uid.size; i++) {
        scannedRFID += String(rfid.uid.uidByte[i], HEX);
      }
      Serial.println("Scanned RFID Tag: "+scannedRFID);
      if(selectedDogsRFID(scannedRFID)) {
        updateDB();
      } else {      
        Serial.print(F("Unknown RFID Tag UID: "));
        printHex(rfid.uid.uidByte, rfid.uid.size);
        Serial.println();
      }      
      rfid.PICC_HaltA();
      rfid.PCD_StopCrypto1();
    }
  }
}

void updateDB() {
  bool automatic = fb.getBool(getPath(JUDES_FOLDER, "selectedDog")+"/auto");
  if(automatic) {
    digitalWrite(MAGNET_LOCK, LOW);
    Serial.println("Magnet OFF");
    fb.setBool(getPath(JUDES_FOLDER, "selectedDog") + "/trapOpen", false);
  } else{
    Serial.println("this would send notification to phone");
  }
}

String getPath(const String& folder, const String& subfolder) {
  return folder + "/" + subfolder;
}

bool selectedDogsRFID(String scannedTag) {
  String listRfid = fb.getString(getPath(JUDES_FOLDER, "selectedDog") + "/listRfid");

  if (listRfid.length() > 0) {
    Serial.println("Retrieved RFID list from Firebase: " + listRfid);

    listRfid.replace("[", "");
    listRfid.replace("]", "");
    listRfid.replace("\"", "");

    int startIndex = 0;
    while (startIndex >= 0) {
      int endIndex = listRfid.indexOf(',', startIndex);
      String rfidTag = (endIndex == -1) ? listRfid.substring(startIndex) : listRfid.substring(startIndex, endIndex);

      rfidTag.trim();
      if (rfidTag.equalsIgnoreCase(scannedTag)) {
        Serial.println("RFID match found!");
        return true;
      }
      startIndex = (endIndex == -1) ? -1 : endIndex + 1;
    }
    Serial.println("No matching RFID found.");
    return false;
  } else {
    Serial.println("Failed to get RFID list from Firebase or list is empty.");
    return false;
  }
}

void printHex(byte *buffer, byte bufferSize) {
    for (byte i = 0; i < bufferSize; i++) {
        Serial.print(buffer[i] < 0x10 ? " 0" : " ");
        Serial.print(buffer[i], HEX);
    }
}
