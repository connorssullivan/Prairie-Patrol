#include "secrets.h"
#include <Firebase.h>
#include <Servo.h> // Include the Servo library
#include <SPI.h>
#include <MFRC522.h>

#define SS_PIN 10
#define RST_PIN 9
#define RELAY_PIN 2 // Define the relay pin

MFRC522 rfid(SS_PIN, RST_PIN); // Instance of the class
MFRC522::MIFARE_Key key;

Servo myServo; // Create a Servo object
//#define MOTOR_PIN 9 // Motor connected to pin 9

// Firebase instance
Firebase fb(REFERENCE_URL);

String selectedDogRFID;  // To store the RFID of the selected dog from Firebase

void setup() {
  Serial.begin(115200);
  delay(2000);
  Serial.println("Starting setup...");

  RFIDSetup();  // Set up RFID

  // Set up the motor pin and LED pin
  myServo.attach(MOTOR_PIN);
  myServo.write(0);  // Set the servo to initial position (0 degrees)

  pinMode(LED_PIN, OUTPUT); // Set the LED pin as an output
  digitalWrite(LED_PIN, LOW); // Initially keep the LED off (door open)

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

  // Fetch the selected dog's RFID from Firebase
  selectedDogRFID = fb.getString("selectedDog/rfid");
  if (selectedDogRFID.length() != 8) { // Ensure it's a valid RFID (8 characters for 4 bytes)
    Serial.println("Failed to fetch selectedDog's RFID from Firebase.");
  } else {
    Serial.print("Selected Dog RFID: ");
    Serial.println(selectedDogRFID);
  }
}

void loop() {
  // Check if the trap is active
  bool trapActive = fb.getBool("selectedDog/trapActive");
  bool trapOpen = fb.getBool("selectedDog/trapOpen");

  // If the trap is active and open, check for RFID
  if (trapActive && trapOpen) {
    Serial.println("Trap is active and open. Checking RFID...");

    // Check if a new card is present on the sensor/reader
    if (rfid.PICC_IsNewCardPresent()) {
      // Verify if the UID has been read
      if (rfid.PICC_ReadCardSerial()) {
        // Convert scanned UID to string for comparison
        String scannedRFID = "";
        for (byte i = 0; i < rfid.uid.size; i++) {
          scannedRFID += String(rfid.uid.uidByte[i], HEX);
        }

        // Compare the scanned RFID with the selectedDog's RFID from Firebase
        if (scannedRFID.equalsIgnoreCase(selectedDogRFID)) {
          // If it's the desired RFID, print "Door Closed" and update Firebase
          Serial.println("Door Closed");

          // Move the servo to simulate closing the door
          myServo.write(180);  // Move to 180 degrees to "close" the door
          digitalWrite(LED_PIN, HIGH); // Turn on the LED when the door is closed
          delay(1000);         // Wait for 1 second
          myServo.write(0);    // Move back to 0 degrees to "open" the door

          // Update Firebase: set trapOpen to false
          fb.setBool("selectedDog/trapOpen", false);

          // Set the corresponding dog's inTrap to true
          if (scannedRFID.equalsIgnoreCase("d3fe381c")) {  // For Green Dog
            fb.setBool("dogs/GreenDog/inTrap", true);
          } else if (scannedRFID.equalsIgnoreCase("123456")) {  // For Red Dog
            fb.setBool("dogs/RedDog/inTrap", true);
          }

        } else {
          // If it's not the desired RFID, print the unknown RFID
          Serial.print(F("Unknown RFID Tag UID: "));
          printHex(rfid.uid.uidByte, rfid.uid.size);
          Serial.println();
        }

        // Halt the RFID reader to process the next card
        rfid.PICC_HaltA();
      }
    }
  } else {
    // If trap is not active, keep the motor in the initial position
    Serial.println("Trap is inactive or closed. Waiting...");
    digitalWrite(LED_PIN, HIGH);
    myServo.write(0);  // Keep the motor in the initial position (door open)
    digitalWrite(LED_PIN, LOW); // Turn off the LED when the door is open
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

}
