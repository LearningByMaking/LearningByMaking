class WavPrims extends Primitives {

  static String[] primlist={
      "setsamples", "2",
      "getsample", "1", "getsamples", "2", "avemag", "2",
      "setupfftsamples", "3", "freqmix", "3",
      "freqshift", "1", "downsample", "1",
  };

  public String[] primlist(){return primlist;}

  int offset;
  Complex [] samples;

  public Object dispatch(int offset, Object[] args, LContext lc){
    switch(offset){
      case 0: return prim_setsamples(args[0], args[1], lc);
      case 1: return prim_getsample(args[0], lc);
      case 2: return prim_getsamples(args[0], args[1], lc);
      case 3: return prim_avemag(args[0], args[1], lc);
      case 4: return prim_setupfftsamples(args[0], args[1], args[2], lc);
      case 5: return prim_freqmix(args[0], args[1], args[2], lc);
      case 6: return prim_freqshift(args[0], lc);
      case 7: return prim_downsample(args[0], lc);
    }
    return null;
  }

  Object prim_setsamples(Object arg1, Object arg2, LContext lc){
    byte[] bytes = (byte[]) arg1;
    offset = Logo.anInt(arg2, lc);
		samples = new Complex[(bytes.length-offset)/4];
		int i=0;
		for(int index=offset;index<bytes.length;index+=4){
			int idata = (bytes[index]&0xff)+256*(bytes[index+1]&0xff);
			if(idata>32767) idata-=65536;
			int qdata = (bytes[index+2]&0xff)+256*(bytes[index+3]&0xff);
			if(qdata>32767) qdata-=65536;
			samples[i++] = new Complex(idata, qdata);
		}
    return null;
  }


  Object prim_getsample(Object arg1, LContext lc){
    return samples[Logo.anInt(arg1, lc)];
  }


  Object prim_getsamples(Object arg1, Object arg2, LContext lc){
    int start = Logo.anInt(arg1, lc);
    int len = Logo.anInt(arg2, lc);
    Object[] res = new Object[len];
    for(int i=0;i<len;i++) res[i]=samples[i+start];
    return res;
  }

  Object prim_avemag(Object arg1, Object arg2, LContext lc){
    int start = Logo.anInt(arg1, lc);
    int len = Logo.anInt(arg2, lc);
    double sum = 0;
    for(int i=start;i<start+len;i++) sum+=samples[i].abs();
    return new Double(sum/len);
  }

  Object prim_setupfftsamples(Object arg1, Object arg2, Object arg3, LContext lc){
    int start = Logo.anInt(arg1, lc);
    int len = Logo.anInt(arg2, lc);
    int bins = Logo.anInt(arg3, lc);
    Complex [] res = new Complex[bins];
    Complex zero = new Complex(0,0);
    for(int i=0;i<bins;i++) res[i]= zero;
    Complex sum = new Complex(0,0);
    for(int i=0;i<len;i++) sum = sum.plus(samples[i+start]);
    Complex average = sum.times(new Complex(len, 0).reciprocal());
    for(int i=0;i<len;i++) res[i] = samples[i+start].minus(average);
    return res;
  }

  Object prim_freqmix(Object arg1, Object arg2, Object arg3, LContext lc){
    int start = Logo.anInt(arg1, lc);
    int len = Logo.anInt(arg2, lc);
    double phasedelta = Logo.aDouble(arg3, lc);
    Complex res = new Complex(0,0);
    double phase=0;
    for(int i=0;i<len;i++) {
      res = res.plus(samples[i+start].times(new Complex(Math.cos(phase), Math.sin(phase))));
      phase += phasedelta;
    }
    return res.abs();
  }

  Object prim_freqshift(Object arg1, LContext lc){
    double phasedelta = Logo.aDouble(arg1, lc), phase=0;
    for(int i=0;i<samples.length;i++) {
      samples[i] = samples[i].times(new Complex(Math.cos(phase), Math.sin(phase)));
      phase += phasedelta;
    }
    return null;
  }

  Object prim_downsample(Object arg1, LContext lc){
    int factor = Logo.anInt(arg1, lc);
    Complex[] newsamples = new Complex[samples.length/factor];
    Complex ifactor = new Complex(1.0/factor, 0);
    for(int i=0;i<newsamples.length;i++){
				Complex sum = new Complex(0,0);
				for(int j=0;j<factor;j++) sum = sum.plus(samples[i*factor+j]);
				newsamples[i] = sum.times(ifactor);
		}
		samples = newsamples;
		return null;
	}
}

