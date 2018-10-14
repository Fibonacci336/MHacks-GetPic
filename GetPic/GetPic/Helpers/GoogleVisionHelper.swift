//
//  GoogleHelper.swift
//  GetPic
//
//  Created by Ben Carlson on 10/13/18.
//  Copyright © 2018 AO Admin. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON


class GoogleVisionHelper{
    
    let session = URLSession.shared
    
    let googleAPIKey = "AIzaSyA_32pBGPo7hA44gaUwWxA5FDWGAj8gvBM"
    var googleURL: URL {
        return URL(string: "https://vision.googleapis.com/v1/images:annotate?key=\(googleAPIKey)")!
    }
    
    var completionHandler : ((_ recognizedLabels : [String], _ recognizedLogos : [String], _ recognizedColors : [String]) -> Void)
    
    let labelMinConfidence : Float = 0
    
    init(image : UIImage, requestCompletedHandler : @escaping ((_ recognizedLabels : [String], _ recognizedLogos : [String], _ recognizedColors : [String]) -> Void)){
        completionHandler = requestCompletedHandler
        
        // Base64 encode the image and create the request
        let binaryImageData = base64EncodeImage(image)
        createGoogleRequest(with: binaryImageData)
    }
    
    
    func createGoogleRequest(with imageBase64: String) {
        // Create our request URL
        
        var request = URLRequest(url: googleURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(Bundle.main.bundleIdentifier ?? "", forHTTPHeaderField: "X-Ios-Bundle-Identifier")
        
        // Build our API request
        let jsonRequest = [
            "requests": [
                "image": [
                    "content": imageBase64
                ],
                "features": [
                    [
                        "type": "LABEL_DETECTION",
                        "maxResults": 10
                    ],
                    [
                        "type": "LOGO_DETECTION"
                    ],
                    [
                    	"type": "IMAGE_PROPERTIES"
                    ]
                ]
            ]
        ]
        let jsonObject = JSON(jsonRequest)
        
        // Serialize the JSON
        guard let data = try? jsonObject.rawData() else {
            return
        }
        
        request.httpBody = data
        
        // Run the request on a background thread
        
        let task: URLSessionDataTask = session.dataTask(with: request) { (data, response, error) in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "")
                return
            }
            
            self.analyzeGoogleResults(data)
        }
        
        task.resume()
    }
    
    
    func analyzeGoogleResults(_ dataToParse: Data) {
        
        // Use SwiftyJSON to parse results
        guard let json = try? JSON(data: dataToParse) else{
            self.completionHandler([String](), [String](), [String]())
            return
        }
        let errorObj: JSON = json["error"]
        
        // Check for errors
        if (errorObj.dictionaryValue != [:]) {
            print("Error code \(errorObj["code"]): \(errorObj["message"])")
        } else {
            // Parse the response
            //print(json)
            let responses: JSON = json["responses"][0]
            
            // Get label annotations
            let labelAnnotations: JSON = responses["labelAnnotations"]
            let logoAnnotations: JSON = responses["logoAnnotations"]
            let dominantColors : JSON = responses["imagePropertiesAnnotation"]["dominantColors"]["colors"]
            
            var topColorsLabels = [String]()
            let maxTopColor = 1
            
            for index in 0..<maxTopColor{
                
                let currentColor = dominantColors[index]
                var currentColorLabel : String!
                let colorBuffer = 20
                
                let currentR = currentColor["color"]["red"].intValue
                let currentG = currentColor["color"]["green"].intValue
                let currentB = currentColor["color"]["blue"].intValue
                
                let currentRRange = currentR-colorBuffer...currentR+colorBuffer
                let currentGRange = currentG-colorBuffer...currentG+colorBuffer
                let currentBRange = currentB-colorBuffer...currentB+colorBuffer
                
                let whiteRange = 225...255
                let blackRange = 0...15
                
                if whiteRange ~= currentR && whiteRange ~= currentG && whiteRange ~= currentB{
                    //White
                    currentColorLabel = "White"
                    continue
                }
                
                if blackRange ~= currentR && blackRange ~= currentG && blackRange ~= currentB{
                    //Black
                    currentColorLabel = "Black"
                    continue
                }
                
                if currentRRange ~= currentR && currentGRange ~= currentR && currentBRange ~= currentR{
                    //All around the same
                    currentColorLabel = "Grey"
                    continue
                }
                
                if currentR > currentG && currentR > currentB{
                    //Red
                    currentColorLabel = "Red"
                }
                
                if currentG > currentR && currentG > currentB{
                    //Green
                    currentColorLabel = "Green"
                }
                
                if currentB > currentG && currentB > currentR{
                    //Blue
                    currentColorLabel = "Blue"
                }
                if !topColorsLabels.contains(currentColorLabel){
                    topColorsLabels.append(currentColorLabel)
                }
                
                
            }
            
            
            
            let numLogos = logoAnnotations.count
            let numLabels: Int = labelAnnotations.count
            
            var labels = [String]()
            var logos = [String]()
            
            for logoIndex in 0..<numLogos{
                
                let confidenceScore = logoAnnotations[logoIndex]["score"].floatValue
                
                //if confidenceScore >= self.labelMinConfidence{
                let logo = logoAnnotations[logoIndex]["description"].stringValue
                logos.append(logo)
                //}
                
            }
            
            
            if numLabels > 0 {
                for index in 0..<numLabels {
                    
                    let confidenceScore = labelAnnotations[index]["score"].floatValue
                    
                    if confidenceScore >= self.labelMinConfidence{
                        let label = labelAnnotations[index]["description"].stringValue
                        labels.append(label)
                    }
                }
            }
            self.completionHandler(labels, logos, [])
        }
        
    }
    
    func base64EncodeImage(_ image: UIImage) -> String {
        guard var imagePNGData = image.pngData() else{
            return ""
        }
        
        // Resize the image if it exceeds the 2MB API limit
        if (imagePNGData.count > 2097152) {
            let oldSize: CGSize = image.size
            let newSize: CGSize = CGSize(width: 800, height: oldSize.height / oldSize.width * 800)
            imagePNGData = resizeImage(newSize, image: image)
        }
        
        return imagePNGData.base64EncodedString(options: .endLineWithCarriageReturn)
    }
    
    func resizeImage(_ imageSize: CGSize, image: UIImage) -> Data {
        UIGraphicsBeginImageContext(imageSize)
        image.draw(in: CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        let resizedImage = newImage!.pngData()
        UIGraphicsEndImageContext()
        return resizedImage!
    }
    
    
}
