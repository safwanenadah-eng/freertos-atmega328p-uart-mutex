#ifndef UART_H_
#define UART_H_

#include <stdint.h>

// Initialise l'UART et crée le Mutex FreeRTOS
void UART_Init(uint32_t baudrate);

// Envoi bas niveau
void UART_SendChar(char c);

// Envoi classique (non sécurisé)
void UART_SendString(const char *str);

// Envoi Thread-Safe (sécurisé par Mutex)
void UART_SendString_Safe(const char *str);

#endif /* UART_H_ */