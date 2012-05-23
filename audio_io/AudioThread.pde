/*
 *  This file has been adapted from 
 * https://github.com/mhroth/jvsthost/blob/master/src/com/synthbot/audioio/vst/JVstAudioThread.java
 *
 *  which contains the following license:
 *
 * Copyright 2007 - 2009 Martin Roth (mhroth@gmail.com)
 *                        Matthew Yee-King
 * 
 *  JVstHost is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU Lesser General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  JVstHost is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU Lesser General Public License for more details.
 *  
 *  You should have received a copy of the GNU Lesser General Public License
 *  along with JVstHost.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

import javax.sound.sampled.AudioFormat;
import javax.sound.sampled.AudioSystem;
import javax.sound.sampled.DataLine;
import javax.sound.sampled.LineUnavailableException;
import javax.sound.sampled.SourceDataLine;
import javax.sound.sampled.TargetDataLine;

public class AudioThread extends Thread {
  // buffer to store the audio data coming in
  // it's a 2D array as we may have more than one channel
  private  float[][] fInputs;
  // buffer to store the audio data going out
  private  float[][] fOutputs;
  // raw binary buffer which is used to actually send data to the sound card as bytes
  private  byte[] bOutput;
  private  byte[] bInput;
  private byte[] twoBytes;
  // how many samples to process per cycle? 
  private int blockSize;
  // how many audio outputs/ inputs
  private int numOutputs;
  private int numInputs;
  // samples per second
  private int sampleRate;
  private int bitDepth;
  // the type of audio we are going to generate (PCM/compressed etc? )
  // see http://download.oracle.com/javase/1.5.0/docs/api/javax/sound/sampled/AudioFormat.html
  private AudioFormat audioFormat;
  //  used to access outgoing audio resources
  private SourceDataLine sourceDataLine;
  // used to access incoming audio 
  private TargetDataLine targetDataLine;
  // are we running?

  private boolean running;

  // we pull this value into a variable for speed (avoids repeating the field access and cast operation)
  private static final float ShortMaxValueAsFloat = (float) Short.MAX_VALUE;

  // constructor attempts to initialise the audio device
  AudioThread () {
    running = false;
    // mono
    numOutputs = 1;
    numInputs = 1;
    // block size 4096 samples, lower it if you want lower latency
    blockSize = 1024;
    sampleRate = 44100;
    bitDepth = 16;
    // initialise audio buffers
    fInputs = new float[numInputs][blockSize];
    fOutputs = new float[numOutputs][blockSize];
    bOutput = new byte[numOutputs * blockSize * 2];
    bInput = new byte[numInputs * blockSize * 2];
    twoBytes = new byte[2];
    // set up the audio format, 
    audioFormat = new AudioFormat(sampleRate, bitDepth, numOutputs, true, false);
    // create an object which contains the info required to create an audio out
    DataLine.Info audioOutDataLineInfo = new DataLine.Info(SourceDataLine.class, audioFormat);
    // create an object which contains the info required to create an audio in
    DataLine.Info audioInDataLineInfo = new DataLine.Info(TargetDataLine.class, audioFormat);

    sourceDataLine = null;
    targetDataLine = null;
    // here we try to initialise the audio system. try catch is exception handling, i.e. 
    // dealing with things not working as expected
    try {
      sourceDataLine = (SourceDataLine) AudioSystem.getLine(audioOutDataLineInfo);
      sourceDataLine.open(audioFormat, bOutput.length);
      sourceDataLine.start();

      targetDataLine = (TargetDataLine) AudioSystem.getLine(audioInDataLineInfo);
      targetDataLine.open(audioFormat, bInput.length);
      targetDataLine.start();

      running = true;
    } 
    catch (LineUnavailableException lue) {
      // it went wrong!
      lue.printStackTrace(System.err);
      System.out.println("Could not initialise audio. check above stack trace for more info");
      //System.exit(1);
    }
  }
  // we are ovverriding the run method from the Thread class
  // run gets called when the thread starts
  @Override
    // We must implement run, this gets triggered by start()
  void run () {
    while (running) {
      // read from audio in to the float input array
      targetDataLine.read(bInput, 0, bInput.length);
      // generate the float buffer
      generateAudioOut(fOutputs[0], bytesToFloats(bInput, fOutputs[0]));
      // convert to bytes and send it to the card
      sourceDataLine.write(floatsToBytes(fOutputs, bOutput), 0, bOutput.length);
    }
  }

  // returns the current contents of the audio buffer
  float[] getAudio() {
    return fOutputs[0];
  }

  // Our method that quits the thread
  // taken from http://wiki.processing.org/w/Threading
  void quit() {
    System.out.println("Quitting audio thread."); 
    running = false;  // Setting running to false ends the loop in run()
    sourceDataLine.drain();
    sourceDataLine.close();  
    // IUn case the thread is waiting. . .
    // note that the interrupt method is defined in the Thread class which we are extending
    interrupt();
  }
  // this method is not general, it just assumes 2 bytes per sample and a single input channel
  private float[] bytesToFloats(byte[] bData, float[] fData) {
    for (int i=0;i<bData.length;i+=2) {
      twoBytes[0] = bData[i];
      twoBytes[1] = bData[i+1]; 
      fData[i/2] = twoBytesToFloat(twoBytes);
      //if (i % 4000 == 0){
      //     println("f: "+fData[i/2]);
      //}
    }
    return fData;
  }

  // hacked mercilessly out of the AudioFileIn class
  // written by 'AA' (see other tab...)
  // it assumes that the buffer contains enough bytes for one sample
  // e.g. if 16 bit, 2 bytes. 

  private float twoBytesToFloat(byte[] b) {
    float sample = 0.0f;
    int ret = 0;
    int length = b.length;
    //for (int i = 0; i < b.length; i++, length--) {
    ret |= ((int) (b[0] & 0xFF) << ((((false) ? length : (1)) * 8) - 8));
    ret |= ((int) (b[1] & 0xFF) << ((((false) ? length : (2)) * 8) - 8));
    if (ret > 0x7FFF) {
      ret = ~ret + 1;
      ret &= 0x7FFF;
      ret = ~ret + 1;
    }
    sample = (float) ((float) ret / (float) Short.MAX_VALUE);
    return sample;
  }


  /**
   * Converts a float audio array [-1,1] to an interleaved array of 16-bit samples
   * in little-endian (low-byte, high-byte) format.
   */
  private byte[] floatsToBytes(float[][] fData, byte[] bData) {
    int index = 0;
    for (int i = 0; i < blockSize; i++) {
      for (int j = 0; j < numOutputs; j++) {
        short sval = (short) (fData[j][i] * ShortMaxValueAsFloat);
        bData[index++] = (byte) (sval & 0x00FF);
        bData[index++] = (byte) ((sval & 0xFF00) >> 8);
      }
    }
    return bData;
  }
}


