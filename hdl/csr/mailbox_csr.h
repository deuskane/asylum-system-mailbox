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
// Register    : status0
// Description : FIFO0 status (read only, writes are ignored)
// Address     : 0x1
//==================================
#define MAILBOX_STATUS0 0x1

// Field       : status0.empty
// Description : 1: no data to read in fifo0, a read stalls (BLOCKING_READ) or returns a non valid data
// Range       : [0]
#define MAILBOX_STATUS0_EMPTY      0
#define MAILBOX_STATUS0_EMPTY_MASK 1

// Field       : status0.full
// Description : 1: no free slot in fifo0, a write stalls (BLOCKING_WRITE) or is dropped
// Range       : [1]
#define MAILBOX_STATUS0_FULL      1
#define MAILBOX_STATUS0_FULL_MASK 1

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

//==================================
// Register    : status1
// Description : FIFO1 status (read only, writes are ignored)
// Address     : 0x3
//==================================
#define MAILBOX_STATUS1 0x3

// Field       : status1.empty
// Description : 1: no data to read in fifo1, a read stalls (BLOCKING_READ) or returns a non valid data
// Range       : [0]
#define MAILBOX_STATUS1_EMPTY      0
#define MAILBOX_STATUS1_EMPTY_MASK 1

// Field       : status1.full
// Description : 1: no free slot in fifo1, a write stalls (BLOCKING_WRITE) or is dropped
// Range       : [1]
#define MAILBOX_STATUS1_FULL      1
#define MAILBOX_STATUS1_FULL_MASK 1

//----------------------------------
// Structure mailbox_t
//----------------------------------
typedef struct {
  uint8_t fifo0; // 0x0
  uint8_t status0; // 0x1
  uint8_t fifo1; // 0x2
  uint8_t status1; // 0x3
} mailbox_t;

#endif // MAILBOX_REGISTERS_H
