import java.awt.Color;
import java.awt.Dimension;
import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.Image;
import java.awt.image.BufferedImage;
import java.awt.MediaTracker;
import java.awt.Point;
import java.awt.Rectangle;
import java.awt.Toolkit;
import java.awt.geom.AffineTransform;
import java.awt.RenderingHints;

import java.util.Vector;
import java.util.List;

import javax.swing.JDialog;
import javax.swing.JFrame;
import javax.swing.JPanel;

import java.awt.dnd.*;
import java.awt.datatransfer.DataFlavor;
import java.awt.datatransfer.Transferable;

import java.net.URL;

class SpriteFrame extends JFrame {

//class SpriteFrame extends Frame implements java.io.FilenameFilter {

  SpritePanel panel;
  SpriteCanvas canvas;
  static SpriteFrame frame;
  LContext lc;
  double wscale = 1.0;

  SpriteFrame(int w, int h, LContext lc){
    super("untitled");
    frame = this;
    this.lc=lc;
//    Toolkit toolkit = Toolkit.getDefaultToolkit();
//    Dimension screenSize = toolkit.getScreenSize();
//    System.out.println(screenSize);
    panel = new SpritePanel (w, h, wscale, lc);
    Color c = new Color (200, 218,255);
    setBackground(c);
    setResizable(false);
    setDefaultCloseOperation (DO_NOTHING_ON_CLOSE);
 }

  public void addNotify(){
    super.addNotify();
    getContentPane().add("Center", panel);
    addWindowListener(new ToplevelWindowListener());
    pack();
  }

 Image loadImage (String filename, LContext lc) {
    URL u = SpriteFrame.class.getResource("images/" + filename);
    if (u == null) Logo.error("can't get image "+filename, lc);
    Image res = Toolkit.getDefaultToolkit().getImage(u);
    MediaTracker mt = new MediaTracker(this);
    try {
       mt.addImage(res, 0);
       mt.waitForID(0);
    }
    catch(Exception e) {Logo.error("can't get image "+" "+e+" "+filename, lc);}
    return res;
  }

}


class SpritePanel extends JPanel {
  int width, height;
  LContext lc;

  SpritePanel(int w, int h, double s, LContext lc){
    this.lc=lc;
    width=(int)(w*s); height=(int)(h*s);
    setLayout (null);
    }

public boolean isOptimizedDrawingEnabled() {return false;}
public Dimension getPreferredSize(){return new Dimension(width, height);}
public Dimension getMinimumSize(){return new Dimension(width, height);}

}

class SpriteCanvas extends JPanel implements DropTargetListener {
  int width, height, bgw, bgh,maskx=0, masky=0;
  BufferedImage offscreen, bg;
  Vector sprites = new Vector();
  LContext lc;

  Rectangle invalrect = new Rectangle();
  AffineTransform trans;

  SpriteCanvas(int w, int h, LContext lc){
    this.lc=lc;
    width=w; height=h;
    double s = lc.frame.wscale;
    setSize((int)(w*s), (int)(h*s));
  }

  public void addNotify(){
    super.addNotify();
    offscreen = (BufferedImage)createImage(width, height);
    createBg(width, height);
		new DropTarget(this,this);
		inval(new Rectangle(0, 0, width, height));
    redraw();
  }

  void createBg(int w, int h) {
    int dpis = TAText.dpiscale;
    bgw=w; bgh=h;
    bg = new BufferedImage(w*dpis, h*dpis, BufferedImage.TYPE_INT_RGB);
    Graphics offg = bg.getGraphics();
    Color c = new Color (200, 218,255);
    offg.setColor(c);
    offg.fillRect(0, 0, 50000, 50000);
    offg.dispose();
    trans = AffineTransform.getScaleInstance(1.0/dpis,1.0/dpis);
  }

  void inval(Rectangle r){
    if(invalrect.isEmpty()) invalrect = new Rectangle(r);
    else invalrect = invalrect.union(r);
  }

  void redraw(Rectangle r){
		inval(r);
		double s = lc.frame.wscale;
		repaint(new Rectangle((int)(r.x*s),(int)(r.y*s),(int)(r.width*s+2), (int)(r.height*s+2)));
	}

  public void redraw() {
    Rectangle r = invalrect;
		double s = lc.frame.wscale;
		repaint(new Rectangle((int)(r.x*s),(int)(r.y*s),(int)(r.width*s+2), (int)(r.height*s+2)));
  }

  public void paintComponent(Graphics gin){
    synchronized(this){
			Graphics2D g = (Graphics2D) gin;
			Rectangle r = invalrect;
			Graphics2D offg = (Graphics2D)offscreen.getGraphics();
			offg.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
			offg.setRenderingHint(RenderingHints.KEY_RENDERING, RenderingHints.VALUE_RENDER_QUALITY);
			offg.setRenderingHint(RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_BICUBIC);
			offg.setClip(r.x, r.y, r.width, r.height);
			if(bg!=null) offg.drawImage(bg, trans, null);
			offg.setColor(new Color(128,128,128,128));
  		if((lc.turtle!=null)&&r.intersects(lc.turtle.rect)) lc.turtle.paint(offg);
			offg.dispose();
			invalrect=new Rectangle();
      g.drawImage(offscreen, 0, 0, width, height, this);
    }
  }

  public void drop(DropTargetDropEvent e){
		Transferable t = e.getTransferable();
    try {
			e.acceptDrop(e.getDropAction());
			Object str = "";
			Point p = e.getLocation();
			if(t.isDataFlavorSupported(DataFlavor.javaFileListFlavor)){
			  str = ((List)t.getTransferData(DataFlavor.javaFileListFlavor)).get(0);
				(new Thread(new LogoCommandRunner("drop-file \"|"+str+"|", lc))).start();
			}
			e.dropComplete(true);
		} catch (Exception ex) {System.out.println(ex);}
  }

 	public void dragEnter(DropTargetDragEvent e){}
  public void dragExit(DropTargetEvent e){}
  public void dragOver(DropTargetDragEvent e){}
  public void dropActionChanged(DropTargetDragEvent e){}

}

class Turtle {
  Rectangle rect=new Rectangle();
  SpriteCanvas canvas;
  double heading;
	Image img;
	boolean shown=true;

  Turtle(Image img, SpriteCanvas canvas){
    this.img = img;
    this.canvas = canvas;
    rect=new Rectangle(0, 0, img.getWidth(null), img.getHeight(null));
  }

  void setxy(int x, int y){
    synchronized(canvas){
	    inval();
	    rect=new Rectangle(x, y, img.getWidth(null), img.getHeight(null));
	    inval(); redraw();
    }
  }

  void setheading(double theta){
    heading=theta;
    inval(); redraw();
  }

  void paint(Graphics2D g){
		if(!shown) return;
	  AffineTransform t = AffineTransform.getRotateInstance(heading*3.14159f/180f,
																		 (double)(rect.x+ 20), (double)(rect.y+20));
	  t.translate((double)rect.x, (double)rect.y);
	  g.drawImage(img, t, null);
  }

	void showturtle(){shown=true; inval(); redraw();};
	void hideturtle(){shown=false; inval(); redraw();};
  void inval () {canvas.inval(rect);}
  void redraw () {canvas.redraw();}

}