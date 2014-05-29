
public abstract class SerialHandler {

  boolean openPort (String s) {return false;}
  boolean reopenPort() {return false;}
  String getPortName(int pid, int vid) {return null;}
  Object[] getPortNames(int pid, int vid) {return null;}
  void closePort () {}
  int readbyte () {return 0;}
  void clearcom () {}
  void writebyte (int b) {}
  void writebytes (byte[] arr) {}
	int portHandle() {return 0;}
  void usbInit () {}
  void modemCtrl(int dtr, int rts) {}

  void setSerialPortParams(int baud, int databits,
                                  int stopbits, int parity){};
}

