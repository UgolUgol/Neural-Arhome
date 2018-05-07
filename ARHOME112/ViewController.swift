//
//  ViewController.swift
//  ARHOME112
//
//  Created by Ugol Ugol on 08/02/2018.
//  Copyright © 2018 Ugol Ugol. All rights reserved.
//

import UIKit
import ARKit
import SceneKit
import SceneKit.ModelIO

import CoreML
import Vision
import Accelerate

class ViewController: UIViewController {

    @IBOutlet var sceneView: ARSCNView!
    var isAddingPlane: Bool = true
    var solarSystemVisible = false
    var hand_pos: Float = 0
    var dhand: Float = 0.2
    var rotate_scene: Bool = false
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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addObjOnTap()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUpSceneView()
        
    }
    
    func setUpSceneView(){
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = .horizontal
        sceneView.session.run(config)
        
        sceneView.delegate = self
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
    }
    
    @objc func createSolarSystem(withGestureRecognizer recognizer: UIGestureRecognizer){
        
        // check if in tap's coordinate plane is situated
        let tapLocation = recognizer.location(in: sceneView)
        let hitTestResults = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)
        
        guard let planeResult = hitTestResults.first else { return }
        
        // get plane position
        let position = planeResult.worldTransform.columns.3
        let x = CGFloat(position.x)
        let y = CGFloat(position.y + 0.5)
        let z = CGFloat(position.z)
        let posVec = SCNVector3(x, y, z)
        
        // create solar system scene
        let solarSystem = SolarSystem(sunPosition: posVec)
        
        // set new scene
        sceneView.scene = solarSystem
        self.isAddingPlane = false
        self.solarSystemVisible = true
    }
    
    
    func addObjOnTap(){
        let tap = UITapGestureRecognizer(target: self,
                                         action: #selector(ViewController.createSolarSystem(withGestureRecognizer:)))
        sceneView.addGestureRecognizer(tap)
        
    }
    
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
            let hand_pos = predictions[0].hand
            let new_hand_pos = hand_pos.xc
            let dh = fabs(new_hand_pos - self.hand_pos)
            print(dh)
            if(self.hand_pos == 0 || dh < dhand){
                self.rotate_scene = false
            }
            else {
                self.rotate_scene = true
            }
            
            self.hand_pos = new_hand_pos
        }
    }
    
}

extension ViewController: ARSCNViewDelegate{
    // first plane detection
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if self.isAddingPlane {
            addPlane(didAdd: node, for: anchor)
        }
    }
    
    
    // updation of plane that was already detected
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if self.isAddingPlane {
            updatePlane(didUpdate: node, for: anchor)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
        if(self.solarSystemVisible){
            let scene = self.sceneView.scene as! SolarSystem
            detector(frame: self.sceneView.session.currentFrame!)
            
            scene.rotateSun(rotate: self.rotate_scene)
            scene.makeRotationCicle()
            scene.addTrajectoryPoints()
            self.rotate_scene = false
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
        
    }
    
    // adding plane function
    func addPlane(didAdd node: SCNNode, for anchor: ARAnchor) {
        // check is it plane
        guard let planeAnchor = anchor as? ARPlaneAnchor else {return}
        
        // create virtual plane
        let plane = VirtualPlane(anchor:planeAnchor)
        
        // add new node to display
        node.addChildNode(plane)
    }
    
    
    // update plane function
    func updatePlane(didUpdate node: SCNNode, for anchor: ARAnchor){
        
        // check is it plane and find it node
        guard let planeAnchor = anchor as? ARPlaneAnchor,
            let plane = node.childNodes.first as? VirtualPlane
            else {return }
        
        // update plane
        plane.Update(anchor: planeAnchor)
    }
    
    
    // coreml functions
    
    func detector(frame: ARFrame) {
        guard self.currentBuffer == nil, case .normal = frame.camera.trackingState else{
            return
        }
        
        self.currentBuffer = frame.capturedImage
        detectImageObject()
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




