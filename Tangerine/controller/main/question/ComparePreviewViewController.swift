//
//  ComparePreviewViewController.swift
//  
//
//  Created by Wyatt Weber on 2/18/17.
//  Copyright © 2017 Insightful Inc. All rights reserved.
//
//  This is the last View the user sees before finalizing a Compare.
//  Currently we publish the Compare after the user confirms that he or she wants to do that.
//    Once SocialApp is integrated into this, the Send Question to Friends View will follow this one.
//      We should publish the Compare first for max exposure time to reviewers, then load the question friends view.
//      (i.e. not wait until user has selected friend recipients until we send to the cloud)

import UIKit
import Firebase
import RealmSwift


class ComparePreviewViewController: UIViewController, UINavigationControllerDelegate, UIScrollViewDelegate {

    

    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var topScrollView: UIScrollView!
    @IBOutlet weak var topImageView: UIImageView!
  
    @IBOutlet weak var topCaptionTextField: UITextField!
    //    @IBOutlet weak var topCaptionTextField: UITextField!
    @IBOutlet weak var topCaptionTextFieldTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var bottomScrollView: UIScrollView!
    @IBOutlet weak var bottomImageView: UIImageView!
    @IBOutlet weak var bottomCaptionTextField: UITextField!
    @IBOutlet weak var bottomCaptionTextFieldTopConstraint: NSLayoutConstraint!
    
        
    
    var topButtonLocked: Bool = false
    var bottomButtonLocked: Bool = false
    
    // Sample values loaded into captions to avoid having to write an initializer method.
    var topCaption: Caption = Caption(text: "", yLocation: 0.0) // recall that if text is "", computed exists property returns false
    var bottomCaption: Caption = Caption(text: "", yLocation: 0.0)
    
    let backgroundCirclesAlphaValue: CGFloat = 0.75
    
    
    // this is where we'll save the profile image or any other image //profile image? Is this a stack overflow cut and paste error?
    var imageRef_1: StorageReference!
    var imageRef_2: StorageReference!

    weak var st: UIStoryboard?
    // pulled from below
    var userList: [String] = [String]()
 
    
    // should prevent the status bar from displaying at the top of the screen
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        //self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        topScrollView.delegate = self
        bottomScrollView.delegate = self
        
//        self.publishButtonBackgroundView.backgroundColor = .white
//        makeCircle(view: self.publishButtonBackgroundView, alpha: self.backgroundCirclesAlphaValue)
        
        // unwraps the Compare to be displayed (passed from EditQuestionVC)
        if let iE1: UIImage = currentCompare.imageBeingEdited1?.iBEimageBlurredCropped,
            let iE2: UIImage = currentCompare.imageBeingEdited2?.iBEimageBlurredCropped,
            let tCap = currentCompare.imageBeingEdited1?.iBEcaption,
            let bCap = currentCompare.imageBeingEdited2?.iBEcaption {
            topImageView.image = iE1
            bottomImageView.image = iE2
            topCaption = tCap
            bottomCaption = bCap
            
        } else {
            print("Could not unwrap one or both images in ComparePreviewViewController")
        }
              
        // For tapping the images to edit:
        let tapTopImageGesture = UITapGestureRecognizer(target: self, action: #selector(ComparePreviewViewController.userTappedTop(_:) ))
        topImageView.addGestureRecognizer(tapTopImageGesture)
        
        let tapBottomImageGesture = UITapGestureRecognizer(target: self, action: #selector(ComparePreviewViewController.userTappedBottom(_:) ))
        bottomImageView.addGestureRecognizer(tapBottomImageGesture)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // configureCaptions is called here because calling it in viewDidLoad results in wrong topConstraint values being calculated because it's too early.
        // for some reason, calling configureCaptions in viewDidLayoutSubViews() like we do in the ReviewAskVC and ReviewCompareVC messes it up bigtime. Not sure why.
        configureCaptions()
    }
    
    /// Sets up the captions using local values that are initalized in viewDidLoad().
    func configureCaptions() {
        topCaptionTextField.isHidden = !topCaption.exists
        topCaptionTextField.text = topCaption.text
        
        bottomCaptionTextField.isHidden = !bottomCaption.exists
        bottomCaptionTextField.text = bottomCaption.text
       
        // does some math to place each caption in the right spot
        topCaptionTextFieldTopConstraint.constant = calcCaptionTextFieldTopConstraint(imageViewFrameHeight: topImageView.frame.height, captionYLocation: CGFloat(topCaption.yLocation))
        
 
        bottomCaptionTextFieldTopConstraint.constant = calcCaptionTextFieldTopConstraint(imageViewFrameHeight: bottomImageView.frame.height, captionYLocation: CGFloat(bottomCaption.yLocation))
        
        // ensures user cannot tap on the text fields to edit them in this View
        topCaptionTextField.isEnabled = false
        bottomCaptionTextField.isEnabled = false
    }
    
//    override func viewDidAppear(_ animated: Bool) {
//
//        // show help labels
//        let inWaitTime: Double = 3.0
//        let outWaitTime: Double = 8.0
//
////        self.helpTapEditLabelTop.bringSubviewToFront(topView)
////        self.helpTapEditLabelBottom.bringSubviewToFront(bottomView)
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { // `0.4` is the desired number of seconds.
//            self.helpTapEditLabelTop.fadeInAfter(seconds: inWaitTime)
//            self.helpTapEditLabelBottom.fadeInAfter(seconds: inWaitTime)
//            self.helpTapPublishLabelBottom.fadeInAfter(seconds: inWaitTime)
//
//            self.helpTapEditLabelTop.fadeOutAfter(seconds: outWaitTime)
//            self.helpTapEditLabelBottom.fadeOutAfter(seconds: outWaitTime)
//            self.helpTapPublishLabelBottom.fadeOutAfter(seconds: outWaitTime)
//        }
//
//    }
    
//    override func viewDidAppear() {
//        super.viewDidAppear(true)


        
//        let inWaitTime: Double = 0.2
//        let outWaitTime: Double = 4.0
//
//        self.helpTapEditLabelTop.bringSubviewToFront(topView)
//        self.helpTapEditLabelBottom.bringSubviewToFront(bottomView)
//
//        self.helpTapEditLabelTop.fadeInAfter(seconds: inWaitTime) {
//
//        }
//
//        self.helpTapEditLabelBottom.fadeInAfter(seconds: inWaitTime) {
//
//        }
//        self.helpTapEditLabelTop.fadeOutAfter(seconds: outWaitTime)
//        self.helpTapEditLabelBottom.fadeOutAfter(seconds: outWaitTime)
//    }
    
    @IBAction func editTopButtonTapped(_ sender: Any) {
        returnForEditing(editTopImage: true)
    }
    
    @IBAction func editBottomButtonTapped(_ sender: Any) {
        returnForEditing(editTopImage: false)
    }
    
    @objc func userTappedTop(_ pressImageGesture: UITapGestureRecognizer){
        print("user tap top")
        returnForEditing(editTopImage: true)
    }
    
    @objc func userTappedBottom(_ pressImageGesture: UITapGestureRecognizer){
        print("user tap bottom")
        returnForEditing(editTopImage: false)
    }
    /// Segues back to the image editor View so that the user can change the image that they just tapped on.
    func returnForEditing(editTopImage: Bool) {
        print("returnForEditing called from ComparePreviewVC")
        // set the flag so we know which image to display in EditQuestionVC
        if editTopImage == true {
            currentCompare.creationPhase = .reEditingFirstPhoto
        } else {
            currentCompare.creationPhase = .reEditingSecondPhoto
        }
        self.dismiss(animated: true, completion: nil)
    }
 
    /// Allows the user to zoom within the scrollView that the user is manipulating at the time.
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        if scrollView == topScrollView {
            return self.topImageView
        } else {
            return self.bottomImageView
        }
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        topScrollView.setZoomScale(1.0, animated: true)
        bottomScrollView.setZoomScale(1.0, animated: true)
    }

//    @IBAction func topLockButtonTapped(_ sender: Any) {
//        if topButtonLocked == false {
//            // lock the top image
//            topButtonLocked = true
//            topImageLockButton.setImage(#imageLiteral(resourceName: "lock_white"), for: .normal)
//            checkIfBothImagesAreLocked()
//        } else {
//            // unlock the image
//            topButtonLocked = false
//            topImageLockButton.setImage(#imageLiteral(resourceName: "unlock_white"), for: .normal)
//        }
//    }
    
    
    
    
    
    @IBAction func publishButtonTapped(_ sender: Any) {
        if let iBE1 = currentCompare.imageBeingEdited1, let iBE2 = currentCompare.imageBeingEdited2 {
            // SEND THE QUESTION TO DATABASE
          // fetch the username from Auth

          print("Running ML")

          //MARK: ML Runs
            let nudityPercentage1 = NSFWManager.shared.checkNudityIn(image: iBE1.iBEimageBlurredCropped)
            let nudityPercentage2 = NSFWManager.shared.checkNudityIn(image: iBE2.iBEimageBlurredCropped) 

          // SEND THE QUESTION TO DATABASE
          let docID = Firestore.firestore().collection(FirebaseManager.shared.getQuestionsCollection()).document().documentID
          print("Compare: \(docID) Nude1: \(nudityPercentage1) Nude2: \(nudityPercentage2)")

          // instead of getting both, we're comparing the max one
          let nudityPercentage = max(nudityPercentage1, nudityPercentage2)
          // update the ML values
            if nudityPercentage > Constants.MIN_ADMIN_REVIEW_NUDITY && nudityPercentage <= Constants.MAX_ADMIN_REVIEW_NUDITY {
              let report = [reportType.ml.rawValue: 1]
            // send for review
            sendCompareToServer(id: docID, image1: iBE1, image2: iBE2, circulate: false, needsReview: true, report: report)
            //sendMLReport(for: .ml, of: docID)

          } else if nudityPercentage > Constants.MAX_ADMIN_REVIEW_NUDITY {

            // show an alert for false positive
              self.presentFalsePositiveAlert { decision in
                  // The decision true == user wants admin to review, else they'll try again
                  if decision {
                      let report = [reportType.requestedReview.rawValue: 1]
                      self.sendCompareToServer(id: docID, image1: iBE1, image2: iBE2, circulate: false, needsReview: true, report: report)
                      //sendMLReport(for: .ml, of: docID)
                  }
              }

          } else {
            sendCompareToServer(id: docID, image1: iBE1, image2: iBE2, circulate: true, needsReview: false)
          }
            
        }
    }

  func sendCompareToServer(id docID: String, image1 iBE1: imageBeingEdited, image2 iBE2: imageBeingEdited, circulate shouldCirculate: Bool = false, needsReview reviewRequired: Bool = false, report: Dictionary<String, Int> = [:]) {

    let storageRef = Storage.storage().reference();

    print("Compare \(docID)")
    if let user = Auth.auth().currentUser, let name = user.displayName{
      // if nil then it isn't updated on firestore, so displayname it is

      // create a compare here

      // bucket/profiles/username/question_name/imageName_1.jpg
      self.imageRef_1 = storageRef.child(Constants.PROFILES_FOLDER).child(name).child(docID).child("image_1.jpg")
      self.imageRef_2 = storageRef.child(Constants.PROFILES_FOLDER).child(name).child(docID).child("image_2.jpg")

      let imageData_1 = iBE1.iBEimageBlurredCropped.jpegData(compressionQuality: 0.6)
      let imageData_2 = iBE2.iBEimageBlurredCropped.jpegData(compressionQuality: 0.6)


      // put guard for optional
      guard let data_1 = imageData_1, let data_2 = imageData_2 else {
        self.presentDismissAlertOnMainThread(title: "Image Error", message: "Corrupted Image")
        return
      }

      // create 2 upload task and call send Question

      // upload the file to imageref 1
      let uploadTask1 = self.imageRef_1.putData(data_1, metadata: nil){ (metadata,error) in
        // check the meta for error check
        guard metadata != nil else{
          //error
          self.presentDismissAlertOnMainThread(title: "Upload Error", message: "An error occured. Try again!")
          return
        }
      } // end of upload task

      // start the upload
      uploadTask1.resume()

      // upload the file to profileRef
      let uploadTask2 = self.imageRef_2.putData(data_2, metadata: nil){ (metadata,error) in
        // check the meta for error check
        guard metadata != nil else{
          //error
          self.presentDismissAlertOnMainThread(title: "Upload Error", message: "An error occured. Try again!")
          return
        }

      } // end of upload task

      // start the upload
      uploadTask2.resume()

      print("Sending to firestore")
      //Saves the compare to the firestore database
      // create the question
      let question = Question(question_name: docID, title_1: iBE1.iBEtitle, imageURL_1: "gs://\(self.imageRef_1.bucket)/\(self.imageRef_1.fullPath)", captionText_1: iBE1.iBEcaption.text, yLoc_1: iBE1.iBEcaption.yLocation, title_2: iBE2.iBEtitle, imageURL_2: "gs://\(self.imageRef_2.bucket)/\(self.imageRef_2.fullPath)", captionText_2: iBE2.iBEcaption.text, yLoc_2: iBE2.iBEcaption.yLocation, creator: name, recipients: [String](),report: report)

      // update these
      question.is_circulating = shouldCirculate
      question.adminReviewRequired = reviewRequired

      // save to local Compare
      myActiveQuestions.append(ActiveQuestion(question: question))

      // need to increment local and firestore count here
      // locked += 1, toReview += 3
      updateCountOnNewQues()

      FirebaseDatabase.Database.database().reference()
        .child("usernames").observe(.value, with: { [weak self] snapshot in

          if let snapDict = snapshot.value as? [String:AnyObject]{
            for item in snapDict{
              if item.key != myProfile.username{
                  self?.userList.append(item.key)
              }

            }// end for

              #warning("Check if this one is correct")
              if let userList = self?.userList {
                  if myProfile.isSeeder {
                      question.usersNotConsumedBy = userList
                  } else {
                      question.usersNotReviewedBy = userList
                  }
              }


            do{
              try Firestore.firestore().collection(FirebaseManager.shared.getQuestionsCollection()).document(docID).setData(from: question)

                self?.userList.removeAll()
            }catch let error {
              print("Error writing city to Firestore: \(error)")
              self?.presentDismissAlertOnMainThread(title: "Server Error", message: error.localizedDescription)
            }


          } // if let

        })

      // logs the event in firebase analytics (the specific Ask as well as the generalized Question)
      Analytics.logEvent(Constants.CREATE_COMPARE, parameters: nil)
      Analytics.logEvent(Constants.POST_QUESTION, parameters: nil)


      clearOutCurrentCompare()


      // GOTO CQ
      st = UIStoryboard(name: "Main", bundle: nil)
      let vc = st?.instantiateViewController(withIdentifier: "SendToFriendsVC") as! SendToFriendsVC
      vc.modalPresentationStyle = .fullScreen
      vc.newlyCreatedDocID = question.question_name
      self.present(vc, animated: true, completion: nil)

    } // end of if let user

  }
    

    
    
//    @IBAction func bottomLockButtonTapped(_ sender: Any) {
//        if bottomButtonLocked == false {
//            // lock the top image
//            bottomButtonLocked = true
//            bottomImageLockButton.setImage(#imageLiteral(resourceName: "lock_white"), for: .normal)
//            checkIfBothImagesAreLocked()
//        } else {
//            // unlock the image
//            bottomButtonLocked = false
//            bottomImageLockButton.setImage(#imageLiteral(resourceName: "unlock_white"), for: .normal)
//        }
//    }
    
    /// Aka: "createCompare()". When both images are locked, that means the user is satisfied with both and is ready to publish. We call this every time a locked button is tapped to see if they other image is already locked.
//    func checkIfBothImagesAreLocked() {
//        if topButtonLocked == true && bottomButtonLocked == true {
//            // do stuff to create the compare - both images are locked, time to create a compare!!
//
//            // This alert controller is essentially like the "third lock":
//            let alertController = UIAlertController(title: "Both Images Locked", message: "Submit for Review?", preferredStyle: .alert)
//            let actionYes = UIAlertAction(title: "Publish", style: .default) {
//                UIAlertAction in
//
//                if let iBE1 = currentCompare.imageBeingEdited1, let iBE2 = currentCompare.imageBeingEdited2 {
//
//
//
//
////                    localQuestionCollection.append(newCompare)
////                    localMyUser.addLockedQuestion(questionName: newCompare.questionName)
//
//
//                    // the current image needs to be taken care of
//                    // upload the image to firebase here
//
//
//                    // SEND THE QUESTION TO DATABASE
//
//                    let storageRef = Storage.storage().reference();
//                    // fetch the username from Auth
//                    let docID = Firestore.firestore().collection(FirebaseManager.shared.getQuestionsCollection()).document().documentID
//
//                    print("Compare \(docID)")
//                    if let user = Auth.auth().currentUser, let name = user.displayName{
//                        // if nil then it isn't updated on firestore, so displayname it is
//
//                            // create a compare here
//
//
//                            // bucket/profiles/username/question_name/imageName_1.jpg
//                        self.imageRef_1 = storageRef.child(Constants.PROFILES_FOLDER).child(name).child(docID).child("image_1.jpg")
//                        self.imageRef_2 = storageRef.child(Constants.PROFILES_FOLDER).child(name).child(docID).child("image_2.jpg")
//
//
//                            //   "gs://\(self.imageRef_1.bucket)/\(self.imageRef_1.fullPath)"
//
//                        let imageData_1 = iBE1.iBEimageBlurredCropped.jpegData(compressionQuality: 0.6)
//                        let imageData_2 = iBE2.iBEimageBlurredCropped.jpegData(compressionQuality: 0.6)
//
//
//                            // put guard for optional
//                            guard let data_1 = imageData_1, let data_2 = imageData_2 else {
//                                self.presentDismissAlertOnMainThread(title: "Image Error", message: "Corrupted Image")
//                                return
//                            }
//
//                            // create 2 upload task and call send Question
//
//                            // upload the file to imageref 1
//                        let uploadTask1 = self.imageRef_1.putData(data_1, metadata: nil){ (metadata,error) in
//                                // check the meta for error check
//                                guard metadata != nil else{
//                                    //error
//                                    self.presentDismissAlertOnMainThread(title: "Upload Error", message: "An error occured. Try again!")
//                                    return
//                                }
//                            } // end of upload task
//
//                            // start the upload
//                            uploadTask1.resume()
//
//
//                            // upload the file to profileRef
//                        let uploadTask2 = self.imageRef_2.putData(data_2, metadata: nil){ (metadata,error) in
//                                // check the meta for error check
//                                guard metadata != nil else{
//                                    //error
//                                    self.presentDismissAlertOnMainThread(title: "Upload Error", message: "An error occured. Try again!")
//                                    return
//                                }
//
//                        } // end of upload task
//
//                            // start the upload
//                            uploadTask2.resume()
//
//
//                        print("Sending to firestore")
//                        //Saves the compare to the firestore database
//                        // create the question
//                        let question = Question(question_name: docID, title_1: iBE1.iBEtitle, imageURL_1: "gs://\(self.imageRef_1.bucket)/\(self.imageRef_1.fullPath)", captionText_1: iBE1.iBEcaption.text, yLoc_1: iBE1.iBEcaption.yLocation, title_2: iBE2.iBEtitle, imageURL_2: "gs://\(self.imageRef_2.bucket)/\(self.imageRef_2.fullPath)", captionText_2: iBE2.iBEcaption.text, yLoc_2: iBE2.iBEcaption.yLocation, creator: name, recipients: [String]())
//
//
//
//                        // save to local Compare
//                        myActiveQuestions.append(ActiveQuestion(question: question))
//                        saveImageToDiskWith(imageName: "\(docID)_image_1.jpg", image: iBE1.iBEimageBlurredCropped)
//                        saveImageToDiskWith(imageName: "\(docID)_image_2.jpg", image: iBE2.iBEimageBlurredCropped)
//
//
//
//                        // need to increment local and firestore count here
//                        // locked += 1, toReview += 3
//                        updateCountOnNewQues()
//
//                            var userList = [String]()
//                            FirebaseDatabase.Database.database().reference()
//                                .child("usernames").observe(.value, with: { snapshot in
//
//                                    if let snapDict = snapshot.value as? [String:AnyObject]{
//                                        for item in snapDict{
//                                            if item.key != myProfile.username{
//                                                userList.append(item.key)
//                                            }
//
//                                        }// end for
//
//                                        question.usersNotReviewedBy = userList
//
//
//                                        do{
//                                        try Firestore.firestore().collection(FirebaseManager.shared.getQuestionsCollection()).document(docID).setData(from: question)
//
//                                            userList.removeAll()
//                                        }catch let error {
//                                            print("Error writing city to Firestore: \(error)")
//                                            self.presentDismissAlertOnMainThread(title: "Server Error", message: error.localizedDescription)
//                                        }
//                                    } // if let
//
//                                })
//
//
//
//                            clearOutCurrentCompare()
//
//
//                            // GOTO CQ
//                            let storyboard = UIStoryboard(name: "Main", bundle: nil)
//                            let vc = storyboard.instantiateViewController(withIdentifier: "cq_vc") as! CQViewController
//                            vc.modalPresentationStyle = .fullScreen
//                            vc.newlyCreatedDocID = question.question_name
//                            self.present(vc, animated: true, completion: nil)
//
//
//
//                    } // end of if let user
//
//
//                }
//            }
//            // Tapping "Cancel" allows the user the chance to go back to editing the Compare before publishing.
//            let actionNo = UIAlertAction(title: "Cancel", style: .default) {
//                UIAlertAction in
//                self.bottomButtonLocked = false
//                self.bottomImageLockButton.setImage(#imageLiteral(resourceName: "unlock_white"), for: .normal)
//                self.topButtonLocked = false
//                self.topImageLockButton.setImage(#imageLiteral(resourceName: "unlock_white"), for: .normal)
//            }
//
//            alertController.addAction(actionNo)
//            alertController.addAction(actionYes)
//
//
//            // MARK: This alert view should probably just be replaced with an arrow that appears and lights up or something
//            //  Then if the user unlocks one of the locks, the arrow goes away until they lock both again
//            present(alertController, animated: true, completion: nil)
//
//        } else {
//            // do nothing until the user locks both images
//            return
//        }
//    }
    
  
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
