#include <Stepper.h> 

  

int fullRotate= 2048; //number of steps for a full rotation 

int speed = 1; //motor speed in rpms 

Stepper motor(fullRotate, 8, 10, 9, 11); //stepsPerRev, IN1,IN3,IN2,IN4)<-INITIALIZING STEPPER LIBRARY ON THE PINS WE USED 

void setup() { 

  // put your setup code here, to run once: 

  motor.setSpeed(speed);  

} 

  

  

void loop() { 

  // put your main code here, to run repeatedly: 

  motor.step(fullRotate); //takes in number of steps 

  delay(1000);//stops for a second 

  motor.step(-fullRotate);  

  delay (5000) ;  

    

  

} 
