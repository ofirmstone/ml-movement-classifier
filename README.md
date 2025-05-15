<div align="center"> 

# FitTrack - an IoT system to assist athlete load monitoring
  
<em>Using an Arduino Nano 33 BLE and TinyML to classify movement to a mobile phone in real-time</em>

<img src="https://img.shields.io/github/license/ofirmstone/ml-movement-classifier?logo=opensourceinitiative&logoColor=white&color=blue" alt="license">
<img src="https://img.shields.io/github/last-commit/ofirmstone/ml-movement-classifier?style=flat&logo=git&logoColor=white&color=blue" alt="last-commit">
<img src="https://img.shields.io/github/languages/top/ofirmstone/ml-movement-classifier?style=flat&color=blue" alt="repo-top-language">
<img src="https://img.shields.io/github/languages/count/ofirmstone/ml-movement-classifier?style=flat&color=blue" alt="repo-language-count">

<em>Built with the following tools and technologies:</em>

<img alt="Static Badge" src="https://img.shields.io/badge/Arduino-%2300878F?logo=arduino&logoColor=white">
<img alt="Static Badge" src="https://img.shields.io/badge/TensorFlow-%23FF6F00?logo=tensorflow&logoColor=white">
<img alt="Static Badge" src="https://img.shields.io/badge/Python-%233776AB?logo=python&logoColor=white">
<img alt="Static Badge" src="https://img.shields.io/badge/Colab-%23F9AB00?logo=googlecolab&logoColor=white">
<img alt="Static Badge" src="https://img.shields.io/badge/Flutter-%2302569B?logo=flutter&logoColor=white">
<img alt="Static Badge" src="https://img.shields.io/badge/Dart-%230175C2?logo=dart&logoColor=white">

</div>
<br>


---

## Overview

FitTrack was originally developed as a team project for Mobile & Ubiquitous Computing by Team 9 in semester 2 of 3rd year. The project required building a functional prototype that used the output of an Arduino Nano 33 BLE, classified it using TinyML and then displayed this classification on a mobile phone using a BLE connection. We decided on an IoT system that would classify an athlete's movement using on-body sensing.

In this project, we have collated datasets for the 3 movement types: idle, walking, running. This was done using the **serialreader.py** file, reading the Arduino's accelerometer coordinates which are outputted every 20ms. After collecting 3000+ samples for each dataset, they were then used within our Google Colab page to develop a TinyML classifier which could then be uploaded back to the Arduino. 

This meant that any new data from the accelerometer could be classified and communicated to the phone using Bluetooth Low Energy (BLE) in real-time. We developed a Flutter app (**main.dart** and **pubspec.yaml**) to display this classification from the Arduino.

## Prototype testing

Footage of early testing for our prototype is shown below:

https://github.com/user-attachments/assets/4be26ba9-1a9a-4b1a-a314-8687633debb2

<br>

## Further development

After research into the evolution of athlete load monitoring, and the current multifaceted approach used to help prevent injuries in sport, I have outlined a future development path for this prototype to help tackle problems with current athlete monitoring technology (use at all levels of competition, real-time data rather than retrospective for proactive prevention).

My solution is a wearable IoT system connected to a smartphone application, allowing multiple players (a full team) to be tracked simultaneously to aid coaches' abilities to assess when certain players require a break by providing statistical data rather than relying on observational judgement and communication. This solution would utilize a **heart rate sensor** in tandem with our Arduino.

## Acknowledgments

**Team 9:** <a href="https://github.com/ofirmstone" target="_blank" style="">Oliver Firmstone</a>, 
<a href="https://github.com/sam-lawal" target="_blank">Samuel Lawal</a>, 
Saleban Abdi, Fareedah Bello

