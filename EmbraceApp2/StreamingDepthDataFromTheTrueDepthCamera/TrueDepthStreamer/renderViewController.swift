//
//  renderViewController.swift
//  TrueDepthStreamer
//
//  Created by Sean Hall on 10/21/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import UIKit

class renderViewController: UIViewController {

    @IBOutlet weak var testText: UILabel!
    
    @IBOutlet weak var metalImage: UIImageView!
    
    var titleText = ""
    
    var pixelBufferHeight = 0
    var pixelBufferWidth = 0
    
    var pixelBufferBytesPerRow = 0
    
    var finalPixelBufferAddress: UnsafeMutableRawPointer?
    
    var finalPixelBuffer: CVPixelBuffer?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        testText.text = titleText
        
//        // Define a function to call when the pixel buffer is freed.
//        let releaseCallback: CVPixelBufferReleaseBytesCallback = { releaseRefCon, baseAddress in
//            guard let baseAddress = baseAddress else { return }
//            free(UnsafeMutableRawPointer(mutating: baseAddress))
//            // Perform additional cleanup as needed.
//        }
//        
//        CVPixelBufferCreateWithBytes(kCFAllocatorDefault, pixelBufferWidth, pixelBufferHeight, kCVPixelFormatType_DepthFloat32, &finalPixelBufferAddress, pixelBufferBytesPerRow, releaseCallback, nil, nil, &finalPixelBuffer)
//        
//        //print(finalPixelBuffer!)
//        CVPixelBufferLockBaseAddress(finalPixelBuffer!, .readOnly)
//        let row = CVPixelBufferGetBaseAddress(finalPixelBuffer!)! + 320 * CVPixelBufferGetBytesPerRow(finalPixelBuffer!)
//        //print(row)
//        
//        let data = UnsafeMutableBufferPointer<Float32>(start: row.assumingMemoryBound(to: Float32.self), count: pixelBufferWidth)
//        
//        //let data = row.assumingMemoryBound(to: UInt32.self)[Int(200)]
//        CVPixelBufferUnlockBaseAddress(finalPixelBuffer!, .readOnly)
//        //print("FROM TRANSFERED PIXEL BUFFER")
//        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
