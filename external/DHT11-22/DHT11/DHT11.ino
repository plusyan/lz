/*
  Board	          int.0	  int.1	  int.2	  int.3	  int.4	  int.5
 Uno, Ethernet	  2	  3
 Mega2560	  2	  3	  21	  20	  19	  18
 Leonardo	  3	  2	  0	  1
 Due	          (any pin, more info http://arduino.cc/en/Reference/AttachInterrupt)
 
 This example, as difference to the other, make use of the new method acquireAndWait()
 */

#include "idDHT11.h"

int idDHT11pin = 2; //Digital pin for comunications
int idDHT11intNumber = 0; //interrupt number (must be the one that use the previus defined pin (see table above)
float prevTempC=0;
float prevHum=0;

//declaration
void dht11_wrapper(); // must be declared before the lib initialization

// Lib instantiate
idDHT11 DHT11(idDHT11pin,idDHT11intNumber,dht11_wrapper);

void setup()
{
  Serial.begin(9600);
}
// This wrapper is in charge of calling 
// mus be defined like this for the lib work
void dht11_wrapper() {
  DHT11.isrCallback();
}
void loop()
{
  //delay(100);
  
  int result = DHT11.acquireAndWait();
  switch (result)
  {
  case IDDHTLIB_OK: 
    break;
  case IDDHTLIB_ERROR_CHECKSUM: 
    Serial.println("error-txt=incorrect_checksum"); 
    break;
  case IDDHTLIB_ERROR_ISR_TIMEOUT: 
    Serial.println("error-txt=ISR_time_out"); 
    break;
  case IDDHTLIB_ERROR_RESPONSE_TIMEOUT: 
    Serial.println("error-txt=response_time_out"); 
    break;
  case IDDHTLIB_ERROR_DATA_TIMEOUT: 
    Serial.println("error-txt=data_time_out_error"); 
    break;
  case IDDHTLIB_ERROR_ACQUIRING: 
    Serial.println("error-txt=error_aquiring_data"); 
    break;
  case IDDHTLIB_ERROR_DELTA: 
    Serial.println("error-txt=delta_time_too_small"); 
    break;
  case IDDHTLIB_ERROR_NOTSTARTED: 
    Serial.println("error-txt=not_started"); 
    break;
  default: 
    Serial.println("error-txt=unknown_error"); 
    break;
  }
  if ( prevTempC != DHT11.getCelsius() || prevHum != DHT11.getHumidity()){
    prevTempC=DHT11.getCelsius();
    prevHum=DHT11.getHumidity();
    
    Serial.print("chipid-text=iteaduino_nano");
    Serial.print(" nextseq=onchange");
    
    Serial.print(" pin-d=");
    Serial.print(idDHT11pin);
  
    Serial.print(" hum-%=");
    Serial.print(DHT11.getHumidity(), 2);

    Serial.print(" temp-C=");
    Serial.print(DHT11.getCelsius(), 2);

    Serial.print(" temp-F=");
    Serial.print(DHT11.getFahrenheit(), 2);

    Serial.print(" temp-K=");
    Serial.print(DHT11.getKelvin(), 2);

    Serial.print(" text=");
    Serial.print("DewPoint(oC):");
    Serial.print(DHT11.getDewPoint());

    Serial.print(",DewPointSlow(oC):");
    Serial.println(DHT11.getDewPointSlow());
  }
  delay(2000);
}

