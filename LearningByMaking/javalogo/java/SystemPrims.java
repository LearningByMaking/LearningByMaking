import java.util.Vector;
import java.text.SimpleDateFormat;
import java.text.ParseException;
import java.util.Date;
import java.util.TimeZone;
import java.io.InputStreamReader;
import java.io.BufferedReader;
import java.io.OutputStream;
import java.io.ByteArrayOutputStream;
import java.util.Date;

class SystemPrims extends Primitives {

  static String[] primlist={
    "resett", "0",
    "timer", "0",
    "eq", "2",
    "(", "0",
    ")", "0",
    "wait", "1",
    "true", "0",
    "false", "0",
    "hexw", "2",
    "octw", "2",
    "tab", "0",
    "classof", "1",
    "class", "1",
    "string", "1",
    "%nothing%", "0",
    "cprint", "1",
    "print", "1",
    "hexparse", "1",
    "scanhex", "3",
    "exec", "1",
    "blindexec", "1",
    "getproperty", "1",
    "ignore", "1",
    "qsym", "1",
    "now", "0",
    "dateformat", "3",
    "dateparse", "2",
    "exit", "0",
    "clarg", "1",
    "setindent", "1",
    "sethandleline", "1",
  };

  public String[] primlist(){return primlist;}

  public Object dispatch(int offset, Object[] args, LContext lc){
    switch(offset){
      case 0: return prim_resett(lc);
      case 1: return prim_timer(lc);
      case 2: return prim_eq(args[0], args[1], lc);
      case 3: return prim_parleft(lc);
      case 4: return prim_parright(lc);
      case 5: return prim_wait(args[0], lc);
      case 6: return prim_true(lc);
      case 7: return prim_false(lc);
      case 8: return prim_hexw(args[0], args[1], lc);
      case 9: return prim_octw(args[0], args[1], lc);
      case 10: return prim_tab(lc);
      case 11: return prim_classof(args[0], lc);
      case 12: return prim_class(args[0], lc);
      case 13: return prim_string(args[0], lc);
      case 14: return new Nothing();
      case 15: System.out.println(Logo.prs(args[0])); return null;
      case 16: StdioJL.println(Logo.prs(args[0])); return null;
      case 17: return prim_hexparse(args[0], lc);
      case 18: return prim_scanhex(args[0], args[1], args[2], lc);
      case 19: return prim_exec(args[0], lc);
      case 20: return prim_blindexec(args[0], lc);
      case 21: return prim_getProperty(args[0], lc);
      case 22: return null;   // ignore
      case 23: return prim_qsym(args[0], lc);
      case 24: return prim_now(lc);
      case 25: return prim_dateformat(args[0], args[1], args[2], lc);
      case 26: return prim_dateparse(args[0], args[1], lc);
      case 27: System.exit(0); return null;
      case 28: return prim_clarg(args[0], lc);
      case 29: lc.indent = Logo.prs(args[0]);
      case 30: lc.handleLine = Logo.aBoolean(args[0], lc);
    }
    return null;
  }

  Object prim_resett(LContext lc){
    Logo.starttime=System.currentTimeMillis();
    return null;
  }

  Object prim_timer(LContext lc){
    return new Double(System.currentTimeMillis()-Logo.starttime);
  }

  Object prim_eq(Object arg1, Object arg2, LContext lc){
    return new Boolean(arg1.equals(arg2));
  }

  Object prim_parright(LContext lc){
    Logo.error("Missing \"(\"", lc);
    return null;
  }

  Object prim_parleft(LContext lc){
    if (ipmnext(lc.iline)) return ipmcall(lc);
    Object arg=Logo.eval(lc), next=lc.iline.next();
    if ((next instanceof Symbol) &&
        ((Symbol) next).pname.equals(")"))
      return arg;
    Logo.error("Missing \")\"", lc);
    return null;
  }

  boolean ipmnext(MapList iline){
    try { return ((Symbol)iline.peek()).fcn.ipm;}
    catch (Exception e) {return false;}
  }

  Object ipmcall(LContext lc){
    Vector<Object> v=new Vector<Object>();
    lc.cfun=(Symbol) lc.iline.next();
    while(!finIpm(lc.iline))
      v.addElement(Logo.evalOneArg(lc.iline, lc));
    Object[] o=new Object[v.size()];
    v.copyInto(o);
    return Logo.evalSym(lc.cfun, o, lc);
  }

  boolean finIpm(MapList l){
    if (l.eof()) return true;
    Object next=l.peek();
    if ((next instanceof Symbol) &&
        ((Symbol) next).pname.equals(")"))
      {l.next();return true;}
    return false;
  }

  Object prim_wait(Object arg1, LContext lc){
    double d=10*Logo.aDouble(arg1, lc);
    int n = (int)d;
    for(int i=0;i<n;i++){
     if(lc.timeToStop) return null;
     try{Thread.sleep(10);}
     catch(InterruptedException e){};
    }
    return null;
  }

  Object prim_hexw(Object arg1, Object arg2, LContext lc){
    Logo.anInt(arg1, lc);
    String s = Logo.prs(arg1, 16);
    int len = Logo.anInt(arg2, lc);
    String pad = "00000000".substring(8-len+s.length());
    return pad+s;
  }

  Object prim_octw(Object arg1, Object arg2, LContext lc){
    Logo.anInt(arg1, lc);
    String s = Logo.prs(arg1, 8);
    int len = Logo.anInt(arg2, lc);
    String pad = "00000000".substring(8-len+s.length());
    return pad+s;
  }

  Object prim_true(LContext lc){return new Boolean(true);}
  Object prim_false(LContext lc){return new Boolean(false);}
  Object prim_tab(LContext lc){return "\t";}

  Object prim_classof(Object arg1, LContext lc){
    return arg1.getClass();
  }

  Object prim_class(Object arg1, LContext lc){
    try {return Class.forName(Logo.prs(arg1));}
    catch (Exception e) {return "";}
    catch (Error e) {return "";}
  }

  Object prim_string(Object arg1, LContext lc){
    if(arg1 instanceof byte[]) return new String((byte[])arg1);
    return prstring (arg1);
  }


  String prstring(Object l) {
    if(l instanceof Number && Logo.isInt((Number)l))
       return Long.toString(((Number)l).longValue(), 10);
    if(l instanceof String) return "|"+((String)l)+"|";
    if(l instanceof Object[]){
       String str="";
       Object[] ll= (Object[])l;
       for(int i=0;i<ll.length;i++){
           if(ll[i] instanceof Object[]) str +="[";
           str+=prstring(ll[i]);
           if(ll[i] instanceof Object[])str+="]";
           if (i!=ll.length-1)str+=" ";
          }
       return str;
      }
    return l.toString();
  }

  Object prim_hexparse(Object arg1, LContext lc){
    TokenStream ts = new TokenStream(Logo.prs(arg1), true);
    return ts.readList(lc);
  }

  Object prim_scanhex(Object arg1, Object arg2, Object arg3, LContext lc){
    String input = (String) arg1;
    Object[] result = (Object[]) arg2;
    Object[] format = (Object[]) arg3;
    for(int i=0;i<result.length;i++){
      int start = ((Number)format[i*2]).intValue();
      int end = ((Number)format[i*2+1]).intValue()+start;
      String str = input.substring(start, end);
      result[i]=new Long(Long.parseLong(str, 16));
    }
    return null;
  }

  Object prim_exec(Object arg1, LContext lc){
    String cmd = Logo.prs(arg1),s, res="";
    try {
     Process p = Runtime.getRuntime().exec(cmd);
     BufferedReader br1 = new BufferedReader(new InputStreamReader(p.getInputStream()));
     BufferedReader br2 = new BufferedReader(new InputStreamReader(p.getErrorStream()));
     while ((s = br1.readLine()) != null) res=res+s+"\n";
     while ((s = br2.readLine()) != null) res=res+s+"\n";
    } catch (Exception e) {Logo.error("exec: "+e+" "+cmd, lc);}
    return res;
  }

  Object prim_blindexec(Object arg1, LContext lc){
    String cmd = Logo.prs(arg1),s, res="";
    try {
     Process p = Runtime.getRuntime().exec(cmd);
    } catch (Exception e) {Logo.error("exec: "+e+" "+cmd, lc);}
    return null;
  }

  Object prim_getProperty(Object arg1, LContext lc){
    String res = System.getProperty(Logo.prs(arg1));
    if(res == null) return "";
    return res;
  }

  Object prim_qsym(Object arg1, LContext lc){
    return new QuotedSymbol(Logo.aSymbol(arg1,lc));
  }

  Object prim_now(LContext lc){
    return new Double((new Date()).getTime());
  }

  Object prim_dateformat(Object arg1, Object arg2, Object arg3, LContext lc){
    String format = Logo.prs(arg1);
    long time = Logo.aLong(arg2, lc);
    TimeZone timezone = TimeZone.getTimeZone(Logo.prs(arg3));
    SimpleDateFormat sdf = new SimpleDateFormat(format);
    sdf.setTimeZone(timezone);
    return sdf.format(new Date(time));
  }

  Object prim_dateparse(Object arg1, Object arg2, LContext lc){
    String pattern= Logo.prs(arg1), datestring = Logo.prs(arg2);
    try { return new Long((new SimpleDateFormat(pattern)).parse(datestring).getTime());}
    catch (ParseException e) {//Logo.error("can't parse date:"+datestring, lc);//
    }
    Logo.error("can't parse date:"+datestring, lc);
    return "null";
   }

  Object prim_clarg(Object arg1, LContext lc){
    int argn = Logo.anInt(arg1,lc);
    if(argn<lc.clargs.length) return lc.clargs[argn];
    else return new Object[0];
  }


}
