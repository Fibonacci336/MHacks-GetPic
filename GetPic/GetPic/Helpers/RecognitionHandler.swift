//
//  RecognitionHandler.swift
//  GetPic
//
//  Created by Ben Carlson on 10/14/18.
//  Copyright © 2018 AO Admin. All rights reserved.
//

import Foundation
import UIKit


class RecognitionHandler : NSObject{

    let confidenceThreshold : Float = 0.8
    
    var completedRequests : ((_ labels : [String]) -> Void)
    
    init(image : UIImage, completionHandler : @escaping ((_ labels : [String]) -> Void)){
        
        completedRequests = completionHandler
        
    }
    
    
}
