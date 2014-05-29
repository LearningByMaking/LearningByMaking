
public class PCSerialHandler extends SerialHandler {

  static final String[] parityLetter = {"N", "E", "O", "M", "S"};
  static {System.loadLibrary("javaserial-v2");}

  boolean openPort (String portname) {
    closePort();
    return nOpenPort(portname)!=0;
  }

  void closePort () {
    nClosePort();
  }

  String getPortName(int pid, int vid){
		String fname = nGetPortName(pid, vid);
		return portPath(fname);
	}

  Object[] getPortNames(int pid, int vid){
		String fname = nGetPortName(pid, vid);
		String [] ports = fname.split("::");
		Object [] res = new Object[ports.length];
		for(int i=0;i<ports.length;i++) res[i] = portPath(ports[i]);
		return res;
	}

	String portPath(String fname){
		int s = fname.lastIndexOf('(');
		int e = fname.lastIndexOf(')');
		if(s==-1) return "";
		if(e==-1) return "";
		return "\\\\.\\"+fname.substring(s+1,e);
	}


  int readbyte() {return nReadbyte ();}
  void clearcom() {nClearcom ();}
  void writebyte(int b) {nWritebyte (b);}
	void writebytes(byte[] arr){nWritebytes(arr);}
  void usbInit() {nUsbInit ();}
  int portHandle() {return nPortHandle ();}
  void modemCtrl(int dtr, int rts) {nModemCtrl (dtr, rts);}

  void setSerialPortParams(int baud, int databits,
                                  int stopbits, int parity){
    String control = "baud="+baud+" parity="+parityLetter[parity];
    control += " data="+databits+" stop="+stopbits;
    nSetCommState(control);
  }

  static native int nOpenPort(String s);
  static native boolean nClosePort();
  static native boolean nSetCommState(String control);
  static native int nReadbyte();
  static native boolean nClearcom();
  static native boolean nWritebyte(int b);
  static native boolean nWritebytes(byte[] arr);
  static native boolean nUsbInit();
  static native int nPortHandle();
  static native String nGetPortName(int pid, int vid);
  static native boolean nModemCtrl(int dtr, int rts);
}

