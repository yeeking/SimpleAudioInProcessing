
AudioThread audioThread;


void setup() {
 size(500, 400, P2D);
 // start up the audio thread
 audioThread = new AudioThread();
 audioThread.start();
}

void draw() {
 background(255);
 fill(0);
}

// this gets called by the audio thread when it wants some audio
// we should fill the sent buffer with the audio we want to send to the
// audio output
void generateAudioOut(float[] output, float[] input) {
  for (int i=0;i<output.length;i++){
    // copy the input to the output
    output[i] = input[i];
  }
}

// this function gets called when you press the escape key in the sketch

void stop() {
 // tell the audio to stop
  audioThread.quit();
 // call the version of stop defined in our parent class, in case it does anything vital
 super.stop();
}

