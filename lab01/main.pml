#define rand(var) if \
:: var = 1;   \
:: var = 2;   \
:: var = 3;   \
:: var = 4;   \
:: var = 5;   \
fi            \

mtype {EST, MSG, ACK, CLS};

/* 
Simple fictional data exchange protocol with connection establishment.
Firstly both sender and receiver must send EST message to each other 
and wait for ACK response. After the connection established sender send 
N messages to receiver and wait for ACK response for each sended message.
When the transmishion is finished both sides should send CLS message 
with waiting for ACK response.
*/

proctype Sender(chan ch; int msgCount)
{
	byte sendbit, recvbit;

    printf("SENDER: running, pid=%d\n", _pid);

    rand(sendbit);
    printf("SENDER: sending EST\n");
    ch ! EST, sendbit;
    printf("SENDER: waiting for ACK\n");
    ch ? ACK, recvbit;

    if
    :: recvbit == sendbit -> 
      printf("SENDER: ACK received, waiting for EST\n");
      ch ? EST, recvbit;
      printf("SENDER: EST received, sending ACK\n");
      ch ! ACK, recvbit;
      printf("SENDER: connection established\n");

      do
	  :: msgCount > 0 ->
        rand(sendbit);
        printf("SENDER: sending MSG %d\n", sendbit);
		ch ! MSG, sendbit;
        printf("SENDER: waiting for ACK\n");
        ch ? ACK, recvbit;
        msgCount = msgCount - 1;
		if
		:: recvbit == sendbit -> printf("SENDER: ACK received, verification number is valid\n");
		:: else -> printf("SENDER: ACK received, but verification number is invalid\n");
		fi
      :: msgCount == 0 -> 
        rand(sendbit);
        printf("SENDER: end of transmition, sending CLS\n");
        ch ! CLS, sendbit;
        printf("SENDER: waiting for ACK\n");
        ch ? ACK, recvbit;
        if 
        :: recvbit == sendbit -> 
            printf("SENDER:: ACK received, waiting for CLS\n");
            ch ? CLS, recvbit;
            ch ! ACK, recvbit;
            printf("SENDER: CLS received, clean close\n");
        :: else -> printf("SENDER: ACK received, invalid verification number, dirty close\n");
        fi
        break;
	  od
    :: else -> printf("SENDER: ACK received, invalid verification number, connection was not established\n");
    fi
}

proctype Receiver(chan ch)
{
    byte sendbyte, recvbyte;

    printf("RECEIVER: running, pid=%d\n", _pid);

    printf("RECEIVER: waiting for EST\n");
    ch ? EST, recvbyte;
    printf("RECEIVER: EST received, sending ACK\n");
    ch ! ACK, recvbyte;
    rand(sendbyte);
    printf("RECEIVER: sending EST\n");
    ch ! EST, sendbyte;
    printf("RECEIVER: waiting for ACK\n");
    ch ? ACK, recvbyte;

    if
    :: recvbyte == sendbyte ->
      printf("RECEIVER: connection established, waiting for incoming MSG\n");
      do
      :: ch ? MSG, recvbyte -> 
        printf("RECEIVER: MSG received with code %d\n", recvbyte);
        ch ! ACK, recvbyte;
      :: ch ? CLS, recvbyte ->
        printf("RECEIVER: CLS received, closing connection ...\n");
        ch ! ACK, recvbyte;
        rand(sendbyte);
        ch ! CLS, sendbyte;
        ch ? ACK, recvbyte;
        if 
        :: recvbyte == sendbyte -> 
          break;
        :: else
        fi
      od
    :: else
    fi
}

init
{
    int msgCount = 5;
    chan ch = [2] of { mtype, byte }
    run Sender(ch, msgCount);
	run Receiver(ch);
}