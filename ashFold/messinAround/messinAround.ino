#include <SoftwareSerial.h>

SoftwareSerial rdm6300(12,13);
void setup() {
  // put your setup code here, to run once:
  Serial.begin(9600);
  rdm6300.begin(9600);
  Serial.println("Ready to read RFID tags: ");

}

void loop() {
  // put your main code here, to run repeatedly:

  Serial.print(rdm6300.available()); 
  Serial.print("here"); 
  if(rdm6300.available()>0){
    byte rfidData = rdm6300.read(); 
    

    if(rfidData==2){
      String rfidTag=""; 
      Serial.print("hmmmm"); 
      for(int i =0; i <12; i++){
     //   rfidTag+= String (rdm6300.read(), HEX);
          rfidTag+= String (rdm6300.read(), HEX);
 
        
      }

      Serial.print("RFID Tag ID: ");
      Serial.println(rfidTag);
      
     
    }
  }
  delay(2000);
}
