import java.io.File;
import java.io.FileOutputStream;
import java.io.FileInputStream;
import java.io.IOException;

public class MacSerialHandler extends SerialHandler {

  String name;
  FileInputStream fis;
  FileOutputStream fos;

	boolean openPort (String s) {
    closePort();
    if(!(new File(s)).exists()) return false;
    try {
			fos = new FileOutputStream(s);
			fis = new FileInputStream(s);
    }
    catch (IOException e) {return false;}
    return true;
  }

  boolean reopenPort(){
    return true;
  }


  void closePort () {
		try {
				if(fos!=null) fos.close();
				if(fis!=null) fis.close();
		}
		catch (IOException e) {System.out.println(e);}
	}

  void writebyte (int b) {
		if(fos==null) return;
		try {fos.write(b);}
		catch (IOException e) {System.out.println(e);}
	}

  void writebytes (byte[] arr) {
		if(fos==null) return;
		try {fos.write(arr);}
		catch (IOException e) {System.out.println(e);}
	}

  void clearcom() {
		if(fis==null) return;
		try {while(fis.available()>0) fis.read();}
		catch (IOException e) {System.out.println(e);}
	}


  int readbyte () {
		if(fis==null) return -1;
		try {
			if(fis.available()==0) return -1;
			return fis.read();
		}
		catch (IOException e) {return -1;}
	}

}

