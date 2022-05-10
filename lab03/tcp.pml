#define rand(var) if \
:: var = 1;          \
:: var = 2;          \
:: var = 3;          \
:: var = 4;          \
:: var = 5;          \
fi                   \


#define randAckNumber(ack, window, receivedSeqNumbers, j) if \
:: ack = ack + window - 1; receivedSeqNumbers[j] = 0;        \
:: ack = ack + window;                                       \
:: ack = ack + window + 1;                                   \
fi                                                           \


#define MAX_DATA_BUFER_SIZE      100
#define MAX_WINDOW_SIZE          100


mtype {SYN, SYNACK, ACK, DATA, FIN, FINACK, RST};


/* 
Simplified implementation of Transfer Control Protocol.
Sender and receiver exchange initial sequnce and acknowledgement numbers
and then use it to exchange data. If sender receive RST message during connection 
establishment, connection establichment process will be terminated.
After sender send specified number of messages it will initiate process of closing the connection.
Sender and receiver always checks sequence and acknowledgement numbers but never
*/


proctype Sender(chan ch; byte msgCount)
{
  byte senderNumber, receiverNumber;
  byte seqNumber = 0, ackNumber, window;
  byte data[MAX_DATA_BUFER_SIZE];

  printf("SENDER: running, pid=%d\n", _pid);

  rand(senderNumber);
  printf("SENDER: sending SYN\n");
  ch ! SYN(senderNumber);
  printf("SENDER: waiting for SYNACK\n");

  if
  :: ch ? SYNACK(receiverNumber, window) ->
    ch ! ACK(receiverNumber);
    printf("SENDER: connection established, senderNumber=%d, receiverNumber=%d, window=%d\n", senderNumber, receiverNumber, window);

    do
    :: seqNumber < msgCount ->
      do
      :: window > 0 && seqNumber < msgCount ->
        rand(data[seqNumber]);
        printf("SENDER: sending DATA %d with seq number %d\n", data[seqNumber], senderNumber + seqNumber);
        ch ! DATA(senderNumber + seqNumber, data[seqNumber]);
        seqNumber++;
        window--;
      :: else -> break;
      od
      
      printf("SENDER: waiting for ACK\n");
      ch ? ACK(ackNumber, window);
      byte nextPackage = ackNumber - receiverNumber;

      if
      :: nextPackage >= seqNumber && window > 0 ->
        printf("SENDER: ACK received, ackNumber=%d(packageNumber=%d), window=%d\n", ackNumber, nextPackage, window);
      :: nextPackage < seqNumber && window > 0 ->
        printf("SENDER: ACK received, package lost, retring from packageNumber=%d\n", nextPackage);
      :: else -> 
        printf("SENDER: ACK received, window == 0, wating for receiver is ready to receive\n");

        do
        :: ch ? ACK(ackNumber, window) ->
          if
          :: window > 0 -> 
            nextPackage = ackNumber - receiverNumber;
            break;
          :: else -> skip;
          fi
        od
      fi

      seqNumber = nextPackage;

    :: else -> 
      printf("SENDER: end of transmition, closing connection ...\n");
      ch ! FIN;
      ch ? FINACK;
      ch ! ACK;
      printf("SENDER: connection closed\n");
      break;
    od
  :: ch ? RST -> 
    printf("SENDER: RST received, connection was not established\n");
  fi
}


proctype Receiver(chan ch; byte window)
{
  byte senderNumber, receiverNumber;
  byte seqNumber, ackNumber = 0, expectedPackageNumber;
  byte data, temp;

  printf("RECEIVER: running, pid=%d\n", _pid);

  printf("RECEIVER: waiting for SYN\n");
  ch ? SYN(senderNumber);
  printf("RECEIVER: sending SYNACK\n");
  rand(receiverNumber);
  ch ! SYNACK(receiverNumber, window);
  printf("RECEIVER: waiting for ACK\n");
  ch ? ACK(temp);

  if
  :: temp == receiverNumber ->
    printf("RECEIVER: connection established, senderNumber=%d, receiverNumber=%d, window=%d\n", senderNumber, receiverNumber, window);

    byte receivedSeqNumbers[MAX_WINDOW_SIZE];
    byte i = 0, j = 0;

    do
    :: ch ? DATA(seqNumber, data) -> 
      byte packageNumber = seqNumber - senderNumber;

      if
      :: packageNumber >= ackNumber && packageNumber < ackNumber + window ->
        j = 0;

        do
        :: j < i && receivedSeqNumbers[j] != seqNumber -> j++;
        :: j == i ->
          printf("RECEIVER: valid DATA %d received, seqNumber=%d\n", data, seqNumber);
          receivedSeqNumbers[j] = seqNumber;
          i++; 
          break;
        :: else -> 
          printf("RECEIVER: duplicate DATA %d received, ignoring\n", data);
          break;
        od
      :: else ->
        printf("RECEIVER: invalid DATA %d received, seqNumber=%d out of expected range\n", data, seqNumber);
      fi

      if
      :: i == window ->
        printf("RECEIVER: window is full, generating new ackNumber and window\n");
        randAckNumber(ackNumber, window, receivedSeqNumbers, j);
        rand(window);
        printf("RECEIVER: new ackNumber=%d, new window=%d\n", ackNumber, window);
        ch ! ACK(receiverNumber + ackNumber, window);
        i = 0;
      :: else -> skip
      fi

    :: ch ? FIN ->
      printf("RECEIVER: FIN received, closing connection ...\n");
      ch ! FINACK;
      ch ? ACK;
      printf("RECEIVER: connection closed\n");

    :: timeout -> 
      ch ! ACK(0, 1);
    od
  :: else ->
    printf("RECEIVER: error during connection establishment, exiting ...")
  fi
}


init
{
  byte msgCount = 5;  // Number of DATA messages that will be sent by the sender
  byte window = 1;    // Initial receiver window size
  chan ch = [3] of { mtype, byte, byte }

  run Sender(ch, msgCount);
	run Receiver(ch, window);
}