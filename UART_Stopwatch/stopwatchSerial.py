# Serial interface for FPGA implementation of UART controlled stopwatch

# setup serial port
import serial                   
PORT = 'COM8'
BAUD = 19200
s = serial.Serial(PORT, BAUD)
s.flush()

# variables to hold received user input and received timestamp fro;m FPGA
c = ''
r = ''

# welcome message
print("Stopwatch Control Interface:\nEnter g or G to go\nEnter s or S to stop\nEnter c or C to clear\nEnter r or R to receive time\nEnter e or E to exit\n")

# event loop
while(True):
    # get user input
    c = input()

    # user wants to exit
    if(c == 'e' or c == 'E'):
        s.close()
        
        print("goodbye!\n")
        break

    # start stopwatch
    elif(c == 'g' or c == 'G'):
        print("start\n")
        # write encoded input over UART
        s.write(c.encode())
        
    # stop stopwatch
    elif(c == 's' or c == 'S'):
        print("stop\n")
        # write encoded input over UART
        s.write(c.encode())

    # clear stopwatch
    elif(c =='c' or c == 'C'):
        print("clear\n")
        # write encoded input over UART
        s.write(c.encode())

    # received timestamp
    elif(c == 'r' or c == 'R'):
        # write encoded input over UART
        s.write(c.encode())
        print("receive\n")
        
        #reset received timestamp
        r = ''
        # read in 5 bytes, decode to char and append to r
        for i in range(5):
            r += (s.read(1)).decode()
        print(r)

    # invalid input
    else:
        print("invalid input\n")
        
    
