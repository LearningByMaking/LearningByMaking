import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.File;
import java.io.FileOutputStream;
import java.io.FileInputStream;
import java.io.DataInputStream;
import java.io.FileReader;
import java.io.IOException;
import java.io.PrintWriter;
import java.io.StringWriter;
import java.net.URL;
import java.io.FileWriter;
import java.io.File;

class FilePrims extends Primitives {

String readtext;
int textoffset;

  static String[] primlist={
    "filetostring", "1",
    "resourcetostring", "1",
    "%load", "1",
    "%reload", "0",
    "stringtofile", "2",
    "file?", "1",
    "setread", "1",
    "readline", "0",
    "eot?", "0",
    "lineback", "0",
    "filenamefrompath", "1",
    "dirnamefrompath", "1",
    "dir?", "1",
    "dir", "1",
    "setfread", "1",
    "freadline", "0",
    "feot?", "0",
    "fclose", "0",
    "erfile", "1",
    "files", "1",
    "logopen", "1",
    "logprint", "1",
    "logclose", "0"
  };

  public String[] primlist(){return primlist;}

  public Object dispatch(int offset, Object[] args, LContext lc){
    switch(offset){
    case 0: return prim_filetostring(args[0], lc);
    case 1: return prim_resourcetostring(args[0], lc);
    case 2: return prim_load(args[0], lc);
    case 3: return prim_reload(lc);
    case 4: return prim_stringtofile(args[0], args[1], lc);
    case 5: return prim_isfile(args[0], lc);
    case 6: return prim_setread(args[0], lc);
    case 7: return prim_readline(lc);
    case 8: return prim_eot(lc);
    case 9: return prim_lineback(lc);
    case 10: return prim_filenamefrompath(args[0], lc);
    case 11: return prim_dirnamefrompath(args[0], lc);
    case 12: return prim_isdir(args[0], lc);
    case 13: return prim_dir(args[0], lc);
    case 14: return prim_setfread(args[0], lc);
    case 15: return prim_freadline(lc);
    case 16: return prim_feot(lc);
    case 17: return prim_fclose(lc);
    case 18: return prim_erfile(args[0], lc);
    case 19: return prim_files(args[0], lc);
    case 20: return prim_logopen(args[0], lc);
    case 21: return prim_logprint(args[0], lc);
    case 22: return prim_logclose(lc);
    }
    return null;
  }

  Object prim_filetostring(Object arg1, LContext lc){
    String filename = Logo.prs(arg1);
    return fileToString(filename, lc);
  }

  Object prim_resourcetostring(Object arg1, LContext lc){
    String filename = Logo.prs(arg1);
    return resourceToString(filename, lc);
  }

  Object prim_reload(LContext lc){
    lc.tyo.println("reloading "+lc.filename);
    return prim_load(lc.filename, lc);
  }

  Object prim_load(Object arg1, LContext lc){
    String name = Logo.prs(arg1);
    if(new File(name).isFile()) Logo.readAllFunctions(fileToString(name, lc), lc);
    else Logo.readAllFunctions(resourceToString(name, lc), lc);
    lc.filename = name;
    return null;
  }

 String resourceToString(String filename, LContext lc){
    InputStream is = FilePrims.class.getResourceAsStream(filename);
    BufferedReader br = new BufferedReader(new InputStreamReader(is));
    StringWriter sw = new StringWriter();
    PrintWriter pw = new PrintWriter(new BufferedWriter(sw), true);
    String line;
    try {
      while ((line=br.readLine())!=null) pw.println(line);
      String result = sw.toString();
      return result;
    }
    catch (IOException e)
      {Logo.error("Can't open file "+filename, lc);}
    return null;
  }

  String fileToString(String filename, LContext lc){
      byte[] buffer=null; String content=null;
      try {
        File file = new File(filename);
        int len = (int)file.length();
        FileInputStream fis = new FileInputStream(file);
        DataInputStream dis=new DataInputStream(fis);
        buffer=new byte[len];
        dis.readFully(buffer);
        fis.close();
      }
      catch (IOException e)
        {Logo.error("Can't open file "+filename, lc);}
      return(new String(buffer));
    }


  Object prim_stringtofile(Object arg1, Object arg2, LContext lc){
    String filename = Logo.prs(arg1);
    String str = (arg2 instanceof String) ? (String) arg2 :Logo.prs(arg2);
    try {
         FileWriter fw = new FileWriter(filename);
         fw.write(str, 0, str.length());
         fw.close();
      }
    catch (IOException e)
      {Logo.error("Can't write file "+filename, lc);}
    return null;
  }

  Object prim_isfile(Object arg1, LContext lc){
    String name = Logo.prs(arg1);
    return new Boolean (new File(name).isFile());
  }

  Object prim_isdir(Object arg1, LContext lc){
    String name = Logo.prs(arg1);
    return new Boolean (new File(name).isDirectory());
  }

  Object prim_setread(Object arg1, LContext lc){
    readtext = Logo.prs(arg1);
    textoffset = 0;
    return null;
  }

  Object prim_readline(LContext lc){
    String str = "";
    int index = readtext.indexOf("\n", textoffset);
    if (index == -1) {
      if (textoffset < readtext.length()) {
      str = readtext.substring(textoffset, readtext.length());
      textoffset = readtext.length();}
    } else {
      str = readtext.substring(textoffset, index);
      textoffset = index + 1;}
    if(str.length()==0) return str;
    if(str.charAt(str.length()-1)=='\r') str=str.substring(0, str.length()-1);
    return str;
  }

  Object prim_eot(LContext lc){
    return new Boolean (textoffset >= readtext.length());
  }

  Object prim_lineback(LContext lc){
   int index = readtext.lastIndexOf("\n", textoffset - 2);
   if (index < 0) textoffset = 0;
   else textoffset = index + 1;
    return null;
  }

  Object prim_filenamefrompath(Object arg1, LContext lc){
    return (new File(Logo.prs(arg1))).getName();
  }

  Object prim_dirnamefrompath(Object arg1, LContext lc){
    File f = new File(Logo.prs(arg1));
    if(f.isDirectory()) return f.getPath();
    else return f.getParent();
  }

  Object prim_dir(Object arg1, LContext lc){
    String[] files = (new File(Logo.prs(arg1))).list();
    if(files==null) return new Object[0];
    return files;
  }


  BufferedReader freader;

  Object prim_setfread(Object arg1, LContext lc){
    String filename = Logo.prs(arg1);
    try {
    freader = new BufferedReader(new FileReader(filename));
    } catch (IOException e) {Logo.error("Can't fread "+filename, lc);}
    return null;
  }

  Object prim_freadline(LContext lc){
    try {
    return freader.readLine();
    } catch (IOException e) {}
    return null;
  }

  Object prim_feot(LContext lc){
    String s=null;
    try {
    freader.mark(1000);
    s = freader.readLine();
    freader.reset();
    } catch (IOException e) {}
    return new Boolean(s==null);
  }

  Object prim_fclose(LContext lc){
	if (freader==null) return null;
    try {
    freader.close();
    freader = null;
    } catch (IOException e) {Logo.error("fclose error", lc);}
    return null;
  }

  PrintWriter logwriter;

  Object prim_logopen(Object arg1, LContext lc){
    String filename = Logo.prs(arg1);
    try {
    logwriter = new PrintWriter(new BufferedWriter(new FileWriter(filename)));
    } catch (IOException e) {Logo.error("Can't open log for "+filename, lc);}
    return null;
  }

  Object prim_logprint(Object arg1, LContext lc){
    logwriter.println(Logo.prs(arg1));
    return null;
  }

  Object prim_logclose(LContext lc){
    logwriter.close();
    logwriter = null;
    return null;
  }

  Object prim_erfile(Object arg1, LContext lc){
	String filename = Logo.prs(arg1);
    File file = new File(filename);
    try { file.delete();}
    catch (Exception e)
      {Logo.error("Can't delete file "+filename, lc);}
    return null;
  }

  Object prim_files(Object arg1, LContext lc){
	String filename = Logo.prs(arg1);
    File dir = new File(filename);
    try
    {
		File[] files = dir.listFiles();
		String[] filenames = new String[files.length];
		for(int i=0;i<files.length;i++) filenames[i]=files[i].getCanonicalPath();
		return filenames;
	}
    catch (Exception e)
      {Logo.error("Can't list directory for "+filename, lc);}
    return null;
  }

}
