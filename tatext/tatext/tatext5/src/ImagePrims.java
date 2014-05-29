import javax.imageio.ImageIO;
import javax.imageio.ImageReader;
import javax.imageio.ImageWriter;
import javax.imageio.ImageWriteParam;
import javax.imageio.stream.ImageOutputStream;
import javax.imageio.stream.ImageInputStream;
import javax.imageio.ImageTypeSpecifier;
import javax.imageio.metadata.IIOMetadata;
import javax.imageio.metadata.IIOMetadataNode;
import javax.imageio.IIOImage;
import java.awt.Color;
import java.awt.Image;
import java.awt.image.BufferedImage;
import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.Rectangle;
import java.awt.geom.AffineTransform;
import java.awt.RenderingHints;
import java.io.File;
import java.io.InputStream;
import java.io.FileInputStream;
import java.io.DataInputStream;
import java.util.Iterator;
import java.net.URL;

class ImagePrims extends Primitives {


  static String[] primlist={
    "getpixel", "2", "getalpha", "2", "setpixel", "3",
    "readfunctions", "1", "settitle", "1",
    "loadpic", "2", "savepic", "1"
  };


  public String[] primlist(){return primlist;}


  public Object dispatch(int offset, Object[] args, LContext lc){
    synchronized((lc.canvas==null) ? ((Object)lc) : ((Object) lc.canvas)){
      switch(offset){
      case 0: return prim_getpixel(args[0], args[1], lc);
      case 1: return prim_getalpha(args[0], args[1], lc);
      case 2: return prim_setpixel(args[0], args[1], args[2], lc);
      case 3: return prim_readfunctions(args[0], lc);
      case 4: return prim_settitle(args[0], lc);
      case 5: return prim_loadpic(args[0], args[1], lc);
      case 6: return prim_savepic(args[0], lc);
      }
      return null;
    }
  }

  Object prim_getpixel(Object arg1, Object arg2, LContext lc){
    int x = Logo.anInt(arg1, lc), y = Logo.anInt(arg2, lc);
    return new Integer(lc.canvas.bg.getRGB(x,y)&0xffffff);
  }

  Object prim_getalpha(Object arg1, Object arg2, LContext lc){
    int x = Logo.anInt(arg1, lc), y = Logo.anInt(arg2, lc);
    return new Integer((lc.canvas.bg.getRGB(x,y)>>24)&0xff);
  }

  Object prim_setpixel(Object arg1, Object arg2, Object arg3, LContext lc){
    int x = Logo.anInt(arg1, lc), y = Logo.anInt(arg2, lc), c = Logo.anInt(arg3, lc);
    lc.canvas.bg.setRGB(x,y,c);
    return null;
  }

  Object prim_readfunctions(Object arg1, LContext lc){
		String procs = Logo.aString(arg1, lc);
		Logo.readAllFunctions(procs, lc);
		return null;
	}

  Object prim_settitle(Object arg1, LContext lc){
		String title = Logo.aString(arg1, lc);
		lc.frame.setTitle(title);
		return null;
	}

  Object prim_loadpic(Object arg1, Object arg2, LContext lc){
    String filename = Logo.aString(arg1, lc);
    boolean isLocal = Logo.aBoolean(arg2, lc);
    BufferedImage img = null;
    InputStream is;
    try {
			if(isLocal) is = new FileInputStream(new File(filename));
			else is = new URL(filename).openStream();
      ImageReader reader = null;
      Iterator iter = ImageIO.getImageReadersByFormatName("png");
      if (iter.hasNext()) {
          reader = (ImageReader)iter.next();
      }
      ImageInputStream iis = ImageIO.createImageInputStream(is);
      reader.setInput( iis, true );
      img = reader.read(0);
			is.close();
    }
    catch(Exception e) {Logo.error("loadbg problem "+" "+e+" "+filename, lc);}
    Graphics g = lc.canvas.bg.getGraphics();
    g.drawImage(img, 0, 0, null);
    g.dispose();
    lc.canvas.redraw(new Rectangle(0,0,10000,10000));
    return null;
  }

	Object prim_savepic(Object arg1, LContext lc){
		String name = Logo.prs(arg1);
		savePNG(name, lc.canvas.bg, lc);
		return null;
	}

	void savePNG(String name, BufferedImage img, LContext lc){
    try {
        File f = new File(name+".png");
        f.delete();
        ImageWriter writer = null;
        Iterator iter = ImageIO.getImageWritersByFormatName("png");
        if (iter.hasNext()) {
            writer = (ImageWriter)iter.next();
        }
        ImageOutputStream ios = ImageIO.createImageOutputStream(f);
        writer.setOutput(ios);
        writer.write(imageWithDPI(writer, img, lc));
        ios.flush();
        writer.dispose();
        ios.close();
    } catch (Exception e) {Logo.error("savebg problem - "+e, lc);}
	}

	IIOImage imageWithDPI(ImageWriter iw, BufferedImage image, LContext lc){
    try {
			ImageWriteParam iwp = iw.getDefaultWriteParam();
			ImageTypeSpecifier its = new ImageTypeSpecifier(image);
			IIOMetadata imd = iw.getDefaultImageMetadata(its,iwp);
			String format = "javax_imageio_png_1.0";
			IIOMetadataNode tree = (IIOMetadataNode)imd.getAsTree(format);
			IIOMetadataNode node = new IIOMetadataNode("pHYs");
			String dpm = Integer.toString((int)Math.ceil(300/0.0254));
			node.setAttribute("pixelsPerUnitXAxis",dpm);
			node.setAttribute("pixelsPerUnitYAxis",dpm);
			node.setAttribute("unitSpecifier","meter");
			tree.appendChild(node);
			imd.setFromTree(format,tree);
			return new IIOImage(image,null,imd);
    } catch (Exception e) {Logo.error("dpi problem - "+e, lc);}
    return null;
   }

}


