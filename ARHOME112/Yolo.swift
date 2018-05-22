//
//  Yolo.swift
//  ARHOME112
//
//  Created by Ugol Ugol on 17/04/2018.
//  Copyright © 2018 Ugol Ugol. All rights reserved.
//

import Foundation
import UIKit
import CoreML
import Accelerate

let anchors: [Float] = [1.3221, 1.73145, 3.19275, 4.00944, 5.05587, 8.09892, 9.47112, 4.84053, 11.2364, 10.0071]

class Yolo {
    public static let inputWidth = 416
    public static let inputHeight = 416
    
    public struct Object {
        let xc: Int
        let yc: Int
    }
    
    public struct Prediction {
        let classIndex: Int
        let score: Float
        let rect: CGRect
        let hand: Object
    }
    
    let model = yolo24()
    
    public func computeBBox(features: MLMultiArray) -> [Prediction] {
        assert(features.count == 30 * 13 * 13)
        
        var predictions = [Prediction]()
        
        let blockSize: Float = 32
        let gridHeight = 13
        let gridWidth = 13
        let boxesPerCell = 5
        let numClasses = 1
        
        for cy in 0..<gridHeight {
            for cx in 0..<gridWidth {
                for b in 0..<boxesPerCell {
                    
                    let channel = b*(numClasses + 5)
                    let tx = features[[channel    , cx, cy] as [NSNumber]].floatValue
                    let ty = features[[channel + 1, cx, cy] as [NSNumber]].floatValue
                    let tw = features[[channel + 2, cx, cy] as [NSNumber]].floatValue
                    let th = features[[channel + 3, cx, cy] as [NSNumber]].floatValue
                    let tc = features[[channel + 4, cx, cy] as [NSNumber]].floatValue
                    
                    // x and y - centers of bounding boxes
                    let xc = (Float(cx) + sigmoid(tx))
                    let yc = (Float(cy) + sigmoid(ty))
                    let x = xc * blockSize
                    let y = yc * blockSize
                    let hand = Object(xc: cx, yc: cy)
                    
                    // transforming width and height to original sizes
                    let w = exp(tw) * anchors[2*b] * blockSize
                    let h = exp(th) * anchors[2*b + 1] * blockSize
                    
                    let confidence = sigmoid(tc)
                    
                    var classes = [Float](repeating: 0, count: numClasses)
                    for c in 0..<numClasses {
                        classes[c] = features[[channel + 5 + c, cx, cy] as [NSNumber]].floatValue
                    }
                    classes = softmax(classes)
                    
                    // find the index of the class with the largest score
                    let (detectedClass, bestClassScore) = classes.argmax()
                    
                    let confidenceInClass = bestClassScore * confidence
                    
                    if confidenceInClass > 0.3 {
                        let rect = CGRect(x: CGFloat(x - w/2), y: CGFloat(y - h/2),
                                          width: CGFloat(w), height: CGFloat(h))
                        let prediction = Prediction(classIndex: detectedClass, score: confidenceInClass, rect: rect, hand: hand)
                        
                        predictions.append(prediction)
                    }
                }
            }
        }
        return nonMaxSuppression(boxes: predictions, limit: 10, threshold: 0.5)
    }
    
    
    /**
     Logistic sigmoid.
    */
    public func sigmoid(_ x: Float) -> Float {
        return 1 / (1 + exp(-x))
    }
    
    
    /**
     Softmax
    */
    public func softmax(_ x: [Float]) -> [Float] {
        var x = x
        let len = vDSP_Length(x.count)
        
        // Find the maximum value in the input array.
        var max: Float = 0
        vDSP_maxv(x, 1, &max, len)
        
        // Subtract the maximum from all the elements in the array.
        // Now the highest value in the array is 0.
        max = -max
        vDSP_vsadd(x, 1, &max, &x, 1, len)
        
        // Exponentiate all the elements in the array.
        var count = Int32(x.count)
        vvexpf(&x, x, &count)
        
        // Compute the sum of all exponentiated values.
        var sum: Float = 0
        vDSP_sve(x, 1, &sum, len)
        
        // Divide each element by the sum. This normalizes the array contents
        // so that they all add up to 1.
        vDSP_vsdiv(x, 1, &sum, &x, 1, len)
        
        return x
    }
    
    public func nonMaxSuppression(boxes: [Prediction], limit: Int, threshold: Float) -> [Prediction] {
        
        // argsort from high to lowest
        // Do an argsort on the confidence scores, from high to low.
        let sortedIndices = boxes.indices.sorted { boxes[$0].score > boxes[$1].score }
        
        var selected: [Prediction] = []
        var active = [Bool](repeating: true, count: boxes.count)
        var numActive = active.count
        
        // The algorithm is simple: Start with the box that has the highest score.
        // Remove any remaining boxes that overlap it more than the given threshold
        // amount. If there are any boxes left (i.e. these did not overlap with any
        // previous boxes), then repeat this procedure, until no more boxes remain
        // or the limit has been reached.
        outer: for i in 0..<boxes.count {
            if active[i] {
                let boxA = boxes[sortedIndices[i]]
                selected.append(boxA)
                if selected.count >= limit { break }
                
                for j in i+1..<boxes.count {
                    if active[j] {
                        let boxB = boxes[sortedIndices[j]]
                        if IOU(a: boxA.rect, b: boxB.rect) > threshold {
                            active[j] = false
                            numActive -= 1
                            if numActive <= 0 { break outer }
                        }
                    }
                }
            }
        }
        return selected
    }
    
    public func IOU(a: CGRect, b: CGRect) -> Float {
        let areaA = a.width * a.height
        if areaA <= 0 { return 0 }
        
        let areaB = b.width * b.height
        if areaB <= 0 { return 0 }
        
        let intersectionMinX = max(a.minX, b.minX)
        let intersectionMinY = max(a.minY, b.minY)
        let intersectionMaxX = min(a.maxX, b.maxX)
        let intersectionMaxY = min(a.maxY, b.maxY)
        let intersectionArea = max(intersectionMaxY - intersectionMinY, 0) *
            max(intersectionMaxX - intersectionMinX, 0)
        return Float(intersectionArea / (areaA + areaB - intersectionArea))
    }
}


extension Array where Element: Comparable {
    
    public func argmax() -> (Int, Element){
        
        precondition(self.count > 0)
        
        var maxIndex = 0
        var maxValue = self[0]
        for i in 1..<self.count{
            if self[i] > maxValue {
                maxValue = self[i]
                maxIndex = i
            }
        }
        return (maxIndex, maxValue)
    }
}



