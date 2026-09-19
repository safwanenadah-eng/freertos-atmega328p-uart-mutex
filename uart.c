#ifndef F_CPU
#define F_CPU 16000000UL
#endif

#include <avr/io.h>
#include "uart.h"

// En-têtes FreeRTOS requis pour le Mutex
#include "FreeRTOS.h"
#include "semphr.h"

// Déclaration du handle du Mutex (privé à uart.c)
static SemaphoreHandle_t xUARTMutex = NULL;

void UART_Init(uint32_t baudrate)
{
    uint16_t ubrr_value = (F_CPU / (16 * baudrate)) - 1;

    UBRR0H = (uint8_t)(ubrr_value >> 8);
    UBRR0L = (uint8_t)ubrr_value;

    UCSR0B = (1 << TXEN0) | (1 << RXEN0);
    UCSR0C = (1 << UCSZ01) | (1 << UCSZ00);

    // CRÉATION DU MUTEX FREERTOS
    xUARTMutex = xSemaphoreCreateMutex();
}

void UART_SendChar(char c)
{
    while (!(UCSR0A & (1 << UDRE0))) { ; }
    UDR0 = c;
}

void UART_SendString(const char *str)
{
    while (*str != '\0')
    {
        UART_SendChar(*str);
        str++;
    }
}

void UART_SendString_Safe(const char *str)
{
    if (xUARTMutex != NULL)
    {
        // 1. Demander le verrou (Mutex)
        if (xSemaphoreTake(xUARTMutex, portMAX_DELAY) == pdTRUE)
        {
            // 2. Section Critique : Transmission exclusive du message
            while (*str != '\0')
            {
                UART_SendChar(*str);
                str++;
            }

            // 3. Libérer le verrou (Mutex)
            xSemaphoreGive(xUARTMutex);
        }
    }
}