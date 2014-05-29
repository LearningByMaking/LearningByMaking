import java.awt.BasicStroke;
import java.awt.Color;
import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.Rectangle;
import java.awt.geom.AffineTransform;
import java.awt.RenderingHints;
import java.awt.geom.Arc2D;
import java.awt.geom.Line2D;
import java.awt.geom.Rectangle2D;
import java.awt.geom.GeneralPath;

class TurtlePrims extends Primitives {

  static String[] primlist={
    "createframe", "4", "%line", "6", "%arc", "7", "%fillscreen", "1",
    "%tsetxy", "2", "%setxy", "2", "%setheading", "1", "heading", "0",
    "%startfill", "2", "%endfill", "1", "%dropfill", "0",
    "showturtle", "0", "hideturtle", "0", "shown?", "0"
  };


  public String[] primlist(){return primlist;}

  public Object dispatch(int offset, Object[] args, LContext lc){
    synchronized((lc.canvas==null) ? ((Object)lc) : ((Object) lc.canvas)){
      switch(offset){
      case 0: return prim_createframe(args[0], args[1], args[2], args[3], lc);
      case 1: return prim_line(args[0], args[1], args[2], args[3], args[4], args[5], lc);
      case 2: return prim_arc(args[0], args[1], args[2], args[3], args[4], args[5], args[6], lc);
      case 3: return prim_fillscreen(args[0], lc);
      case 4: return prim_tsetxy(args[0], args[1], lc);
      case 5: return prim_setxy(args[0], args[1], lc);
      case 6: return prim_setheading(args[0], lc);
      case 7: return prim_heading(lc);
      case 8: return prim_startFill(args[0], args[1], lc);
      case 9: return prim_endFill(args[0], lc);
      case 10: return prim_dropFill(lc);
      case 11: lc.turtle.showturtle(); return null;
      case 12: lc.turtle.hideturtle(); return null;
      case 13: return new Boolean(lc.turtle.shown);
      }
      return null;
    }
  }

	GeneralPath path = null;

  Object prim_createframe(Object arg1, Object arg2, Object arg3, Object arg4, LContext lc){
    int left = Logo.anInt(arg1, lc), top = Logo.anInt(arg2, lc);
    int width = Logo.anInt(arg3, lc), height = Logo.anInt(arg4, lc);
    if(lc.frame!=null) lc.frame.dispose();
    lc.frame = new SpriteFrame(width, height, lc);
    lc.canvas  = new SpriteCanvas(width, height, lc);
    lc.frame.canvas = lc.canvas;
    lc.panel = lc.frame.panel;
    lc.panel.add(lc.canvas, 0);
    lc.frame.setLocation(left, top);
    lc.frame.setVisible(true);
    lc.frame.getContentPane().setLayout (null);
    lc.turtle = new Turtle(lc.frame.loadImage("t0.gif",lc), lc.canvas);
    return null;
  }

  Object prim_line(Object arg1, Object arg2, Object arg3, Object arg4,
                   Object arg5, Object arg6, LContext lc){
    double x1 = Logo.aDouble(arg1, lc), y1 = Logo.aDouble(arg2, lc),
        x2 = Logo.aDouble(arg3, lc), y2 = Logo.aDouble(arg4, lc);
    int c = Logo.anInt(arg5, lc);
		int dpis = TAText.dpiscale;
    float pensize = Math.abs((float)Logo.aDouble(arg6, lc));
		Line2D.Double line = new Line2D.Double(x1*dpis, y1*dpis, x2*dpis, y2*dpis);
    if(path!=null) path.append(line, true);
    if(pensize==0) return null;
    Graphics2D g = (Graphics2D)lc.canvas.bg.getGraphics();
    g.setStroke(new BasicStroke(pensize*dpis, BasicStroke.CAP_ROUND, BasicStroke.JOIN_ROUND));
    g.setColor (new Color(regamut(c)));
    g.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
    g.draw(line);
    int l = (int)Math.min (x1, x2), t = (int)Math.min (y1, y2),
        w = (int)Math.abs (x2 - x1), h = (int)Math.abs (y2 - y1);
    Rectangle r = new Rectangle(l, t, w, h);
    int ipen = (int)pensize;
    r.grow(ipen+5,ipen+5);
    lc.canvas.redraw (r);
    g.dispose();
    return null;
  }

  Object prim_arc(Object arg1, Object arg2, Object arg3, Object arg4,
                   Object arg5, Object arg6, Object arg7, LContext lc){
		int dpis = TAText.dpiscale;
    double x=Logo.aDouble(arg1, lc), y=Logo.aDouble(arg2, lc), r=Logo.aDouble(arg3, lc);
    x-=r; y-=r;
    double startangle = 90-Logo.aDouble(arg4, lc);
    double arcangle = -Logo.aDouble(arg5, lc);
    double d = 2 * r;
    int c = Logo.anInt(arg6, lc);
    float pensize = Math.abs((float)Logo.aDouble(arg7, lc));
		Arc2D.Double arc = new Arc2D.Double(x*dpis,y*dpis,d*dpis,d*dpis,
		                                    startangle, arcangle, Arc2D.OPEN);
    if(path!=null) path.append(arc, true);
    if(pensize==0) return null;
    Graphics2D g = (Graphics2D)lc.canvas.bg.getGraphics();
    g.setStroke(new BasicStroke(pensize*dpis, BasicStroke.CAP_ROUND, BasicStroke.JOIN_ROUND));
    g.setColor (new Color(regamut(c)));
    g.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
    g.draw(arc);
    Rectangle rect = new Rectangle((int)(x), (int)(y), (int)(d), (int)(d));
    int ipen = (int)pensize;
    rect.grow(ipen+5,ipen+5);
    lc.canvas.redraw (rect);
    g.dispose();
    return null;
  }

  Object prim_fillscreen(Object arg1, LContext lc){
    int c = Logo.anInt(arg1, lc);
    Graphics g = lc.canvas.bg.getGraphics();
    g.setColor (new Color(regamut (c)));
    g.fillRect(0, 0,50000, 50000);
    lc.canvas.redraw(new Rectangle(0, 0, 10000, 10000));
    g.dispose();
    return null;
  }

  int regamut(int c){
		return c;
//    if(!TAText.cmykenabled) return c;
//    int r=(c>>16)&0xff, g=(c>>8)&0xff, b=c&0xff;
//		float[] frgb = {(float)(r/256.0),(float)(g/256.0),(float)(b/256.0)};
//		float[] cmyk = TAText.cmykcs.fromRGB(frgb);
//		float[] nfrgb = TAText.cmykcs.toRGB(cmyk);
//		r=(int)(nfrgb[0]*255); g=(int)(nfrgb[1]*255); b=(int)(nfrgb[2]*255);
//    return (r<<16)+(g<<8)+b;
  }

  Object prim_tsetxy(Object arg1, Object arg2, LContext lc){
    int x = Logo.anInt(arg1, lc), y = Logo.anInt(arg2, lc);
    lc.turtle.setxy (x,y);
    return null;
  }

  Object prim_setheading(Object arg1, LContext lc){
    lc.turtle.setheading(Logo.aDouble(arg1, lc));
    return null;
  }

  Object prim_heading(LContext lc){
    return new Double(lc.turtle.heading);
  }

	Object prim_startFill(Object arg1, Object arg2, LContext lc){
		int dpis = TAText.dpiscale;
    double x = Logo.aDouble(arg1, lc), y = Logo.aDouble(arg2, lc);
		path = new GeneralPath();
		path.moveTo((float)(x*dpis),(float)(y*dpis));
		return null;
	}

	Object prim_setxy(Object arg1, Object arg2, LContext lc){
		if(path==null) return null;
		int dpis = TAText.dpiscale;
    double x = Logo.aDouble(arg1, lc), y = Logo.aDouble(arg2, lc);
		path.lineTo((float)(x*dpis),(float)(y*dpis));
		return null;
	}

  Object prim_endFill(Object arg1, LContext lc){
		if (path==null) return null;
    int c = Logo.anInt(arg1, lc);
    Graphics2D g = (Graphics2D)lc.canvas.bg.getGraphics();
    path.closePath();
    g.setColor (new Color(regamut (c)));
    g.fill(path);
    int dpis = TAText.dpiscale;
    Rectangle2D r2d = path.getBounds2D();
    int t = (int)(r2d.getX()/dpis);
    int l = (int)(r2d.getY()/dpis);
    int w = (int)(r2d.getWidth()/dpis);
    int h = (int)(r2d.getHeight()/dpis);
    Rectangle r = new Rectangle(t,l,w,h);
    lc.canvas.redraw(r);
    g.dispose();
    path = null;
    return null;
	}

  Object prim_dropFill(LContext lc){
		path = null;
    return null;
  }
}
