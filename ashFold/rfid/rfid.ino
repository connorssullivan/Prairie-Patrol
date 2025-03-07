#include "secrets.h" 

#include <Firebase.h> 

#include <SPI.h> 

#include <MFRC522.h> 

  

#define SS_PIN 10 //sda pin 

#define RST_PIN 9 

#define relayPin 5 // Define the relay pin 

  

MFRC522 rfid(SS_PIN, RST_PIN); // Instance of the class 

MFRC522::MIFARE_Key key; 

  

// Firebase instance 

Firebase fb(REFERENCE_URL); 

  

String selectedDogRFID;  // To store the RFID of the selected dog from Firebase 

  

void setup() { 

    Serial.print("HEREEEE "); 

  Serial.begin(9600) ;// --> intialize serial communications w/ pc 

// Serial.begin(115200); 

  delay(2000); 

  Serial.println("Starting setup..."); 

  

  RFIDSetup();  // Set up RFID 

  

  Serial.print("HMMMMMMM"); 

  pinMode(relayPin, OUTPUT); // Set the relay pin as an output 

  digitalWrite(relayPin, HIGH); // Initially keep the magnetON (door open) 

  

  // Disconnect any previous WiFi connections 

  WiFi.disconnect(); 

  delay(1000);   

  // Connect to WiFi 

  Serial.print("Connecting to: "); 

  Serial.println(WIFI_SSID); 

  WiFi.begin(WIFI_SSID, WIFI_PASSWORD); 

  while (WiFi.status() != WL_CONNECTED) { 

    Serial.print("???... "); //GETTING STUCK HERE!!! 

    Serial.print("-"); 

    delay(500); 

  } 

  Serial.println(); 

  

  // Fetch the selected dog's RFID from Firebase 

  selectedDogRFID = fb.getString("AshleysFolder/selectedDog/rfid"); //currently set to B3FF461C --> dog1 

  if (selectedDogRFID.length() != 8) { // Ensure it's a valid RFID (8 characters for 4 bytes) 

    Serial.println("Failed to fetch selectedDog's RFID from Firebase."); 

  } else { 

    Serial.print("Selected Dog RFID: "); 

    Serial.println(selectedDogRFID); 

  } 

} 

  

void loop() { 

  // Check if the trap is active 

  bool isCaught = fb.getBool("AshleysFolder/selectedDog/isCaught");  

  bool isOpen= fb.getBool("AshleysFolder/cageStatus/isOpen"); 

  bool magnetOn= fb.getBool("AshleysFolder/cageStatus/magnetOn"); 

   

  // If selected dog hasnt been caught yet and the trap is open, check for RFID 

  if (isCaught==false && isOpen) { 

    Serial.println("the trap is actively checking for RFID#  "); 

    Serial.println(selectedDogRFID); 

  

    // Check if a new card is present on the sensor/reader 

    if (rfid.PICC_IsNewCardPresent()) { 

      // Verify if the UID has been read 

      if (rfid.PICC_ReadCardSerial()) { 

        // Convert scanned UID to string for comparison 

        String scannedRFID = ""; 

        for (byte i = 0; i < rfid.uid.size; i++) { 

          scannedRFID += String(rfid.uid.uidByte[i], HEX); 

        } 

  

         Serial.println(scannedRFID); //prints out the scanned rfid number 

          

        // Compare the scanned RFID with the selectedDog's RFID from Firebase 

        if (scannedRFID.equalsIgnoreCase(selectedDogRFID))  

        {  

          // If it's the desired RFID, print "Door Closed" and update Firebase 

         

          digitalWrite(relayPin, LOW); // Turn off power to relay to turn off the magents to close the door  

         

          Serial.println("The door has been closed--selected dog caught!"); 

           

          // Update Firebase: set trapOpen to false 

          fb.setBool("AshleysFolder/selectedDog/isCaught", true); 

            

          // Set the corresponding dog's inTrap to true 

          if (scannedRFID.equalsIgnoreCase("B3FF461c")) {  // makes updates if dog1 is in the trap 

            fb.setBool("AshleysFolder/dogs/dog1/inTrap", true); 

          }  

          else if (scannedRFID.equalsIgnoreCase("D3273014")) {  // updates if its dog2 UID 

            fb.setBool("AshleysFolder/dogs/dog2/inTrap", true); 

          } 

  

        } else  

        { 

          // If it's not the desired RFID, print the unknown RFID 

          Serial.print(F("Unknown RFID Tag UID: ")); 

          printHex(rfid.uid.uidByte, rfid.uid.size); 

          Serial.println(); 

        } 

  

        // Halt the RFID reader to process the next card 

        rfid.PICC_HaltA(); 

        //rfid.PCD_StopCrypto1(); -->resets 

      } 

    } 

  } else { 

    // If trap is not active, keep the motor in the initial position 

    Serial.println("Trap is inactive or closed. Waiting..."); 

    digitalWrite(relayPin, HIGH); //magnets r on-->door is up  

  } 

  

  // Add a delay to avoid flooding Firebase with requests 

  delay(2000); // Check Firebase every 2 seconds 

} 

  

void RFIDSetup() { 

  SPI.begin();           // Init SPI bus 

  rfid.PCD_Init();       // Init RC522 

  

  Serial.println("Place your RFID card near the reader..."); 

} 

  

  

  

// Routine to compare two UIDs 

void printHex(byte *buffer, byte bufferSize) { 

  for (byte i = 0; i < bufferSize; i++) { 

    Serial.print(buffer[i] < 0x10 ? " 0" : " "); 

    Serial.print(buffer[i], HEX); 

  } 

} 
