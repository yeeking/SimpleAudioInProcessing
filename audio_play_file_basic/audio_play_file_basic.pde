AudioThread audioThread;
// we'll use this to store the audio data we read from the audio file
float[] audioData;
// we'll use this to remember our position in the audio data array
int readHead;


void setup() {
  size(50,50, P2D);
  // the audio file we want to play, which should be in the data dir
  String audioFilename = "myk_hats_dub1.wav";
  // read the audio data into a float array using the AudioFileIn class
  audioData = new AudioFileIn(audioFilename, this).getSampleData();
  // print how many samples we read
  println("Read "+audioData.length+" samples");
  // set the read head to zero, the first sample
  readHead = 0;
  // start up the audio thread
  audioThread = new AudioThread();
  audioThread.start();
  
}
 
void draw() {
  background(0); 
  
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
    // copy data from the audio we read from the file (audioData)
    // into the buffer that gets sent to the sound card
    buffer[i] =audioData[readHead];
    readHead = (readHead + 1) % audioData.length;

  }
}


