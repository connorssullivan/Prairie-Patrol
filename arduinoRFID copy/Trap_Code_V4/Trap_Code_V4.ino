#include "secrets.h"
#include <SPI.h>
#include <WiFi.h>
#include <Firebase.h>
#include <ArduinoJson.h>
#include <EEPROM.h>
#include <Adafruit_Keypad.h>
#include <LiquidCrystal_I2C.h>
#include <string>
#include <Rfid134.h>

unsigned long prevMill = 0;
const long timeChange = 1000;
unsigned long prevMillBatt = 0;
const long timeChangeBatt = 60000;
bool blank = false;

const int runningVolt = 12;
const int minVolt = 8;
const float res1 = 7000;
const float res2 = 5000;

#define MAGNET_LOCK 2 // Sets magnet signal pin
#define ANALOG_PIN A0

const byte ROWS = 4;//sets how many rows
const byte COLS = 3;//sets how many columns
char keys[ROWS * COLS] = {// keypad layout character
  '2','3','A',
  '5','6','B',
  '8','9','C',
  '0','#','D'
};

//description of pad names/function
//   '2','Exit',up,
//   '5','back','select',
//   '8','Mag I/O','down',
//   '0','Reset','enter'

byte rowPins[ROWS] = {13, 12, 11, 10};// sets row pins
byte colPins[COLS] = {9, 8, 7};//sets column pins

Adafruit_Keypad customKeypad = Adafruit_Keypad(makeKeymap(keys), rowPins, colPins, ROWS, COLS);//setups keypad from library for use as the controller

// const int rs = 12, en = 11, d4 = 7, d5 = 6, d6 = 4, d7 = 2;//labels pinouts for the lcd
// LiquidCrystal lcd(A0,A1,A2,A3,A4,A5);// lcd pinout setup

LiquidCrystal_I2C lcd(0x27,  16, 2);

byte invertedBlank[8] = {
  B11111,
  B11111,
  B11111,
  B11111,
  B11111,
  B11111,
  B11111,
  B11111
};

byte mode = 0; // global variable which mode the trap is in

char characterList[] = {'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z',//setups the character list for user to select through for setup mode
                        'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z',
                        '0','1','2','3','4','5','6','7','8','9',
                        '!','#','$','%','&','\'','(',')','*','+','-','.','/',':',';','<','>','?','@','[',']','^','_','`','{','|','}','~','„','“',','};

Firebase fb(REFERENCE_URL);//setups base firebase connection with reference url 

String scannedTag = "";
String ll_toString(long long);

class rfidScan {
  public: 
    static void OnError(Rfid134_Error code) {
      Serial.print("Error Code: ");
      Serial.println(code);
    }

    static void OnPacketRead(const Rfid134Reading& reading) {
      long long tempScanned = (reading.country * 1000000000000) + reading.id;
      scannedTag = ll_toString(tempScanned);
      Serial.println(scannedTag);
    }
};

Rfid134<HardwareSerial, rfidScan> rfid(Serial1);
//SoftwareSerial secondarySerial(10, 11); // RX, TX
//Rfid134<SoftwareSerial, rfidScan> rfid(secondarySerial);

//list of functions to initialize
void magnetONOFF();
void selectMode();
void enterWiFi();
void settingMode();
void menuSelection();
void textMode(bool&, bool&, String&, int&);
void saveWifiCredentials(String, String);
void readWifiCredentials(String&, String&);
void trapSetup();
void trapMode();
void wifiSetup();
void selectedDogsRFID();
void setInTrap();
void updateDB();
void printText(String);
int getPercent();
void settingDisplay(int&);
void selectSetting(int);
void battCheck(); 

//setups the essential functions first
void setup() {
  Serial.begin(9600);//to read from arduino ide
  Serial1.begin(9600, SERIAL_8N2);
  rfid.begin();
  pinMode(MAGNET_LOCK, OUTPUT);//setups up pinout as an output
  pinMode(ANALOG_PIN,INPUT_PULLUP);
  digitalWrite(MAGNET_LOCK, LOW);//sets it to low to keep it off
  lcd.init();
  lcd.backlight();
  lcd.setCursor(0, 0);//sets cursor
  lcd.print("Prairie Patrol");//prints name of project
  delay(2000);
  lcd.clear();//clears lcd
  lcd.setCursor(0, 0);
  lcd.print("Select Mode");
  Serial.println("All Set up!");
  customKeypad.begin();// begins reading the keypad
  lcd.createChar(0, invertedBlank);
}

//loops as the main menu 
void loop() {
  menuSelection();
}

//function to control main menu, and to allow user to select which mode to enter
void menuSelection(){
  String ssid, password;
  customKeypad.tick();//gets any input if a button is pressed or not
  while (customKeypad.available()) {//sees if a button was pressed 
    keypadEvent e = customKeypad.read();//reads what the key should be on the layout
    char Key = (char)e.bit.KEY;//converts key to a char to be read

    if (e.bit.EVENT == KEY_JUST_PRESSED) {//recognizes that the key was just pressed
      Serial.println("Button pressed: " + String(Key));//outputs what key was pressed
      switch (Key) {//switch statement for char
        case 'A'://A displays setup mode and sets mode to one
          mode = 1;
          lcd.clear();
          lcd.setCursor(0, 0);
          lcd.print("Settings");
          break;
        case 'B'://Be calls the select mode to decide which mode the user enters into
          selectMode();
          break;
        case 'C'://C displays trap mode and sets mode to two
          mode = 2;
          lcd.clear();
          lcd.setCursor(0, 0);
          lcd.print("Trap Mode");
          break;
        case '9'://calls for the magnet on off function
          magnetONOFF();      
          break;  
        default:
          break;
      }
    }
  }
}

//function to set magnet on/off when called
void magnetONOFF() {
  if(digitalRead(MAGNET_LOCK) == LOW)//sees if the magnet is on or off at the moment
    digitalWrite(MAGNET_LOCK, HIGH);//turns it on
  else
    digitalWrite(MAGNET_LOCK, LOW);//turns it off
}

//function to enter which mode the user wants
void selectMode() {
  Serial.println("selectmode");
  switch (mode) {//case switch for mode
      case 1://enters into setting mode
        settingMode();
        break;
      case 2://enters into trapmode/setup
        trapSetup();
        break;
      default:
        break;
    }
  Serial.println("Mode: " + mode);//displays mode to ide
}

void settingMode() {
  Serial.println("settings");
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Wifi Setup");
  int settingMenu = 0;
  while(true) {
    customKeypad.tick();//gets any input if a button is pressed or not
    while (customKeypad.available()) {//sees if a button was pressed 
      keypadEvent e = customKeypad.read();//reads what the key should be on the layout
      char Key = (char)e.bit.KEY;//converts key to a char to be read

      if (e.bit.EVENT == KEY_JUST_PRESSED) {//recognizes that the key was just pressed
        Serial.println("Button pressed: " + String(Key));//outputs what key was pressed
        switch (Key) {//switch statement for char
          case 'A'://A displays setup mode and sets mode to one
            settingMenu--;
            settingDisplay(settingMenu);
            break;
          case 'B'://Be calls the select mode to decide which mode the user enters into
            selectSetting(settingMenu);
            settingDisplay(settingMenu);
            break;
          case 'C'://C displays trap mode and sets mode to two
            settingMenu++;
            settingDisplay(settingMenu);
            break;
          case '9'://calls for the magnet on off function
              magnetONOFF();      
              break;  
          case '3':
              mode=0;
              lcd.clear();
              lcd.setCursor(0, 0);
              lcd.print("Select Mode");     
              return; 
              break;  
          default:
            break;
        }
      }
    }
  }
}

//function to enter in wifi settings for trap to connect to wifi 
void enterWiFi() {   
  Serial.println("wifi setup");
  bool on1 = true;//setups up variables for menu control
  bool on2 = true; 
  String ssid = "a";//variables to hold wifi ssid and password temp
  String  password = "a";
  int pos = 0;//sets up position of character

  lcd.clear();// tells user to enter wifi password
  lcd.setCursor(0, 0);
  lcd.print("Enter SSID:");
  
  while(on1)// keeps going until user is finished entering the ssid
    textMode(on1, on2, ssid, pos);//call to textmode with reference

  if(on2) {
    lcd.clear();// tells user to enter wifi password
    lcd.setCursor(0, 0);
    lcd.print("Enter Password:");
  }
  else
    on1=true;

  while(on2)// keeps going until user is finished entering the password
    textMode(on1, on2, password, pos);

  if(!on1 && !on2) {//sees if the user wanted to exit instead of keep on going
    saveWifiCredentials(ssid, password);//saves the wifi credentials

    lcd.clear();//tells user setup is done and goes back to setup mode
    lcd.setCursor(0, 0);
    lcd.print("Setup Done");
    delay(1000);
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Select Mode");
  }
}

//function to let user enter in text info for wifi
void textMode(bool &on1, bool &on2, String &text, int &pos) {
  unsigned long currMill = millis();
  
  lcd.setCursor(0, 1);//shows the current text
  if (currMill - prevMill >= timeChange) {
    prevMill = currMill;
    blank = !blank;

    if (blank) {
      lcd.print(text.substring(0, text.length()-1));
      lcd.write(byte(0));
    }
    else {
      lcd.print(text);
    }
  }

  customKeypad.tick(); //sees if key is pressed
  while (customKeypad.available()) {//sees if ones was pressed
    keypadEvent e = customKeypad.read();//gets char from layout
    char Key = (char)e.bit.KEY;//converts to regula char

    if (e.bit.EVENT == KEY_JUST_PRESSED) {//see if key was just pressed
      Serial.println("Button pressed: " + String(Key));//prints key to ide
      switch (Key) {//exits setup mode entirely
      case '3':
        if(on1)//checks to see if we are in the ssid or password section from the setupMode function when it wass called
          on1=false;//turns false if we are ssid section
        else
          on1=true;//turns true to allow setupMode function to detect while in the password section if user wants to exit at that moment
        on2=false;//turns false regardless, but more important while in ssid section
        mode = 0;//sets mode back to 0
        break;
      case 'A'://moves the character up by one, but goes back to the beginning once we reach the end of the list
        pos++;//updates current position
        if(pos==94){//resets to beginning
          pos=0;
        }
        text.remove(text.length()-1);//gets rid of old character
        text+=characterList[pos];//adds in the next character
        printText(text);
        break;
      case 'B'://lets enter select current character
        if (text[text.length()-1] != ' ') { 
          text+=" ";//setup the text for the next character
          pos = -1;//resets position
          printText(text);
        }
        break;
      case 'C'://moves the character down by one, but goes back to the end once we reach the beginning of the list
        pos--;//updates current position
        if(pos<=-1){//resets to end
          pos=93;
        }
        text.remove(text.length()-1);//gets rid of old character
        text+=characterList[pos];//adds in the next character
        printText(text);
        break;
      case '#'://resets text and setup lcd
        text=" ";//resets text
        pos = -1;//resets pos
        lcd.clear();//resets lcd to be clear of old text
        lcd.setCursor(0, 0);
        if(on1)//checks which section we are in setupMode
          lcd.print("Enter SSID:");
        else
          lcd.print("Enter Password:");
        printText(text);
        break;
      case 'D'://this is called when user wants a the current text to be used for the ssid or password
        if(on1)//tells the setup mode when to end loop in current section
          on1=false;
        else
          on2=false;
        text.remove(text.length()-1);//gets rid of extra chracter used for text
        pos=-1;
        break;
      case '6'://removes one chracter from current text
        if(text.length()>1){//only removes if there is more than one chracter
          text.remove(text.length()-1);//removes the last character
          text.setCharAt(text.length()-1,' ');//replaces the last character with a space
          pos = -1;//resets pos
          lcd.clear();//displays what section we are currently on
          lcd.setCursor(0, 0);
          if(on1)//sees which mode we are on
          
            lcd.print("Enter SSID:");
          else
            lcd.print("Enter Password:");
          printText(text);
          }
          
        break;
      case '9'://turns magnet on or off
        magnetONOFF();      
        break;
      case '2'://sets character to lowercase
        pos=0;
        text.remove(text.length()-1);//gets rid of old character
        text+=characterList[pos];//adds in the next character
        printText(text);
        break;
      case '5'://sets character to Uppercase
        pos=26;
        text.remove(text.length()-1);//gets rid of old character
        text+=characterList[pos];//adds in the next character
        printText(text);
        break;
      case '8'://sets character to numbers
        pos=52;
        text.remove(text.length()-1);//gets rid of old character
        text+=characterList[pos];//adds in the next character
        printText(text);
        break;   
      case '0'://sets character to speacial chracter
        pos=62;
        text.remove(text.length()-1);//gets rid of old character
        text+=characterList[pos];//adds in the next character
        printText(text);
        break;     
      default:
        break;
      }
    }
  }
}

 
void trapSetup() {
  Serial.println("trapSetup");
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Set Magnet");
  while(true) {
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
          mode = 0;
          lcd.clear();
          lcd.setCursor(0, 0);
          lcd.print("Setup Mode");
          return;     
          break;
        case '#':
          scannedTag="";
          break;    
        case 'D':
          lcd.clear();
          lcd.setCursor(0, 0);
          lcd.print("Wifi Setup");
          if (WiFi.status() != WL_CONNECTED)
            WifiSetup();
          lcd.clear();
          lcd.setCursor(0, 0);
          lcd.print("Trap Ready");
          delay(1000);
          lcd.noBacklight();
          scannedTag="";
          // fb.setBool("/selectedDog/trapActive", true);
          // fb.setBool("/selectedDog/trapOpen", true);
          trapMode();  
          lcd.backlight();
          lcd.clear();
          lcd.setCursor(0, 0);
          lcd.print("Set Magnet"); 
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
  while(true) {
    battCheck();
    rfid.loop();
    if(scannedTag != "") {
      // bool tA = fb.getBool("/selectedDog/trapActive");
      // bool tO = fb.getBool("/selectedDog/trapOpen");
      // bool intrap = fb.getBool("/dogs/-OOi7FTzu2Efi5Tacw8f/inTrap");

      // if(tA&&tO) {
      //   Serial.println("Active Trap");
      //   selectedDogsRFID();
      // }
      // else if (!intrap&&!tO) {
      //   Serial.println("catching dog");
      //   digitalWrite(MAGNET_LOCK, LOW);
      //   scannedTag = "";
      // }

      selectedDogsRFID();
      scannedTag = "";
    }

    customKeypad.tick();
    while (customKeypad.available()) {
      keypadEvent e = customKeypad.read();
      char Key = (char)e.bit.KEY;

      if (e.bit.EVENT == KEY_JUST_PRESSED) {
        Serial.println("Button pressed: " + String(Key));
        switch (Key) {
          case '3':
            return;
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

void selectedDogsRFID() {
  String listRfid = fb.getString("/selectedDog/listRfid");

  if (listRfid.length() > 0) {
    Serial.println("Retrieved RFID list from Firebase: " + listRfid);

    listRfid.replace("[", "");
    listRfid.replace("]", "");
    listRfid.replace("\"", "");

    int startIndex = 0;
    while (startIndex >= 0) {
      int endIndex = listRfid.indexOf(',', startIndex);
      String rfidTag;
      if (endIndex == -1) {
        rfidTag = listRfid.substring(startIndex);
      } else {
        rfidTag = listRfid.substring(startIndex, endIndex);
      }

      rfidTag.trim();
      if (rfidTag.c_str() == scannedTag) {
        Serial.println("RFID match found!");
        setInTrap();
        digitalWrite(MAGNET_LOCK, HIGH);
        delay(1000);
        digitalWrite(MAGNET_LOCK, LOW);
      } else {
        Serial.println("No matching RFID found.");
      }
      if (endIndex == -1) {
        startIndex = -1;
      } else 
        startIndex = endIndex + 1;
    }
  } else 
    Serial.println("Failed to get RFID list from Firebase or list is empty.");
}


void setInTrap() {
  // String listRfid = fb.getString("/dogs");
  // StaticJsonDocument<200> doc;
  // DeserializationError error = deserializeJson(doc, listRfid);
  // String path;
 
  // for (JsonPair keyValue : doc.as<JsonObject>()) {
  //   String name = String(keyValue.key().c_str());
  //   String rfid = keyValue.value()["rfid"];
  //   Serial.println("Name:"+ name + "|");
  //   Serial.println("rfid:"+ rfid);

  //   if (rfid == scannedTag)
  //     path = "/dogs/" + name +"/inTrap";

  // }
  //bool success fb.setBool(path, true);
  //fb.setBool(path, true);
  // updateDB();

  fb.setString("/caughtDog", scannedTag);

  // fb.setBool("/dogs/-OOi7FTzu2Efi5Tacw8f/inTrap", true);
  // bool success = fb.setBool("/dogs/-OOYqEXmieJh0-MXi6eG/inTrap", true);
  // updateDB();
  scannedTag = "";
}


// void updateDB() {
//   bool automatic = fb.getBool("/selectedDog/auto");
//   if(automatic) {
//     //fb.setBool("/selectedDog/trapOpen", false);
//     Serial.println("Magnet OFF");
//   }
//   fb.setBool("/selectedDog/trapOpen", false);

// }

//Function to write and save the wifi credentials
void saveWifiCredentials(String ssid, String password) {
  for (int i = 0; i < ssid.length(); i++) {//enters the ssid into the eeprom to read later
    EEPROM.write(i, ssid[i]);
  }
  EEPROM.write(ssid.length(), '\0');//writes the end of ssid

  int offset = ssid.length() + 1;//sets offset
  for (int i = 0; i < password.length(); i++) {//enters the password into the eeprom to read later
    EEPROM.write(offset + i, password[i]);
  }
  EEPROM.write(offset + password.length(), '\0');//writes the end of password
}

//Function to read the saved wifi credentials
void readWifiCredentials(String &ssid, String &password) {
  char buffer[50];//an array to hold credential data

  int i = 0;//track which position we are in
  while (true) {//reapeats forever
    buffer[i] = EEPROM.read(i);//reads from eeprom
    if (buffer[i] == '\0')//stops if it is the end
      break;
    i++;//increaes pos
  }
  ssid = String(buffer);//sets ssid

  int offset = i + 1;//sets pos offset
  i = 0;
  strcpy(buffer, "");//clears buffer
  while (true) {//keeps going on forever
    buffer[i] = EEPROM.read(offset + i);//reads from eeprom
    if (buffer[i] == '\0') //stops if it is the end
      break;
    i++;//increaes pos
  }
  password = String(buffer);//sets password
}

void printText(String text) {
  lcd.setCursor(0, 1);//shows the current text
  lcd.print(text);
  prevMill=millis();
  blank=false;
}

int getPercent(){
  int readValue = analogRead(A0);
  float temp = readValue * (5.0/1024);
  float voltage = temp * ((res1+res2)/res2);

  if (voltage < minVolt) 
    voltage = 0;
  else if (voltage > runningVolt)
    voltage = runningVolt;

  Serial.println(voltage);
  int percent = ((voltage-minVolt)/(runningVolt-minVolt))*100;
  Serial.println(percent);
  if (WiFi.status() == WL_CONNECTED) 
    fb.setInt("/Config/BatteryLife", percent);

  return percent; 
}

void settingDisplay(int &displayMode) {
  if (displayMode < 0) {
    displayMode = 0;
    return;
  }
  else if (displayMode > 3) {
    displayMode = 3;
    return;
  }

  lcd.clear();
  lcd.setCursor(0, 0);
  if (displayMode == 0) 
    lcd.print("Wifi Setup");
  else if(displayMode == 1){
    int percent = getPercent();
    lcd.print("Battery: ");
    lcd.print(percent);
    lcd.print("%");
  }
  else if(displayMode == 2) {
  String ssid, password;
    readWifiCredentials(ssid, password);
    password="";
    lcd.print("Connected SSID:");
    lcd.setCursor(0, 1);
    lcd.print(ssid);
  }
  else if (displayMode == 3){
    if (WiFi.status() != WL_CONNECTED) {
      lcd.print("Disconnected");
      lcd.setCursor(0, 1);
      lcd.print("Connect?");
    }
    else {
      lcd.print("Connected");
      lcd.setCursor(0, 1);
      lcd.print("Disconnect?");
    }
  }
}

void selectSetting(int settingMenu) {
  if (settingMenu == 0) 
    enterWiFi();
  else if (settingMenu == 3) {
    if (WiFi.status() != WL_CONNECTED) 
      WifiSetup();
    else
      WiFi.disconnect();
  }
}

void WifiSetup() {
  String ssid, password;
  readWifiCredentials(ssid, password);
  WiFi.begin(ssid.c_str(), password.c_str());
  //WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
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

String ll_toString(long long long_Num) {
  String numString = "";
  do {
    numString = int(long_Num%10) + numString;
    long_Num /= 10;
  } while (long_Num != 0);
  return numString;
}

void battCheck() {
  unsigned long currMill = millis();
  if (currMill - prevMillBatt >= timeChangeBatt) {
    prevMillBatt = currMill;
    int temp = getPercent();
  }
}