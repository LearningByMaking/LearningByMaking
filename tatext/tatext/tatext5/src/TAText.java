import java.awt.BorderLayout;
import java.awt.FlowLayout;
import java.awt.event.ActionListener;
import java.awt.event.ActionEvent;
import java.awt.event.KeyEvent;
import java.awt.event.KeyListener;
import java.awt.event.WindowAdapter;
import java.awt.event.WindowEvent;
import java.awt.FileDialog;
import java.awt.Font;
import java.awt.Insets;
import java.io.OutputStream;
import java.io.PrintWriter;
import java.util.Hashtable;
import java.util.Timer;

import javax.swing.Action;
import javax.swing.AbstractAction;
import javax.swing.JButton;
import javax.swing.JFrame;
import javax.swing.JPanel;
import javax.swing.JScrollPane;
import javax.swing.JTextField;
import javax.swing.JTextArea;
import javax.swing.KeyStroke;
import javax.swing.text.DefaultEditorKit;
import javax.swing.text.JTextComponent;
import javax.swing.text.Keymap;

public class TAText {

  static LogoConsole logoconsole;
  static LContext lc;
	static int dpiscale=2;

  static String[] primclasses =
    {"SystemPrims", "MathPrims", "ControlPrims",
     "DefiningPrims", "WordListPrims", "FilePrims",
     "TurtlePrims", "ImagePrims", "CCPrims"
     };

  public static void main(String[] args){
    lc = new LContext();
    Logo.setupPrims(primclasses, lc);

    (logoconsole = new LogoConsole("JavaLogo")).init();
    lc.cc = logoconsole.cc;
    (new LogoCommandRunner("%load \"startup.logo startup", lc)).run();
    lc.tyo.println("Welcome to Logo!");
    logoconsole.cc.requestFocus();
    }
}


class LogoConsole extends JFrame {

  Listener cc;
	JPanel panel;
	JPanel buttons;
  static JTextComponent filename;
  LogoButtonListener bl;

  LogoConsole(String s){super(s);}

  void init() {
    panel = new JPanel();
    panel.setLayout(new BorderLayout());
    getContentPane().add(panel, BorderLayout.CENTER);

    cc = new Listener(30, 75);
    cc.init();
    JScrollPane scrollpanecc = new JScrollPane(cc,
              JScrollPane.VERTICAL_SCROLLBAR_ALWAYS,
              JScrollPane.HORIZONTAL_SCROLLBAR_AS_NEEDED);
    panel.add(scrollpanecc, BorderLayout.CENTER);
    setTitle("Command Center");

    buttons = new JPanel();
    panel.add(buttons, BorderLayout.SOUTH);
    buttons.setLayout(new FlowLayout(FlowLayout.LEFT));
    bl = new LogoButtonListener(cc);

    filename = new JTextField("test.txt", 12);
    buttons.add(filename);

    JButton browse = new JButton("...");
    buttons.add(browse);
    browse.addActionListener(new ActionListener (){
      public void actionPerformed(ActionEvent e) {
        getFileName(TAText.logoconsole, "logo file");
      }
    });
    addButton("load", "load-button");
    addButton("go", "go");
    addButton("ht/st", "ht-st");

    pack(); setVisible(true);
    addWindowListener(new ToplevelWindowListener() );
    cc.lc.filebox = filename;
  }

  void addButton(String s, String name){
    JButton button = new JButton(s);
    button.setName(name);
    button.addActionListener(bl);
    buttons.add(button);
  }

  static String currentdir = "";

  void getFileName(JFrame frm, String s){
   FileDialog f = new FileDialog(frm, s);
   f.setDirectory(currentdir);
   f.setVisible(true);
   currentdir = f.getDirectory();
   cc.lc.dirname = f.getDirectory();
   filename.setText(f.getFile());
   f.dispose();
 }

}

class LogoButtonListener implements ActionListener
{
  Listener cc;
  LogoButtonListener(Listener cc){this.cc = cc;}

  public void actionPerformed(ActionEvent e)
  {
    String label = ((JButton) e.getSource()).getName();
    cc.runLine(label);
    cc.requestFocus();
  }
}

class ToplevelWindowListener extends WindowAdapter {
  public void windowClosing(WindowEvent e) { System.exit(0); }
}


class Listener extends JTextArea implements KeyListener{

  LContext lc = TAText.lc;

  Listener(int h, int w){super(h,w);};

	void init(){
    setFont(new Font("Courier", Font.PLAIN, 12));
    setMargin (new Insets(0, 5, 0, 0));
    setWrapStyleWord(true);
    setLineWrap(true);
    addKeyListener(this);
    lc.tyo = new PrintWriter(new TEStream(this), true);
	}

  public void keyPressed(KeyEvent e){
    char key = e.getKeyChar();
    int code = e.getKeyCode();                          // Patch so Ctrl + C is not interpreted as a return
    if(key=='\u0001'){selectAll(); e.consume(); return;}
    if(key== '\n' && code == 10)
     if(e.isShiftDown()) lc.tyo.println();
     else {handlecr(); e.consume(); return;}
    if(key=='\u0004'){handleDoit(); e.consume(); return;}
    if (key=='\u0012') {runLine("%reload"); e.consume(); return;} // ctrl+r
    if (key=='\u0013') {runLine("save"); lc.tyo.println("saved."); e.consume(); return;} // ctrl+s
    if (key=='\u001b') {
      lc.timeToStop=true;
      lc.tyo.println("Stopped!!!");
      e.consume();
      return;
      } // escape
    }

  void handleDoit(){
		String s = getSelectedText();
		s = s.replace('\n', ' ');
		setCaretPosition(getSelectionEnd());
    runLine(s);
  }

  void handlecr(){
    String s=getText();
    int sol=findStartOfLine(s, getCaretPosition());
    int eol=findEndOfLine(s, sol);
    if(eol==s.length()) append("\n");
    setCaretPosition(eol+1);
    runLine(s.substring(sol, eol));
  }

  int findStartOfLine(String s, int i){
    int val = s.lastIndexOf(10,i-1);
    if (val<0) return 0;
    return val+1;
  }

  int findEndOfLine(String s, int i){
    int val = s.indexOf('\n',i);
    if (val<0) return s.length();
    return val;
  }

  void runLine(String s){
    (new Thread(new LogoCommandRunner(s, lc))).start();
  }

public void keyTyped(KeyEvent e){}
public void keyReleased(KeyEvent e){}
}


class TEStream extends OutputStream {

  JTextArea te;
  String buffer = "";

  public TEStream(JTextArea te){this.te = te;}

  public void write(int n) {
    if (n==10) buffer+='\n';
    else if (n==13) return;
    else buffer+=(char)n;
  }

  public void flush(){
    int pos = te.getCaretPosition();
    te.insert(buffer, pos);
    te.setCaretPosition(pos+buffer.length());
    buffer="";
  }
}

//--------------- for Mac Key handling -----------------
class SelectAllAction extends AbstractAction implements Action {

    public void actionPerformed(ActionEvent e) {
      JTextArea text = (JTextArea)e.getSource();
      text.selectAll();
     // e.consume();
    }
}

class CCPrims extends Primitives {

  static String[] primlist={
    "setfile-field", "1", "file-field", "0", "dirname", "0",
    "focuscc", "0", "print", "1"
};

  public String[] primlist(){return primlist;}

  public Object dispatch(int offset, Object[] args, LContext lc){
    switch(offset){
    case 0: return prim_setfilename(args[0], lc);
    case 1: return prim_filename(lc);
    case 2: return prim_dirname(lc);
    case 3: lc.cc.requestFocus(); return null;	// focuscc
    case 4: return prim_print(args[0], lc);
 }
    return null;
  }

  Object prim_setfilename(Object arg1, LContext lc){
    lc.filebox.setText(Logo.prs(arg1));
    return null;
  }

  Object prim_filename(LContext lc){
    return lc.dirname + lc.filebox.getText();
  }

  Object prim_dirname(LContext lc){
    return lc.dirname;
  }

	Object prim_print(Object arg1, LContext lc){
			lc.tyo.println(Logo.prs(arg1));
			return null;
	}
}

class LContext {
  Hashtable oblist = new Hashtable();
  Hashtable props = new Hashtable();
  MapList iline;
  Symbol cfun, ufun;
  Object ufunresult, juststop = new Object();
  boolean mustOutput, timeToStop;
  int priority = 0;
  Object[] locals;
  String errormessage;
  PrintWriter tyo;
  Thread thread;
  String filename;
  String dirname="";
  JTextComponent filebox;
  boolean loadFromResource = false;
  Listener cc;
  SpriteFrame frame;
  SpriteCanvas canvas;
  SpritePanel panel;
  Turtle turtle;
}
