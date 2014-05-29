class SerialPrims extends Primitives {

  static String[] primlist={
    "openport", "1", "closeport", "0",
    "portname", "2", "portnames", "2", "setportparams", "4",
    ".send", "1", "sendl", "1", ".recc", "0",
    "clearcom", "0", "usbinit", "0", "porthandle", "0",
    "modemctrl", "2", "windows?", "0"
  };

  public String[] primlist(){return primlist;}

  public Object dispatch(int offset, Object[] args, LContext lc){
    switch(offset){
      case 0: return prim_openport(args[0], lc);
      case 1: return prim_closeport(lc);
      case 2: return prim_portname(args[0], args[1], lc);
      case 3: return prim_portnames(args[0], args[1], lc);
      case 4: return prim_setportparams(args[0], args[1], args[2], args[3], lc);
      case 5: return prim_send(args[0], lc);
      case 6: return prim_sendl(args[0], lc);
      case 7: return prim_recc(lc);
      case 8: return prim_clearcom(lc);
      case 9: return prim_usbinit(lc);
      case 10: return prim_porthandle(lc);
      case 11: return prim_modemctrl(args[0], args[1], lc);
      case 12: return new Boolean (System.getProperty("os.name").toLowerCase().startsWith("windows"));
    }
    return null;
  }

  static SerialHandler handler;

  static  {try {
  			String serialclass;
            if(System.getProperty("os.name").toLowerCase().startsWith("windows"))
              serialclass="PCSerialHandler";
            else {
           	  serialclass = "MacSerialHandler";
			}
            Class cl=Class.forName(serialclass);
            handler=(SerialHandler) cl.newInstance();
           } catch (Exception e) {System.out.println(e);}
   }

  Object prim_openport(Object arg1, LContext lc){
		String name = Logo.prs(arg1);
    if (!handler.openPort(name)) Logo.error("can't open port "+name, lc);
    return null;
  }

  Object prim_closeport(LContext lc){
    handler.closePort();
    return null;
  }

  Object prim_portname(Object arg1, Object arg2, LContext lc){
		int pid = Logo.anInt(arg1, lc);
		int vid = Logo.anInt(arg2, lc);
    return handler.getPortName(pid, vid);
  }

  Object prim_portnames(Object arg1, Object arg2, LContext lc){
		int pid = Logo.anInt(arg1, lc);
		int vid = Logo.anInt(arg2, lc);
    return handler.getPortNames(pid, vid);
  }

  Object prim_setportparams(Object arg1, Object arg2, Object arg3, Object arg4, LContext lc){
    int baud = Logo.anInt(arg1, lc);
    int databits = Logo.anInt(arg2, lc);
    int stopbits = Logo.anInt(arg3, lc);
    int parity = Logo.anInt(arg4, lc);
    handler.setSerialPortParams(baud, databits, stopbits, parity);
    return null;
  }

  Object prim_send(Object arg1, LContext lc){
    handler.writebyte(Logo.anInt(arg1, lc));
    return null;
  }

  Object prim_sendl(Object arg1, LContext lc){
		Object[] arr = Logo.aList(arg1, lc);
		byte[] barr = new byte[arr.length];
		for(int i=0;i<arr.length;i++) barr[i] = (byte)(Logo.anInt(arr[i],lc));
    handler.writebytes(barr);
    return null;
  }

  Object prim_recc(LContext lc){
    return new Double(handler.readbyte());
  }

  Object prim_clearcom(LContext lc){
    handler.clearcom();
    return null;
  }

  Object prim_porthandle(LContext lc){;
    return new Double(handler.portHandle());
  }

  Object prim_usbinit(LContext lc){
    handler.usbInit();
    return null;
  }

  Object prim_modemctrl(Object arg1, Object arg2, LContext lc){
    handler.modemCtrl(Logo.anInt(arg1, lc), Logo.anInt(arg2, lc));
    return null;
  }
}
