#include "DHT.h"

DHT dht;

int DHTpin = 2;
void setup()
{
  Serial.begin(9600);
  Serial.println();

  dht.setup(DHTpin); // data pin 2
}

void loop()
{
  delay(dht.getMinimumSamplingPeriod());

  float humidity = dht.getHumidity();
  float temperature = dht.getTemperature();



    Serial.print("chipid-text=iteaduino_nano");
    Serial.print(" nextseq=onchange");
    
    Serial.print(" pin-n=");
    Serial.print(DHTpin);

    Serial.print(" pin-type=d");
  
    Serial.print(" hum-%=");
    Serial.print(humidity, 2);

    Serial.print(" temp-C=");
    Serial.print(temperature, 2);

    Serial.print(" temp-F=");
    Serial.print(dht.toFahrenheit(temperature), 1);

    Serial.print(" temp-K=");
    Serial.println("TODO");




//  Serial.print(dht.getStatusString());
//  Serial.print("\t");
//  Serial.print(humidity, 1);
//  Serial.print("\t\t");
//  Serial.print(temperature, 1);
//  Serial.print("\t\t");
//  Serial.println(dht.toFahrenheit(temperature), 1);
}

