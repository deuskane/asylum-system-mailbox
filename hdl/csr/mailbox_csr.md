# mailbox
CSR for mailbox

| Address | Registers |
|---------|-----------|
|0x0|fifo0|
|0x1|status0|
|0x2|fifo1|
|0x3|status1|

## 0x0 fifo0
FIFO0

### [7:0] value
Data TX or Data RX

## 0x1 status0
FIFO0 status (read only, writes are ignored)

### [0:0] empty
1: no data to read in fifo0, a read stalls (BLOCKING_READ) or returns a non valid data

### [1:1] full
1: no free slot in fifo0, a write stalls (BLOCKING_WRITE) or is dropped

## 0x2 fifo1
FIFO1

### [7:0] value
FIFO1 : Data TX or Data RX

## 0x3 status1
FIFO1 status (read only, writes are ignored)

### [0:0] empty
1: no data to read in fifo1, a read stalls (BLOCKING_READ) or returns a non valid data

### [1:1] full
1: no free slot in fifo1, a write stalls (BLOCKING_WRITE) or is dropped

