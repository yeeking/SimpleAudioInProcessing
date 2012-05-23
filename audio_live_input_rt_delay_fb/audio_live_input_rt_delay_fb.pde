
AudioThread audioThread;

// delay line buffer
float[] delayLine;
// read and write postions on the delay line
int delayReadHead, delayWriteHead;
// the size of the delay line
int maxDelayTime;
float fb;
void setup() {
 size(500, 400, P2D);
 maxDelayTime = 22050;
 delayLine = new float[maxDelayTime];
 // start writing at the start
 delayWriteHead = 0;
 // start reading from the end
 //- maximum delay!
 delayReadHead = maxDelayTime - 1;
 // set feedback to 0
 fb = 0;
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
 float delayTimeF;
 int delayTime;
 for (int i=0;i<output.length; i++) {
  if (pmouseY != mouseY) {
   // they moved the mouseY, chnage the feedback
   fb = (float) mouseY / (float) height;
  }

  if (pmouseX != mouseX) {
   // they moved the mouse, update the delay time
   delayTimeF = (float)mouseX/ (float)width * (float) maxDelayTime;
   // cast to an int
   delayTime = (int) delayTimeF;
   if (delayWriteHead - delayTime < 0) {
    // wrap round to the end
    delayReadHead = maxDelayTime - delayTime + delayWriteHead;
   }
   else {
    delayReadHead = delayWriteHead - delayTime;
   }
  }
  // write into the delayLime, applying the difference equation
  // y[n] = x[n] + 0.95 y[n-D];
  //delayLine[delayWriteHead] = audioData[readHead] + fb * delayLine[delayReadHead];
  delayLine[delayWriteHead] = input[i] + fb * delayLine[delayReadHead];
  // write the delayLine to the buffer
  output[i] = input[i] + delayLine[delayReadHead];

  // now move the various read and write heads
  delayWriteHead = (delayWriteHead + 1) % delayLine.length;
  delayReadHead = (delayReadHead + 1) % delayLine.length;
 }
}

// this function gets called when you press the escape key in the sketch

void stop() {
 // tell the audio to stop
  audioThread.quit();
 // call the version of stop defined in our parent class, in case it does anything vital
 super.stop();
}

