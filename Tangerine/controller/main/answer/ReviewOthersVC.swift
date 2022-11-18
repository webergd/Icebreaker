//
//  BlueVC.swift
//  SocialApp
//
//  Created by Mahmudul Hasan on 2021-04-25.
//

import UIKit
import FirebaseFirestore

class ReviewOthersVC: UIViewController{
    
    
    /************************************************************ Organization of Code ************************************************/
    /*
     - Outlets
     - Storyboard Actions
     - Custom methods
     - Delegates
     - View Controller methods
     */
    /******************************************************************************************************************************/
    
    
    //flag that tells if we are fetching data
    var loadingFromFirestore = false
    // the loading
    var indicator: UIActivityIndicatorView!
    
    // to determine if show after fetch or not
    // cause when we are showing question, there is no need to show immediately,
    // just fetch new and make them ready
    var shouldPushController = true
    var activeVCType : QType!
    @IBOutlet weak var containerView: UIView!
    var listener: ListenerRegistration!
    
    
    // ASK and COMPARE VC
    
    private lazy var askController: ReviewAskViewController =  {
        // Load Storyboard
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        
        // Instantiate View Controller
        let controller = storyboard.instantiateViewController(withIdentifier: "reviewAskViewController") as! ReviewAskViewController
        //controller.centerPoint = view.center
        
        return controller
    }()
    
    private lazy var compareController: ReviewCompareViewController =  {
        // Load Storyboard
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        
        // Instantiate View Controller
        let controller = storyboard.instantiateViewController(withIdentifier: "reviewCompareViewController") as! ReviewCompareViewController
        
        return controller
    }()
    
    /******************************************************************************************************************************/
    @IBAction func backPressed(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    
    
    /******************************************************************************************************************************/
    
    
    
    
    
    // show ASK
    
    func showAsk(_ ques: Question){
        // remove old vc if any
        removeChildVC(viewController: askController)
        addChildVC(viewController: askController)
        
        askController.question = ques
        askController.blueVC = self
//        askController.configureView()
    }
    // show Compare
    
    func showCompare(_ ques: Question){
        
        // remove old vc if any
        removeChildVC(viewController: compareController)
        
        addChildVC(viewController: compareController)
        
        compareController.question = ques
        compareController.blueVC = self
//        compareController.configureView()
        
        
    }
    
    // to add child to vc
    func addChildVC(viewController: UIViewController){
        addChild(viewController)
        // Add the child's View as a subview
        containerView.addSubview(viewController.view)
        
        
        viewController.view.frame = containerView.frame
        //viewController.view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        // tell the childviewcontroller it's contained in it's parent
        viewController.didMove(toParent: self)
        
        
        setCons(controller: viewController)
    }
    
    // to remove from parent
    func removeChildVC(viewController: UIViewController){
        
        // first remove the old one
        if !shouldPushController{
            
            print("removing old vc")
            
            //means we already have one
            // Notify Child View Controller
            viewController.willMove(toParent: nil)
            // Remove Child View From Superview
            viewController.view.removeFromSuperview()
            // Notify Child View Controller
            viewController.removeFromParent()
            
        }
    }
    
    /// Displays key info about the Question on the screen being reviewed
    func printQ2RoutputFeed(startingQues: PrioritizedQuestion) {
        /// Output statements for checking Q2R   - - - - - - - - - - -
        /// The point of these print statements is so that we can easily copy and paste the output for each question that is displayed to the local user while
        ///     he/she is reviewing Questions from others.
        ///     We want to see if the localUser is getting the best possible questions (i.e. ones that should be reviewed by him or her first)
        ///  In the current format, the output can be cut and pasted into the "Q2R Tests" spreadsheet (saved in the Tangerine Dev Shared google folder)
        ///     so that we can compare all the questions that the user is being sent to ensure that the "best" aka highest priority ones are sent first and in descending order.
        let timeRemainingToPrint = calcTimeRemaining(startingQues.question.created)
        
        print("- - - - - - - - - - - BEGIN Q2R Test output - - - - - - - - - - - - - -")
        print("- - - - - You      |      Creator - - - - -")
        //reviewer name:created by
        print("|      \(myProfile.username)      |      \(startingQues.question.creator)      |")
        
        //question name:
        print("|      QuestionID => \(startingQues.question.question_name)")
        
        print("|      QuestionType => \(startingQues.question.type.description)")
        
        print("|      Caption => \(startingQues.question.captionText_1)")
        
        //> 2 reviews true or false:
        print("|      Reviews>2 ? => \(startingQues.question.reviews > 2)")
        
        //reviewer orientation | desired orientation(s)
        
        var orientationStringToPrint = ""
        if startingQues.question.targetDemo!.straight_woman_pref {orientationStringToPrint = orientationStringToPrint + "SW"}
        if startingQues.question.targetDemo!.gay_man_pref {orientationStringToPrint.append(" GM")}
        if startingQues.question.targetDemo!.straight_man_pref {orientationStringToPrint.append(" SM")}
        if startingQues.question.targetDemo!.gay_woman_pref {orientationStringToPrint.append(" Les")}
        if startingQues.question.targetDemo!.other_pref {orientationStringToPrint.append(" Oth")}
        
        print("|      \(myProfile.orientation)      |      \(orientationStringToPrint.isEmpty ? "Empty" : orientationStringToPrint)")
        
        // age distance
        let minAge = startingQues.question.targetDemo!.min_age_pref
        
        print("|      minAge => \(minAge)")
        let maxAge = startingQues.question.targetDemo!.max_age_pref
        
        print("|      maxAge => \(maxAge)")
        let userAge = getAgeFromBdaySeconds(myProfile.birthday)
        let ageDistance = ((abs(minAge-userAge)+(minAge-userAge))/2) + ((abs(userAge-maxAge)+(userAge-maxAge))/2)
        
        print("|      Age, Distance => \(userAge), \(ageDistance)")
        
        // numReviews
        print("|      QuestionReviews => \(startingQues.question.reviews)")
        //timeRemaining
        print("|      Time Remaining => \(timeRemainingToPrint)")
        print("|      Priority       => \(String(describing: startingQues.priority))")
        
        // for some weird reason contains isn't working. AFAIK complexity of contains is O(n), so it should be the same
        var isSentToMe = false
        
        for item in startingQues.question.recipients{
            
            if item == myProfile.username{
                isSentToMe = true
                break
            }
        }
        
        
        
        print("|      isSentToMe explicitly from a friend?       => \(isSentToMe)")
        
        //                print("|      Members who already reviewed this => \(startingQues.question.q_reviewed.description)")
        
        print("- - - - - - - - - - - END Q2R Test output - - - - - - - - - - - - - -")
        /// end of Output statements for checking Q2R   - - - - - - - - - - -
    }
    
    /// fetch next
    public func showNextQues(){
        
        print("Showing next question")
        // remove current ques if any
        if askController.question != nil || compareController.question != nil{
            print("removing top ques")
            // before we do, remove the vc as well
            if activeVCType == .ASK{
                removeChildVC(viewController: askController)
            }else{
                removeChildVC(viewController: compareController)
            }
            
            // get the question ID/name
            if let firstQuestionToReview = filteredQuestionsToReview.first {
                
                // decrement the qff count
                if firstQuestionToReview.question.recipients.contains(myProfile.username) {
                    print("Reducing QFF count")
                    qFFCount -= 1
                    // Update the qff count on firebase
                    decreaseQFFCountOf(username: myProfile.username)
                    // we should have one less qff count locally
                    // handled on the second live above
                    // so update the badge now
                    updateBadgeCount()
                }
                
                let questionName = firstQuestionToReview.question.question_name
                
                // the type so we can delete single or dual image
                let qType = firstQuestionToReview.question.type
                
                // the name is like qid_image_x.jpg
                let fileName = getFilenameFrom(qName: questionName, type: qType)
                
                // try deleting the images here
                removeImageFromDevice(ofName: fileName)
                
                // and the second image if it is compare
                if qType == .COMPARE {
                    // the secondPhoto var gives
                    let fileName2 = getFilenameFrom(qName: questionName, type: qType, secondPhoto: true)
                    removeImageFromDevice(ofName: fileName2)
                }
                
                /// delete from realm
                questionReviewed[questionName] = questionName
                // delete from filtered question
                print("Removing from filterQTR")
                filteredQuestionsToReview.removeFirst()
            } else {
                // No Questions to review, segue to MainVC
                print("unwrapped nil for head of filteredQuestionsToReview list -> segueing to Main View")
                returnToMenu()
            }
            
        }
        
        
        print("Local \(filteredQuestionsToReview.count)")
        // means we didn't get any more questions
        // so show alert
        if filteredQuestionsToReview.count > 0 {
            if let startingQues = filteredQuestionsToReview.first{
                
                // this call saves space so we can focus on the functionality that matters.
                printQ2RoutputFeed(startingQues: startingQues)
                
                print("type of question to load next: \(startingQues.question.type)")
                print("name of question to load next: \(startingQues.question.question_name)")
                
                questionOnTheScreen = PrioritizedQuestion()
                questionOnTheScreen.question = startingQues.question
                questionOnTheScreen.priority = -999
                
                // check type and show
                if startingQues.question.type == .ASK{
                    print("loading reviewCompareVC")
                    activeVCType = .ASK
                    showAsk(startingQues.question)
                }else{
                    print("loading reviewAsk VC")
                    activeVCType = .COMPARE
                    showCompare(startingQues.question)
                }
                
                
            }else{
                showNomoreQues()
            }
        }else{
            showNomoreQues()
        }
        
        // order matters
        if filteredQuestionsToReview.count < minimumQuestion {
            // check for new question
            print("checking again")
            checkForQuestionsToFetch(){
                
                print("BlueVC called CheckForQ2Fetch and ended")
                
            }
        }
        
        
    } // end of showNextQues
    
    /// Gets called when there are no more Questions left for the member to review
    func showNomoreQues(){
        print("showNoMoreQues called")
        print("Resetting QFF count")
        qFFCount = 0
        
        // AUTO-UNLOCK FUNCTIONALITY
        if Reachability.isConnectedToNetwork(){
            print("Internet Connection Available!")
            // unlock now, async
            
            // zero out reviews required on client
            lockedQuestionsCount = 0
            obligatoryQuestionsToReviewCount = 0
            
            
            // zero out reviews required on server
            Firestore.firestore()
                .collection(Constants.USERS_COLLECTION)
                .document(myProfile.username)
                .collection(Constants.USERS_PRIVATE_SUB_COLLECTION)
                .document(Constants.USERS_PRIVATE_INFO_DOC).setData([
                    Constants.UD_LOCKED_QUESTION_KEY : 0, // locked question
                    Constants.UD_QUESTION_TO_REVIEW_KEY: 0, // to review count
                    Constants.USER_QFF_COUNT_KEY: 0, // number of qff that we have left
                ],merge: true)
            
            // Now we iterate through all user's Questions and unlock each one locally and in firestore:
            for questionToUnlock in myActiveQuestions {
                
                // verify if Question is locked
                if questionToUnlock.question.isLocked == false {
                    // already unlocked, move on to the next one to save firestore writes
                    continue
                } else {
                    //unlock on client
                    questionToUnlock.question.isLocked = false
                    
                    //unlock on server
                    Firestore.firestore()
                        .collection(Constants.QUESTIONS_COLLECTION)
                        .document(questionToUnlock.question.question_name).updateData([
                            "isLocked":false
                        ])
                }
            } //end for loop
            
            // This is the message member gets if we unlocked all their Questions for them because they reviewed everything and still had locked Questions left over:
            let alertVC = UIAlertController(title: "The Tangerine Community thanks you!", message: "You reviewed everything! \nCheck back here later to see if anyone needs your help. \n\nALL your QUESTIONS have been UNLOCKED.", preferredStyle: .alert)
            alertVC.addAction(UIAlertAction.init(title: "Got It!", style: .cancel, handler: { (action) in
                self.view.window?.rootViewController?.dismiss(animated: false, completion: nil)
            }))
            
            // The culprit that caused the ADF thingy
            // when we don't have any question, we remove the top one as well
            
            if let _ = questionOnTheScreen {
                questionOnTheScreen = nil
            }
            print("Checking QONS \(questionOnTheScreen)")
            self.present(alertVC, animated: true)
            
            
        }else{
            print("Internet Connection not Available!")
            
            // This is the message the member gets if we just can't get anymore Questions from the database to give them to review because the phone can't reach the cloud. This logic prevents user from going on airplane mode to have all Questions unlocked "for free:"
            
            let alertVC = UIAlertController(title: "We're having trouble connecting your phone to the internet.", message: "Please try back later when the connection improves.", preferredStyle: .alert)
            alertVC.addAction(UIAlertAction.init(title: "Got It", style: .cancel, handler: { (action) in
                self.view.window?.rootViewController?.dismiss(animated: false, completion: nil)
            }))
            
            self.present(alertVC, animated: true)
            
        }
        
        // just clearing up
        filteredQuestionsToReview.removeAll()
    }
    
    // set constraint of child vc
    private func setCons(controller : UIViewController){
        
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            controller.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 0),
            controller.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: 0),
            controller.view.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 0),
            controller.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 0)
        ])
    }
    
    func setFirebaseonSwipe(_ swipeStatus: SwipeStatus, _ index: Int, _ reported: Bool = false){
        // save the values to a new collection for later use maybe
        Firestore.firestore().collection(Constants.QUESTION_REVIEWED).document(myProfile.username).setData([filteredQuestionsToReview[index].question.question_name:swipeStatus.description], merge: true)
        // delete the name from sender list
        var senderList = filteredQuestionsToReview[index].question.recipients
        if let idx = senderList.firstIndex(of: myProfile.username){
            senderList.remove(at: idx)
        }
        
        // update the list with me removed as I viewed this question
        
        if reported{
            Firestore.firestore().collection(Constants.QUESTIONS_COLLECTION).document(filteredQuestionsToReview[index].question.question_name).setData(
                [Constants.QUES_RECEIP_KEY:senderList,
                 Constants.QUES_REPORTS: FieldValue.increment(Int64(1))
                ],
                merge: true)
        }else{
            Firestore.firestore().collection(Constants.QUESTIONS_COLLECTION).document(filteredQuestionsToReview[index].question.question_name).setData([Constants.QUES_RECEIP_KEY:senderList], merge: true)
        }
        
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func filterQ(){
        
        if shouldPushController {
            showNextQues()
            shouldPushController = false
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if listener != nil{
            print("Listener removing...")
            listener.remove()
            listener = nil
        }else{
            print("Listener nil")
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if filteredQuestionsToReview.count > 0 {
            // filters available question and store to realm and shows
            filterQ()
            
        }else{
            
            showNomoreQues()
        }
        
        // start listening to live
        let upToFiveMins = NSDate(timeIntervalSinceNow: -60 * 5)
        let ts = Timestamp(date: upToFiveMins as Date)
        
        // to prevent listening on multiple instance
        if listener == nil {
            print("Listening to live...")
            listener = Firestore.firestore().collection(Constants.QUESTIONS_COLLECTION)
                .whereField(Constants.USER_CREATED_KEY, isGreaterThanOrEqualTo: ts)
                .limit(to: searchLimit).addSnapshotListener { snapshot, error in
                
                    // usual error handling
                    if error != nil{
                        print("LIVE: An error occured while getting questions")
                    }
                    
                    defer{
                        print("LIVE: Filtering...")
                              filterQuestionsAndPrioritize(isFromLive: true,onComplete:{
                              })
                        
                    }
                    // process the data fetched by this query:
                    if let snaps = snapshot?.documents{
                        if snaps.count > 0 {
                            print("LIVE: Total questions fetched: \(snaps.count)")
                            
                            for item in snaps{
                                let doc = item.data()
                                // create a question object
                                let question = Question(firebaseDict: doc)
                                
                                if question.is_circulating == false{
                                    print("LIVE: Returning from question:\(question.question_name) not in circulation")
                                    continue
                                }
                                
                                // to prevent already reviewed ones
                                if let _ = questionReviewed[question.question_name]{
                                    print("LIVE: This Q is already reviewed and in qReviewed, not adding to raw")
                                }else{
                                    // save to local db
                                    rawQuestions.insert(question)
                                }
                                
                            } // end of for loop of snaps
                        }
                        
                    }
                    
                    
                    
            }
        }else{
            print("Listener already attached...")
        }
        
        
        
    }
    
    @objc func returnToMenu() {
        print("returnToMenu() called")
        //        self.dismiss(animated: true, completion: nil)
        self.view.window?.rootViewController?.dismiss(animated: true, completion: nil)
    }
    
    
}

