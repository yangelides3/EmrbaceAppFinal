//
//  DepthSlice.swift
//  TrueDepthStreamer
//
//  Created by Yanni Angelides on 10/26/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import Foundation

class DepthSlice{
    
    var depthToCamera = 0
    var depthToBackground = 5
    var closestDistance: Int32?
    var cvPixelBuff: CVPixelBufferPool?
    
    func getClosestDistance(_ myBuffer: Array<Array<Float>>) -> Float {
        var x = 0 //starting pixel location
        var y = 0 //starting pixel location
        let bufferHeight = myBuffer.count
        let bufferWidth = myBuffer[0].count
        var closestDistance = Float(0) //this needs to be initialized to a max value (like infinity integer or whatever swift has)
        
        //go through pixel buffer input line by line and check for pixel depth
        
       while y < bufferHeight {
           y += 1
            x = 0;
            while x < bufferWidth {
                //check if currentPixel is less than closestPixel, if it is then closestPixel = currentPixel
            }
            
        }
        return closestDistance
    }
    
    
    // Returns the distance from the camera to the chest wall by averaging the values in the middle 2 columns of the image for the entire height of the image
    func getChestWallDistance( _ myBuffer: Array<Array<Float>>) -> Float {
        
        var chestWallDistance = Float(0)
        var toAverage: Array<Float> = []
        let midline = myBuffer[0].count / 2
        
        var row = 0
        
        while row < myBuffer.count {
            toAverage.append(myBuffer[row][midline])
            toAverage.append(myBuffer[row][midline + 1])
            row += 1
        }
        
        let sumArray = toAverage.reduce(0, +)
        chestWallDistance = Float(sumArray) / Float(toAverage.count)
        
        return chestWallDistance
    }
    
    // Returns the thickness of each slice depending on the chest wall distance and the closest pixel to the camera. Used to create a range (min/max depth) of values to be included for each slice.
    func getSliceThickness( _ closestDistance: Float, _ chestWallDistance: Float) -> Float {
        
        // Number of slices is currently set to 35, this can be varied (either in the code or by a slider in the app or we can develop an algorithm to determine the optimal number of slices that should be taken.
        let thickness = (chestWallDistance - closestDistance) / 35

        return thickness
    }
    
    // Returns an array of 1's and 0's, where a 1 represents a pixel that is within the specified depth range. This array will be used as a mask on the array of depth values to pull out individual slices to render.
    func getSlice(_ myInitialBuffer: Array<Array<Float>>, _ myDepthMin: Float, _ myDepthMax: Float) -> Array<Array<Float>> {
        
        var slicePixelBuffer: Array<Array<Float>>
        var x = 0 //starting pixel location
        var y = 0 //starting pixel location
        let bufferHeight = myInitialBuffer.count
        let bufferWidth = myInitialBuffer[0].count
        var curr = Float()
        
        slicePixelBuffer = Array<Array>(repeating: Array<Float>(repeating: 0, count: myInitialBuffer.count), count:myInitialBuffer[0].count)
        
        while y < bufferHeight {
            y += 1
            x = 0
            while x < bufferWidth {
                
                curr = myInitialBuffer[x][y]
                if ((curr <= myDepthMax) && (curr >= myDepthMin)) {
                    slicePixelBuffer[x][y] = 1
                    
                } else {
                    slicePixelBuffer[x][y] = 0
                }
                
                x+=1
            }
        }
        return slicePixelBuffer
    }
    
    func showSlice(_ mySlicedBuffer: CVPixelBuffer) -> UIImage {
        var sliceImage: UIImage?
        //using our new pixel buffer we can show the pixels we have at that slice level
        let w = CVPixelBufferGetWidth(mySlicedBuffer)
        let h = CVPixelBufferGetHeight(mySlicedBuffer)
        let buffer = CVPixelBufferGetBaseAddress(mySlicedBuffer)
        let bounds = CGRect(x: 0, y: 0, width: w, height: h)
        let myRender = UIGraphicsRenderer.init(bounds: bounds)
        
        return sliceImage!
    }
}
