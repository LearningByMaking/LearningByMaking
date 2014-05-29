import java.util.Vector;

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
    "getproperty", "1"
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
      case 15: return prim_getProperty(args[0], lc);
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
    if(lc.iline.eof()) Logo.error("Missing \")\"", lc);
		if (ipmnext(lc.iline)) return ipmcall(lc);
    Object arg=Logo.eval(lc);
    if(lc.iline.eof()) Logo.error("Missing \")\"", lc);
    Object next=lc.iline.next();
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
    Vector v=new Vector();
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

  Object prim_getProperty(Object arg1, LContext lc){
    String res = System.getProperty(Logo.prs(arg1));
    if(res == null) return "";
    return res;
  }

}
