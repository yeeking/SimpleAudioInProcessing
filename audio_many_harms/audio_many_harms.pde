AudioThread audioThread;

float[] wt;
float[] amps;
float phase;
int partials;
float damping = 0.99999;
float baseFreq; 
void setup() {
  size(500,400, P2D);
  partials = 50;
  phase = 0;
  wt = new float[44100];
 // one amp value per partial
  amps = new float[partials]; 
  // generate a simple sin wavetable 
  for(float p=0;p<44100;p++){
    wt[(int)p] = sin(p/44100.0 * TWO_PI);
  } 
  // the frequency of the lowest partial
  baseFreq = 200;
// Create the AudioThread object, which will connect to the audio 
// interface and get it ready to use
  audioThread = new AudioThread();
// Start the audioThread, which will cause it to continually call 'getAudioOut' (see below)
  audioThread.start();
}
 
void draw() {
  background(255);
  fill(0);
  // decide which partial we will be changeing the amp for based on mouseX
  int part = (int)map(mouseX, 0, width, 0, partials);
  // vary the amp based on mouseY
  amps[part] = map(mouseY, 0, height, 0, 1);
  // now draw the current state of the amp array
  for (int i=0;i<partials;i++){
    rect((width / partials) * i, 0, width / partials, height * amps[i]);
  }
}

// this function gets called when you press the escape key in the sketch
void stop(){
  // tell the audio to stop
  audioThread.quit();
  // call the version of stop defined in our parent class, in case it does anything vital
  super.stop();
}

// this gets called by the audio thread when it wants some audio
// we should fill the sent buffer with the audio we want to send to the 
// audio output
void generateAudioOut(float[] buffer){
  for (int i=0;i<buffer.length; i++){
    buffer[i] = 0;
    // use the same wavetable to generate each 
     for (int j=0;j<partials;j++){
     buffer[i] += wt[(int) ((phase * (j+1))%wt.length)] * amps[j];   
      amps[j] *= damping;
    }
    buffer[i] /= partials;
    phase = (phase + baseFreq) % wt.length;
  }
}
 
