// red one main executable and library

#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

// Allow memory mapping to file
#include <fcntl.h>
#include <sys/types.h>
#include <errno.h>


#include <wiringPi.h>
// Include the multi threaded programming.
#include <pthread.h>
#include <semaphore.h>

const float  VERSION=0.1;

int sencePin=0; // get this from config file.
long int sleepTime=0;

void *senceMovement(void *arg){
  int result=0;
  int pipe;
  // Initialize the data, and connect it to file.
  int fd, pagesize;
  char * pipeFile="/data/tmp/sensor_ir";
  char ascii_result[]="0\n";
  FILE *testOpen;  
  
  
  
  
  wiringPiSetup();
  pinMode (sencePin,INPUT);

  for (;;){
    result=digitalRead(sencePin);
    
    if (result == HIGH){ 
      ascii_result[0]='1';
    }else{
      ascii_result[0]='0';
    }
    
    if (pipe = open(pipeFile, O_WRONLY) == -1){
      perror("Failed to open the pipe");
      return;
    }
    
    if (write(pipe, ascii_result,sizeof(ascii_result)) == -1){
      perror("Failed to write to pipe !");
      return;
    }
    
    close (pipe);
    delay (sleepTime);
  }
  return 0;
}

int help ( int code){
    if (! code) code=0;
    printf("\n\nlzlz version %f !!!\n",VERSION);
    printf("Usage: gpio parameter parameter ...\n");
    printf("This program is free software. Use it at your own risk !\n");
    printf("\t-d\tFIFO directory\n");
    printf("\t-p\tpin,pin,pin,pin....\n");
    printf("\t-t\ttime in miliseconds to wait before retrieve sensor valuse again.\n");
    exit(code);
}

int main (int argc, char **argv){
  char *fvalue = NULL;
  char *gvalue = NULL;
  char *tvalue = NULL;
  int index;
  int c;

  pthread_t thr; // Define the thread id holder
  
  opterr = 0;
  while ((c = getopt (argc, argv, "d:,p:,t:")) != -1){
    switch (c){      
      case 'd':
        fvalue = optarg;
        break;
      case 'p':
        gvalue = optarg;
        break;
      case 't':
        tvalue = optarg;
        break;
      case '?':
        if (optopt == 'd')
          fprintf (stderr, "Option -%c requires an argument.\n", optopt);
        else if (optopt == 'p')
          fprintf (stderr, "Option -%c requires an argument.\n", optopt);
        else if (optopt == 't')
          fprintf (stderr, "Option -%c requires an argument.\n", optopt);
          
          
        else if (isprint (optopt)){
          fprintf (stderr, "Unknown option `-%c'.\n", optopt);
          help(1);
        }else{
          fprintf (stderr, "Unknown option character `\\x%x'.\n",optopt);
          help(1);
        }
      default:
        help(1);
    }
  }
  
  printf ("fvalue = %s\ngvalue= %s \n", fvalue,gvalue);
  for (index = optind; index < argc; index++){
    printf ("Unknown option:  %s\n", argv[index]);
    help(1);;
  }
  
  if (! fvalue || ! gvalue || ! tvalue ) help(1);
  if (1 == sscanf(tvalue,"%ld",&sleepTime)){
    printf("Succesfully converted number %ld",sleepTime);
  }else{
    printf("Incorrect value of parameter -t\n");
    return 1;
  }

  printf("Dispatching agent to listen to our device ...\n");
  // Start the sensor driver
  pthread_create(&thr, NULL, senceMovement, NULL);
  pthread_join(thr, NULL);
  //delay (60000);
  //pthread_cancel(thr);
  printf("The agent has finished.");  
  return 0;
}

