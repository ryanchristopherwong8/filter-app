//
//  ViewController.swift
//  MyCameraApp
//
//  Created by Ryan Wong on 2016-09-07.
//  Copyright © 2016 RyanWong. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var captureSession : AVCaptureSession?
    var stillImageOutput : AVCaptureStillImageOutput?
    var previewLayer : AVCaptureVideoPreviewLayer?
    var backCamera : AVCaptureDevice?
    var videoOutput : AVCaptureVideoDataOutput?
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var capturedImageView: UIImageView!
    @IBOutlet weak var takePhotoButton: UIButton!
    @IBOutlet weak var test: UIImageView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.setupCamera()
        // Bring button to front of view
        previewView.bringSubviewToFront(takePhotoButton)
        self.test.layer.zPosition = 1
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool){
        super.viewDidAppear(animated)
        // set the bounds of preview layer to containing view, which is camera View
        previewLayer?.frame = previewView.frame;
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func setupCamera(){
        // creates the capture session object which combines the input and output and data stream for a particular purpose in this example, capture still image from camera and output as still image
        captureSession = AVCaptureSession()
        // Set the capture quality
        captureSession?.sessionPreset = AVCaptureSessionPreset1920x1080
        // select the device to use, since rear camera is default device for photo and video
        self.backCamera = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        // prepare to accept input
        
        // create the input/device (the camera)
        var input = AVCaptureDeviceInput()
        do {
            input = try AVCaptureDeviceInput(device: backCamera)
        } catch {
            //error
        }
        
        if (captureSession?.canAddInput(input) != nil){
            // associate device with capture session
            captureSession?.addInput(input)
            
            // setup output
            stillImageOutput = AVCaptureStillImageOutput()
            // specify data format output
            stillImageOutput?.outputSettings = [AVVideoCodecKey : AVVideoCodecJPEG]
            if ((captureSession?.canAddOutput(stillImageOutput)) != nil){
                // add output to capture session
                captureSession?.addOutput(stillImageOutput)
            }
                
            // connects preview layer object with capture session to get live video feed
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            
            /*
            previewLayer?.frame = self.view.bounds;
            previewLayer?.videoGravity = AVLayerVideoGravityResizeAspect
            previewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.Portrait
            // adds previewLayer to cameraView
            previewView.layer.addSublayer(previewLayer!)
            */
            
            // add video output
            videoOutput = AVCaptureVideoDataOutput()
            videoOutput!.setSampleBufferDelegate(self, queue: dispatch_queue_create("sample buffer delegate", DISPATCH_QUEUE_SERIAL))
            
            if((captureSession?.canAddOutput(self.videoOutput)) != nil){
                captureSession?.addOutput(videoOutput)
            }

            videoOutput?.connectionWithMediaType(AVMediaTypeVideo).videoOrientation = AVCaptureVideoOrientation.Portrait
            
            
            captureSession?.startRunning()
            
        }
    }
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!){
        
        // convert to core image
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        let cameraImage = CIImage(CVPixelBuffer: pixelBuffer!)
        let comicEffect = CIFilter(name: "CIComicEffect")
        
        comicEffect!.setValue(cameraImage, forKey: kCIInputImageKey)
        
        let filteredImage = UIImage(CIImage: comicEffect!.valueForKey(kCIOutputImageKey) as! CIImage!)
        
        dispatch_async(dispatch_get_main_queue())
        {
            self.test.image = filteredImage
        }
        
        
    }
 
   
    @IBAction func takePhoto(sender: AnyObject) {
        
        if let videoConnection = self.stillImageOutput?.connectionWithMediaType(AVMediaTypeVideo){
            videoConnection.videoOrientation = AVCaptureVideoOrientation.Portrait
            self.stillImageOutput?.captureStillImageAsynchronouslyFromConnection(videoConnection, completionHandler: {
                (sampleBuffer, error) in
                
                if sampleBuffer != nil {
                    var imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
                    var dataProvider  = CGDataProviderCreateWithCFData(imageData)
                    var cgImageRef = CGImageCreateWithJPEGDataProvider(dataProvider, nil, true, .RenderingIntentDefault)
                    var image = UIImage(CGImage: cgImageRef!, scale: 1.0, orientation: UIImageOrientation.Right)
                    self.capturedImageView.image = image
                    self.capturedImageState()
                }
            })
        }
    }
    
    // Add abitility to focus to preview layer
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if(previewView.hidden == false){
            let screenSize = previewView.bounds.size
            if let touchPoint = touches.first {
                let x = touchPoint.locationInView(previewView).y / screenSize.height
                let y = 1.0 - touchPoint.locationInView(previewView).x / screenSize.width
                let focusPoint = CGPoint(x: x, y: y)
            
                if let device = self.backCamera {
                    do {
                        try device.lockForConfiguration()
                    
                        device.focusPointOfInterest = focusPoint
                        //device.focusMode = .ContinuousAutoFocus
                        device.focusMode = .AutoFocus
                        //device.focusMode = .Locked
                        device.exposurePointOfInterest = focusPoint
                        device.exposureMode = AVCaptureExposureMode.ContinuousAutoExposure
                        device.unlockForConfiguration()
                    }
                    catch {
                        // just ignore
                    }
                }
            }
        }
    }
    
    
    @IBAction func backButtonPressed(sender: AnyObject) {
        self.previewViewState()
    }
    
    // app is in captured image state where back button capture image view is present 
    func capturedImageState(){
        self.capturedImageView.hidden = false
        self.backButton.hidden = false
        self.takePhotoButton.hidden = true
    }
    
    func previewViewState(){
        self.capturedImageView.hidden = true
        self.backButton.hidden = true
        self.takePhotoButton.hidden = false
    }
    
}

