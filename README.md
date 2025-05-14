# Mobile & Ubiquitous Computing - Team 9  
### Using Arduino Nano 33 BLE to classify movement to a mobile phone  

Team 9: 
<!-- Write your name followed by 2 spaces and then return -->
- Oliver Firmstone
- Samuel Lawal

In this project, we have collated datasets for the 3 movement types: idle, walking, running. This was done using the **serialreader.py** file, reading the Arduino's accelerometer coordinates which are outputted every 20ms. After collecting 3000+ samples for each dataset, they were then used within our Google Colab page to develop a TinyML classifier which could then be uploaded back to the Arduino. 

This meant that any new data from the accelerometer could be classified and communicated to the phone using Bluetooth Low Energy (BLE) in real-time. We developed a Flutter app (**main.dart** and **pubspec.yaml**) to display this classification from the Arduino.

### Prototype functioning in early test:

https://github.com/user-attachments/assets/4be26ba9-1a9a-4b1a-a314-8687633debb2


# Further Solo Development
### FitTrack - using movement classification and heart rate data to assist athlete load management

After research into the evolution of athlete load monitoring, and the current multifaceted approach used to help prevent injuries in sport, I have outlined a future development path for this prototype to help tackle problems with current athlete monitoring technology (use at all levels of competition, real-time data rather than retrospective for proactive prevention).

My solution is a wearable IoT system connected to a smartphone application, allowing multiple players (a full team) to be tracked simultaneously to aid coaches' abilities to assess when certain players require a break by providing statistical data rather than relying on observational judgement and communication. This solution would utilize a heart rate sensor in tandem with our Arduino.


