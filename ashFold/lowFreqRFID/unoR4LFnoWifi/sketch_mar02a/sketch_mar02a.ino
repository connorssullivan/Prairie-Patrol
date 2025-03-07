/*
 #include <SoftwareSerial.h>

SoftwareSerial rfidSerial( 10,11);  // RX, TX (connect RDM6300 TX to Arduino Pin 4)

void setup() {
  // Start serial communication with the Arduino IDE and the RFID reader
  Serial.begin(9600);  // For serial monitor output
  rfidSerial.begin(9600);  // For RFID reader communication

  Serial.println("RDM6300 RFID Reader Initialized");
}

void loop() {
  // Check if data is available to read from the RFID reader
  if (rfidSerial.available() > 0) {
    String rfidTag = "";
    Serial.println("here");
    // Read 12 bytes of data from the RFID reader
    for (int i = 0; i < 12; i++) {
      byte data = rfidSerial.read();
      // Output the raw byte data in hexadecimal format
      rfidTag += String(data, HEX);
    }

    // Print the RFID tag ID to the serial monitor
    Serial.print("RFID Tag Detected: ");
    Serial.println(rfidTag);

    delay(1000);  // Delay before reading the next tag
  }
   //Serial.println("hmmm");
}
*/

/*
#include <SoftwareSerial.h>

SoftwareSerial rdm6300 = SoftwareSerial(10,11); // RX, TX pins

void setup() {
  // Start communication with the serial monitor
  Serial.begin(9600);  // Set baud rate for serial monitor

  // Start communication with the RFID reader
  rdm6300.begin(9600);  // Set baud rate for the RDM6300
 
  Serial.println("RDM6300 RFID Reader");
}

void loop() {
  if (rdm6300.available()) {
    // Read RFID data from the reader
    byte rfidData[12];
    
    for (int i = 0; i < 12; i++) {
      rfidData[i] = rdm6300.read();
    }

    // Print the RFID data to the Serial Monitor
    Serial.print("RFID Data: ");
    for (int i = 0; i < 12; i++) {
      Serial.print(rfidData[i], HEX);
      Serial.print(" ");
    }
    Serial.println();
    
    delay(1000);  // Wait for a second before reading again
  }
}
*/

/*
#include <SoftwareSerial.h>

SoftwareSerial rdm6300(10, 11); // RX, TX pins for RDM6300 communication

void setup() {
  // Start communication with the serial monitor at 115200 baud rate
  Serial.begin(9600);
  
  // Start communication with the RFID reader at 9600 baud rate
  rdm6300.begin(9600);

  Serial.println("RDM6300 RFID Reader Initialized");
}

void loop() {
  // Check if data is available from the RFID reader
  if (rdm6300.available()) {
    byte rfidData[12];

    // Read 12 bytes of RFID data from the reader
    for (int i = 0; i < 12; i++) {
      rfidData[i] = rdm6300.read();
    }

    // Convert the RFID data to a string to print in the Serial Monitor
    String cardNumber = "";
    for (int i = 0; i < 12; i++) {
      // Combine bytes into a string and convert to a decimal number
      cardNumber += String(rfidData[i], DEC); 
      if (i < 11) cardNumber += "-";  // Add a separator between each byte
    }

    // Print the RFID card number in decimal format
    Serial.print("RFID Card Number: ");
    Serial.println(cardNumber);
    
    delay(1000); // Wait a second before reading again
  }
}*/

 
 // (c) Michael Schoeffler 2018, http://www.mschoeffler.de
#include <SoftwareSerial.h>

const int BUFFER_SIZE = 14; // RFID DATA FRAME FORMAT: 1byte head (value: 2), 10byte data (2byte version + 8byte tag), 2byte checksum, 1byte tail (value: 3)
const int DATA_SIZE = 10; // 10byte data (2byte version + 8byte tag)
const int DATA_VERSION_SIZE = 2; // 2byte version (actual meaning of these two bytes may vary)
const int DATA_TAG_SIZE = 8; // 8byte tag
const int CHECKSUM_SIZE = 2; // 2byte checksum

SoftwareSerial ssrfid = SoftwareSerial(10,11); //(far right peg, 2nd from end peg)

uint8_t buffer[BUFFER_SIZE]; // used to store an incoming data frame 
int buffer_index = 0;

void setup() {
 Serial.begin(9600); 
 
 ssrfid.begin(9600);
 //ssrfid.listen(); 
 
 Serial.println("INIT DONE");
}

void loop() {
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

    if (buffer_index >= BUFFER_SIZE) { // checking for a buffer overflow (It's very unlikely that an buffer overflow comes up!)
      Serial.println("Error: Buffer overflow detected!");
      return;
    }
    
    buffer[buffer_index++] = ssvalue; // everything is alright => copy current value to buffer

    if (call_extract_tag == true) {
      if (buffer_index == BUFFER_SIZE) {
        unsigned tag = extract_tag();
      } else { // something is wrong... start again looking for preamble (value: 2)
        buffer_index = 0;
        return;
      }
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

    long tag = hexstr_to_value(msg_data_tag, DATA_TAG_SIZE);
    Serial.print("Extracted Tag: ");
    Serial.println(tag);

    long checksum = 0;
    for (int i = 0; i < DATA_SIZE; i+= CHECKSUM_SIZE) {
      long val = hexstr_to_value(msg_data + i, CHECKSUM_SIZE);
      checksum ^= val;
    }
    Serial.print("Extracted Checksum (HEX): ");
    Serial.print(checksum, HEX);
 /*   if (checksum == hexstr_to_value(msg_checksum, CHECKSUM_SIZE)) { // compare calculated checksum to retrieved checksum
      Serial.print(" (OK)"); // calculated checksum corresponds to transmitted checksum!
    } else {
      Serial.print(" (NOT OK)"); // checksums do not match
    }
*/
    Serial.println("");
    Serial.println("--------");

    return tag;
}

long hexstr_to_value(uint8_t *str, unsigned int length) { // converts a hexadecimal value (encoded as ASCII string) to a numeric value
  char* copy = malloc((sizeof(char) * length) + 1); 
  memcpy(copy, str, sizeof(char) * length);
  copy[length] = '\0'; 
  // the variable "copy" is a copy of the parameter "str". "copy" has an additional '\0' element to make sure that "str" is null-terminated.
  long value = strtol(copy, NULL, 16);  // strtol converts a null-terminated string to a long value
  free(copy); // clean up 
  return value;
}
