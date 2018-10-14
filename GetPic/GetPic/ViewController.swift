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
import Vision
import SwiftOCR

class ViewController: UIViewController, AVCapturePhotoCaptureDelegate {

    @IBOutlet var cameraView: UIView!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    var debugMode = true
    var imagePicker = UIImagePickerController()
    
    let session = URLSession.shared
    
    let app = UIApplication.shared.delegate as! AppDelegate
    
    //var itemDetailVC : ItemDetailViewController?
    var itemDetailWebVC : ItemDetailWebViewController?
    var itemDetailVCView : UIView!
    var isDetailViewShown = false
    
    let slideUpAnimationSpeed = 0.75
    let sideBuffer : CGFloat = 38
    
    var clarLabels = [String]()
    var googleLabels = [String]()
    var logoLabels = [String]()
    var colorLabels = [String]()
    
    let blackList = ["people", "person", "paper", "business", "danger", "vertical", "horizontal", "empty", "image", "text", "transportation", "system", "still"]
    
    var selectionAreaLayer : CALayer!
    
    var debugLabel : UILabel!
    
    
    //Custom Camera View Instance Variables
    var captureSession: AVCaptureSession!
    var stillImageOutput: AVCapturePhotoOutput!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicator.startAnimating()
        activityIndicator.isHidden = true
        
        //Create Zoom Gesture
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinchToZoom))
        pinchGesture.delegate = self
        cameraView.addGestureRecognizer(pinchGesture)
        
        //Create Capture Gesture
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapGestureRecognized))
        tapGestureRecognizer.delegate = self
        cameraView.addGestureRecognizer(tapGestureRecognizer)
        
        //Adds Slide up View
        let width = self.view.bounds.width - CGFloat(2 * sideBuffer)
        let itemDetailRect = CGRect(x: sideBuffer, y: self.view.frame.maxY, width: width, height: 500)
        itemDetailVCView = UIView(frame: itemDetailRect)
        self.view.addSubview(itemDetailVCView)
        
        //Creates Selection Area Layer
        let layerBufferX : CGFloat = 35
        let layerBufferY : CGFloat = 65
        let layerWidth = self.view.frame.width - (2 * layerBufferX)
        let layerHeight = self.view.frame.height - (2 * layerBufferY)
        
        let layerRect = CGRect(x: layerBufferX, y: layerBufferY, width: layerWidth, height: layerHeight)
        
        let borderCALayer = CALayer()
        borderCALayer.frame = layerRect
        
        let cornerLength : CGFloat = 30
        
        borderCALayer.addBorder(corner: .allCorners, cornerLength: cornerLength, color: .white, thickness: 3)
        selectionAreaLayer = borderCALayer
        
        if(debugMode){
            //Draw Debug Label
            let labelRect = CGRect(x: 30, y: 20, width: 300, height: 20)
            let label = UILabel(frame: labelRect)
            label.textAlignment = .center
            label.textColor = .white
            
            debugLabel = label
            cameraView.addSubview(debugLabel)
            cameraView.bringSubviewToFront(debugLabel)
        }
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if children.contains(itemDetailWebVC!){
            itemDetailWebVC!.willMove(toParent: nil)
            // Remove the child
            itemDetailWebVC!.removeFromParent()
            // Remove the child view controller's view from its parent
            itemDetailWebVC!.view.removeFromSuperview()
        }
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
            try backCamera.lockForConfiguration()
            defer { backCamera.unlockForConfiguration() }
            
            backCamera.focusMode = .continuousAutoFocus
            
            
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
    
    func recognizeTextRectangles(image : UIImage){
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
            
            
            
            guard let results = request.results as? [VNTextObservation] else{
                print("Could not cast to VNTextObservation")
             	return
            }
            
            if results.count > 0{
                print("Detected Text")
            }
            
            var textGeneratedLabels = [String]()
            let swiftOCRInstance = SwiftOCR()
            
            for result in results{
                
                var transform = CGAffineTransform.identity
                transform = transform.scaledBy(x: image.size.width, y: -image.size.height)
                transform = transform.translatedBy(x: 0, y: -1)
                var rect = result.boundingBox.applying(transform)
                
                let scaleUp: CGFloat = 0.2
                let biggerRect = rect.insetBy(
                    dx: -rect.size.width * scaleUp,
                    dy: -rect.size.height * scaleUp
                )
                
                let croppedImage = self.cropToBounds(inputImage: image, cropArea: biggerRect)
                
                swiftOCRInstance.recognize(croppedImage) { recognizedString in
                    print(recognizedString)
                    textGeneratedLabels.append(recognizedString)
                }
                
            }
            
            
            
        })
        
        
        request.reportCharacterBoxes = true
        
        do {
            try handler.perform([request])
        } catch {
            print(error as Any)
        }
    
    }
    
    func setupLivePreview() {
        
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        
        videoPreviewLayer.videoGravity = .resizeAspectFill
        videoPreviewLayer.connection?.videoOrientation = .portrait
        self.videoPreviewLayer.frame = self.cameraView.bounds
        cameraView.layer.addSublayer(videoPreviewLayer)
        
        videoPreviewLayer.addSublayer(selectionAreaLayer)
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
            
            DispatchQueue.main.async {
                self.videoPreviewLayer.frame = self.cameraView.bounds
                self.cameraView.bringSubviewToFront(self.debugLabel)
            }
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        guard let imageData = photo.fileDataRepresentation()
            else { return }
        
        guard let image = UIImage(data: imageData) else{
            return
        }
        //captureSession.stopRunning()
        
        let croppedImage = cropToBounds(inputImage: image, cropArea: selectionAreaLayer.frame)
        
        handleRecognitionLibraries(imageToRecognize: croppedImage)
        print(croppedImage.size)
        print(image.size)
        
    }
    
    func cropToBounds(inputImage: UIImage, cropArea : CGRect) -> UIImage {
        
        let cgimage = inputImage.cgImage!
        
        let imageRef: CGImage = cgimage.cropping(to: cropArea)!
        
        // Create a new image based on the imageRef and rotate back to the original orientation
        let image: UIImage = UIImage(cgImage: imageRef, scale: inputImage.scale, orientation: inputImage.imageOrientation)
        
        return image
    }
    
    func handleRecognitionLibraries(imageToRecognize image : UIImage){

        let dataQueue = DispatchQueue.global(qos: .userInteractive)
        
        dataQueue.async {
            
            //Text
            self.recognizeTextRectangles(image: image)
            
            //Google
            let _ = GoogleVisionHelper(image: image) { (outputLabels, outputLogos, outputColors)  in
                print("Google Recognized Labels")
                print(outputLabels)
                self.googleLabels = outputLabels
                
                self.logoLabels = outputLogos
                
                self.colorLabels = outputColors
                
                if self.clarLabels.count != 0{
                    self.checkAndSendSimilarLabels()
                }
            }
            
            //Clarifai
            let _ = ClarifaiHelper(image: image, completionHandler: { (outputLabels) in
                print("Clarifai Recognized Labels")
                print(outputLabels)
                self.clarLabels = outputLabels
                
                if self.googleLabels.count != 0{
                    self.checkAndSendSimilarLabels()
                }
            })
        }
        
    }
    
    func checkAndSendSimilarLabels(){
        
        var similarLabels = [String]()
        
        similarLabelLoop: for labelIndex in 0..<clarLabels.count{
            let label = clarLabels[labelIndex]
            
            for blackListedItem in blackList{
                if label.contains(blackListedItem){
                    continue similarLabelLoop
                }
            }
            
            if(googleLabels.contains(label)){
                similarLabels.insert(label, at: 0)
                continue
            }
            
            similarLabels.append(label)
        }
        print("Similars")
        print(similarLabels)
        
        //Transfer Data to itemDetailVC
        
        var finalKeywords = logoLabels
        for nextKeywordIndex in 0..<(3 - logoLabels.count){
            
            if nextKeywordIndex < colorLabels.count{
             	finalKeywords.append(colorLabels[nextKeywordIndex])
            }
            
            finalKeywords.append(similarLabels[nextKeywordIndex])
        }
        
        
        
        clarLabels = []
        googleLabels = []
        logoLabels = []
        colorLabels = []
        
        DispatchQueue.main.async {
            let keywordsListed = self.app.createSeperatedString(array: finalKeywords)
            self.debugLabel.text = keywordsListed
            self.itemDetailWebVC?.setupWebview(from: finalKeywords)
        }
        
        
    }
    
    
    @IBAction func beginScan() {
        
        activityIndicator.isHidden = false
        
        let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        stillImageOutput.capturePhoto(with: settings, delegate: self)
        
        
        //Show Item Detail with Animation
        itemDetailWebVC = self.storyboard?.instantiateViewController(withIdentifier: "itemDetailWebVC") as? ItemDetailWebViewController
        
        itemDetailWebVC!.view.bounds = itemDetailVCView.bounds
        itemDetailWebVC!.view.frame.origin = CGPoint(x: 0, y: 0)
        
        //Add Rounded Corners
        itemDetailVCView.layer.cornerRadius = 8
        itemDetailVCView.layer.masksToBounds = true
        
        if !children.contains(itemDetailWebVC!){
            addChild(itemDetailWebVC!)
            itemDetailVCView.addSubview(itemDetailWebVC!.view)
            
            itemDetailWebVC!.didMove(toParent: self)
        }
        
        isDetailViewShown = true
        UIView.animate(withDuration: slideUpAnimationSpeed) {
            self.itemDetailVCView.frame.origin.y = (self.view.frame.height - self.itemDetailVCView.frame.height)
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
    
    @objc func pinchToZoom(_ sender: UIPinchGestureRecognizer) {
        
        guard let device = AVCaptureDevice.default(for: AVMediaType.video) else {return}
        
        if sender.state == .changed {
            
            let maxZoomFactor = device.activeFormat.videoMaxZoomFactor
            let pinchVelocityDividerFactor: CGFloat = 12.5
            
            do {
                
                try device.lockForConfiguration()
                defer { device.unlockForConfiguration() }
                
                let desiredZoomFactor = device.videoZoomFactor + atan2(sender.velocity, pinchVelocityDividerFactor)
                device.videoZoomFactor = max(1.0, min(desiredZoomFactor, maxZoomFactor))
                
            } catch {
                print(error)
            }
        }
    }
    
    @objc func tapGestureRecognized(){
        
        if isDetailViewShown{
            isDetailViewShown = false
            itemDetailWebVC?.webView.stopLoading()
            UIView.animate(withDuration: slideUpAnimationSpeed) {
                self.itemDetailVCView.frame.origin.y = self.view.frame.maxY
            }
        }else{
            beginScan()
        }
        
    }
    
    
    

}

extension ViewController : UIGestureRecognizerDelegate{

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }



}

