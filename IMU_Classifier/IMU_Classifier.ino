/*
  IMU Classifier

  This example uses the on-board IMU to start reading acceleration
  data from on-board IMU, once enough samples are read, it then uses a
  TensorFlow Lite (Micro) model to try to classify the movement as a known gesture.

  Note: The direct use of C/C++ pointers, namespaces, and dynamic memory is generally
        discouraged in Arduino examples, and in the future the TensorFlowLite library
        might change to make the sketch simpler.

  The circuit:
  - Arduino Nano 33 BLE or Arduino Nano 33 BLE Sense board.

  Created by Abhirup Ghosh for MUC lab, University of Birmingham

  This example code is inspired by https://github.com/arduino/ArduinoTensorFlowLiteTutorials/tree/master
*/

#include <Arduino_LSM9DS1.h>
#include <ArduinoBLE.h>

#include <TensorFlowLite.h>
#include "tensorflow/lite/micro/all_ops_resolver.h"
#include "tensorflow/lite/micro/micro_interpreter.h"
#include "tensorflow/lite/schema/schema_generated.h"

#include "model.h"

BLEService imuService("181A");
BLEStringCharacteristic gestureCharacteristic("2A56", BLERead | BLENotify, 20);
// BLEFloatCharacteristic confidenceCharacteristic("2A58", BLERead | BLENotify);

const int numSamples = 150;

int samplesRead = 0;

// pull in all the TFLM ops, you can remove this line and
// only pull in the TFLM ops you need, if would like to reduce
// the compiled size of the sketch.
tflite::AllOpsResolver tflOpsResolver;

const tflite::Model* tflModel = nullptr;
tflite::MicroInterpreter* tflInterpreter = nullptr;
TfLiteTensor* tflInputTensor = nullptr;
TfLiteTensor* tflOutputTensor = nullptr;

// Create a static memory buffer for TFLM, the size may need to
// be adjusted based on the model you are using
constexpr int tensorArenaSize = 8 * 1024;
byte tensorArena[tensorArenaSize] __attribute__((aligned(16)));

// array to map gesture index to a name
const char* GESTURES[] = {
  "running",
  "walking",
  "idle"
};

#define NUM_GESTURES (sizeof(GESTURES) / sizeof(GESTURES[0]))

void setup() {
  Serial.begin(9600);
  while (!Serial);

  // initialize the BLE
  if (!BLE.begin()) {
    Serial.println("Failed to initialize BLE!");
    while (1);
  }

  Serial.println("Initialized BLE");

  // initialize the IMU
  if (!IMU.begin()) {
    Serial.println("Failed to initialize IMU!");
    while (1);
  }

  Serial.println("Initialized IMU");

  BLE.setLocalName("IMUClassifier");
  BLE.setAdvertisedService(imuService);

  imuService.addCharacteristic(gestureCharacteristic);
  // imuService.addCharacteristic(confidenceCharacteristic);

  BLE.addService(imuService);

  // initial values
  gestureCharacteristic.writeValue("unknown");
  // confidenceCharacteristic.writeValue(0.0);


  // print out the samples rates of the IMUs
  Serial.print("Accelerometer sample rate = ");
  Serial.print(IMU.accelerationSampleRate());
  Serial.println(" Hz");

  Serial.println();

  // get the TFL representation of the model byte array
  tflModel = tflite::GetModel(model);
  if (tflModel->version() != TFLITE_SCHEMA_VERSION) {
    Serial.println("Model schema mismatch!");
    return;
  }

  // Create an interpreter to run the model
  tflInterpreter = new tflite::MicroInterpreter(tflModel, tflOpsResolver, tensorArena, tensorArenaSize);


  // Allocate memory from the tensor_arena for the model's tensors.
  TfLiteStatus allocate_status = tflInterpreter->AllocateTensors();
  if (allocate_status != kTfLiteOk) {
    MicroPrintf("AllocateTensors() failed");
    return;
  }

  // Get pointers for the model's input and output tensors
  tflInputTensor = tflInterpreter->input(0);
  tflOutputTensor = tflInterpreter->output(0);
}

void loop() {
  float aX, aY, aZ;

  if (samplesRead < numSamples) {
    // check if new acceleration data is available
    if (IMU.accelerationAvailable()) {
      // read the acceleration
      IMU.readAcceleration(aX, aY, aZ);

      // normalize the IMU data between 0 to 1 and store in the model's
      // input tensor
      tflInputTensor->data.f[samplesRead * 3 + 0] = aX;
      tflInputTensor->data.f[samplesRead * 3 + 1] = aY;
      tflInputTensor->data.f[samplesRead * 3 + 2] = aZ;
      samplesRead++;
    }
  }

  if (samplesRead == numSamples) {
    // Run inferencing
    TfLiteStatus invokeStatus = tflInterpreter->Invoke();
    if (invokeStatus != kTfLiteOk) {
      Serial.println("Invoke failed!");
      while (1);
      return;
    }

    float maxConfidence = 0;
    int gestureIndex = 0;

    // Loop through the output tensor values from the model
    for (int i = 0; i < NUM_GESTURES; i++) {
      float confidence = tflOutputTensor->data.f[i];

      Serial.print(GESTURES[i]);
      Serial.print(": ");
      Serial.println(confidence, 6);

      if (confidence > maxConfidence) {
        maxConfidence = confidence;
        gestureIndex = i;
      }
    }

    gestureCharacteristic.writeValue(GESTURES[gestureIndex]);
    // confidenceCharacteristic.writeValue(maxConfidence);

    Serial.print("Classified as: ");
    Serial.print(GESTURES[gestureIndex]);
    Serial.print(" (confidence: ");
    Serial.print(maxConfidence);
    Serial.println(")");

    // Clean up the data buffer before filling up for the next batch.
    int i = 0;
    for (; i< numSamples; i ++) {
      tflInputTensor->data.f[i * 3 + 0];
    }

    Serial.println();
    samplesRead = 0;
  }
}
