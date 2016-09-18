#include "DHT.h"

DHT dht;
// Initiallize the pins !!!
int DHTpin=2;
float hTemp,tTemp;
int htChg;

int pirPin1=3;
int tmpPir1=0;

int pirPin2=4;
int tmpPir2=0;

char initString[]="dsc=iteaduino-nono";
char pirPin1String[]="|nseq=chg/pin-n= /pin-type=d/bin= ";
char pirPin2String[]="|nseq=chg/pin-n= /pin-type=d/bin= ";

void setup()
{
  pirPin1String[16]=pirPin1 + 48;
  pirPin2String[16]=pirPin2 + 48;
  Serial.begin(9600);

  dht.setup(DHTpin); // data pin 2 because this is the only pin with IRQ;
   pinMode(pirPin1, INPUT);
   pinMode(pirPin2, INPUT);
}

void loop()
{
//  delay(dht.getMinimumSamplingPeriod());

  int i,movement1=0,movement2=0,tmp=0; 
  for (i=0; i< 600; i++){
    
    tmp=digitalRead(pirPin1);
    if (tmp != tmpPir1){
      tmpPir1=tmp;
      pirPin1String[33]= tmp + 48;
      movement1=1;
    }else{
      movement1=0;
    }

    tmp=digitalRead(pirPin2);
    if (tmp != tmpPir2){
      tmpPir2=tmp;
      pirPin2String[33]= tmp + 48;
      movement2=1;
    }else{
      movement2=0;
    }

    if (movement1 || movement2) Serial.print(initString);
    if (movement1) Serial.print(pirPin1String);
    if (movement2) Serial.print(pirPin2String);
    if (movement1 || movement2) Serial.print("\n");
    delay (100); // 10 = 1 sec, 600 = 1 min, 3000 = 5 min.    
  }

  float humidity = dht.getHumidity();
  float temperature = dht.getTemperature();
  htChg=0;
  // If there is change, print the header, and then add whatever we need.
  if (hTemp != humidity || tTemp != temperature){
    Serial.print(initString);  
    Serial.print("|nseq=ochg");
    Serial.print("/pin-type=d");  
    Serial.print("/pin-n=");
    Serial.print(DHTpin);
  }
  
  if (hTemp != humidity){
    Serial.print("/hum-%=");
    Serial.print(humidity, 2);
    htChg++;
  }

  if (tTemp != temperature){
    Serial.print("/temp-C=");
    Serial.print(temperature, 2);

    Serial.print("/temp-F=");
    Serial.print(dht.toFahrenheit(temperature), 1);
    htChg++;
  }
  if (htChg > 0){
    Serial.println("\n");
    htChg=0;
  }

}

