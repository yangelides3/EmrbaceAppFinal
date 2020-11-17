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
    let bothBreastScan = true
    let depthArray: Array<Array<Float>>
    var scaleFactor: Float = 0
    var depthToBackground = 5
    static let numSlicesTaken = 10
    static let nippleDistance: Float = 19
    var filterDistance: Float = 0
    
    init(fullScan: Array<Array<Float>>, leftCenteredScan: Array<Array<Float>>, rightCenteredScan: Array<Array<Float>>) {
        self.depthArray = fullScan
        
        let scanCenterWidth = Int(fullScan[0].count/2)
        
        if (self.bothBreastScan) {
            
            var finalArrayFull = self.resizeArray(arr: fullScan)
            var finalArrayLeft = self.resizeArray(arr: leftCenteredScan)
            var finalArrayRight = self.resizeArray(arr: rightCenteredScan)
            
            finalArrayLeft = self.padSidesOfArray(arr: finalArrayLeft)
            finalArrayRight = self.padSidesOfArray(arr: finalArrayRight)
            
            //finalArrayFull = self.padBottomOfArray(arr: finalArrayFull)
            
            //Split image in half to isolate left and right breast
            let leftBreast = DepthSlice.getScanSection(scan: finalArrayFull, widthStart: scanCenterWidth, heightStart: 0, widthEnd: finalArrayFull[0].count, heightEnd: finalArrayFull.count)
            let rightBreast = DepthSlice.getScanSection(scan: finalArrayFull, widthStart: 0, heightStart: 0, widthEnd: scanCenterWidth, heightEnd: finalArrayFull.count)
            
            //Get nipple depth and position
            print("GETTING LEFT NIPPLE")
            var leftNipple = self.getClosestDistance(leftBreast)
            leftNipple[1] += 320
            print(leftNipple)
            print("")
            print("GETTING RIGHT NIPPLE")
            var rightNipple = self.getClosestDistance(rightBreast)
            print(rightNipple)
            print("")
            
            // Getting position of nipple/ position of center of each breast to use for scaling
//            print("GETTING LEFT CENTER")
            var leftBreastCenter = self.getCenterOfSlice(self.getSlice(leftBreast, leftNipple[0], leftNipple[0] + 2))
            leftBreastCenter[1] += 320
//            print(leftBreastCenter)
//            print("GETTING RIGHT CENTER")
            var rightBreastCenter = self.getCenterOfSlice(self.getSlice(rightBreast, rightNipple[0], rightNipple[0] + 2))
//            print(rightBreastCenter)
            
//            self.scaleFactor = Float(DepthSlice.nippleDistance)/Float(abs((rightNipple[2] - leftNipple[2])))
            
            //Calculate scalefactor to scale pixel distances into real world distances
            let scaleFactor2 = Float(DepthSlice.nippleDistance)/Float(abs((rightNipple[1] - leftNipple[1])))
            
            self.filterDistance = Float(abs((rightBreastCenter[1] - leftBreastCenter[1]))) * Float(0.575)
            
//            print("SCALE FACTOR")
//            print(self.scaleFactor)
            
            print("SCALE FACTOR 2")
            print(scaleFactor2)
            print("")
            
            
//            let leftBreatVolume = self.calculateVolume(leftBreast, self.scaleFactor)
//            print("LEFT BREAST VOLUME S1")
//            print(leftBreatVolume)
            
            //Calculate the volume of each breast
            print("LEFT BREAST VOLUME S2")
            leftBreastCenter[1] -= 320
            print(self.calculateVolume(finalArrayLeft, scaleFactor2))
            print("")
            
//            let rightBreastVolume = self.calculateVolume(rightBreast, self.scaleFactor)
//            print("RIGHT BREAST VOLUME")
//            print(rightBreastVolume)
            print("RIGHT BREAST VOLUME S2")
            print(self.calculateVolume(finalArrayRight, scaleFactor2))
            
        } else {
            print(self.getClosestDistance(depthArray))
            print("Scanning single breast or object for testing")
        }
        
        
    }
    
    // Get volume of singular breast by integrating over depth slices
    public func calculateVolume(_ myBuffer: Array<Array<Float>>, _ scale: Float) -> Float {
        
        var depthSlicesArray = Array<Array<Array<Float>>>()
        
        // get depth range of breast and intervals to slice at
        let closestDist = self.getClosestDistance(myBuffer)[0]
//        print("NIPPLE DISTANCE")
//        print(String(closestDist))
        let position = self.getCenterOfSlice(self.getSlice(myBuffer, closestDist, closestDist + 2))
//        print("SLICE CENTER")
//        print(position)
        let chestWallDist = self.getFurthestDistance(myBuffer, position)
        print("CHEST WALL DISTANCE")
        print(chestWallDist)
        let depthIntervals = DepthSlice.getSliceThickness(closestDist, chestWallDist)
        
        var currDepth = closestDist
        
        //Added .5 = 5mm just in case the rounding for the intervals causes the sum to be slightly off
        while ((currDepth + depthIntervals) < chestWallDist + 0.1) {
                depthSlicesArray.append(self.getSlice(myBuffer, (currDepth + 0.01), (currDepth + depthIntervals)))
                currDepth += depthIntervals
        }
        
        var totalVolume: Float = 0.0
        
        for ind in 0 ..< depthSlicesArray.count {
            totalVolume += (self.getAreaOfSlice(depthSlicesArray[ind], scale, position) * depthIntervals)
        }
        
        return totalVolume
    }
    
//    public static func calculateVolumeJanky(_ radius: Float) -> Float {
//        
//        var currDepth: Float = 0.0
//        let intervals = DepthSlice.getSliceThickness(0, radius)
//        var scaleFactor = Float(1)/Float(DepthSlice.numSlicesTaken)
//        var scale: Float = scaleFactor
//        var volume: Float = 0.0
//        
//        while (currDepth < radius) {
//            var radiusOfSlice = radius * scale
//            var area = Float(Double.pi) * radiusOfSlice * radiusOfSlice
//            volume += area * intervals
//            currDepth += intervals
//            scale += scaleFactor
//        }
//        
//        return volume
//    }
    
    public func getClosestDistance(_ myBuffer: Array<Array<Float>>) -> Array<Float> {
        
        var arr = DepthSlice.makeCopyOfArray(arr: myBuffer)
        
        var x = 0 //starting pixel location
        var y = 0 //starting pixel location
        
        let bufferHeight = arr.count
        let bufferWidth = arr[0].count
        
        let numSamplePoints = 100
        var sumDepth: Float = 0
        var sumx: Float = 0
        var sumy: Float = 0
        
        var xVals = Array<Float>()
        var yVals = Array<Float>()
        
        for _ in 0 ..< numSamplePoints {
            
            var closest = [Float(Int.max), 0, 0] //this needs to be initialized to a max value (like infinity integer or whatever swift has)
            y = 0
            //go through pixel buffer input line by line and check for pixel depth
            while y < bufferHeight {
                x = 0
                while x < bufferWidth {
                    //check if currentPixel is less than closestPixel, if it is then closestPixel = currentPixel
                    if (arr[y][x] < closest[0] && (arr[y][x] > 5)) {
                        closest[0] = myBuffer[y][x]
                        closest[1] = Float(x)
                        closest[2] = Float(y)
                    }
                    x += 1
                }
                y += 1
            }
            arr[Int(closest[2])][Int(closest[1])] = 0
            //print(String(closest[0]) + ", " + String(closest[1]) + ", " + String(closest[2]))
            sumDepth += closest[0]
            xVals.append(closest[1])
            yVals.append(closest[2])
            sumx += closest[1]
            sumy += closest[2]

        }
        
//        print(xVals)
//        print(yVals)
        return [sumDepth/Float(100), sumx/100, sumy/100]
    }
    
    public func getFurthestDistance(_ myBuffer: Array<Array<Float>>, _ centerPoint: Array<Float>) -> Float {
        var arr = DepthSlice.makeCopyOfArray(arr: myBuffer)
        
        for i in 0 ..< arr.count {
            for j in 0 ..< arr[0].count {
                var dist = self.getDistanceBetweenPixelLocations(j, i, Int(centerPoint[1]), Int(centerPoint[0]))
                if (dist > self.filterDistance) {
                    arr[i][j] = 0
                }
            }
        }
        
        var x = 0 //starting pixel location
        var y = 0 //starting pixel location
           
        let bufferHeight = arr.count
        let bufferWidth = arr[0].count
           
        let numSamplePoints = 100
        var sumDepth: Float = 0
        var sumx: Float = 0
        var sumy: Float = 0
           
        var xVals = Array<Float>()
        var yVals = Array<Float>()
           
        for _ in 0 ..< numSamplePoints {
               
            var furthest = [Float(0), 0, 0]
            y = 0
            //go through pixel buffer input line by line and check for pixel depth
            while y < bufferHeight {
                x = 0
                while x < bufferWidth {
                    //check if currentPixel is more than closestPixel, if it is then closestPixel = currentPixel
                    if (arr[y][x] > furthest[0]) {
                        furthest[0] = myBuffer[y][x]
                        furthest[1] = Float(x)
                        furthest[2] = Float(y)
                    }
                    x += 1
                }
                y += 1
            }
            arr[Int(furthest[2])][Int(furthest[1])] = 0
            //print(String(furthest[0]) + ", " + String(furthest[1]) + ", " + String(furthest[2]))
            sumDepth += furthest[0]
            xVals.append(furthest[1])
            yVals.append(furthest[2])
            sumx += furthest[1]
            sumy += furthest[2]

        }
//        print(xVals)
//        print(yVals)
        return sumDepth/Float(100)
    }
    
    
    // Returns the distance from the camera to the chest wall by averaging the values in the middle 2 columns of the image for the entire height of the image
    public func getChestWallDistance() -> Float {
        
        var sumDistances: Float = 0
        var numPoints = 0
        let midline = self.depthArray.count/2
        
        for col in 0 ..< self.depthArray[0].count {
            sumDistances += self.depthArray[midline - 1][col] + self.depthArray[midline][col] + self.depthArray[midline + 1][col]
            numPoints += 3
        }
        
        return Float(sumDistances) / Float(numPoints)
    }
    
    // Returns the thickness of each slice depending on the chest wall distance and the closest pixel to the camera. Used to create a range (min/max depth) of values to be included for each slice.
    public static func getSliceThickness( _ closestDistance: Float, _ chestWallDistance: Float) -> Float {
        
        // Number of slices is currently set to 35, this can be varied (either in the code or by a slider in the app or we can develop an algorithm to determine the optimal number of slices that should be taken.
        let thickness = (chestWallDistance - closestDistance) / Float(DepthSlice.numSlicesTaken)

        return thickness
    }
    
    // Returns an array of 1's and 0's, where a 1 represents a pixel that is within the specified depth range. This array will be used as a mask on the array of depth values to pull out individual slices to render.
    public func getSlice(_ myInitialBuffer: Array<Array<Float>>, _ myDepthMin: Float, _ myDepthMax: Float) -> Array<Array<Float>> {
        
        var x = 0 //starting pixel location
        var y = 0 //starting pixel location
        let bufferHeight = myInitialBuffer.count
        let bufferWidth = myInitialBuffer[0].count
        var curr = Float()
        
        var slicePixelBuffer = Array<Array>(repeating: Array<Float>(repeating: 0, count: myInitialBuffer[0].count), count:myInitialBuffer.count)
        
        while y < bufferHeight {
            x = 0
            while x < bufferWidth {
                
                curr = myInitialBuffer[y][x]
                if ((curr <= myDepthMax) && (curr >= myDepthMin)) {
                    slicePixelBuffer[y][x] = 1
                    
                } else {
                    slicePixelBuffer[y][x] = 0
                }
                
                x+=1
            }
            y += 1
        }
        return slicePixelBuffer
    }
    
    //Gets estimated area of singular slice of breast
    public func getAreaOfSlice(_ slice: Array<Array<Float>>, _ scale: Float, _ centerPoint: Array<Float>) -> Float {
        
        // Get coordinates of the center of the slice
        let position = self.getCenterOfSlice(slice)
        
        // Check if any points were found in the slice. If not area of slice should be calculated as 0
        if (Int(position[2]) != 0) {
            // Set estimate for radius of breast slice to be the distance between the center pixel and the furthest pixel away from it within the depth slice
            let radius = self.getFurthestPixel(slice, Int(centerPoint[1]), Int(centerPoint[0]), position[2]) * scale
//            print("CENTER")
//            print(centerPoint[1], centerPoint[0])
//            print("RADIUS")
//            print(radius)
            
            // Calculate area using radius
            return Float(Double.pi) * radius * radius
        } else {
            return 0
        }
    }
    
    public func getCenterOfSlice(_ slice: Array<Array<Float>>) -> Array<Float> {
        var position = Array<Float>([0, 0, 0])
        
        //Summing row and col positions of all points in depth slice as well as the total number of points in the depth slice
        for row in 0 ..< slice.count {
            for col in 0 ..< slice[0].count {
                if (slice[row][col] == 1.0) {
                    position[0] += Float(row)
                    position[1] += Float(col)
                    position[2] += Float(1)
                }
            }
        }
        
        if (position[2] != 0) {
            // Calculating postion of center of the breast within the slice
            position[0] = position[0]/position[2]
            position[1] = position[1]/position[2]
        }
        
        return position
    }
    
    //Finds pixel in array furthest from given pixel and returns that pixel's distance from the given pixel
    public func getFurthestPixel(_ slice: Array<Array<Float>>, _ x: Int, _ y: Int, _ numPoints2: Float) -> Float {
        
//        var furthestDist: Float = 0
//
//        for row in 0 ..< slice.count {
//            for col in 0 ..< slice[0].count {
//                if (slice[row][col] == 1.0) {
//                    var dist = self.getDistanceBetweenPixelLocations(col, row, x, y)
//                    if (dist > furthestDist) {
//                        furthestDist = dist
//                    }
//                }
//            }
//        }
        
        //start furthest disntance at lowest possible number
        var sumDist: Float = 0
        var numPoints: Float = 0

        // Loop through and calculate distance between given pixel and all other points within the slice to determine which is furthest away
        for row in 0 ..< slice.count {
            for col in 0 ..< slice[0].count {
                if (slice[row][col] == 1.0 ) {
                    var dist = self.getDistanceBetweenPixelLocations(col, row, x, y)
                    if (dist < self.filterDistance) {
                        sumDist += dist
                        numPoints += 1
                    }
                }
            }
        }
        if (numPoints != 0) {
            return Float(sumDist)/Float(numPoints)
            //combining average distance from center and max distance from center to get radius
            //return (averageDist + furthestDist)/2
        } else {
            return 0
        }
    }
    
    public static func getScanSection(scan: Array<Array<Float>>, widthStart: Int, heightStart: Int, widthEnd: Int, heightEnd: Int) -> Array<Array<Float>> {
        var scanSection = Array<Array<Float>>()
        for ind in heightStart ..< heightEnd {
            scanSection.append(Array(scan[ind][widthStart ..< widthEnd]))
        }
        return scanSection
    }
    
    
    //Gets distance between pixel locations within array
    public func getDistanceBetweenPixelLocations(_ x1: Int, _ y1: Int, _ x2: Int, _ y2: Int) -> Float {
        
        // Distance formula
        let diffX = x2 - x1
        let diffY = y2 - y1
        let sumOfDifferencesSqaured = Float((diffX * diffX) + (diffY * diffY))
        return sumOfDifferencesSqaured.squareRoot()
    }
    
    public static func makeCopyOfArray(arr: Array<Array<Float>>) -> Array<Array<Float>> {
        var newArr = Array<Array>(repeating: Array<Float>(repeating: 0, count: arr[0].count), count: arr.count)
        for i in 0 ..< arr.count {
            for j in 0 ..< arr[0].count {
                newArr[i][j] = arr[i][j]
            }
        }
        
        return newArr
    }
    
    public func resizeArray(arr: Array<Array<Float>>) -> Array<Array<Float>> {
        var newArr = Array<Array>(repeating: Array<Float>(repeating: 0, count: arr[0].count), count: arr.count)
        
        for row in 0 ..< arr.count {
            for col in 0 ..< Int(arr[0].count/2) {
                if (col != 0) {
                    newArr[row][col*2] = arr[row][col]
                    newArr[row][(col*2) - 1] = arr[row][col]
                } else {
                    newArr[row][col] = arr[row][col]
                }
            }
        }
        
        return newArr
    }
    
    public func padBottomOfArray(arr: Array<Array<Float>>) -> Array<Array<Float>> {
        
        let cutoffVal = 120
        var newArr = Array<Array>(repeating: Array<Float>(repeating: 0, count: arr[0].count), count: arr.count)
        
        for i in 0 ..< arr.count {
            for j in 0 ..< arr[0].count {
                if (i < cutoffVal) {
                    newArr[i][j] = 0
                } else {
                    newArr[i][j] = arr[i][j]
                }
            }
        }
               
        return newArr
    }
    
    public func padSidesOfArray(arr: Array<Array<Float>>) -> Array<Array<Float>> {
        
        let cutoffVal1 = 200
        let cutoffVal2 = 450
        var newArr = Array<Array>(repeating: Array<Float>(repeating: 0, count: arr[0].count), count: arr.count)
        
        for i in 0 ..< arr.count {
            for j in 0 ..< arr[0].count {
                if (j < cutoffVal1 || j > cutoffVal2) {
                    newArr[i][j] = 0
                } else {
                    newArr[i][j] = arr[i][j]
                }
            }
        }
               
        return newArr
    }
    
    public func showSlice(_ mySlicedBuffer: CVPixelBuffer) -> UIImage {
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
