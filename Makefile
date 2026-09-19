MCU = atmega328p
CC = avr-gcc
OBJCOPY = avr-objcopy
AVRDUDE = avrdude
PORT = COM5
BAUD = 115200

# Chemins FreeRTOS
FREERTOS_PATH = C:\Users\hp\Desktop\freertos_atmega328p_uart_mutex\FreeRTOS_Source

INCLUDES = -I"$(FREERTOS_PATH)/include" \
           -I"$(FREERTOS_PATH)/source/portable" \
           -I.

# Fichiers objets de l'application (main.o ET uart.o)
APP_OBJ = main.o uart.o

# Fichiers objets FreeRTOS
FREERTOS_OBJ = tasks.o queue.o list.o timers.o event_groups.o croutine.o heap_1.o port.o

# -------- BUILD --------

all: main.hex

main.hex: main.elf
	$(OBJCOPY) -R .eeprom -O ihex main.elf main.hex

# Ingestion de APP_OBJ (qui contient main.o ET uart.o)
main.elf: $(APP_OBJ) $(FREERTOS_OBJ)
	$(CC) -mmcu=$(MCU) -o main.elf $(APP_OBJ) $(FREERTOS_OBJ)

main.o: main.c
	$(CC) -c -mmcu=$(MCU) $(INCLUDES) main.c -o main.o

# RÈGLE MANQUANTE : Compilation de uart.c -> uart.o
uart.o: uart.c
	$(CC) -c -mmcu=$(MCU) $(INCLUDES) uart.c -o uart.o

# Compilation des fichiers FreeRTOS
tasks.o: $(FREERTOS_PATH)/source/tasks.c
	$(CC) -c -mmcu=$(MCU) $(INCLUDES) $< -o $@

queue.o: $(FREERTOS_PATH)/source/queue.c
	$(CC) -c -mmcu=$(MCU) $(INCLUDES) $< -o $@

list.o: $(FREERTOS_PATH)/source/list.c
	$(CC) -c -mmcu=$(MCU) $(INCLUDES) $< -o $@

timers.o: $(FREERTOS_PATH)/source/timers.c
	$(CC) -c -mmcu=$(MCU) $(INCLUDES) $< -o $@

event_groups.o: $(FREERTOS_PATH)/source/event_groups.c
	$(CC) -c -mmcu=$(MCU) $(INCLUDES) $< -o $@

croutine.o: $(FREERTOS_PATH)/source/croutine.c
	$(CC) -c -mmcu=$(MCU) $(INCLUDES) $< -o $@

heap_1.o: $(FREERTOS_PATH)/source/portable/heap_1.c
	$(CC) -c -mmcu=$(MCU) $(INCLUDES) $< -o $@

port.o: $(FREERTOS_PATH)/source/portable/port.c
	$(CC) -c -mmcu=$(MCU) $(INCLUDES) $< -o $@

# -------- UPLOAD --------

upload: main.hex
	"C:/Users/hp/Desktop/Arduino/hardware/tools/avr/bin/avrdude" \
		-C"C:/Users/hp/Desktop/Arduino/hardware/tools/avr/etc/avrdude.conf" \
		-v -p$(MCU) -carduino -P$(PORT) -b$(BAUD) -D \
		-Uflash:w:main.hex:i

# -------- CLEAN --------

clean:
	del /Q *.elf *.hex *.o 2>nul || echo Clean complete