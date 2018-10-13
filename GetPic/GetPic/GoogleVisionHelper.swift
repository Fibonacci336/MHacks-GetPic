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
    
    let app = UIApplication.shared.delegate as! AppDelegate
    
    let session = URLSession.shared
    
    var completionHandler : ((_ recognizedLabels : [String]) -> Void)
    
    let labelMinConfidence : Float = 0
    
    init(image : UIImage, requestCompletedHandler : @escaping ((_ recognizedLabels : [String]) -> Void)){
        completionHandler = requestCompletedHandler
        
        // Base64 encode the image and create the request
        let binaryImageData = app.base64EncodeImage(image)
        createGoogleRequest(with: binaryImageData)
    }
    
    
    func createGoogleRequest(with imageBase64: String) {
        // Create our request URL
        
        var request = URLRequest(url: app.googleURL)
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
        
        // Update UI on the main thread
        DispatchQueue.main.async(execute: {
            
            
            // Use SwiftyJSON to parse results
            guard let json = try? JSON(data: dataToParse) else{
                self.completionHandler([String]())
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
                
                let numLabels: Int = labelAnnotations.count
                var labels = [String]()
                if numLabels > 0 {
                    for index in 0..<numLabels {
                        
                        let confidenceScore = labelAnnotations[index]["score"].floatValue
                        
                        if confidenceScore >= self.labelMinConfidence{
                            let label = labelAnnotations[index]["description"].stringValue
                            labels.append(label)
                        }
                    }
                }
                self.completionHandler(labels)
            }
        })
        
    }
    
}
