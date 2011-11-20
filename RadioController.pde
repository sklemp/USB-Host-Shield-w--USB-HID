/*Code is adapted by sklemp@gmail.com for questions contact Steve */
#include <Max3421e.h>
#include <Usb.h>
#include <Max_LCD.h>
#include <SPI.h>
 
#define DEVADDR 1
#define CONFVALUE 1
#define EP_MAXPKTSIZE 8

EP_RECORD ep_record[ 2 ];
 
MAX3421E Max;
USB Usb;
Max_LCD LCD;
 
void setup()
{
    LCD.begin(16, 2);
    LCD.print("USB initialized");
    delay(2000);
    LCD.clear();
    LCD.home();
    LCD.noAutoscroll();
    LCD.noCursor();
    Serial.begin( 115200 );
    Serial.println("Start");
    Max.powerOn();
    delay( 200 );
}
 
void loop()
{
 byte rcode;
    Max.Task();
    Usb.Task();
    if( Usb.getUsbTaskState() == USB_STATE_CONFIGURING ) {
        mouse1_init();
    }//if( Usb.getUsbTaskState() == USB_STATE_CONFIGURING...
    if( Usb.getUsbTaskState() == USB_STATE_RUNNING ) {  //poll the keyboard
        rcode = mouse1_poll();
        if( rcode ) {
          Serial.print("Mouse Poll Error: ");
          Serial.println( rcode, HEX );
        }//if( rcode...
    }//if( Usb.getUsbTaskState() == USB_STATE_RUNNING...
}
/* Initialize mouse */
void mouse1_init( void )
{
 byte rcode = 0;  //return code
 byte tmpdata;
 byte* byte_ptr = &tmpdata;
  /**/
  ep_record[ 0 ] = *( Usb.getDevTableEntry( 0,0 ));  //copy endpoint 0 parameters
  ep_record[ 1 ].MaxPktSize = EP_MAXPKTSIZE;
  ep_record[ 1 ].sndToggle = bmSNDTOG0;
  ep_record[ 1 ].rcvToggle = bmRCVTOG0;
  Usb.setDevTableEntry( 1, ep_record );              //plug kbd.endpoint parameters to devtable
  /* Configure device */
  rcode = Usb.setConf( DEVADDR, 0, CONFVALUE );
  if( rcode ) {
    Serial.print("Error configuring mouse. Return code : ");
    Serial.println( rcode, HEX );
    while(1);  //stop
  }//if( rcode...
  rcode = Usb.getIdle( DEVADDR, 0, 0, 0, (char *)byte_ptr );
  if( rcode ) {
    Serial.print("Get Idle error. Return code : ");
    Serial.println( rcode, HEX );
    //while(1);  //stop
  }
  Serial.print("Idle Rate: ");
  Serial.print(( tmpdata * 4 ), DEC );        //rate is returned in multiples of 4ms
  Serial.println(" ms");
  tmpdata = 0;
  rcode = Usb.setIdle( DEVADDR, 0, 0, 0, tmpdata );
  if( rcode ) {
    Serial.print("Set Idle error. Return code : ");
    Serial.println( rcode, HEX );
   // while(1);  //stop
  }
  Usb.setUsbTaskState( USB_STATE_RUNNING );
  return;
}
/* Poll mouse via interrupt endpoint and print result */
/* assumes EP1 as interrupt endpoint                  */
byte mouse1_poll( void )
{
  byte rcode,i;
  char buf[ 4 ] = { 0 };                          //mouse report buffer
  /* poll mouse */
  rcode = Usb.inTransfer( DEVADDR, 1, 4, buf, 1 );  //
  //rcode = Usb.getReport( DEVADDR, 0, 4, 0, 1, 0, buf );
    if( rcode ) {  //error
      if( rcode == 0x04 ) {  //NAK
        rcode = 0;
      }
      return( rcode );
    }
    /* print buffer */
    Serial.println("");
    Serial.print("Lt Gimbal X: ");
    Serial.println( buf[ 5 ], DEC);
    Serial.print("Lt Gimbal Y: ");
    Serial.println( buf[ 3 ], DEC);
    Serial.print("Rt Gimbal X: ");
    Serial.println( buf[ 1 ], DEC);
    Serial.print("Rt Gimbal Y: ");
    Serial.println( buf[ 2 ], DEC);
    Serial.print("Trim: ");
    Serial.println( buf[ 4 ], DEC);
    Serial.print("Switch: ");
    Serial.println( buf[ 7 ], DEC);
    Serial.println("");
    
    LCD.setCursor(0, 0);
    LCD.print("X:");
    LCD.print(buf[5], DEC);
    LCD.print("Tr:");
    LCD.print(buf[4], DEC);
    LCD.print("X:");
    LCD.print(buf[1], DEC);
    LCD.setCursor(0, 1);
    LCD.print("Y:");
    LCD.print(buf[3], DEC);
    LCD.print("Sw:");
    LCD.print(buf[7], DEC);
    LCD.print("Y:");
    LCD.print(buf[2], DEC);
    return( rcode );
}
