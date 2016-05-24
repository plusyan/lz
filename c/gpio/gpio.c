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

int a = 0,c,d = 0;

int sencePin=8; // get this from config file.
long int sleepTime=0;
char * pipeFile;


void *senceMovement(void *arg){
  int result=0;
  int pipe;
  // Initialize the data, and connect it to file.
  int fd, pagesize;
  // 
  char ascii_result[]="                \n";
  FILE *testOpen;  
    
  wiringPiSetup();
  printf("The pin that we are using is: %u",sencePin);
  pinMode (sencePin,INPUT);

  for (;;){
    if (d == 1) result=digitalRead(sencePin);
    if (a == 1) result=analogRead(sencePin);
    sprintf( ascii_result,"/d:%u:%u/",sencePin,result);

    if (pipe = open(pipeFile, O_WRONLY) == -1){
      perror("Failed to open the pipe");
      return;
    }
    
    if (write(pipe, ascii_result,sizeof(ascii_result)) == -1)
      perror("Failed to write to pipe");
    
    close (pipe);
    delay (sleepTime);
  }
  
  return 0;
}

int help ( int code){
    if (! code) code=0;
    printf("\n\nlzlz version %f !!!\n",VERSION);
    printf("Usage: gpio  -a | -d parameter parameter ...\n");
    printf("\n\n");
    printf("This program is free software. Use it at your own risk !\n");
    printf("\t-p\tpin number to use.\n");
    printf("\t-a\t- the pin is analogue\n");
    printf("\t-d\t- the pin is digital\n");
    printf("\t-f\tFIFO file\n");
    printf("\t-t\ttime in miliseconds to wait before retrieve sensor valuse again.\n");
    exit(code);
}

int main (int argc, char **argv){
  char *fvalue = NULL;
  char *pvalue = NULL;
  char *tvalue = NULL;
   // a - analogue pin, c - character from the argument, d - digital pin
  int index;
  //int c;

  pthread_t thr; // Define the thread id holder
  
  opterr = 0;
  while ((c = getopt (argc, argv, "a,d,f:,p:,t:")) != -1){
    switch (c){
      case 'a' :
        printf("d is ok !\n");
        a=1;
        break;
      case 'd' :
        d=1;
        printf("d is ok !\n");
        break;
      case 'f':
        fvalue = optarg;
        break;
      case 'p':
        pvalue = optarg;
        break;
      case 't':
        tvalue = optarg;
        break;
      case '?':
        if (optopt == 'f')
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
  
  
  for (index = optind; index < argc; index++){
    printf ("Unknown option:  %s\n", argv[index]);
    help(1);;
  }
  
  if (d ==1 && a == 1){
    printf("You may use only one of -d and -a parameters !!!\n");
    return 1;
  }
  
  printf("d=%i,a=%i",d,a);
  if (d == 0 && a == 0 ){
    printf ("You must specify one of -a or -d !!!\n");
    return 1;
  }
  

  if (! fvalue || ! pvalue || ! tvalue ) help(1);
  if (1 == sscanf(tvalue,"%ld",&sleepTime)){
    printf("Succesfully converted number %ld\n",sleepTime);
  }else{
    printf("Incorrect value of parameter -t\n");
    return 1;
  }

  if (1 == sscanf(pvalue,"%d",&sencePin)){
    printf("Succesfully converted number %d\n",sencePin);
  }else{
    printf("Incorrect value of parameter -t\n");
    return 1;
  }
  
  pipeFile = fvalue;

  printf("Dispatching agent to listen to our device ...\n");

  pthread_create(&thr, NULL, senceMovement, NULL);
  pthread_join(thr, NULL);
  //delay (60000);
  //pthread_cancel(thr);
  printf("The agent has finished.\n");  
  return 0;
}

