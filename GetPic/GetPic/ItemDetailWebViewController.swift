//
//  ItemDetailWebViewController.swift
//  GetPic
//
//  Created by Ben Carlson on 10/13/18.
//  Copyright © 2018 AO Admin. All rights reserved.
//

import Foundation
import UIKit
import WebKit

class ItemDetailWebViewController : UIViewController, WKNavigationDelegate{
    
    @IBOutlet var webView: WKWebView!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    let app = UIApplication.shared.delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicator.isHidden = false
        webView.navigationDelegate = self
    }
    
    func setupWebview(from keywords : [String]){
        
        let amazonBaseLink = "https://www.amazon.com/s/ref=nb_sb_noss_2?url=search-alias%3Daps&field-keywords="
        
        let keywordLink = app.createSeperatedString(array: keywords, seperator: "+")
        
        var finalLink = amazonBaseLink + keywordLink
        
        finalLink = finalLink.replacingOccurrences(of: " ", with: "%20")
        
        guard let requestURL = URL(string: finalLink) else{
            print("NOT VALID URL")
            return
        }
        
        let urlRequest = URLRequest(url: requestURL)
        
        webView.load(urlRequest)
        
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicator.isHidden = true
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("WEB VIEW LOAD FAILED")
    }
}
