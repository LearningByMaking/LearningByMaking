class FFT {

    // compute the FFT of x[], assuming its length is a power of 2
    public static Complex[] fft(Complex[] x) {
        int N = x.length;

        // base case
        if (N == 1) return new Complex[] { x[0] };

        // radix 2 Cooley-Tukey FFT
        if (N % 2 != 0) { throw new RuntimeException("N is not a power of 2"); }

        // fft of even terms
        Complex[] even = new Complex[N/2];
        for (int k = 0; k < N/2; k++) {
            even[k] = x[2*k];
        }
        Complex[] q = fft(even);

        // fft of odd terms
        Complex[] odd  = even;  // reuse the array
        for (int k = 0; k < N/2; k++) {
            odd[k] = x[2*k + 1];
        }
        Complex[] r = fft(odd);

        // combine
        Complex[] y = new Complex[N];
        for (int k = 0; k < N/2; k++) {
            double kth = -2 * k * Math.PI / N;
            Complex wk = new Complex(Math.cos(kth), Math.sin(kth));
            y[k]       = q[k].plus(wk.times(r[k]));
            y[k + N/2] = q[k].minus(wk.times(r[k]));
        }
        return y;
    }


    // compute the inverse FFT of x[], assuming its length is a power of 2
    public static Complex[] ifft(Complex[] x) {
        int N = x.length;
        Complex[] y = new Complex[N];

        // take conjugate
        for (int i = 0; i < N; i++) {
            y[i] = x[i].conjugate();
        }

        // compute forward FFT
        y = fft(y);

        // take conjugate again
        for (int i = 0; i < N; i++) {
            y[i] = y[i].conjugate();
        }

        // divide by N
        for (int i = 0; i < N; i++) {
            y[i] = y[i].times(1.0 / N);
        }

        return y;

    }

    // compute the circular convolution of x and y
    public static Complex[] cconvolve(Complex[] x, Complex[] y) {

        // should probably pad x and y with 0s so that they have same length
        // and are powers of 2
        if (x.length != y.length) { throw new RuntimeException("Dimensions don't agree"); }

        int N = x.length;

        // compute FFT of each sequence
        Complex[] a = fft(x);
        Complex[] b = fft(y);

        // point-wise multiply
        Complex[] c = new Complex[N];
        for (int i = 0; i < N; i++) {
            c[i] = a[i].times(b[i]);
        }

        // compute inverse FFT
        return ifft(c);
    }


    // compute the linear convolution of x and y
    public static Complex[] convolve(Complex[] x, Complex[] y) {
        Complex ZERO = new Complex(0, 0);

        Complex[] a = new Complex[2*x.length];
        for (int i = 0;        i <   x.length; i++) a[i] = x[i];
        for (int i = x.length; i < 2*x.length; i++) a[i] = ZERO;

        Complex[] b = new Complex[2*y.length];
        for (int i = 0;        i <   y.length; i++) b[i] = y[i];
        for (int i = y.length; i < 2*y.length; i++) b[i] = ZERO;

        return cconvolve(a, b);
    }


}

class Complex {
    private final double re;   // the real part
    private final double im;   // the imaginary part

    // create a new object with the given real and imaginary parts
    public Complex(double real, double imag) {
        re = real;
        im = imag;
    }

    // return a string representation of the invoking Complex object
    public String toString() {
        if (im == 0) return re + "";
        if (re == 0) return im + "i";
        if (im <  0) return re + " - " + (-im) + "i";
        return re + " + " + im + "i";
    }

    // return abs/modulus/magnitude and angle/phase/argument
    public double abs()   { return Math.hypot(re, im); }  // Math.sqrt(re*re + im*im)
    public double phase() { return Math.atan2(im, re); }  // between -pi and pi

    // return a new Complex object whose value is (this + b)
    public Complex plus(Complex b) {
        Complex a = this;             // invoking object
        double real = a.re + b.re;
        double imag = a.im + b.im;
        return new Complex(real, imag);
    }

    // return a new Complex object whose value is (this - b)
    public Complex minus(Complex b) {
        Complex a = this;
        double real = a.re - b.re;
        double imag = a.im - b.im;
        return new Complex(real, imag);
    }

    // return a new Complex object whose value is (this * b)
    public Complex times(Complex b) {
        Complex a = this;
        double real = a.re * b.re - a.im * b.im;
        double imag = a.re * b.im + a.im * b.re;
        return new Complex(real, imag);
    }

    // scalar multiplication
    // return a new object whose value is (this * alpha)
    public Complex times(double alpha) {
        return new Complex(alpha * re, alpha * im);
    }

    // return a new Complex object whose value is the conjugate of this
    public Complex conjugate() {  return new Complex(re, -im); }

    // return a new Complex object whose value is the reciprocal of this
    public Complex reciprocal() {
        double scale = re*re + im*im;
        return new Complex(re / scale, -im / scale);
    }

    // return the real or imaginary part
    public double re() { return re; }
    public double im() { return im; }

    // return a / b
    public Complex divides(Complex b) {
        Complex a = this;
        return a.times(b.reciprocal());
    }

    // return a new Complex object whose value is the complex exponential of this
    public Complex exp() {
        return new Complex(Math.exp(re) * Math.cos(im), Math.exp(re) * Math.sin(im));
    }

    // return a new Complex object whose value is the complex sine of this
    public Complex sin() {
        return new Complex(Math.sin(re) * Math.cosh(im), Math.cos(re) * Math.sinh(im));
    }

    // return a new Complex object whose value is the complex cosine of this
    public Complex cos() {
        return new Complex(Math.cos(re) * Math.cosh(im), -Math.sin(re) * Math.sinh(im));
    }

    // return a new Complex object whose value is the complex tangent of this
    public Complex tan() {
        return sin().divides(cos());
    }



    // a static version of plus
    public static Complex plus(Complex a, Complex b) {
        double real = a.re + b.re;
        double imag = a.im + b.im;
        Complex sum = new Complex(real, imag);
        return sum;
    }



}

class ComplexPrims extends Primitives {

  static String[] primlist={
    "complex", "2", "re", "1", "im", "1", "mag", "1", "phase", "1",
    "csum", "2", "cdiff", "2", "cprod", "2", "cquot", "2",
    "clist", "1", "cnth", "2", "csetnth", "3",
    "fft", "1", "ifft", "1", "fnth", "2", "fsetnth", "3",
  };


  public String[] primlist(){return primlist;}

  public Object dispatch(int offset, Object[] args, LContext lc){
    switch(offset){
    case 0: return new Complex(Logo.aDouble(args[0], lc), Logo.aDouble(args[1], lc));
    case 1: return ((Complex) args[0]).re();
    case 2: return ((Complex) args[0]).im();
    case 3: return ((Complex) args[0]).abs();
    case 4: return ((Complex) args[0]).phase();
    case 5: return ((Complex) args[0]).plus((Complex) args[1]);
    case 6: return ((Complex) args[0]).minus((Complex) args[1]);
    case 7: return ((Complex) args[0]).times((Complex) args[1]);
    case 8: return ((Complex) args[0]).divides((Complex) args[1]);
    case 9: return prim_clist(args[0],lc);
    case 10: return prim_cnth(args[0], args[1], lc);
    case 11: return prim_csetnth(args[0], args[1], args[2], lc);
    case 12: return FFT.fft((Complex[]) args[0]);
    case 13: return FFT.ifft((Complex[]) args[0]);
    case 14: return prim_fnth(args[0], args[1], lc);
    case 15: return prim_fsetnth(args[0], args[1], args[2], lc);
    }
    return null;
  }

  Object prim_clist(Object arg1, LContext lc){
    int len = Logo.anInt(arg1, lc);
    Complex zero = new Complex(0,0);
    Complex[] clist = new Complex[len];
    for(int i=0;i<len;i++) clist[i]= zero;
    return clist;
  }

  Object prim_cnth(Object arg1, Object arg2, LContext lc){
    Complex [] arr = (Complex[]) arg2;
    int index = (Logo.anInt(arg1, lc)+arr.length)%arr.length;
    return arr[index];
  }

  Object prim_csetnth(Object arg1, Object arg2, Object arg3, LContext lc){
    Complex [] arr = (Complex[]) arg2;
    int index = (Logo.anInt(arg1, lc)+arr.length)%arr.length;
    Complex val = (arg3 instanceof Complex) ?
      ((Complex) arg3) :
      new Complex (Logo.aDouble(arg3, lc), 0);
    arr[index] = val;
    return null;
  }

  Object prim_fnth(Object arg1, Object arg2, LContext lc){
    byte[] arr = (byte[]) arg2;
    int index = (Logo.anInt(arg1, lc))*4;
    int bits = (arr[index]&0xff)+((arr[index+1]&0xff)<<8)+((arr[index+2]&0xff)<<16)+((arr[index+3]&0xff)<<24);
    return new Double(Float.intBitsToFloat(bits));
  }

  Object prim_fsetnth(Object arg1, Object arg2, Object arg3, LContext lc){
    byte[] arr = (byte[]) arg2;
    int index = (Logo.anInt(arg1, lc))*4;
    float val = (float)(Logo.aDouble(arg3, lc));
    int bits = Float.floatToIntBits(val);
    arr[index]=(byte)bits;
    arr[index+1]=(byte)(bits>>8);
    arr[index+2]=(byte)(bits>>16);
    arr[index+3]=(byte)(bits>>24);
    return null;
  }

}

