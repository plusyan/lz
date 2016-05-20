CC=gcc
CFLAGS=-I.

all:
	$(CC) gpio.c -o gpio $(CFLAGS) -lwiringPi -lpthread -W -O3
clean:
	rm gpio || echo "Mever mind."
