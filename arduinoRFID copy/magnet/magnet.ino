const int relay = 9;   //arduino pin connected to relay1

void magnetOn() {
    digitalWrite(relay, HIGH);
   
}

void magnetOff() {
    digitalWrite(relay, LOW);
   
}



void setup() {
pinMode(relay, OUTPUT);//set relay as an output
}
void loop() {

  magnetOn();
  delay(5000);
  magnetOff();           
  delay(5000);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               
}
 
 
