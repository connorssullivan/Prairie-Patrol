#include <SoftwareSerial.h>
#include <Rfid134.h>
#include <string>
#include <ArduinoJson.h>
#include <EEPROM.h>
#include <SPI.h>
//# include "secrets.h"
#include <Firebase.h> 
//#include "C:\Users\ang06\Desktop\426proj\Prairie-Patrol\ashFold\lowFreqRFID\lfFirebase\RDM6300firebase\secrets.h"

////////////////////////////////////////////////////////////////////////////////
 // stuff for RFID:
 
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

///////////////////////////////////////////////////////////////////////////////////////////////
//relay pin connection:
int relayPin=2; //white relay in connected to aruino pin 2

//Other variables
bool isCaught, isOpen,magnetOn;  //has the dog been caught yet, is the cage open, is the magnet on 



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
//SELECTED DOG LIST
 // Max number of RFIDs expected
const int MAX_DOGS = 10; 
String selectedDogs[MAX_DOGS];
int numSelectedDogs = 0;

/////////////////////////////////////////////
void setup() 
{
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
//rfid setup 
 Serial1.begin(9600, SERIAL_8N2); // 8 data bits, no parity, 2 stop bits
  rfid.begin(); // Initialize RFID reader




//this is setting up the cage and dog settings:
 pinMode(relayPin, OUTPUT);
 // selectedDogRFID = "428767048"; //bird tag ID nuber 
 // selectedDogRFID = 428767048;
 //  selectedDogRFID = fb.getInt("AshleysFolder/selectedDog/rfid"); //this is what was used when there was only 1 selected dog
  //   Serial.print("Selected Dog RFID: ");
  //  Serial.println(selectedDogRFID);


  fb.setBool("AshleysFolder/cageStatus/magnetOn", true);
   fb.setBool("AshleysFolder/cageStatus/isOpen", true);
  fb.setBool("AshleysFolder/selectedDog/isCaught", false); 

    // get the other variable values from firebase
  isCaught = fb.getBool("AshleysFolder/selectedDog/isCaught");  
   isOpen=fb.getBool("AshleysFolder/cageStatus/isOpen"); 
  magnetOn= fb.getBool("AshleysFolder/cageStatus/magnetOn"); 
       
  digitalWrite(relayPin, HIGH); //magnets r on-->door is up  
//////////////////////////////////////////////////////////////////////////


//This code is strictly for reading the battery charge *IGNORE FOR RIGHT NOW*
// -- still experimenting with this  
  // Define the analog input pin
  int batteryPin = A0; // Analog pin to measure the voltage
  float voltage = 0.0;  // Variable to store the measured voltage
  // Read the analog value from the battery
  int sensorValue = analogRead(batteryPin);

  // Convert the sensor value to voltage
  voltage = sensorValue * (5.0 / 1023.0);
  // Print the voltage to the serial monitor
  Serial.print("Battery Voltage: ");
  Serial.print(voltage);
  Serial.println(" V");

  // Wait for a short time before reading again
  delay(1000);
//////////////////////////////////////////////////////////////////////////////////
  getRFIDList();

  
  Serial.println("INIT DONE");
///////////////////////////////////////////////////////////////////////////////////////////
  
}


void loop()
{

  // get the other variable values from firebase
//  isCaught = fb.getBool("AshleysFolder/selectedDog/isCaught");  
 // isOpen=fb.getBool("AshleysFolder/cageStatus/isOpen"); 
 // magnetOn= fb.getBool("AshleysFolder/cageStatus/magnetOn"); 

    rfid.loop(); // Continuously check for RFID scans

  // Example use of the tag
  if (scannedTag != "") {
    Serial.println("RFID Tag Detected: " + scannedTag);
    
 //*AT THIS POINT TAG IN THE CODE IS READ AND IS ABOUT TO BE CHECKED IF IT MATCHES THE SELECTED DOG TAG*
    //   if (scannedTag == a selectedDogRFID)
    for(int i =0; i <numSelectedDogs; i++)
    {
      if(scannedTag==selectedDogs[i]){
        Serial.println("A SELECTED DOG HAS BEEN SCANNED");
        
      //updates values in firebase
       /* magnetOn=false; 
        isOpen=false; 
        isCaught=true; 
        */
          digitalWrite(relayPin, LOW); //turn magnet off if selected tag is detected

          fb.setBool("AshleysFolder/cageStatus/magnetOn", false); 
          fb.setBool("AshleysFolder/cageStatus/isOpen", false); 
          fb.setBool("AshleysFolder/selectedDog/isCaught", true);
     
          return; //stop looping-- dog has been caught 
      }
    }
       
            
        scannedTag = ""; // Clear tag after reading
  } 
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
