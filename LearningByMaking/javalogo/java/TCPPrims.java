import java.net.Socket;
import java.net.ServerSocket;
import java.net.InetAddress;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.BufferedInputStream;
import java.io.BufferedReader;
import java.io.OutputStream;
import java.lang.StringBuilder;
import java.net.URL;
import java.net.URLConnection;
import java.net.URLEncoder;
import java.net.URLDecoder;

class TCPPrims extends Primitives implements Runnable {

  static String[] primlist={
    "connect", "2", "tcprecv", "0", "tcprecvn", "1", "tcpavail", "0", "tcpsend", "1",
    "tcptimeout", "1", "tcpclose", "0",
    "urlencode", "1", "urldecode", "1",
    "startserver", "1", "ipaddress", "0",
    "newconnection", "0", "readurl", "1"
  };

  public String[] primlist(){return primlist;}

  public Object dispatch(int offset, Object[] args, LContext lc){
    switch(offset){
    case 0: return prim_connect(args[0], args[1], lc);
    case 1: return prim_tcprecv(lc);
    case 2: return prim_tcprecvn(args[0], lc);
    case 3: return prim_tcpavail(lc);
    case 4: return prim_tcpsend(args[0], lc);
    case 5: return prim_tcptimeout(args[0], lc);
    case 6: return prim_tcpclose(lc);
    case 7: return prim_urlencode(args[0], lc);
    case 8: return prim_urldecode(args[0], lc);
    case 9: return prim_startserver(args[0], lc);
    case 10: return ipaddress()+":"+port;
    case 11: return prim_newconnection(lc);
    case 12: return prim_readurl(args[0], lc);
 }
    return null;
  }

  static Sock sock;
  int port;
  LContext lc;
  boolean newconnection;

  String ipaddress(){
    try {return InetAddress.getLocalHost().getHostAddress();}
    catch (Exception e) {return null;}
  }

  Object prim_connect(Object arg1, Object arg2, LContext lc){
    try{sock = new Sock(Logo.aString(arg1, lc), Logo.anInt(arg2, lc));
        sock.sock.setSendBufferSize(1024*1024);
        sock.sock.setKeepAlive(true);}
    catch (Exception e) {Logo.error("connect error: " + e, lc);}
    return null;
  }

  Object prim_tcprecv(LContext lc){
    try{return new Double(sock.sockin.read());}
    catch (Exception e) {return new Double(-1);}
  }

  Object prim_tcprecvn(Object arg1, LContext lc){
    int len = Logo.anInt(arg1,lc), off=0;
    byte[] buf = new byte[len];
    try {
      while(len>0){
        int nread=sock.sockin.read(buf,off,len);
        len-=nread;off+=nread;}}
    catch (Exception e) {Logo.error("tcprecv error: " + e, lc);}
    return buf;
  }

  Object prim_tcpavail(LContext lc){
    try{return new Double(sock.sockin.available());}
    catch (Exception e) {return new Double(-1);}
  }

  Object prim_tcpsend(Object arg1, LContext lc){
    try{
      if(arg1 instanceof byte[]) sock.sockout.write((byte[])arg1);
      else if(arg1 instanceof String) sock.sockout.write(((String)arg1).getBytes());
      else sock.sockout.write(Logo.anInt(arg1, lc));
      sock.sockout.flush();}
    catch (Exception e) {Logo.error("tcpsend error: " + e, lc);}
    return null;
  }

  Object prim_tcptimeout(Object arg1, LContext lc){
    int to = Logo.anInt(arg1,lc);
    try{sock.sock.setSoTimeout(to);}
    catch (Exception e) {Logo.error("tcptimeout error: " + e, lc);}
    return null;
  }

  Object prim_urlencode(Object arg1, LContext lc){
    try{return URLEncoder.encode(Logo.prs(arg1), "UTF-8");}
    catch (Exception e) {Logo.error("urlencode error: " + e, lc);}
    return null;
  }

  Object prim_urldecode(Object arg1, LContext lc){
    try{return URLDecoder.decode(Logo.prs(arg1), "UTF-8");}
    catch (Exception e) {Logo.error("urldecode error: " + e, lc);}
    return null;
  }

  Object prim_readurl(Object arg1, LContext lc){
    String s = Logo.prs(arg1);
    StringBuilder content = new StringBuilder();
    try
    {
      URL url = new URL(s);
      URLConnection urlConnection = url.openConnection();
      BufferedReader bufferedReader = new BufferedReader(new InputStreamReader(urlConnection.getInputStream()));
      String line;
      while ((line = bufferedReader.readLine()) != null){content.append(line + "\n");}
      bufferedReader.close();
    } catch(Exception e) {Logo.error("urlread error: "+e, lc);}
    return content.toString();
  }

  Object prim_tcpclose(LContext lc){
    try{
      sock.sock.close();
      sock = null;
    }
    catch (Exception e) {Logo.error("tcpsend error: " + e, lc);}
    return null;
  }


  Object prim_startserver(Object arg1, LContext lc){
    port = Logo.anInt(arg1, lc);
    this.lc = lc;
    new Thread(this).start();
    return null;
  }

  public void run(){
    ServerSocket srv;
    try {srv = new ServerSocket(port, 1);}
    catch(Exception e){StdioJL.println("server "+e); return;}
    while(true){
    try {
      sock = new Sock(srv.accept());
      StdioJL.println("connected to: "+sock.sock.getInetAddress());
      newconnection = true;
//      while(true) {
//        int c = sock.sockin.read();
//        if(c==-1) {sock.sock.close(); break;}
//        }
    } catch(Exception e){System.out.println("server "+e);}
    }
  }

  Object prim_newconnection(LContext lc){
      if(newconnection) {newconnection=false; return new Boolean(true);}
      return new Boolean(false);
  }

  void writeArray(byte[] buf) throws Exception{
    int len = buf.length, addr=0;
    while(len>0){
      System.out.println(len);
      int chunk=(len<1000)?len:1000;
      sock.sockout.write(buf, addr, chunk);
      addr+=chunk;
      len-=chunk;
    }
  }


}

class Sock {
  Socket sock;
  InputStream sockin;
  OutputStream sockout;

  Sock(String addr, int port) throws Exception{
    sock = new Socket(addr, port);
    sockin = new BufferedInputStream(sock.getInputStream());
    sockout = sock.getOutputStream();
  }

  Sock(Socket s) throws Exception{
    sock = s;
    sockin = new BufferedInputStream(sock.getInputStream());
    sockout = sock.getOutputStream();
  }


}
