//
//  SolarSystem.swift
//  ARHOME112
//
//  Created by Ugol Ugol on 13/02/2018.
//  Copyright © 2018 Ugol Ugol. All rights reserved.
//

import Foundation
import SceneKit

class SolarSystem: SCNScene{
    var sun: SkyBody!
    var sunRadius: Float!
    var planets: Dictionary<String, SkyBody>!
    var time: Float! = 0.0
    var G: Float! = 6.67 * powf(10, -11)    // Gravity constant
    var au: Float! = 6.6846e-12             // how much astronimical units in 1 meter
    var scale: Float! = 1.5e11
    
    convenience init(sunPosition posVec: SCNVector3){
        self.init()
        
        // create sun and it's material
        createSun(posVec: posVec)
        
        // create solar planets
        createPlanets(posVec: posVec)
        
        // add sun and it's child nodes to scene
        self.rootNode.addChildNode(self.sun)
    }
    
    // sun creation func
    func createSun(posVec: SCNVector3){
        self.sunRadius = Float(6.9551e8)
        self.sun = SkyBody(position: posVec, withRad: self.sunRadius, onDispRad: 0.15,
                           withDensity: 1409.0,
                           withOrbit: Orbit(majorAxis: 0, eccentricity: 0, sunPosition: posVec, gravity: 0),
                           withSelfRotPeriod: -986420,
                           withName: "Sun", gravity: self.G)
        self.sun.addMaterial(materialName: "Sun_diffuse")
    }
    
    
    // create planets of solar system
    func createPlanets(posVec: SCNVector3){
        
        // set planets default parameters
        // [name, orbitRadius, selfRadius, density, temperature, materialPath]
        let defaultPlanetsParameters = [
            ["name": "Mercury", "selfRadius": Float(2440e3),
             "dRad": Float(0.03), "density": Float(5427.0),
             "majorAxis": Float(57909227000), "eccentricity": Float(0.206),
             "selfRotPeriod": Float(5097600), "materialPath": "mercury_diffuse_2k"],
            ["name": "Venera", "selfRadius": Float(6052e3),
             "dRad": Float(0.05), "density": Float(5240.0),
             "majorAxis": Float(108208930000), "eccentricity": Float(0.0068),
             "selfRotPeriod": Float(20995200), "materialPath": "venera_diffuse_2k"],
            ["name": "Earth", "selfRadius": Float(6371e3),
             "dRad": Float(0.06), "density": Float(5515.0),
             "majorAxis": Float(149598261000), "eccentricity": Float(0.0167),
             "selfRotPeriod":Float(86400), "materialPath": "earth_diffuse_2k"],
            ["name": "Mars", "selfRadius": Float(3390e3),
             "dRad": Float(0.04), "density": Float(3930.0),
             "majorAxis": Float(227943820000), "eccentricity": Float(0.0934),
             "selfRotPeriod":Float(86420),"materialPath": "mars_diffuse_2k"],
            
        ]
        
        // create planets of scene adding it to planets array
        self.planets = [String:SkyBody]()
        for planet in defaultPlanetsParameters{
            
            // get planet parameters
            let planetName = planet["name"] as! String
            let planetRad = planet["selfRadius"] as! Float
            let planetDRad = planet["dRad"] as! Float
            let planetDensity = planet["density"] as! Float
            let selfRotPeriod = planet["selfRotPeriod"] as! Float
            let material = planet["materialPath"] as! String
            let a = planet["majorAxis"] as! Float
            let e = planet["eccentricity"] as! Float
            
            // create planet orbit and position in sky
            // x coordinate is caculating considering scale
            // in local sun coordinates
            let planetOrbit = Orbit(majorAxis: a, eccentricity: e,
                                    sunPosition: posVec, gravity: self.G * self.sun.mass!)
            let planetPosition = SCNVector3((planetOrbit.x()) / self.scale, 0, 0)
            
            // create planet
            // g = G * au * sunMass - grav parameter in astronomic units (g = GM)
            self.planets[planetName] = SkyBody(position: planetPosition, withRad: planetRad,
                                               onDispRad: planetDRad, withDensity: planetDensity,
                                               withOrbit: planetOrbit, withSelfRotPeriod: selfRotPeriod,
                                               withName: planetName, gravity: self.G * self.sun.mass!)
            
            // set plane material
            self.planets[planetName]!.addMaterial(materialName: material)
            
            // add plane to solar system
            self.sun.addChildNode(self.planets[planetName]!)
            
            // add planet orbit to solar system
            self.sun.addChildNode(self.planets[planetName]!.orbit)
        }
    }
    
    
    // sun rotation
    func rotateSun(rotate: Bool) {
        if rotate{
            self.sun.selfAxisRotationStep()
            self.sun.selfAxisRotationStep()
        }
    }
    
    // making one rotation step for each planet
    func makeRotationCicle(){
        for planet in planets{
            
            // rotate around sun and rotate round self axis
            planet.value.rotationStep(position: planet.value.position, scale: self.scale)
            planet.value.selfAxisRotationStep()
        }
    }
        
    // add point of trajectory to scene
    // every planet rotation step add 1 point to scene
    func addTrajectoryPoints(){
        for planet in planets{
            planet.value.addTrajectoryPoint(position: planet.value.position)
        }
    }
    
}
