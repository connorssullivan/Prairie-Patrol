#include <SoftwareSerial.h>

//# include "secrets.h"
#include <Firebase.h> 
//#include "C:\Users\ang06\Desktop\426proj\Prairie-Patrol\ashFold\lowFreqRFID\lfFirebase\RDM6300firebase\secrets.h"


 // stuff for RFID:
const int BUFFER_SIZE = 14; // RFID DATA FRAME FORMAT: 1byte head (value: 2), 10byte data (2byte version + 8byte tag), 2byte checksum, 1byte tail (value: 3)
const int DATA_SIZE = 10; // 10byte data (2byte version + 8byte tag)
const int DATA_VERSION_SIZE = 2; // 2byte version (actual meaning of these two bytes may vary)
const int DATA_TAG_SIZE = 8; // 8byte tag
const int CHECKSUM_SIZE = 2; // 2byte checksum
uint8_t buffer[BUFFER_SIZE]; // used to store an incoming data frame 
int buffer_index = 0;

SoftwareSerial ssrfid = SoftwareSerial(12,13); //(far right peg, 2nd from end peg)

//relay pin connection:
int relayPin=2; //white relay in connected to aruino pin 2

//Other variables
unsigned currentTag, selectedDogRFID ;
bool isCaught, isOpen,magnetOn;  //has the dog been caught yet, is the cage open, is the magnet on 



//////////////////////////////////////////////////////////////////


//SECRETS.H ----- WIFI_SETUP

//#define WIFI_SSID     "217HAYWARD" //wifiUsername
//#define WIFI_PASSWORD "Chickennugget123" //wifiPassword

#define WIFI_SSID     "SBY City Zoo" //wifiUsername
#define WIFI_PASSWORD "" //wifiPassword

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
  
unsigned extract_tag() {
    uint8_t msg_head = buffer[0];
    uint8_t *msg_data = buffer + 1; // 10 byte => data contains 2byte version + 8byte tag
    uint8_t *msg_data_version = msg_data;
    uint8_t *msg_data_tag = msg_data + 2;
    uint8_t *msg_checksum = buffer + 11; // 2 byte
    uint8_t msg_tail = buffer[13];

    // print message that was sent from RDM630/RDM6300
    Serial.println("--------");

    Serial.print("Message-Head: ");
    Serial.println(msg_head);

    Serial.println("Message-Data (HEX): ");
    for (int i = 0; i < DATA_VERSION_SIZE; ++i) {
      Serial.print(char(msg_data_version[i]));
    }
    Serial.println(" (version)");
    for (int i = 0; i < DATA_TAG_SIZE; ++i) {
      Serial.print(char(msg_data_tag[i]));
    }
    Serial.println(" (tag)");

    Serial.print("Message-Checksum (HEX): ");
    for (int i = 0; i < CHECKSUM_SIZE; ++i) {
      Serial.print(char(msg_checksum[i]));
    }
    Serial.println("");

    Serial.print("Message-Tail: ");
    Serial.println(msg_tail);

    Serial.println("--");

    // Cast the uint8_t* to char* to fix type mismatch
    long tag = hexstr_to_value((char*)msg_data_tag, DATA_TAG_SIZE);
    Serial.print("Extracted Tag: ");
    Serial.println(tag);

    long checksum = 0;
    for (int i = 0; i < DATA_SIZE; i += CHECKSUM_SIZE) {
      long val = hexstr_to_value((char*)(msg_data + i), CHECKSUM_SIZE); // cast here too
      checksum ^= val;
    }
    Serial.print("Extracted Checksum (HEX): ");
    Serial.print(checksum, HEX);
    if (checksum == hexstr_to_value((char*)msg_checksum, CHECKSUM_SIZE)) { // cast here too
      Serial.print(" (OK)"); // calculated checksum corresponds to transmitted checksum!
    } else {
      Serial.print(" (NOT OK)"); // checksums do not match
    }

    Serial.println("");
    Serial.println("--------");

    return tag;
}



long hexstr_to_value(char *str, unsigned int length) { // converts a hexadecimal value (encoded as ASCII string) to a numeric value
   char* copy = (char*)malloc((sizeof(char) * length) + 1);

  memcpy(copy, str, sizeof(char) * length);
  copy[length] = '\0'; 
  // the variable "copy" is a copy of the parameter "str". "copy" has an additional '\0' element to make sure that "str" is null-terminated.
  long value = strtol(copy, NULL, 16);  // strtol converts a null-terminated string to a long value
  free(copy); // clean up 
  return value;
}
