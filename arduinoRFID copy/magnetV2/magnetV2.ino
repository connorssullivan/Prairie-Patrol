#include "secrets.h"
#include <Firebase.h>
#include <SPI.h>
#include <MFRC522.h>

#define MAGNET_LOCK 5
#define RST_PIN 9
#define SS_PIN 10

MFRC522 rfid(SS_PIN, RST_PIN);
MFRC522::MIFARE_Key key;
Firebase fb(REFERENCE_URL);

const String JUDES_FOLDER = "JudesFolder";
String getPath(const String& folder, const String& subfolder) {
  return folder + "/" + subfolder;
}

String selectedDogRFID;

void setup() {
  Serial.begin(9600);
  delay(500);
  Serial.println("Setting Up Stuff");

  RFIDSetup();
  Serial.println("RFID Ready");

  pinMode(MAGNET_LOCK, OUTPUT);
  digitalWrite(MAGNET_LOCK, LOW);
  Serial.println("Magnet OFF");

  WiFi.disconnect();
  delay(500);
  Serial.println("Connecting to Network: ");
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print("-");
    delay(500);
  } 
  Serial.println("\nNetwork Connected");
  selectedDogRFID = fb.getString(getPath(JUDES_FOLDER, "selectedDog") + "/rfid");
}

void loop() {
  bool tA = fb.getBool(getPath(JUDES_FOLDER, "selectedDog")+"/trapActive");
  bool tO = fb.getBool(getPath(JUDES_FOLDER, "selectedDog")+"/trapOpen");
  bool automatic = fb.getBool(getPath(JUDES_FOLDER, "selectedDog")+"/auto");

  if(tA&&tO) {
    if(digitalRead(MAGNET_LOCK) == LOW){
      digitalWrite(MAGNET_LOCK, HIGH);
    }
    Serial.println("Active Trap");
    if(rfid.PICC_IsNewCardPresent()) {
      if(rfid.PICC_ReadCardSerial())  {
        String scannedRFID = "";
        for(byte i = 0; i < rfid.uid.size; i++) {
          scannedRFID += String(rfid.uid.uidByte[i], HEX);
        }
        Serial.println("Scanned RFID Tag: "+scannedRFID);
        if(scannedRFID.equalsIgnoreCase(selectedDogRFID)) {
          if(automatic) {
            digitalWrite(MAGNET_LOCK, LOW);
            Serial.println("Magnet OFF");
            fb.setBool(getPath(JUDES_FOLDER, "selectedDog") + "/trapOpen", false);
          } else{
            Serial.println("this would send notification to phone");// this would send notification to phone
          }
          delay(500);
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
  else
  {
    digitalWrite(MAGNET_LOCK, LOW);
  }
  delay(2000);
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
