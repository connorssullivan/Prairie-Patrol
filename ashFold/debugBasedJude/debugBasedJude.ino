#include <SoftwareSerial.h>
#include <Rfid134.h>

//# include "secrets.h"
#include <Firebase.h> 
//#include "C:\Users\ang06\Desktop\426proj\Prairie-Patrol\ashFold\lowFreqRFID\lfFirebase\RDM6300firebase\secrets.h"
//////////////////////////////////////////////////////////////////////////////////////////////////////////
// Stuff for RFID


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



////////////////////////////////////////////////////////////////////
//relay pin connection:
int relayPin=2; //white relay in connected to aruino pin 2

//Other variables
unsigned currentTag, selectedDogRFID ;
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
 
void setup() {
  Serial.begin(9600); 
  
  ssrfid.begin(9600);
  // ssrfid.listen(); 
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


//this is setting up the cage and dog settings:
 pinMode(relayPin, OUTPUT);
 // selectedDogRFID = "428767048"; //bird tag ID nuber 
 // selectedDogRFID = 428767048;
   selectedDogRFID = fb.getInt("AshleysFolder/selectedDog/rfid");
     Serial.print("Selected Dog RFID: ");
    Serial.println(selectedDogRFID);


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

  Serial.println("INIT DONE");
///////////////////////////////////////////////////////////////////////////////////////////
  
}


void loop()
{

  // get the other variable values from firebase
//  isCaught = fb.getBool("AshleysFolder/selectedDog/isCaught");  
 // isOpen=fb.getBool("AshleysFolder/cageStatus/isOpen"); 
 // magnetOn= fb.getBool("AshleysFolder/cageStatus/magnetOn"); 
  if(isCaught ==false && isOpen==true)
  {
    // Wait for RFID cards to be scanned
     // Serial.println(" WHY TF WONT U WORK ");
    
    if (ssrfid.available() > 0){
      bool call_extract_tag = false;
      
      int ssvalue = ssrfid.read(); // read 
      if (ssvalue == -1) { // no data was read
        return;
      }
  
      if (ssvalue == 2) { // RDM630/RDM6300 found a tag => tag incoming 
        buffer_index = 0;
      } else if (ssvalue == 3) { // tag has been fully transmitted       
        call_extract_tag = true; // extract tag at the end of the function call
      }
  
      if (buffer_index >= BUFFER_SIZE) { // checking for a buffer overflow (It's very unlikely that a buffer overflow comes up!)
        Serial.println("Error: Buffer overflow detected!");
        return;
      }
      
      buffer[buffer_index++] = ssvalue; // everything is alright => copy current value to buffer
  
      if (call_extract_tag == true) {
        if (buffer_index == BUFFER_SIZE) {
          unsigned tag = extract_tag();
          currentTag= tag; 
        } else { // something is wrong... start again looking for preamble (value: 2)
          buffer_index = 0;
         
          return;
        }
      }    
    }    

 //*AT THIS POINT TAG IN THE CODE IS READ AND IS ABOUT TO BE CHECKED IF IT MATCHES THE SELECTED DOG TAG*
       if (currentTag ==selectedDogRFID)
       {
          Serial.println("THE SELECTED DOG HAS BEEN SCANNED");
        
      //updates values in firebase
       /* magnetOn=false; 
        isOpen=false; 
        isCaught=true; 
        */

          fb.setBool("AshleysFolder/cageStatus/magnetOn", false); 
          fb.setBool("AshleysFolder/cageStatus/isOpen", false); 
          fb.setBool("AshleysFolder/selectedDog/isCaught", true);
           
       
          digitalWrite(relayPin, LOW); //turn magnet off if selected tag is detected
          return; 
       }
    }    
  
  }
