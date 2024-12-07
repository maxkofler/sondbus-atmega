#define F_CPU 16000000

#include <avr/io.h>
#include <avr/interrupt.h>
#include <util/delay.h>
#include <stdint.h>

#define USART_BAUDRATE 1000000 // We really want 2000000, that is accomplished by using 2x later
#define BAUD_PRESCALE (((F_CPU / (USART_BAUDRATE * 16UL))) - 1)

typedef struct __attribute__((__packed__))
{
    /// @brief The current state of the sondbus stack
    uint8_t state;
    /// @brief The remaining bytes that still need to be processed
    uint8_t remaining_bytes;
    /// @brief The address of this sondbus instance
    uint8_t my_address;
    /// @brief  The current frame type that is being processed
    uint8_t cur_frame_type;
    /// @brief  The current value for the CRC
    uint8_t crc;
    uint8_t gp_1;
    uint8_t gp_2;
    uint8_t gp_3;
} sondbus_instance;

void sondbus_init(sondbus_instance *state, uint8_t my_address)
{
    state->state = 0;
    state->my_address = my_address;
}

uint16_t sondbus_rx(sondbus_instance *, uint8_t incoming_byte);

sondbus_instance sondbus_0;

int main()
{

    sondbus_init(&sondbus_0, 0x1);

    // Enable USART x2 frequency to reach 2_000_000 BAUD
    UCSR0A |= (1 << 1);
    // Enable RX and TX and their respective interrupts
    UCSR0B = (1 << 7) | (1 << 6) | (1 << 4) | (1 << 3);
    // We operate in asynchronous mode with 8n1
    UCSR0C = (1 << 1) | (1 << 2);
    UBRR0L = BAUD_PRESCALE;
    UBRR0H = (BAUD_PRESCALE >> 8);

    DDRB = 0xFF;
    PORTB = 0x0;

    sei();

    while (1)
    {
    }
}

ISR(USART0_RX_vect)
{
    if (UCSR0A & 1 << 7)
    {
        uint8_t data = UDR0;
        uint16_t res = sondbus_rx(&sondbus_0, data);

        if ((res >> 8) & 0xFF)
        {
            PORTB ^= (1 << 7);
            UDR0 = res & 0xFF;
        }
    }
}

ISR(USART0_TX_vect)
{
    if (UCSR0A & (1 << 5))
    {

        uint16_t res = sondbus_rx(&sondbus_0, 0);

        if ((res >> 8) & 0xFF)
        {
            PORTB ^= (1 << 7);
            UDR0 = res & 0xFF;
        }
    }
}
