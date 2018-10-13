//
//  ViewController.swift
//  GetPic
//
//  Created by AO Admin on 10/13/18.
//  Copyright © 2018 AO Admin. All rights reserved.
//

import UIKit
import AVFoundation
import SwiftyJSON

class ViewController: UIViewController,  UINavigationControllerDelegate, UIImagePickerControllerDelegate, AVCapturePhotoCaptureDelegate {

    @IBOutlet var cameraView: UIView!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    var debugMode = false
    var imagePicker = UIImagePickerController()
    
    let session = URLSession.shared
    
    let app = UIApplication.shared.delegate as! AppDelegate
    
    //Custom Camera View Instance Variables
    var captureSession: AVCaptureSession!
    var stillImageOutput: AVCapturePhotoOutput!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicator.startAnimating()
        activityIndicator.isHidden = true
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapGestureRecognized))
        cameraView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .medium
        
        guard let backCamera = AVCaptureDevice.default(for: AVMediaType.video)
            else {
                print("Unable to access back camera!")
                return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: backCamera)
            stillImageOutput = AVCapturePhotoOutput()
            
            if captureSession.canAddInput(input) && captureSession.canAddOutput(stillImageOutput) {
                captureSession.addInput(input)
                captureSession.addOutput(stillImageOutput)
                setupLivePreview()
            }
            
        }
        catch let error  {
            print("Error Unable to initialize back camera:  \(error.localizedDescription)")
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.captureSession.stopRunning()
    }
    
    func setupLivePreview() {
        
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        
        videoPreviewLayer.videoGravity = .resizeAspect
        videoPreviewLayer.connection?.videoOrientation = .portrait
        self.videoPreviewLayer.frame = self.cameraView.bounds
        cameraView.layer.addSublayer(videoPreviewLayer)
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
            
            DispatchQueue.main.async {
                self.videoPreviewLayer.frame = self.cameraView.bounds
            }
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        guard let imageData = photo.fileDataRepresentation()
            else { return }
        
        guard let image = UIImage(data: imageData) else{
            return
        }
//        imageView.image = image
//
//        if !cameraView.subviews.contains(imageView){
//            imageView.frame = cameraView.bounds
//            cameraView.addSubview(imageView)
//        }
        //captureSession.stopRunning()
        let googleHelp = GoogleVisionHelper(image: image) { (labels) in
            print(labels)
            self.activityIndicator.isHidden = true
        }
        
    }
    
    
    @IBAction func pressedScanButton(_ sender: Any) {
        
        activityIndicator.isHidden = false
        
        if debugMode{
            uploadFromCameraRoll()
        }else{
            let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
            stillImageOutput.capturePhoto(with: settings, delegate: self)
        }
        
        
    }
    
    func uploadFromCameraRoll(){
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary){
            
            imagePicker.delegate = self
            imagePicker.sourceType = .savedPhotosAlbum;
            imagePicker.allowsEditing = false
            
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    /*
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            
            imageView.image = pickedImage
            
            if !cameraView.subviews.contains(imageView){
                imageView.frame = cameraView.bounds
                cameraView.insertSubview(imageView, at: 0)
            }
            
            
            //Call Google
            
            let googleHelper = GoogleVisionHelper(image: pickedImage) { (topLabels) in
                print(topLabels)
            }
            
        }
        dismiss(animated: true, completion: nil)
        
    }
    */
    @objc func tapGestureRecognized(){
        
//        if !captureSession.isRunning{
//            captureSession.startRunning()
//        }
        
    }
    
    
    

}

