//
//  ItemDetailViewController.swift
//  GetPic
//
//  Created by Ben Carlson on 10/13/18.
//  Copyright © 2018 AO Admin. All rights reserved.
//

import Foundation
import UIKit

class ItemDetailViewController : UIViewController{
    
    @IBOutlet var itemImageView: UIImageView!
    @IBOutlet var itemTitle: UILabel!
    @IBOutlet var itemDescription: UITextView!
    
    var currentItem : AmazonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard currentItem != nil else{
            return
        }
        
        itemTitle.text = currentItem.title
        itemDescription.text = currentItem.description
        
    }
    
    @IBAction func openItemInAmazon(_ sender: Any) {
        
    }
    
    @IBAction func showSimilarItems(_ sender: Any) {
        
    }
    
}
