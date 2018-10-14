//
//  TextRecognitionHandler.swift
//  GetPic
//
//  Created by Ben Carlson on 10/14/18.
//  Copyright © 2018 AO Admin. All rights reserved.
//

import Foundation
import Vision
import UIKit

class TextRecognitionHandler : RecognitionHandler{
    
    override init(image: UIImage, completionHandler: @escaping ((_ labels: [String]) -> Void)) {
        super.init(image: image, completionHandler: completionHandler)
        
        guard let cgImage = image.cgImage else{
            print("Could not create CGImage")
            return
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [VNImageOption: Any]())
        
        let request = VNDetectTextRectanglesRequest(completionHandler: { request, error in
            
            if let e = error{
                print(e.localizedDescription)
                return
            }
            
            self.detectTextRectangles(request: request)
        })
        
        request.reportCharacterBoxes = true
        
        do {
            try handler.perform([request])
        } catch {
            print(error as Any)
        }
        
    }
    
    private func detectTextRectangles(request : VNRequest){
        
        
//        let layer = CALayer()
//        view.layer.addSublayer(layer)
//        layer.borderWidth = 2
//        layer.borderColor = UIColor.green.cgColor
//        
//        let rect = cameraLayer.layerRectConverted(fromMetadataOutputRect: request.boundingBox)
//        layer.frame = rect
        
        
    }
    
    
}
