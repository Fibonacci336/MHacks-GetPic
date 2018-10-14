//
//  ClarifaiHelper.swift
//  GetPic
//
//  Created by Ben Carlson on 10/13/18.
//  Copyright © 2018 AO Admin. All rights reserved.
//

import Foundation
import UIKit
import Clarifai_Apple_SDK

class ClarifaiHelper : RecognitionHandler{
    
    var generalLabelOutputs = [String]()
    var colorLabelOutputs = [String]()
    
    override init(image : UIImage, completionHandler : @escaping ((_ labels : [String]) -> Void)){
        
        super.init(image: image, completionHandler: completionHandler)
        
        let newImage = Image(image: image)
        let dataAsset = DataAsset(image: newImage)
        let input = Input(dataAsset: dataAsset)
        
        predictGeneralModel(input: input)
        
    }
    
    private func predictGeneralModel(input : Input){
        
        let generalModel = Clarifai.sharedInstance().generalModel
        
        generalModel.predict([input]) { (outputs, error) in
    
            var outputLabels = [String]()
    
            if let e = error{
                print(e.localizedDescription)
                return
            }
    
            guard let outputs = outputs else{
                return
            }
    
            for output in outputs{
                if let concepts = output.dataAsset.concepts{
                    for concept in concepts{
                        if concept.score >= self.confidenceThreshold{
                            outputLabels.append(concept.name)
                        }
                    }
                }
            }
    
            self.generalLabelOutputs = outputLabels
            self.compileOutputs()
            
        }
    }
    
    private func compileOutputs(){
        
        let totalOutputs = colorLabelOutputs + generalLabelOutputs
        completedRequests(totalOutputs)
        
    }
    
}
