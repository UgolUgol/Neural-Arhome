# Arhome
This is simple application, that show, how we can use AR technology and neural network.
It allow you to create a model of our solar system and to control it with help of your hands.

## What had been already done ? 
+ 3D model of solar system(using physical features)
+ rotation with your own hand

## Troubles
The biggest trouble is neural network, that had been used for hands detection. It is Yolo2 and it is not a good mobile solution
cause of big cpu and gpu usage.
Another problem is that hands detection on mobile with help of yolo working not good(you cant test it yourself)

## Requirements
+ You need device with iOS 11 and A9> CPU
+ IPhone 8,8+,X recommended

## ML model for app
You can train yolo model yourself and use it in app or use my model.

## Instruments 
+ ARKIT
+ Coreml
+ Darknet Yolo
+ Darkflow(convert from darknet format to .pb format)
+ cormeltools(python 2.7 or 3.5)

Thank your.
