import java.awt.BasicStroke;
import java.awt.Color;
import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.Rectangle;
import java.awt.RenderingHints;
import java.awt.geom.Arc2D;
import java.awt.geom.Line2D;
import java.awt.geom.Rectangle2D;
import java.awt.geom.GeneralPath;
import java.awt.image.BufferedImage;
import java.awt.Image;
import java.awt.Font;
import java.awt.font.TextLayout;
import java.awt.Toolkit;
import java.awt.MediaTracker;
import java.io.File;
import javax.imageio.ImageIO;
import javax.imageio.ImageWriter;
import javax.imageio.stream.ImageOutputStream;
import java.util.Iterator;

class ImagePrims extends Primitives {

  static String[] primlist={
    "newimage", "2", "%moveto", "2", "%lineto", "2",
    "fillscreen", "0", "%startfill", "2", "endfill", "0", "dropfill", "0",
    "%drawstring", "3", "setfont", "3", "stringw", "1",
    "%setcolor", "1", "setpensize", "1",
    "savepic", "1", "%xcor", "0", "%ycor", "0",
    "placepic", "3"
  };


  public String[] primlist(){return primlist;}

  public Object dispatch(int offset, Object[] args, LContext lc){
    switch(offset){
      case 0: return prim_newimage(args[0], args[1], lc);
      case 1: return prim_moveto(args[0], args[1], lc);
      case 2: return prim_lineto(args[0], args[1], lc);
      case 3: return prim_fillscreen(lc);
      case 4: return prim_startFill(args[0], args[1], lc);
      case 5: return prim_endFill(lc);
      case 6: return prim_dropFill(lc);
      case 7: return prim_drawstring(args[0], args[1], args[2], lc);
      case 8: return prim_setfont(args[0], args[1], args[2], lc);
      case 9: return prim_stringw(args[0], lc);
      case 10: color = Logo.anInt(args[0], lc); return null;
      case 11: pensize = (float)Logo.aDouble(args[0], lc); return null;
      case 12: return prim_savepic(args[0], lc);
      case 13: return new Double(xcor);
      case 14: return new Double(ycor);
      case 15: return prim_placepic(args[0], args[1], args[2], lc);
      }
    return null;
  }

  GeneralPath path = null;
  BufferedImage img;
  double xcor=0, ycor=0;
  int color = 0;
  float pensize = 2.0f;
  Font font = new Font("Arial", Font.BOLD, 32);

  Object prim_newimage(Object arg1, Object arg2, LContext lc){
    int width = Logo.anInt(arg1, lc), height = Logo.anInt(arg2, lc);
    img = new BufferedImage(width, height, BufferedImage.TYPE_INT_RGB);
    return null;
  }

  Object prim_lineto(Object arg1, Object arg2, LContext lc){
    double x = Logo.aDouble(arg1, lc), y = Logo.aDouble(arg2, lc);
    Line2D.Double line = new Line2D.Double(xcor, ycor, x, y);
    if(path!=null) path.append(line, true);
    Graphics2D g = getGraphics();
    g.draw(line);
    xcor=x; ycor=y;
    g.dispose();
    return null;
  }

  Object prim_moveto(Object arg1, Object arg2, LContext lc){
    xcor = Logo.aDouble(arg1, lc);
    ycor = Logo.aDouble(arg2, lc);
    return null;
  }

  Object prim_fillscreen(LContext lc){
    Graphics2D g = getGraphics();
    g.fillRect(0, 0,50000, 50000);
    g.dispose();
    return null;
  }

  Object prim_startFill(Object arg1, Object arg2, LContext lc){
    double x = Logo.aDouble(arg1, lc), y = Logo.aDouble(arg2, lc);
    path = new GeneralPath();
    path.moveTo((float)x,(float)y);
    return null;
  }

  Object prim_endFill(LContext lc){
    if (path==null) return null;
    Graphics2D g =  getGraphics();
    path.closePath();
    g.fill(path);
    g.dispose();
    path = null;
    return null;
  }

  Object prim_dropFill(LContext lc){
    path = null;
    return null;
  }


  Object prim_drawstring(Object arg1, Object arg2, Object arg3, LContext lc){
    String str = Logo.prs(arg1);
    int x = Logo.anInt(arg2, lc);
    int y = Logo.anInt(arg3, lc);
    Graphics2D g = getGraphics();
    TextLayout tl = new TextLayout (str, font, g.getFontRenderContext());
    Rectangle r = tl.getBounds().getBounds();
    g.drawString(str, x-r.width/2, y+r.height/2);
    g.dispose();
    return null;
  }

  Object prim_setfont(Object arg1, Object arg2, Object arg3, LContext lc){
    String fontname = Logo.prs(arg1);
    int height = Logo.anInt(arg2, lc);
    int[] types = {Font.PLAIN, Font.BOLD, Font.ITALIC};
    int type = types[Logo.anInt(arg3, lc)];
    font = new Font(fontname, type, height);
    return null;
  }

  Object prim_stringw(Object arg1, LContext lc){
    String str = Logo.prs(arg1);
    Graphics2D g = getGraphics();
    TextLayout tl = new TextLayout (str, font, g.getFontRenderContext());
    Rectangle r = tl.getBounds().getBounds();
    return new Double(r.width);
  }

  Object prim_savepic(Object arg1, LContext lc){
    String name = Logo.prs(arg1);
    try {
      File f = new File(name);
      f.delete();
      ImageWriter writer = null;
      Iterator iter = ImageIO.getImageWritersByFormatName("png");
      if (iter.hasNext()) writer = (ImageWriter)iter.next();
      ImageOutputStream ios = ImageIO.createImageOutputStream(f);
      writer.setOutput(ios);
      writer.write(img);
      ios.flush();
      writer.dispose();
      ios.close();
    } catch (Exception e) {Logo.error("savebg problem - "+e, lc);}
    return null;
  }

  Object prim_placepic(Object arg1, Object arg2, Object arg3, LContext lc){
    String filename = Logo.prs(arg1);
    int x = Logo.anInt(arg2, lc), y = Logo.anInt(arg3, lc);
    BufferedImage img = null;
    try {img = ImageIO.read(new File(filename));}
    catch(Exception e) {Logo.error("can't placepic "+filename,lc);}
    int w = img.getWidth(null), h = img.getHeight(null);
    Graphics2D g = getGraphics();
    g.drawImage(img, x, y, w, h, null);
    g.dispose();
    return null;
  }


  Graphics2D getGraphics(){
    Graphics2D g = (Graphics2D)img.getGraphics();
    g.setColor (new Color(color));
//    g.setStroke(new BasicStroke(pensize, BasicStroke.CAP_ROUND, BasicStroke.JOIN_ROUND));
//    g.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
    g.setFont(font);
    return g;
  }

}
