#include "secrets.h"
#include <Firebase.h>
#include <SPI.h>
#include <MFRC522.h>

#define SS_PIN 10
#define RST_PIN 9

MFRC522 rfid(SS_PIN, RST_PIN); // Instance of the class
MFRC522::MIFARE_Key key;

#define MAGNET_PIN 5 // Magnet control pin

// Firebase instance
Firebase fb(REFERENCE_URL);

const String JUDES_FOLDER = "JudesFolder";  // Constant for JudesFolder

// Helper function to generate Firebase paths
String getPath(const String& folder, const String& subfolder) {
    return folder + "/" + subfolder;
}

// Global variable to store the selected dog's RFID
String selectedDogRFID;

void setup() {
    Serial.begin(115200);
    delay(2000);
    Serial.println("Starting setup...");

    RFIDSetup();  // Set up RFID

    // Set up the magnet pin
    pinMode(MAGNET_PIN, OUTPUT); // Set the magnet pin as an output
    digitalWrite(MAGNET_PIN, HIGH); // Initially keep the magnet on

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
    selectedDogRFID = fb.getString(getPath(JUDES_FOLDER, "selectedDog") + "/rfid");
    if (selectedDogRFID.length() != 8) { // Ensure it's a valid RFID (8 characters for 4 bytes)
        Serial.println("Failed to fetch selectedDog's RFID from Firebase.");
    } else {
        Serial.print("Selected Dog RFID: ");
        Serial.println(selectedDogRFID);
    }
}

void loop() {
    // Check if the trap is active
    bool trapActive = fb.getBool(getPath(JUDES_FOLDER, "selectedDog") + "/trapActive");
    bool trapOpen = fb.getBool(getPath(JUDES_FOLDER, "selectedDog") + "/trapOpen");

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

                // Output the scanned RFID tag
                Serial.print("Scanned RFID Tag: ");
                Serial.println(scannedRFID);

                // Compare the scanned RFID with the selectedDog's RFID from Firebase
                if (scannedRFID.equalsIgnoreCase(selectedDogRFID)) {
                    // If it's the desired RFID, activate the magnet
                    Serial.println("Deactivating magnet (door closed)");

                    digitalWrite(MAGNET_PIN, LOW); // Deactivate the magnet
                    delay(1000); // Wait for a second to simulate trapping

                    // Update Firebase: set trapOpen to false
                    fb.setBool(getPath(JUDES_FOLDER, "selectedDog") + "/trapOpen", false);

                    // Set the corresponding dog's inTrap to true
                    if (scannedRFID.equalsIgnoreCase("d3fe381c")) {  // For Green Dog
                        fb.setBool(getPath(JUDES_FOLDER, "dogs/GreenDog") + "/inTrap", true);
                    } else if (scannedRFID.equalsIgnoreCase("38433bd9")) {  // For Red Dog
                        fb.setBool(getPath(JUDES_FOLDER, "dogs/RedDog") + "/inTrap", true);
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
        // If trap is not active, turn off the magnet
        Serial.println("Trap is inactive or closed. Waiting...");
        digitalWrite(MAGNET_PIN, LOW); // Deactivate the magnet
    }

    // Add a delay to avoid flooding Firebase with requests
    delay(2000); // Check Firebase every 2 seconds
}

void RFIDSetup() {
    SPI.begin();           // Init SPI bus
    rfid.PCD_Init();       // Init RC522

    Serial.println("Place your RFID card near the reader...");
}

// Routine to print RFID tag in hexadecimal format
void printHex(byte *buffer, byte bufferSize) {
    for (byte i = 0; i < bufferSize; i++) {
        Serial.print(buffer[i] < 0x10 ? " 0" : " ");
        Serial.print(buffer[i], HEX);
    }
}
