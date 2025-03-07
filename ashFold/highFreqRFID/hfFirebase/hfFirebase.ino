#include "secrets.h" 

#include <Firebase.h> 

#include <SPI.h> 

#include <MFRC522.h> 

 
#define SS_PIN 10 //green wire sda
#define RST_PIN 9 //blue wire rst
MFRC522 mfrc(SS_PIN, RST_PIN);   // Create MFRC522 instance.
MFRC522::MIFARE_Key key; 

int relayPin=5; //white relay in connected to aruino pin 5
String selectedDogRFID ; //stores the RFID of the selected dog from firebase
bool isCaught, isOpen, magnetOn;  
Firebase fb(REFERENCE_URL); //Firebase Instance
  
void setup() 
{
  Serial.begin(9600);   // Initiate a serial communication
  SPI.begin();      // Initiate  SPI bus
  mfrc.PCD_Init();   // Initiate MFRC522
  Serial.println("Please scan your RFID card...");
  Serial.println();
  pinMode(relayPin, OUTPUT);


  digitalWrite(relayPin, HIGH); //magnets r on-->door is up  

  WiFi.disconnect();//disconnects any previous wifi connections
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

//fwtch selected dogs RFID # from Firebase
  selectedDogRFID =  fb.getString("AshleysFolder/selectedDog/rfid"); //currently set to B3FF461C --> dog1 ;
  //selectedDogRFID = "d3273014";
  


   


  
}
void loop() 
{
    // get the other variable values from firebase
  isCaught = fb.getBool("AshleysFolder/selectedDog/isCaught");  
  isOpen= fb.getBool("AshleysFolder/cageStatus/isOpen"); 
  magnetOn= fb.getBool("AshleysFolder/cageStatus/magnetOn"); 
  
  //checks if dog still needs to be caught
  if(isCaught ==false && isOpen==true){
    // Wait for RFID cards to be scanned
      Serial.println("the trap is actively scanning RFID Tags  "); 

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

      //updates values in firebase
     /* magnetOn=false; 
      isOpen=false; 
      isCaught=true; 
      */

       fb.setBool("AshleysFolder/cageStatus/magnetOn", false); 
       fb.setBool("AshleysFolder/cageStatus/isOpen", true); 
       fb.setBool("AshleysFolder/dogs/selectedDog/isCaught", true); 
       
      digitalWrite(relayPin, LOW); //turn magnet off if selected tag is detected
      
    }
 
  }
  

} 
