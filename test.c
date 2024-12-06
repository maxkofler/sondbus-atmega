#include <stdint.h>

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
    uint8_t gp_1;
    uint8_t gp_2;
    uint8_t gp_3;
} sondbus_instance;

void sondbus_init(sondbus_instance *state, uint8_t my_address)
{
    state->state = 0;
    state->my_address = my_address;
}

void sondbus_rx(sondbus_instance *memory, uint8_t incoming_byte);

int main()
{
    sondbus_instance state;

    sondbus_init(&state, 0x1);

    while (1)
    {
        // Enter the start byte: 0x55
        sondbus_rx(&state, 0x55);

        // Then the type
        sondbus_rx(&state, 0x10);

        // Address
        sondbus_rx(&state, 0x11);

        // Length
        sondbus_rx(&state, 0x12);

        // CRC
        sondbus_rx(&state, 0x00);
    }
}
