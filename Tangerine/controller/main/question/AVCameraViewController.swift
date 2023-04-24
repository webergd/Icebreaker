//
//  AVCameraViewController.swift
//  
//
//  Created by Wyatt Weber on 1/28/17.
//  Copyright © 2017 Insightful Inc. All rights reserved.
//
//  This is a custom full screen camera. It looks pretty good but lacks some features like zoom, focus, and brightness control.
//  There is also a disparity between the image that is shown on the camera when the photo is taken and the image that is actually capture (pictured on next view after snapping the photo)

import UIKit
import AVFoundation
import MobileCoreServices // enables us to use kUTTypeImage

public var justFinishedPicking: Bool = false //when it's false, the camera will load upon loading the view. When true, it will show the imageView instead.



@available(iOS 10.0, *)
class AVCameraViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, AVCapturePhotoCaptureDelegate {
    
    //var stillImageOutput: AVCaptureStillImageOutput?
    
    var outputVolumeObserver: NSKeyValueObservation?
    let audioSession = AVAudioSession.sharedInstance()

    var photoWasCapturedWithTangerineAVCamera: Bool = true //default to true to avoid writing an initializer
    

    func startListenToVolButtons() {
        //First, enable member's music to keep playing while we "listen" to the volume buttons
        do {
          let session = audioSession
            try session.setCategory(AVAudioSession.Category.playback, options: [AVAudioSession.CategoryOptions.mixWithOthers/*, AVAudioSession.CategoryOptions.defaultToSpeaker*/])
          try session.setActive(true)
        } catch {}
        
        //Now, start listening to the volume buttons so that the user can use them like a camera button
        do {
            try audioSession.setActive(true)
        } catch {}

        outputVolumeObserver = audioSession.observe(\.outputVolume) { [weak self] (audioSession, changes) in
            /// TODOs
            guard let self = self else{return}
            print("CAPTURE")
            self.takePhoto(self.takePhotoButton)
            
        }
    }
    
    // UI Items
    var cameraTutorialLabel: UILabel!
    var uploadPhotoTutorialLabel: UILabel!
   
    // so that we can access user defaults to know whether to show the tutorial
    var ud = UserDefaults.standard
    
    //belongs to the pre-iOS10 av camera (but I think also to the new one)
    var captureSession: AVCaptureSession! //these 3 might need to be question marks instead of  exclamation points
    var cameraOutput: AVCapturePhotoOutput!
    var previewLayer: AVCaptureVideoPreviewLayer!
        
    
    let imagePicker = UIImagePickerController()
    //public var justFinishedPicking: Bool = false
    var capturedImage: UIImage? = #imageLiteral(resourceName: "tangerineImage2")

    var photoSampleBufferContainer: CMSampleBuffer?
    //let settings = AVCapturePhotoSettings() // controls the camera device's settings, referenced in takePhoto()
    var cameraPosition: cameraPositionType = .standard // sets the default camera position to standard (vice selfie)
    //var device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo) //set default device to standard camera
    //var previewLayerAlreadyLoadedOnce: Bool = false
    
    //var device = AVCaptureDevice.
    
    // var previewPhotoSampleBuffer: CMSampleBuffer?  //an option that we can enable if we start using thumbnails from the camera
    var imageWasPicked: Bool = false
    
    enum flashState: String {
        case flashOn
        case flashAuto
        case flashOff
    }
    // sets the flash enum to off as the first default
    var avCameraFlash: flashState = .flashOff
    var lastFlashSettingForBackCamera: flashState = .flashOff // remembers what the setting was before user switches to selfie camera
    
    enum cameraPositionType: String {
        case standard
        case selfie
    }
    
    @IBOutlet weak var avCameraView: UIView! //this is where the preview layer should show up
    @IBOutlet weak var avImageView: UIImageView! //we use this to display the image after it has been taken
    @IBOutlet weak var takePhotoButton: UIButton!
    @IBOutlet weak var photoLibraryButton: UIButton!
    @IBOutlet weak var flashButton: UIButton!
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var cameraFlipButton: UIButton!
    @IBOutlet weak var cancelPhotoButton: UIButton!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var blackView: UIView!
    
    @IBOutlet weak var avImageViewWidthConstraint: NSLayoutConstraint!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        
        startListenToVolButtons()
        
        
        print("justFinishedPicking is \(justFinishedPicking) (inside AVCameraViewController.ViewDidLoad)")
        //Enabes user to swipe right to return to main menu
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(self.returnToMenu))
        swipeRight.direction = UISwipeGestureRecognizer.Direction.right
        self.view.addGestureRecognizer(swipeRight)
        
        //Switch that determines where we are at in the compare or ask creation process:
        
        switch currentCompare.creationPhase {
        case .noPhotoTaken:
            // While it may seem redundant, this ensures the images are cleared out so we can start fresh
            currentCompare = compareBeingEdited(isAsk: true, imageBeingEdited1: nil, imageBeingEdited2: nil, creationPhase: .noPhotoTaken)
        case .firstPhotoTaken:
            currentCompare.isAsk = false
        default:
            print("Error occurred. currentCompare.creationPhase was something other than .noImageTaken or .firstPhotoTaken")
            print("currentCompare.creationPhase should've been changed before we got here, ...or we shouldn't be here right now")
            print(" ** setting .creationPhase to state 0, .noImageTaken and reloading the VC ** ")
            currentCompare.creationPhase = .noPhotoTaken
            self.viewDidLoad()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(checkPermission), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        configureCameraTutorialLabel()
        configurePhotoUploadTutorialLabel()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
//    // This is another suggested option for setting the frame for the preview layer. Probably unnecessary at this point.
//     override func viewDidLayoutSubviews() {
//     super.viewDidLayoutSubviews()
//     previewLayer.frame = cameraView.bounds
//     }
     
    

    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        print("inside viewWillAppear() in AVCameraViewController")
        print("presenting VC of AVCameraVC is: \(String(describing: self.presentingViewController))")
        
        // Hide the navigation bar on the this view controller
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        previewLayer?.isHidden = true
        blackView.isHidden = false
        
        // when we show the view again after opening the image library, we just want to show the picture selected, not the camera
        if justFinishedPicking == true { // not sure if this should go here or in reload camera
            justFinishedPicking = false
            return
        }
        
        checkPermission()
        
    }
    

     override func viewDidAppear(_ animated: Bool) {
         super.viewDidAppear(animated)
         DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { // `0.7` is the desired number of seconds.
             self.showTutorialAsRequired()
         }
     }

    
    @objc func checkPermission(){
        print("CHECKING PERM")
        let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch cameraAuthorizationStatus {
        case .notDetermined:
            print("Not Determined")
            requestCameraPermission()
        case .authorized:
            print("Authorised")
            presentCamera()
        case .restricted, .denied:
            print("Showing Alert")
            alertCameraAccessNeeded()
        @unknown default:
            requestCameraPermission()
        }
    }
    
    func alertCameraAccessNeeded() {
        let settingsAppURL = URL(string: UIApplication.openSettingsURLString)!

        let alert = UIAlertController(
        title: "Tangerine Requests Access to the Camera",
        message: "Camera access is required to make full use of this app.",
        preferredStyle: UIAlertController.Style.alert
        )

        alert.addAction(UIAlertAction(title: "Ignore", style: .default){_ in
            self.returnToMenu()
        })
        
        alert.addAction(UIAlertAction(title: "Enable in Settings", style: .cancel, handler: { (alertAction) -> Void in
            
            
            UIApplication.shared.open(settingsAppURL, options: [:]){ _ in
               // self.returnToMenu()
            }
            
        }))

        present(alert, animated: true, completion: nil)
    }
    
    
    func showTutorialAsRequired() {
        
        let skipTutorial = UserDefaults.standard.bool(forKey: Constants.UD_SKIP_AVCAM_TUTORIAL_Bool)
        
        if !skipTutorial {
            // manipulate visual elements here
            takePhotoButton.addAttentionRectangle()
            photoLibraryButton.addAttentionRectangle()
            cameraTutorialLabel.fadeInAfter(seconds: 0.0)
            uploadPhotoTutorialLabel.fadeInAfter(seconds: 0.2)
        }
    }
    
    func presentCamera(){
        showCameraIcons()
        reloadCamera()
        
        //MARK: Commented it to see, as viewDidLoad called automatically
        //self.viewDidLoad()
    }
    
    func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video, completionHandler: {accessGranted in
            guard accessGranted == true else { return }
            DispatchQueue.main.async {
                self.presentCamera()
            }
        })
   }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    // This is only in here to unhide the nav bar after this view goes away, we may not actually need it.
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Show the navigation bar on other view controllers
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        
        
    }
    
    func reloadCamera() {

        captureSession = AVCaptureSession()
    
        // we may want to change the AVCaptureSessionPreset____ to a different resolution to save space.
        captureSession.sessionPreset = AVCaptureSession.Preset.photo//AVCaptureSessionPresetPhoto
        cameraOutput = AVCapturePhotoOutput()
        
        // default to back camera
        var device = AVCaptureDevice.default(for: AVMediaType.video)
        print("camera loaded in standard mode (back camera)")
        // unless we have switched our enum to selfie, then use that
        if cameraPosition == .selfie {
            print("camera loaded in selfie mode")
            device = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: AVMediaType.video, position: .front)
        }
        
        if let input = try? AVCaptureDeviceInput(device: device!) {
            if (captureSession.canAddInput(input)) {
                captureSession.addInput(input)
                if (captureSession.canAddOutput(cameraOutput)) {
                    captureSession.addOutput(cameraOutput)
                    
                    previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                    
                    // This causes the preview layer to take up the whole screen:
                    //  (it may be zooming incorrectly and causing the disparity mentioned in the comment header of this file)
                    let previewLayerBounds: CGRect = self.view.layer.bounds
                    previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
                    previewLayer?.bounds = previewLayerBounds
                    previewLayer?.position = CGPoint(x: previewLayerBounds.midX, y: previewLayerBounds.midY)
                    
                    // This inserts the previewLayer underneath the buttons
                    avCameraView.layer.insertSublayer(previewLayer!, below: self.blackView.layer)
                    blackView.isHidden = true
                    
                    captureSession.startRunning()
                    print("capture session started")
                }
            } else {
                print("Issue encountered inside captureSession.canAddInput")
            }
        } else {
            print("Issue encountered when reloading camera.")
        }
    }
    
    /// Snaps a picture
    @IBAction func takePhoto(_ sender: UIButton) {
        print("snap")
        photoWasCapturedWithTangerineAVCamera = true
        
        // AVCapturePhotoOutput code:
        
        let settings = AVCapturePhotoSettings()
        
        imageWasPicked = false
        
        switch avCameraFlash {
        case .flashAuto: settings.flashMode = .auto
        case .flashOff: settings.flashMode = .off
        case .flashOn: settings.flashMode = .on
        }
        
        
        let previewPixelType = settings.__availablePreviewPhotoPixelFormatTypes.first!
        let previewFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
                             kCVPixelBufferWidthKey as String: 160, //no clue what these numbers mean
                             kCVPixelBufferHeightKey as String: 160,
        ]
        settings.previewPhotoFormat = previewFormat
        self.cameraOutput.capturePhoto(with: settings, delegate: self)
        print("self.cameraOutput.capturePhoto(with: CALLED")
        
        hideCameraIcons()
    }
    
    //Maybe a better simpler version of the capture method:
    func photoOutput(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        
        print("inside func photoOutput(_ captureOutput: AVCaptur ....")
        
        if let error = error {
            print(error.localizedDescription)
        }
        
        if let sampleBuffer = photoSampleBuffer,
           let previewBuffer = previewPhotoSampleBuffer,
           let dataImage = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: sampleBuffer, previewPhotoSampleBuffer: previewBuffer) {
            
            let dataProvider = CGDataProvider(data: dataImage as CFData)
            let cgImageRef: CGImage! = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
            let image = UIImage(cgImage: cgImageRef, scale: 1.0, orientation: UIImage.Orientation.right)
            
            // Here we create an instance of EditQuestionVC in order to access EditQuestionVC's sFunc_imageFixOrientation() function. It may be more elegant to move sFunc_imageFixOrientation() to the ImageMethods.swift file.
            let cVC = EditQuestionVC()
            self.capturedImage = cVC.sFunc_imageFixOrientation(img: image)
            print("line 242 self.capturedImage = cVC.sFunc_im")
            
        }
        

        if let capturedImage = capturedImage {
            self.loadAVImageView(imageToLoad: capturedImage)
        }

        
        
        
//        avImageView.image = capturedImage
        
        previewLayer.isHidden = true
        avImageView.isHidden = false
        

        
        
//        // My attempt to make the still frame preview also be zoomed in like the AVPreview layer:
//        let avImageViewLayerBounds: CGRect = self.view.layer.bounds
//        previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
//        previewLayer?.bounds = avImageViewLayerBounds
//        previewLayer?.position = CGPoint(x: avImageViewLayerBounds.midX, y: avImageViewLayerBounds.midY)
        
    }
    
    
    /// Gets rid of all the unnecessary buttons. Designed to be called after a photo is picked or taken.
    func hideCameraIcons() {
        
        // These 2 lines prevent the image from being distorted when displayed
        //  (since the aspect ratio of the screen is not the same aspect ratio as the camera)
//        avImageView.autoresizingMask = UIView.AutoresizingMask.flexibleBottomMargin
        
        
        
        //hide the camera control buttons
        photoLibraryButton.isHidden = true
        takePhotoButton.isHidden = true
        flashButton.isHidden = true
        menuButton.isHidden = true
        cameraFlipButton.isHidden = true
        
        //show the next set of processing buttons
        cancelPhotoButton.isHidden = false
        continueButton.isHidden = false
        blackView.isHidden = false
        
        //hide the tutorial UI elements if applicable
        takePhotoButton.removeAttentionRectangle()
        photoLibraryButton.removeAttentionRectangle()
        cameraTutorialLabel.isHidden = true
        uploadPhotoTutorialLabel.isHidden = true
    }
    
    /// Unhides the camera icons.
    func showCameraIcons() {
        print("Showing Cam icons")
        //hide the camera control buttons
        photoLibraryButton.isHidden = false
        takePhotoButton.isHidden = false
        menuButton.isHidden = false
        cameraFlipButton.isHidden = false
        
        // Don't show the flash if we're in selfie mode
        if cameraPosition == .standard {
            flashButton.isHidden = false
        }
        
        //show the next set of processing buttons after the photo has been taken
        cancelPhotoButton.isHidden = true
        continueButton.isHidden = true
        blackView.isHidden = true
        
        // when we are showing cam icons, it should be when we don't have anything picked: MM
        justFinishedPicking = false
    }
    
    
    @IBAction func selectFromPhotoLibrary(_ sender: Any) {
        print("selectFromPhotoLibary button just tapped")
        photoWasCapturedWithTangerineAVCamera = false
        imageWasPicked = true
        print("imageWasPicked set to true. imageWasPicked: \(imageWasPicked)")
        imagePicker.allowsEditing = false
        imagePicker.mediaTypes = [kUTTypeImage as String] //supposedly this prevents the user from taking videos
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    // MARK: - UIImagePickerControllerDelegate Methods
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // Local variable inserted by Swift 4.2 migrator.
        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)
        if let pickedImage = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as? UIImage {
            
            justFinishedPicking = true
            avImageView.contentMode = .scaleAspectFit
            self.previewLayer?.isHidden = true
            self.avImageView.isHidden = false
            capturedImage = pickedImage
            imageWasPicked = true
            
            // this line ensures that screen is returned to the normal proportions and will show entire picked image (not a cropped version)
            self.loadAVImageView(imageToLoad: pickedImage)
            
//            self.avImageView.image = pickedImage
            
            hideCameraIcons()
        }
        dismiss(animated: true, completion: nil)
    }
    
    /// The goal here is to resize the image view such that the sides of it hang off the screen similar to the way to the AV Preview Layer does before the user taps the snap button
    func loadAVImageView (imageToLoad: UIImage) {
        print("avImageView width before loadImageView() completes \(avImageView.frame.width)")
        print("inside loadAVImageView. \nimageWasPicked = \(imageWasPicked)")
        
        let screenSize: CGRect = UIScreen.main.bounds
        let screenHeight = screenSize.height
        let screenWidth = screenSize.width

        if !imageWasPicked {

            
            //get current width and height of image
            let avImageWidth = imageToLoad.size.width
            let avImageHeight = imageToLoad.size.height
            
            //image's aspect ratio is (width / height)
            
            //determine desired width of the imageView to maintain aspect ratio but make the image the height of the screen (achieving the effect of a "crop" of each side)
            let widthDesired = (screenHeight * avImageWidth) / avImageHeight
            
            print("calculated widthDesired:\(widthDesired)")
            
            //resize the image to adhere to the existing the aspect ratio
    //        avImageView.frame = CGRect(x: 0, y: 0, width: widthDesired, height: screenHeight)
            
            avImageViewWidthConstraint.constant = widthDesired
            

            print("avImageView width before contentMode adjusted \(avImageView.frame.width)")
            
            avImageView.contentMode = UIView.ContentMode.scaleAspectFit
            
            print("avImageView width AFTER contentMode adjusted \(avImageView.frame.width)")
        } else {
            print("image was picked should be true. imageWasPicked: \(imageWasPicked). \nsetting the avImageViewWidthConstraint to screenWidth")
            avImageViewWidthConstraint.constant =  screenWidth
        }
        
        self.avImageView.image = imageToLoad
        
        print("avImageView width after image is loaded \(avImageView.frame.width)")
        
        
        
    }
    /// returns a cropped version of the passed image in the exact dimensions of the iPhone screen
    func cropSides(imageToCrop: UIImage) -> UIImage? {
       
        let screenSize: CGRect = UIScreen.main.bounds
        let screenHeight = screenSize.height
        let screenWidth = screenSize.width
        
        //get current width and height of image
        let avImageWidth = imageToCrop.size.width
        let avImageHeight = imageToCrop.size.height
        
        //image's aspect ratio is (width / height)
        
        // number of times bigger image height is than screen height
        let multiplier =  avImageHeight / screenHeight
        
        //determine desired width of the imageView to maintain aspect ratio but make the image the height of the screen (achieving the effect of a "crop" of each side)
        let imgWidthAtScreenScale = (screenHeight * avImageWidth) / avImageHeight
        
        

        
        // Calculate distance from left side of image to crop off for x origin point. This is half of the "overhang" total
        let overhang = imgWidthAtScreenScale - screenWidth
        
        let totalWidthToCrop = overhang * multiplier
        
        let crop = CGRect(x: totalWidthToCrop/2,y: 0, width: screenWidth * multiplier, height: avImageHeight)
        
        if let cgImage = imageToCrop.cgImage?.cropping(to: crop) {
            let image:UIImage = UIImage(cgImage: cgImage) //convert it from a CGImage to a UIImage
            return image
        }
        return nil
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func toggleFlash(_ sender: Any) {
        
        // so what I'm not sure about is whether it will still turn on the flash even if it's in selfie mode
        for case let (device as AVCaptureDevice) in AVCaptureDevice.devices()  {
            if device.hasFlash && device.isFlashAvailable {
                // this is saying: if it can turn on a flash, switch it to the next configuration
                if device.isFlashModeSupported(.on) {
                    do {
                        try device.lockForConfiguration() // I'm not sure if I need to lock for configuration any more
                        switch avCameraFlash {
                        case .flashOff:
                            turnFlashAuto()
                        case .flashAuto:
                            turnFlashOn()
                        case .flashOn:
                            turnFlashOff()
                        }
                        device.unlockForConfiguration()
                        
                    } catch {
                        print("Error: Could not change flash mode.")
                    }
                }
            }
        }
    }
    
    func turnFlashAuto() {
        avCameraFlash = .flashAuto
        flashButton.setImage(#imageLiteral(resourceName: "auto-flash_white"), for: UIControl.State.normal)
        print("flash mode set to auto")
    }
    func turnFlashOn() {
        avCameraFlash = .flashOn
        //settings.flashMode = .on
        //device.flashMode = .on //deprecated
        flashButton.setImage(#imageLiteral(resourceName: "flash_white"), for: UIControl.State.normal)
        print("flash mode set to on")
    }
    func turnFlashOff() {
        avCameraFlash = .flashOff
        //settings.flashMode = .off
        //device.flashMode = .off //deprecated
        flashButton.setImage(#imageLiteral(resourceName: "no-flash_white"), for: UIControl.State.normal)
        print("flash mode set to off")
    }
    
    @IBAction func menuButtonTapped(_ sender: Any) {
        returnToMenu()
    }
    
    @objc func returnToMenu() {
        print("returnToMenu() called")
        self.dismiss(animated: true, completion: nil)
    }
    
    
    /// just switches the value to the opposite of what it was (front to back or back to front
    @IBAction func cameraFlipButtonTapped(_ sender: Any) {
        
        switch cameraPosition {
        case .standard: // if it's standard SWITCH TO SELFIE (.front)
            cameraPosition = .selfie
            lastFlashSettingForBackCamera = avCameraFlash //stores the user's last setting for the flash
            turnFlashOff() //disables the flash since the selfie cam doesn't have one
            flashButton.isHidden = true
            cameraFlipButton.setImage(UIImage(named: "CameraFlip3_white"), for: .normal)
            
            //device = AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .front)
            print("camera instructed to switch to selfie mode")
        case .selfie: // if it's selfie SWITCH TO STANDARD (.back)
            cameraPosition = .standard
            cameraFlipButton.setImage(UIImage(named: "CameraFlip2_white"), for: .normal)
            
            // Checks which setting the flash was before the user switched over to the selfie camera and returns the flash to that state.
            switch lastFlashSettingForBackCamera {
            case .flashOff:
                turnFlashOff()
            case .flashAuto:
                turnFlashAuto()
            case .flashOn:
                turnFlashOn()
            }
            flashButton.isHidden = false
            print("camera instructed to switch to standard mode")
        }
        
        
        reloadCamera()
        //viewWillAppear(true)
    }
    
    @IBAction func cancelPhotoButtonTapped(_ sender: Any) {
        
        clearCapturedImagePreview()
        //viewWillAppear(true)
    }
    
    // moved the reloadCamera to top, to see if the crash solves
    func clearCapturedImagePreview() {
        reloadCamera()
        previewLayer.isHidden = false
        avImageView.isHidden = true
        showCameraIcons()
        
    }
    
    @IBAction func continueButtonTapped(_ sender: Any) {
        print("continue button tapped called ")
        
        clearCapturedImagePreview()

        if let capturedImage = capturedImage {
            // ensures picked image doesn't have its sides cropped
            if imageWasPicked {
                currentImage = capturedImage
            } else {

                print("capturedImage's width before cropping: \(capturedImage.size.width)")
                if let imageToPassToNextVC = self.cropSides(imageToCrop: capturedImage) {
                    currentImage = imageToPassToNextVC
                    print("after cropping, currentImage.size.width = \(currentImage.size.width)")

                } else {
                    print("cropping failed. passing originally captured image")
                    currentImage = capturedImage
                }
            }

        }
        // Saves image to camera roll if it was captured through the camera (but not if it was uploaded from the photolibary already)
        if photoWasCapturedWithTangerineAVCamera {
            UIImageWriteToSavedPhotosAlbum(currentImage, nil, nil, nil)
        }
            
        //currentImage = capturedImage
        
        // *** Uncomment to check image size:
        // We want to know the size of the capturedImage as a starting referebnce point so that we know how much we have reduced its size
        //let img: UIImage? = UIImage(named: "yolo.png")
        //        let imgData: NSData = currentImage.jpegData(compressionQuality: 1) as! NSData
        //        print("continueButtonTapped")
        //        print("Size of Image: \(imgData.length) bytes ")
        // *** End of image size checking...
        
//        // This shrinks the currentImage size down right here. It may speed up everything.
//        currentImage = currentImage.resizeWithPercent(percentage: 0.3)!
        
        let blankCaption = Caption(text: "", yLocation: 0.0)
        
        let iBE = imageBeingEdited(iBEtitle: "", iBEcaption: blankCaption, iBEimageCleanUncropped: currentImage, iBEimageBlurredUncropped: currentImage, iBEimageBlurredCropped: currentImage, iBEContentOffset: initialContentOffset, iBEZoomScale: initialZoomScale, blursAdded: false)
        
        switch currentCompare.creationPhase {
        case .firstPhotoTaken: //Store image2
            //first photo was already taken so we will store this one as the second image
            currentCompare.imageBeingEdited2 = iBE
            
            ///used to set .secondPhotoTaken but changed this because we want user to be able to edit both photos right away.
            currentCompare.creationPhase = .reEditingSecondPhoto//.secondPhotoTaken //update the creationPhase flag se we know the 2nd image has also been taken
            //whatToCreate = .ask // The next time EditQuestionVC loads, it will be ready to create an ask unless user taps compareButton
            
        case .noPhotoTaken: //Store image1
            //we haven't stored any image yet so we'll store this one to image1
            currentCompare.imageBeingEdited1 = iBE // Stores the imageBeingEdited (iBE) to the first half of the public value known as currentCompare
            
            currentCompare.creationPhase = .firstPhotoTaken //update the creationPhase flag se we know the first image has been taken
            // The next time EditQuestionVC loads, it will be ready to create the second half of the compare
            
        default:
            print("Encountered an unexpected .creationPhase value inside compareButtonTapped")
        }
        
        
        /* ********************     ******************************         *************************
         * Tapping this button also segues to EditQuestionVC (it's an interface builder segue not pictured in the source code)
         * ********************     ******************************         ************************* */
        
    }
    
    deinit {
        print("deinitializing AVCameraVC")
        capturedImage = nil
    }
    
    // MARK: PROGRAMMATIC UI
    func configureCameraTutorialLabel() {
        cameraTutorialLabel = UILabel()
        cameraTutorialLabel.text = "Tap to take a photo"
        cameraTutorialLabel.textColor = .systemBlue
        cameraTutorialLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        cameraTutorialLabel.numberOfLines = 2
        cameraTutorialLabel.isHidden = true
    
        cameraTutorialLabel.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.9)
        
        cameraTutorialLabel.textAlignment = .center
        
        cameraTutorialLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cameraTutorialLabel)
        
        NSLayoutConstraint.activate([
            cameraTutorialLabel.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor, constant: 0),
            cameraTutorialLabel.heightAnchor.constraint(equalToConstant: 40),
            cameraTutorialLabel.bottomAnchor.constraint(equalTo: takePhotoButton.topAnchor, constant: -8),
            cameraTutorialLabel.widthAnchor.constraint(equalToConstant: 110)
        ])
    }
    
    func configurePhotoUploadTutorialLabel() {
        uploadPhotoTutorialLabel = UILabel()
        uploadPhotoTutorialLabel.text = "Tap to upload a photo"
        uploadPhotoTutorialLabel.textColor = .systemBlue
        uploadPhotoTutorialLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        uploadPhotoTutorialLabel.numberOfLines = 3
        uploadPhotoTutorialLabel.isHidden = true
    
        uploadPhotoTutorialLabel.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.9)
        
        uploadPhotoTutorialLabel.textAlignment = .center
        
        uploadPhotoTutorialLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(uploadPhotoTutorialLabel)
        
        NSLayoutConstraint.activate([
            uploadPhotoTutorialLabel.centerYAnchor.constraint(equalTo: photoLibraryButton.centerYAnchor, constant: -10),
            uploadPhotoTutorialLabel.heightAnchor.constraint(equalToConstant: 60),
            uploadPhotoTutorialLabel.trailingAnchor.constraint(equalTo: photoLibraryButton.leadingAnchor, constant: -8),
            uploadPhotoTutorialLabel.widthAnchor.constraint(equalToConstant: 60)
        ])
    }

    
}
















// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
    return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
    return input.rawValue
}
