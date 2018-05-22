//
//  Detector.swift
//  ARHOME112
//
//  Created by Ugol Ugol on 22/05/2018.
//  Copyright © 2018 Ugol Ugol. All rights reserved.
//

import Foundation

import CoreML
import Vision
import Accelerate
import ARKit

class Detector {
    var hand_pos: Int = 0
    var rotate_scene: Bool = false
    var rotation_dir: Int = 0
    
    let yolo = Yolo()
    
    // pixel buffer for Vision request
    private var currentBuffer: CVPixelBuffer?
    
    // queue for dispatching vision detection request
    private let visionQueue = DispatchQueue(label: "com.example.apple-samplecode.ARKitVision.serialVisionQueue")
    
    // Vision Request
    private lazy var detectionRequest: VNCoreMLRequest = {
        do{
            let model = try VNCoreMLModel(for: yolo.model.model)
            let request = VNCoreMLRequest(model: model, completionHandler: visionRequestDidComplete)
            
            request.imageCropAndScaleOption = .scaleFill
            return request
        } catch {
            fatalError("Failed to load Vision Model: \(error)")
        }
    }()
    
    // vision request completionHandler
    func visionRequestDidComplete(request: VNRequest, error: Error?){
        DispatchQueue.main.async {
            if let observations = request.results as? [VNCoreMLFeatureValueObservation],
                let features = observations.first?.featureValue.multiArrayValue{
                let bboxes = self.yolo.computeBBox(features: features)
                self.show(predictions: bboxes)
            }
        }
        
    }
    
    func show(predictions: [Yolo.Prediction]){
        if(predictions.count > 0)
        {
            let cur_pos = predictions[0].hand.xc
            let dh = self.hand_pos - cur_pos
            if(self.hand_pos == 0 || dh == 0){
                self.rotate_scene = false
                print("none")
            }
            else if(dh < 0){
                self.rotate_scene = true
                self.rotation_dir = -1
                print("left")
            }
            else if(dh > 0){
                self.rotate_scene = true
                self.rotation_dir = 1
                print("right")
            }
            
            self.hand_pos = cur_pos
        }
    }
    
    // coreml functions
    func detect(frame: ARFrame) {
        guard self.currentBuffer == nil, case .normal = frame.camera.trackingState else{
            return
        }
        
        self.currentBuffer = frame.capturedImage
        detectImageObject()
    }
    
    func clear(){
        self.rotate_scene = false
    }
    
    private func detectImageObject(){
        
        // orientation of device
        let orientation = CGImagePropertyOrientation(rawValue: UInt32(UIDevice.current.orientation.rawValue))
        
        let request = VNImageRequestHandler(cvPixelBuffer: currentBuffer!, orientation: orientation!)
        visionQueue.async {
            do{
                defer { self.currentBuffer = nil }
                try request.perform([self.detectionRequest])
            } catch {
                print("Error: Vision request failed with error\"\(error)\"")
            }
        }
    }
    
}
