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

class ViewController: UIViewController{

    @IBOutlet var sceneView: ARSCNView!
    var isAddingPlane: Bool = true
    var isRotateSystem: Bool = true
    var solarSystemVisible = false
    var isListening = false
    var detector: Detector = Detector()
    var recognizer: SpeechRecognizer = SpeechRecognizer()
    
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
        
// action functions
    
    @IBAction func stopRotate(_ sender: Any) {
        self.isRotateSystem = false
    }
    
    @IBAction func runRotate(_ sender: Any) {
        self.isRotateSystem = true
    }
    
    @IBAction func makeSpeechRequest(_ sender: Any) {
        DispatchQueue.main.async {
            if !self.recognizer.audioEngine.isRunning{
                try! self.recognizer.startRecording()
            }
        }
    }
    
    func addObjOnTap(){
        let tap = UITapGestureRecognizer(target: self,
                                         action: #selector(ViewController.createSolarSystem(withGestureRecognizer:)))
        sceneView.addGestureRecognizer(tap)
        
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
            
            // check user change paramters with voice
            // if audio recognition was ended
            if(!self.recognizer.audioEngine.isRunning){
                self.checkVoiceCommand(cur_scene: scene)
            }
            
            
            // rotate sun if we pause scene and
            // if we have found hand moving
            if(!self.isRotateSystem){
                self.detector.detect(frame: self.sceneView.session.currentFrame!)
                scene.rotateSun(rotate: detector.rotate_scene, direction: detector.rotation_dir)
                
                // set rotation status of sun to false
                detector.clear()
            }
            
            // check if we must make one step of planets rotation
            if(self.isRotateSystem){
                scene.makeRotationCicle()
                scene.addTrajectoryPoints()
            }
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
    
    func checkVoiceCommand(cur_scene: SolarSystem){
        // list of gui parameters
        let list = ["Name"]
        
        if list.contains(self.recognizer.word) {
            cur_scene.updateGuiOptions(key: self.recognizer.word)
        }
        
        // clear recognizer
        self.recognizer.clear()
    }

}




