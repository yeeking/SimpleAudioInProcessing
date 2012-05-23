AudioThread audioThread;
 
 
 float[] sine;
 int readHead;
 float freq;
 float currFreq;
 
void setup() {
  size(500,400, P2D);
// Create the AudioThread object, which will connect to the audio 
// interface and get it ready to use
    readHead = 0;

  float N = 44100;
  float n;
  float f;
  sine = new float[(int)N];
  for (n = 0; n < N; n++){
    sine[(int)n] = sin(TWO_PI / N * n);
  }
  
  for (n=0;n<sine.length;n++){
     //println("value at "+n+" is "+sine[(int)n]); 
  }
  freq = 1;
  audioThread = new AudioThread();
// Start the audioThread, which will cause it to continually call 'getAudioOut' (see below)
  audioThread.start();
  
  
  
}
 
void draw() {
  background(0);
  fill(0);
  stroke(255);
  strokeWeight(5);
  freq = mouseX;
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
    // generate white noise
    buffer[i] = sine[readHead];
    // smoothing
    if (currFreq > freq){
      currFreq -= 0.01;
    }
    if (currFreq < freq){
      currFreq += 0.01;
    }
    
    readHead = (readHead + (int)currFreq) % sine.length;
  }
}
 
