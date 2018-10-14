//
//  AppDelegate.swift
//  GetPic
//
//  Created by AO Admin on 10/13/18.
//  Copyright © 2018 AO Admin. All rights reserved.
//

import UIKit
import Clarifai_Apple_SDK

extension CGImagePropertyOrientation {
    init(_ uiImageOrientation: UIImage.Orientation) {
        switch uiImageOrientation {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .upMirrored: self = .upMirrored
        case .downMirrored: self = .downMirrored
        case .leftMirrored: self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        }
    }
}

extension CALayer {
    
    func addBorder(corner: UIRectCorner, cornerLength : CGFloat, color: UIColor, thickness: CGFloat) {
        
        
        let border1 = CALayer()
        let border2 = CALayer()
        
        switch corner {
            case .topLeft:
                //TOP
                border1.frame = CGRect(x: 0, y: 0, width: cornerLength, height: thickness)
                //LEFT
                border2.frame = CGRect(x: 0, y: 0, width: thickness, height: cornerLength)
                break
            case .topRight:
                //TOP
                border1.frame = CGRect(x: frame.width-cornerLength, y: 0, width: cornerLength, height: thickness)
                //RIGHT
                border2.frame = CGRect(x: frame.width-thickness, y: 0, width: thickness, height: cornerLength)
                break
            case .bottomLeft:
                //BOTTOM
                border1.frame = CGRect(x: 0, y: frame.height-thickness, width: cornerLength, height: thickness)
                //LEFT
                border2.frame = CGRect(x: 0, y: frame.height-cornerLength, width: thickness, height: cornerLength)
                break
            case .bottomRight:
                //BOTTOM
                border1.frame = CGRect(x: frame.width-cornerLength, y: frame.height-thickness, width: cornerLength, height: thickness)
                //RIGHT
                border2.frame = CGRect(x: frame.width-thickness, y: frame.height-cornerLength, width: thickness, height: cornerLength)
                break
            case .allCorners:
                addBorder(corner: .topLeft, cornerLength: cornerLength, color: color, thickness: thickness)
                addBorder(corner: .topRight, cornerLength: cornerLength, color: color, thickness: thickness)
                addBorder(corner: .bottomLeft, cornerLength: cornerLength, color: color, thickness: thickness)
                addBorder(corner: .bottomRight, cornerLength: cornerLength, color: color, thickness: thickness)
                break
            default:
                break
        }
        
        if corner != .allCorners{
            border1.backgroundColor = color.cgColor;
            border2.backgroundColor = color.cgColor;
            addSublayer(border1)
            addSublayer(border2)
        }
    }
}


extension DispatchQueue {
    class func mainSyncSafe(execute work: () -> Void) {
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.sync(execute: work)
        }
    }
    
    class func mainAsyncSafe(execute work: @escaping () -> Void) {
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.async(execute: work)
        }
    }
    
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    let clarifaiAPIKey = "36c24af7c5e94d6b975e5b2a2c39d96e"

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        Clarifai.sharedInstance().start(apiKey: clarifaiAPIKey)
        
        // Override point for customization after application launch.
        return true
    }
    
    func createSeperatedString(array : [String], seperator : String = ",") -> String{
        
        let description = array.reduce("", { (result, next) -> String in
            if result != ""{
                return (result + seperator + next)
            }
            return next
        })
        return description
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

