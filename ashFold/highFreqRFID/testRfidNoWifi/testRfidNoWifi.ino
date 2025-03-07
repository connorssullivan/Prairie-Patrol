#include <SPI.h>
#include <MFRC522.h>

 
#define SS_PIN 10 //green wire sda
#define RST_PIN 9 //blue wire rst
MFRC522 mfrc(SS_PIN, RST_PIN);   // Create MFRC522 instance.
int relayPin=5; //white relay in connected to aruino pin 5
String selectedDogRFID ;
bool isCaught, isOpen, magnetOn;  

  
void setup() 
{
  Serial.begin(9600);   // Initiate a serial communication
  SPI.begin();      // Initiate  SPI bus
  mfrc.PCD_Init();   // Initiate MFRC522
  Serial.println("Please scan your RFID card...");
  Serial.println();
  pinMode(relayPin, OUTPUT);
 // selectedDogRFID = "b3ff461c";
  selectedDogRFID = "d3273014";
  isCaught = false;  
  isOpen= true; 
  magnetOn= true; 
  digitalWrite(relayPin, HIGH); //magnets r on-->door is up  
}
void loop() 
{
  if(isCaught ==false && isOpen==true){
    // Wait for RFID cards to be scanned

      // Reset the loop if no new card present on the sensor/reader. This saves the entire process when idle.
    if ( ! mfrc.PICC_IsNewCardPresent()) 
    {
      
  
      return;
    }
    // an RFID card has been scanned but no UID   // Select one of the cards
    if ( ! mfrc.PICC_ReadCardSerial()) 
    {
      
      return;
    }
    //Show UID on serial monitor
   // digitalWrite(relayPin,Low);
    String currentTag= "";
   
    for (byte i = 0; i < mfrc.uid.size; i++) //gets numbers of current rfid tag being scanned
    {
    //   Serial.print(mfrc.uid.uidByte[i] < 0x10 ? " 0" : " ");
      // Serial.print(mfrc.uid.uidByte[i], HEX);
       currentTag.concat(String(mfrc.uid.uidByte[i] < 0x10 ? " 0" : ""));
       currentTag.concat(String(mfrc.uid.uidByte[i], HEX));
    }
       Serial.println("Current Tag:");
      Serial.println(currentTag);
      Serial.println();
      Serial.println("selected:");
      Serial.println(selectedDogRFID);
      Serial.println();

    if (currentTag ==selectedDogRFID){
       Serial.println("THE SELECTED DOG HAS BEEN SCANNED");
      
      magnetOn=false; 
      isOpen=false; 
      isCaught=true; 
      digitalWrite(relayPin, LOW); //turn magnet off if selected tag is detected
      
    }
 
  }
  

} 
