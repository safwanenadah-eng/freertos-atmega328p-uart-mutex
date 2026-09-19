#include <avr/io.h>
#include "FreeRTOS.h"
#include "task.h"
#include "uart.h"

void vTask1(void *pvParameters)
{
    while (1)
    {
        // Utilisation de l'API sécurisée avec Mutex
        UART_SendString_Safe("[TASK 1] Hello World! Executing task 1...\r\n");
        vTaskDelay(pdMS_TO_TICKS(100));
    }
}

void vTask2(void *pvParameters)
{
    while (1)
    {
        // Utilisation de l'API sécurisée avec Mutex
        UART_SendString_Safe("[TASK 2] >>> CRITICAL WARNING FROM TASK 2 <<<\r\n");
        vTaskDelay(pdMS_TO_TICKS(100));
    }
}

int main(void)
{
    UART_Init(9600);

    xTaskCreate(vTask1, "Task1", 128, NULL, 1, NULL);
    xTaskCreate(vTask2, "Task2", 128, NULL, 1, NULL);

    vTaskStartScheduler();

    while (1) { ; }
    return 0;
}

void vApplicationIdleHook(void)
{
}