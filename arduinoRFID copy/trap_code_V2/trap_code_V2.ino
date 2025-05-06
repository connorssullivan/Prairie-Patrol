#include "secrets.h"
#include <SPI.h>
#include <WiFi.h>
#include <Firebase.h>
#include <MFRC522.h>
#include <ArduinoJson.h>
#include <EEPROM.h>
#include <Adafruit_Keypad.h>
#include <LiquidCrystal.h>


#define MAGNET_LOCK 2
#define SS_PIN 4
#define RST_PIN 5
#define MAGNET_PIN 3


const byte ROWS = 4;
const byte COLS = 4;
char keys[ROWS * COLS] = {
  '1','2','3','A',
  '4','5','6','B',
  '7','8','9','C',
  '*','0','#','D'
};

//   '1','2','Exit',up,
//   '4','5','back','select',
//   '7','8','Mag I/O','down',
//   '*','0','Reset','enter'

byte rowPins[ROWS] = {13, 12, 11, 10};
byte colPins[COLS] = {9, 8, 7, 6};


Adafruit_Keypad customKeypad = Adafruit_Keypad(makeKeymap(keys), rowPins, colPins, ROWS, COLS);


const int rs = 12, en = 11, d4 = 7, d5 = 6, d6 = 4, d7 = 2;
LiquidCrystal lcd(A0,A1,A2,A3,A4,A5);


int mode = 0;


char characterList[] = {'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z',
                        'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z',
                        '!','#','$','%','&','\'','(',')','*','+','-','.','/','0','1','2','3','4','5','6','7','8','9',
                        ':',';','<','>','?','@','[',']','^','_','`','{','|','}','~','„','“',','};


MFRC522 rfid(SS_PIN, RST_PIN);
MFRC522::MIFARE_Key key;
Firebase fb(REFERENCE_URL);


const String JUDES_FOLDER = "JudesFolder";

void WifiSetup();
String getPath(const String& folder, const String& subfolder);
void RFIDSCAN();

void magnetONOFF() {
  if(digitalRead(MAGNET_LOCK) == LOW)
  digitalWrite(MAGNET_LOCK, HIGH);
  else
  digitalWrite(MAGNET_LOCK, LOW);
}

void setup() {
  Serial.begin(9600);
  pinMode(MAGNET_LOCK, OUTPUT);
  digitalWrite(MAGNET_LOCK, LOW);
  lcd.begin(16, 2);
  lcd.setCursor(0, 0);
  lcd.print("Prairie Patrol");
  delay(2000);
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Select Mode");
  Serial.println("All Set up!");
  customKeypad.begin();
}

void loop() {
  Serial.println("Loop");
  customKeypad.tick();
  while (customKeypad.available()) {
    keypadEvent e = customKeypad.read();
    char Key = (char)e.bit.KEY;


    if (e.bit.EVENT == KEY_JUST_PRESSED) {
      Serial.println("Button pressed: " + String(Key));
      switch (Key) {
        case 'A':
          mode = 1;
          lcd.clear();
          lcd.setCursor(0, 0);
          lcd.print("Setup Mode");
          break;
        case 'B':
          selectMode();
          break;
        case 'C':
          mode = 2;
          lcd.clear();
          lcd.setCursor(0, 0);
          lcd.print("Trap Mode");
          break;
        case '9':
            magnetONOFF();      
            break;  
        default:
          Serial.println(Key);
          break;
      }
    }
  }
}


void selectMode() {
  Serial.println("selectmode");
  switch (mode) {
      case 1:
        setupMode();
        break;
      case 2:
        trapSetup();
        break;
      default:
        break;
    }
  Serial.println(mode);
}


void setupMode() {   
  Serial.println("setup"); 
  bool on1 = true;
  bool on2 = true;
  String ssid = "";
  String  password = "";
  String text = " ";
  int pos = -1;
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Enter Wifi SSID:");


  while(on1){
   
    lcd.setCursor(0, 1);
    lcd.print(text);

    customKeypad.tick(); 
    while (customKeypad.available()) {
      keypadEvent e = customKeypad.read();
      char Key = (char)e.bit.KEY;


      if (e.bit.EVENT == KEY_JUST_PRESSED) {
        Serial.println("Button pressed: " + String(Key));
        switch (Key) {
        case '3':
          on1=false;
          on2=false;
          break;
        case 'A':
          pos++;
          if(pos==94){
            pos=0;
          }
          text.remove(text.length()-1);
          text+=characterList[pos];
          break;
       case 'B':
          text+=" ";
          pos = -1;
          lcd.clear();
          lcd.setCursor(0, 0);
          lcd.print("Enter Wifi SSID:");
          break;
        case 'C':
        pos--;
          if(pos<=-1){
            pos=93;
          }
          text.remove(text.length()-1);
          text+=characterList[pos];
          break;
        case '#':
          text=" ";
          pos = -1;
          break;
        case 'D':
          on1=false;
          text.remove(text.length()-1);
          ssid = text;
          text=" ";
          pos=-1;
          break;
        case '6':
          if(text.length()>1){
            text.remove(text.length()-1);
            pos = -1;
          }
          break;
        case '9':
            magnetONOFF();      
            break;  
        default:
          break;
       }
      }
    }
  }
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Enter Password:");
  while(on2){
    lcd.setCursor(0, 1);
    lcd.print(text);

    customKeypad.tick();
    while (customKeypad.available()) {
      keypadEvent e = customKeypad.read();
      char Key = (char)e.bit.KEY;


      if (e.bit.EVENT == KEY_JUST_PRESSED) {
        Serial.println("Button pressed: " + String(Key));
        switch (Key) {
        case '3':
          on2=false;
          break;
        case 'A':
          pos++;
          if(pos==94){
            pos=0;
          }
          text.remove(text.length()-1);
          text+=characterList[pos];
          break;
        case 'B':
          text+=' ';
          pos = -1;
          break;
        case 'C':
        pos--;
          if(pos<=-1){
            pos=93;
          }
          text.remove(text.length()-1);
          text+=characterList[pos];
          break;
        case '#':
          text=" ";
          pos = -1;
          lcd.clear();
          lcd.setCursor(0, 0);
          lcd.print("Enter Password:");
          break;
        case 'D':
          on2=false;
          text.remove(text.length()-1);
          password = text;
          break;
        case '6':
          if(text.length()>1){
            text.remove(text.length()-1);
            pos = -1;
          }
          break;
        case '9':
            magnetONOFF();      
            break;  
        default:
          break;
        }
      }
    }
  }


  for (int i = 0; i < ssid.length(); i++) {
    EEPROM.write(i, ssid[i]);
  }
  EEPROM.write(ssid.length(), '\0');


  int offset = ssid.length() + 1;
  for (int i = 0; i < password.length(); i++) {
    EEPROM.write(offset + i, password[i]);
  }
  EEPROM.write(offset + password.length(), '\0');
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Setup Done");
  delay(1000);
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Select Mode");
}

void trapSetup() {
  Serial.println("trapSetup");
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Set Magnet");
  bool on=true;
  while(on) {
    customKeypad.tick();
      while (customKeypad.available()) {
        keypadEvent e = customKeypad.read();
        char Key = (char)e.bit.KEY;

        if (e.bit.EVENT == KEY_JUST_PRESSED) {
          Serial.println("Button pressed: " + String(Key));
          switch (Key) {
          case '9':
            magnetONOFF();      
            break;  
          case '3':
            on=false;     
            break;  
          case 'D':
            on=false; 
            lcd.clear();
            lcd.setCursor(0, 0);
            lcd.print("Wifi Setup");
            WifiSetup();
            //SPI.begin();
            //rfid.PCD_Init();
            lcd.clear();
            lcd.setCursor(0, 0);
            lcd.print("Trap Ready");
            mode = 0;
            //lcd.noDisplay();    
            break;       
          default:
            break;
        }
      }
    }
  }  
}





void trapMode() {
  Serial.println("trapMode");
  bool on = true;
  while(on) {
    bool tA = fb.getBool(getPath(JUDES_FOLDER, "selectedDog")+"/trapActive");
    bool tO = fb.getBool(getPath(JUDES_FOLDER, "selectedDog")+"/trapOpen");


    if(tA&&tO) {
      // if(digitalRead(MAGNET_LOCK) == LOW){
      //   digitalWrite(MAGNET_LOCK, HIGH);
      // }
      Serial.println("Active Trap");
      RFIDSCAN();
    // } else  {
    //   digitalWrite(MAGNET_LOCK, LOW);
    }

    customKeypad.tick();
    while (customKeypad.available()) {
      keypadEvent e = customKeypad.read();
      char Key = (char)e.bit.KEY;

      if (e.bit.EVENT == KEY_JUST_PRESSED) {
        Serial.println("Button pressed: " + String(Key));
        switch (Key) {
          case '3':
            on=false;
            mode = 0;
            lcd.display();
            lcd.clear();
            lcd.setCursor(0, 0);
            lcd.print("Select Mode");
            break;
          case '9':
            magnetONOFF();      
            break;  
          default:
            break;
          }
      }
    }    
  }
}


void RFIDSCAN() {
  if(rfid.PICC_IsNewCardPresent()) {
    Serial.println("test");
    if(rfid.PICC_ReadCardSerial())  {
      String scannedRFID = "";
      for(byte i = 0; i < rfid.uid.size; i++) {
        scannedRFID += String(rfid.uid.uidByte[i], HEX);
      }
      Serial.println("Scanned RFID Tag: "+scannedRFID);
      selectedDogsRFID(scannedRFID);
      rfid.PICC_HaltA();
      rfid.PCD_StopCrypto1();
    }
  }
}


String getPath(const String& folder, const String& subfolder) {
  return folder + "/" + subfolder;
}


void selectedDogsRFID(String scannedTag) {
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
        setInTrap(scannedTag);
        updateDB();
      } else {
        Serial.println("No matching RFID found.");
      }
      startIndex = (endIndex == -1) ? -1 : endIndex + 1;
    }
  } else {
    Serial.println("Failed to get RFID list from Firebase or list is empty.");
  }
}


void printHex(byte *buffer, byte bufferSize) {
    for (byte i = 0; i < bufferSize; i++) {
        Serial.print(buffer[i] < 0x10 ? " 0" : " ");
        Serial.print(buffer[i], HEX);
    }
}


void setInTrap(String scannedTag) {
  String listRfid = fb.getString(getPath(JUDES_FOLDER, "dogs"));
  StaticJsonDocument<200> doc;
  DeserializationError error = deserializeJson(doc, listRfid);
 
  for (JsonPair keyValue : doc.as<JsonObject>()) {
    String name = keyValue.key().c_str();
    String id = keyValue.value()["rfid"];
    Serial.println("Name:"+ name);
    Serial.println("ID:"+ id);


    if (id == scannedTag) {
      String dogRfid = "/" + name + "/rfid";
      fb.setBool(getPath(JUDES_FOLDER, "dogs") + dogRfid, true);
    }
  }
}


void updateDB() {
  bool automatic = fb.getBool(getPath(JUDES_FOLDER, "selectedDog")+"/auto");
  if(automatic) {
    digitalWrite(MAGNET_LOCK, LOW);
    Serial.println("Magnet OFF");
    fb.setBool(getPath(JUDES_FOLDER, "selectedDog") + "/trapOpen", false);
  }
}


void WifiSetup() {
  String ssid, password;
  readWifiCredentials(ssid, password);
  WiFi.begin(ssid.c_str(), password.c_str());




  unsigned long timer = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - timer < 10000) {
      delay(500);
  }
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("WiFi Connected!");
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Wifi Connected");
  } else {
    Serial.println("Failed to connect.");
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Error:");
    lcd.setCursor(0, 1);
    lcd.print("Wifi failed");
  }
  delay(1000);
}


void saveWifiCredentials(String ssid, String password) {
  for (int i = 0; i < ssid.length(); i++) {
    EEPROM.write(i, ssid[i]);
  }
  EEPROM.write(ssid.length(), '\0');


  int offset = ssid.length() + 1;
  for (int i = 0; i < password.length(); i++) {
    EEPROM.write(offset + i, password[i]);
  }
  EEPROM.write(offset + password.length(), '\0');
}


void readWifiCredentials(String &ssid, String &password) {
  char buffer[50];


  int i = 0;
  while (true) {
    buffer[i] = EEPROM.read(i);
    if (buffer[i] == '\0') break;
    i++;
  }
  ssid = String(buffer);


  int offset = i + 1;
  i = 0;
  while (true) {
    buffer[i] = EEPROM.read(offset + i);
    if (buffer[i] == '\0') break;
    i++;
  }
  password = String(buffer);
}