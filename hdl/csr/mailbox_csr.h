#ifndef MAILBOX_REGISTERS_H
#define MAILBOX_REGISTERS_H

#include <stdint.h>

// Module      : mailbox
// Description : CSR for mailbox
// Width       : 8

//==================================
// Register    : fifo0
// Description : FIFO0
// Address     : 0x0
//==================================
#define MAILBOX_FIFO0 0x0

// Field       : fifo0.value
// Description : Data TX or Data RX
// Range       : [7:0]
#define MAILBOX_FIFO0_VALUE      0
#define MAILBOX_FIFO0_VALUE_MASK 255

//==================================
// Register    : fifo1
// Description : FIFO1
// Address     : 0x2
//==================================
#define MAILBOX_FIFO1 0x2

// Field       : fifo1.value
// Description : FIFO1 : Data TX or Data RX
// Range       : [7:0]
#define MAILBOX_FIFO1_VALUE      0
#define MAILBOX_FIFO1_VALUE_MASK 255

//----------------------------------
// Structure {module}_t
//----------------------------------
typedef struct {
  uint8_t fifo0; // 0x0
  uint8_t __dummy_0x1__
  uint8_t fifo1; // 0x2
} mailbox_t;

#endif // MAILBOX_REGISTERS_H
