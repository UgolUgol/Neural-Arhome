//
//  VirtualPlane.swift
//  ARHOME112
//
//  Created by Ugol Ugol on 09/02/2018.
//  Copyright © 2018 Ugol Ugol. All rights reserved.
//


import ARKit
import SceneKit


class VirtualPlane: SCNNode {
    var anchor: ARPlaneAnchor!
    var planeGeometry: SCNPlane!
   
    convenience required init(anchor: ARPlaneAnchor){
        self.init()
        self.anchor = anchor
        
        // get founded plane paramters
        let width = CGFloat(self.anchor.extent.x)
        let height = CGFloat(self.anchor.extent.z)
        self.planeGeometry = SCNPlane(width: width, height: height)
        self.planeGeometry.materials.first?.diffuse.contents = UIColor.blue.withAlphaComponent(0.3)
        
        let planeNode = SCNNode(geometry: self.planeGeometry)
        let x = CGFloat(self.anchor.center.x)
        let y = CGFloat(self.anchor.center.y)
        let z = CGFloat(self.anchor.center.z)
        
        planeNode.position = SCNVector3(x, y, z)
        planeNode.eulerAngles.x = -.pi/2
        self.addChildNode(planeNode)
    }
    
    func Update(anchor: ARPlaneAnchor) {
        self.anchor = anchor
        self.planeGeometry.width = CGFloat(self.anchor.extent.x)
        self.planeGeometry.height = CGFloat(self.anchor.extent.z)
        
        
        let x = CGFloat(self.anchor.center.x)
        let y = CGFloat(self.anchor.center.y)
        let z = CGFloat(self.anchor.center.z)
        self.position = SCNVector3(x, y, z)
        
    }
}
