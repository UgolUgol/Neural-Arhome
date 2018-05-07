//
//  SkyBody.swift
//  ARHOME112
//
//  Created by Ugol Ugol on 12/02/2018.
//  Copyright © 2018 Ugol Ugol. All rights reserved.
//

import Foundation
import SceneKit

class SkyBody: SCNNode{
    var mass: Float!
    var speed: Float!
    var angle_speed: Float!
    var velocity: Float!
    
    var density: Float!
    var temperature: Float!
    var radius: Float!                                 // real skybody radius, use for phys calculating
    var drad: Float!                                   // skybody radius considering the scale. it uses for displaing
    var T: Float!                                      // self rotation period time
    
    var selfAnglePerTime: Float!                       // angle of rotation per dt
    var selfAxis: SCNVector3 = SCNVector3(0, 1, 0)
    
    
    var orbit: Orbit!
    
    var g: Float!                       // gravity parameter
    var time: Float! = 0.0              // start time in perigelion
    
    var title: String!
    var geom: SCNGeometry!
    
    convenience init(position: SCNVector3, withRad radius: Float,
                     onDispRad drad: Float, withDensity density: Float,
                     withOrbit orbit: Orbit, withSelfRotPeriod T: Float,
                     withName name: String, gravity g: Float){
        
        // set global sky body characters
        self.init()
        self.radius = radius
        self.drad = drad
        self.density = density
        self.mass = 4/3 * Float.pi * powf(self.radius, 3) * self.density
        self.temperature =  0.0
        self.title = name
        self.orbit = orbit
        self.g = g
        self.T = T
        
        // set angle of self rotation and axis around which rotation
        self.selfAnglePerTime = self.orbit.dt / self.T
        //print(self.selfAnglePerTime)
        
        // create geometry of sphere
        self.geom  = SCNSphere(radius: CGFloat(self.drad))
        
        // create planet node and set it position
        self.geometry = self.geom
        self.name = self.title
        
        // set position to skybody in perigelion
        self.position = position
    }
    
    func addMaterial(materialName material: String) {
        self.geom.firstMaterial?.diffuse.contents = UIImage(named: material)
    }
    
    
    // add one trajectory point of planet to scene
    func addTrajectoryPoint(position: SCNVector3){
        
        // check planet finished one full rotation cycle
        if(self.time == 0.0){
            self.orbit.isTrajFinish = true
        }
        
        // if one cycle is not finished
        // add point to scene
        if(!self.orbit.isTrajFinish){
            self.orbit.updateTrajectory(planetPosition: self.position)
        }
    }
    
    
    // make one rotation step on V angle
    func rotationStep(position: SCNVector3, scale: Float!){
    
        // rotation time moment
        self.time = (self.time + self.orbit.dt) <= self.orbit.T ? self.time + self.orbit.dt : 0.0
        
        
        // find the angle E(t) solving kelper eq with Halleys method
        // after it find true anomaly v(E, t)
        var newPosition = SCNVector3()
        self.orbit.M = self.orbit.n * self.time
        self.orbit.E = methodHalleys()
        self.orbit.v = trueAnomaly()
            
        // set new position to move
        newPosition.x = self.orbit.x() / scale
        newPosition.y = position.y
        newPosition.z = self.orbit.z() / scale
        
        // speed calculation
        speedAtPoint(r: self.orbit.r())
        
        // move to new position
        self.position = newPosition
        
    }
    
    
    // rotation around self axis
    func selfAxisRotationStep(){
        
        // get current planet orientation
        let orientation = self.orientation
        var glQuaternion = GLKQuaternionMake(orientation.x, orientation.y, orientation.z, orientation.w)
        
        // create quaternion with rotation angle
        let multiplier = GLKQuaternionMakeWithAngleAndAxis(self.selfAnglePerTime!, self.selfAxis.x, self.selfAxis.y, self.selfAxis.z)
        glQuaternion = GLKQuaternionMultiply(glQuaternion, multiplier)
        
        // set new orientation to body
        self.orientation = SCNQuaternion(glQuaternion.x, glQuaternion.y, glQuaternion.z, glQuaternion.w)
    }
    
    
    func speedAtPoint(r: Float){
        self.speed = sqrt(self.g * (2 / r - 1 / self.orbit.a))
    }
    
    func trueAnomaly() -> Float{
        return 2 * atanf(sqrtf((1 + self.orbit.e)/(1 - self.orbit.e)) * tanf(self.orbit.E/2))
    }
    
    
    // we should solve eq E - e*sin(E) = M
    // here we will define three functions that's using in halleys method
    // F(E), F'(E), F''(E)
    func F(E: Float) -> Float{
        return E - self.orbit.M - self.orbit.e * sinf(E)
    }
    func dF(E: Float) -> Float{
        return 1 - self.orbit.e * cosf(E)
    }
    func ddF(E: Float) -> Float{
        return self.orbit.e * sinf(E)
    }
    
    func methodHalleys() -> Float{
        var En = Float(0.0)
        var E = self.orbit.M!
        let eps = Float(1e-5)
        repeat{
            En = E
            E = En - (2 * F(E: En) * dF(E: En)) /
                (2 * powf(dF(E: En), 2) - F(E: En)*ddF(E: En))
        }
        while(fabs(E - En) > eps)
        return E
    }
    
    
    
}
