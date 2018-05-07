//
//  ObjModel.swift
//  ARHOME112
//
//  Created by Ugol Ugol on 11/02/2018.
//  Copyright © 2018 Ugol Ugol. All rights reserved.
//

import Foundation
import SceneKit

class Model {
    var node: SCNNode!
    init(position x: Float, position y: Float, position z: Float,
         path location: String) {
        
        guard let path = Bundle.main.path(forResource: location, ofType: "obj") else {
            fatalError("Failed to find model file")
        }
        let url = URL(fileURLWithPath: path)
        let asset = MDLAsset(url: url)
        
        self.node = SCNNode(mdlObject: asset.object(at:0))
        self.node.position = SCNVector3(x, y, z)
        
        let material = SCNMaterial()
        material.diffuse.contents = UIImage(named: "Earth_d")
        
        self.node.geometry?.firstMaterial = material
        self.node.scale = SCNVector3(0.3, 0.3, 0.3)
        self.node.eulerAngles = SCNVector3(0, 0, Float.pi)
        self.node.runAction(SCNAction.repeatForever(SCNAction.rotate(by: CGFloat(2*Double.pi), around: SCNVector3(0,1,0), duration: 20)))
    }
}
