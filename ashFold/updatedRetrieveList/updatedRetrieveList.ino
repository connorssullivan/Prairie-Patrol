#include <SoftwareSerial.h>
#include <Firebase.h> 
#include <string>
#include <ArduinoJson.h>
#include <EEPROM.h>
#include <SPI.h>
#include <WiFi.h>
//////////////////////////////////////////////////////////////////


//SECRETS.H ----- WIFI_SETUP

#define WIFI_SSID     "217HAYWARD" //wifiUsername
#define WIFI_PASSWORD "Chickennugget123" //wifiPassword

//#define WIFI_SSID     "SBY City Zoo" //wifiUsername
//#define WIFI_PASSWORD "" //wifiPassword

//#define WIFI_SSID     "MyNet" //wifiUsername
//#define WIFI_PASSWORD "woodford123" //wifiPassword
#define REFERENCE_URL "https://prairiepatrol-default-rtdb.firebaseio.com/" //firebaseLink

/////////////////////////////////////////////////////////////////////////////

// Firebase instance
Firebase fb(REFERENCE_URL);
  
///////////////////////////////////////////////////////////////////////////////////////

// Max number of RFIDs expected
const int MAX_DOGS = 10; 
String selectedDogs[MAX_DOGS];
int numSelectedDogs = 0;

// Initialize Firebase
//FirebaseData firebaseData;
//FirebaseJson firebaseJson;


void setup() {
  // put your setup code here, to run once:
  Serial.begin(9600);

    /////////////////////////////////////////////////////////
  //WIFI SETUP
   Serial.println("Starting setup...");

  // Disconnect any previous WiFi connections
  WiFi.disconnect();
  delay(1000);

  // Connect to WiFi
  Serial.print("Connecting to: ");
  Serial.println(WIFI_SSID);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print("-");
    delay(500);
  }
  Serial.println();
  Serial.println("WiFi Connected");
//////////////////////////////////////////////////////////////////////////////




  getRFIDList();
}
void loop() {
  // put your main code here, to run repeatedly:

}
void getRFIDList() {
  String listRfid = fb.getString("selectedDog/listRfid");

  if (listRfid.length() > 0) {
    Serial.println("Retrieved RFID list: " + listRfid);

    // Clean up JSON string
    listRfid.replace("[", "");
    listRfid.replace("]", "");
    listRfid.replace("\"", "");
    listRfid.replace("{", "");
    listRfid.replace("}", "");

    // Reset array count
    numSelectedDogs = 0;

    int start = 0;
    while (start < listRfid.length() && numSelectedDogs < MAX_DOGS) {
      int commaIndex = listRfid.indexOf(',', start);
      String entry = (commaIndex == -1)
                     ? listRfid.substring(start)
                     : listRfid.substring(start, commaIndex);
      entry.trim();

      // Get the part after the colon if present
      int colonIndex = entry.indexOf(':');
      String tag = (colonIndex != -1) ? entry.substring(colonIndex + 1) : entry;
      tag.trim();

      if (tag.length() > 0 && tag != "null") {
        selectedDogs[numSelectedDogs++] = tag;
      }

      if (commaIndex == -1) break;
      start = commaIndex + 1;
    }

    // Optional: Print all stored RFID tags
    Serial.println("Stored selected dogs:");
    for (int i = 0; i < numSelectedDogs; i++) {
      Serial.println("Dog " + String(i + 1) + ": " + selectedDogs[i]);
    }

  } else {
    Serial.println("RFID list is empty or could not be retrieved.");
  }
}
