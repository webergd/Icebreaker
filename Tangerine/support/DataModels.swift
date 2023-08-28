//
//  DataModels.swift
//  
//
//  Created by Wyatt Weber on 7/22/16.
//  Copyright © 2016 Insightful Inc. All rights reserved.
//

/// This is a file containing many of the values, methods, and objects required globally throughout the app.
//  When looking for a public field, this is a good place to start the search.



import Foundation;
import UIKit
import Firebase
import RealmSwift
import Kingfisher

// MARK: ENUMS:

public enum RowType: String {
    case isSingle // Ask Rows (one image)
    case isDual // Compare Rows (two images)
}

public enum ImageAspectType: String {
    case isPortrait
    case isLandscape
    case isSquare
}

/// .selection field for Ask
public enum yesOrNo: String {
    case yes
    case no
}

/// .selection field for Compare
public enum topOrBottom: String {
    case top
    case bottom
}

public enum askOrCompare: String {
    case ask
    case compare
}

//public enum orientation: String {
//    case straightWoman
//    case straightMan
//    case gayWoman
//    case gayMan
//    case other
//}

/// These are the three ways we can filter the reviewCollection results for an individual Question. (targetDemo, friends, or allUsers)
public enum dataFilterType: String {
    case targetDemo
    case friends
    case allUsers
}


/// This enum contains the 3 aggregated selection result options that a consolidated compare data set can return.
enum CompareWinner: String {
    case photo1Won
    case photo2Won
    case itsATie
}




// MARK: PUBLIC VARIABLES


public var DEFAULT_USER_IMAGE_URL = "gs://fir-poc-1594b.appspot.com/default_profile_image.jpg"

// my own profile
public var myProfile : Profile {
    return RealmManager.sharedInstance.getProfile()
}


public var filteredQuestionsToReview = [PrioritizedQuestion]()
///a local dictionary of Questions localUser has already reviewed (may be deprecated based on new Q2R query)
public var questionReviewed = [String:String]()


///questions that the localUser has asked and have not yet been deleted
public var myActiveQuestions = [ActiveQuestion]()

// all our unsorted questions will end up here, instead of realm
// called from only DataModels

public var rawQuestions = Set<Question>()
public var seedQuestions = Set<Question>()
public var questionOnTheScreen: PrioritizedQuestion!
public var qFFCount = 0
public var friendReqCount = 0

// MARK: Credits
public let maxPersistentReviewCredits: Int = 15
public let maxTimeToRetainAllReviewCredits: Int = 12 // in hours

/// this is bascially a {get set} portal to the number of locked questions in the UserDefaults Constants object
public var lockedQuestionsCount = {
    return UserDefaults.standard.integer(forKey: Constants.UD_LOCKED_QUESTION_KEY)
}()

/// this is bascially a {get set} portal to the number of reviews the user needs to do in order to unlock all remaining locked questions in the UserDefaults Constants object
public var obligatoryQuestionsToReviewCount = {
    return UserDefaults.standard.integer(forKey: Constants.UD_QUESTION_TO_REVIEW_KEY)
}()


// MARK: We should calculate this value here based on the following:
// ((3*lockedQuestions-1) + obligatoryReviewsToUnlockNextQuestion)
/// computed property returning the number of locked Questions that the user has in the myActiveQuestions array

/// We use this to know whether to call showTutorial() in MainVC just once after toggling the tutorial mode to off in the settings page. Otherwise there could still be labels that look like we're in tutorial mode
var needToClearOutMainVCTutorial: Bool = false


/// These fields are used during Question creation to keep values consistent across multiple view controllers:

public var currentImage: UIImage = UIImage(named: "tangerineImage2")!
public var currentTitle: String = "" //realistically this should probably be an optional
public var currentCaption: Caption = Caption(text: "", yLocation: 0.0)

/// This is part of a bandaid fix for the keyboardWillShow() firing multiple times issue
public var keyboardIsVisible: Bool = false


/// this object holds a max of 2 images that are currently being edited. It stores the first image in, then if the user creates a second image, isAsk is set to false:
public var currentCompare = compareBeingEdited(isAsk: true, imageBeingEdited1: nil, imageBeingEdited2: nil, creationPhase: .noPhotoTaken)

// These are in here so that the properties are only created once, as opposed to every time a new photo is created.
// Image processing variables for Question creation:

public var initialZoomScale: CGFloat {
    return 1 //currentImage.size.height / currentImage.size.width // recomputes in case image is different size than the last one
}

public var initialContentOffset: CGPoint {
    // 47.25 is the ratio of contentOffset/zoomScale when the image is zoomed in enough to make it a square and the contentOffset is centered.
    return CGPoint(x: 0, y: 0)//CGPoint(x: 0 (47.25 * initialZoomScale), y: 47.25 * (initialZoomScale))
}



/// when this is true, we will use the photo info taken in from user to create a compare instead of a simple ask. The default, as you can see, is false, meaning we default to creating an Ask
public var isCompare: Bool = false



/// set this to to true re-save the sample/sample users to the database.
public var uploadSampleUsers: Bool = false
/// starts out false then gets reset to true after sample users have been uploaded
public var sampleUsersUploaded: Bool = false

/// This hold the name of the last ten questions that have been downloaded so that we can prevent a question from being added to the assignedQuestionsArray more than once.
public var trailingReviewedQuestionNamesArray: [String] = []
public let trailingReviewedQuestionNamesArrayCountLimit: Int = 10
// reference the updateTrailingReviewedQuestionNamesArray method below.


/// this allows for hard dates to be created for test examples
public let formatter = DateFormatter()


// MARK: Set this to set time Ask will post
// This determines how long the compares and asks will be displayed before they expire.
// It's a var so that we can change it at runtime in the future if we need to.
// 5 hours is 5 * 3600 => 18,000 seconds
public var displayTime: TimeInterval = 72 * 3600 // easier for me



/// Used by the loadAssignedQuestions() method in FBManager.swift to load the assignedQuestions array up so that the ReviewAsk and ReviewCompare always have new Questions to show the local user for him/her to review.
public let assignedQuestionsBufferLimit: (Int,Int) = (3,10)
// We will use the above constant to set the length of the assignQuestions array.
// The name of the method that references it will be below and called loadAssignedQuestions()

public var unreviewedQuestionsRemainInDatabase: Bool = false

public var tapCoverViewToSegue: Bool = false

// MARK: OBLIGATORY REVIEWS

/// Sets the number of reviews required to unlock a container:
public let obligatoryReviewsPerQuestion: Int = 3

/// Computed property that returns the total number of reviews required to be performed in order to unlock all of local user's active Questions.

// There is also a function in DataModels that adds more obligatory reviews when a new Question is created.

/// Starts out false so that the refreshUserProfile method will download the most recent database version before uploading the client version which may be old.
public var profileInitialized: Bool = false


// MARK: LOCAL CLIENT VARIABLES

public var isUserSuspended = false
public var userSuspensionEnds: Double = 0

// These hold data offline and are used to perform actions in absence of the ability to synch with the database.
// Some push to the database and others pull from it.
// Reload these in MainController


// The User object (including that of local user) has a friendNames array that only stores the friends' usernames locally. We will store copies of the friends' user profiles so that we can display their pictures, etc. Before displaying the friends table view, we will refresh this localFriendCollection by searching the database for each friend's profile, based on the list of usernames that is currently in the online user's friendCollection (which, once again is just a list of strings)

// This will need to be stored locally for "app off" storage
//  using either UserDefaults or CoreData functionality.
// I will need an if statement where if the UserDefaults data is nil,
//  it then reroutes user to a login / create new account page.

// *The below  lines can be deleted once friend functionality module is attached:*
// should be arrays of usernames
//public var undeletedFriends: [String] = []
//public var newlyAcceptedFriends: [String] = []
//public var newlyRequestedFriends: [String] = []
//
//public var friendsIRequestedPending: [User] = []
//public var friendsRequestedMePending: [User] = []


// MARK: Needs to be implemented when the Profile Settings view is attached
/// Used to determine whether database or client has most current user profile info
public var unsavedUserProfileChanges: Bool = false

/// A locally stored list of the user's friends' user names (as strings).
/// Updated by public func updateMyFriendNames(), which is declared here in DataModels.
public var myFriendNames: [String] = []



// END OF CLIENT PROPERTIES


public extension Double {
    /// Rounds the double to decimal places value
    func roundToPlaces(_ places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

/// This enables us to set a View Controller so that when a user taps outside of a text field, the keyboard will dismiss.
/// Must be added to the override func viewDidLoad method in each individual VC's source code.
/// To call this, insert this line: self.hideKeyboardWhenTappedAround()


/// Called after Question creation. Resets public image variables to avoid confusion when creating the next Question.
public func clearOutCurrentCompare() {
    print("clearing out current compare")
    currentCompare.creationPhase = .noPhotoTaken
    currentCompare.imageBeingEdited1 = nil
    currentCompare.imageBeingEdited2 = nil
    
}



/// Used in review view controllers to set the comments text view back to default
public func resetTextView(textView: UITextView?, blankText: String) {
    if let thisTextView = textView {
        thisTextView.text = blankText
        thisTextView.textColor = UIColor.gray
    }
}


/*
 case nudity
 case demeaning
 case notRelevant
 case other
 case none
 */


/// Does the same job as the native function .firstIndex
public func index(of string: String, in arrayOfActiveQuestion: [ActiveQuestion])-> Int? {
    // find containerID's index in the array:
    var index: Int = 0
    for aq in arrayOfActiveQuestion {
        if aq.question.question_name == string {
            return index
        }
        index += 1
    }
    return nil
}

public func reviewCreditsHelpText(on: Bool) -> String {
    if on {
        return "Review credits ↗️ that you've earned."
    } else {
        return "Review this ↗️ many photos to open all your locked Questions."
    }
}




/// There is a cloud fucntion that generates the time remaining for each question. This returns the value as a formatted String. 
public func calcTimeRemaining(_ timePosted: Int64, forActiveQ custom: Bool = false) -> String {
    
    let exT = timePosted + Int64(displayTime)
    let expireTime = Date(timeIntervalSince1970: TimeInterval(exT))
    
    let timeNow = Date()
    
    //returns a double representing seconds
    let secondsRemaining: TimeInterval = timeNow.distance(to: expireTime)
    
    return custom ? secondsRemaining.activeHourMin : secondsRemaining.hourMinuteSecondMS //applies the below extention to the NSTimeInterval (aka elapsed time, aka seconds converted to an actual time)
    
}


public func calcTimeSpent(_ timePosted: Int64)-> String{
    let tdPosted = Date(timeIntervalSince1970: TimeInterval(timePosted))
    
    let timeSpent = tdPosted.distance(to: Date())
    let spentHour = timeSpent.hour
    let spentMin = timeSpent.minute
    
    let spentTimeInMin = spentHour * 60 + spentMin
    
    if spentTimeInMin <= 5 {
        return "2"
    }else if spentTimeInMin <= 30 {
        return "0"
    }else if spentTimeInMin <= 60 {
        return "1"
    }else if spentTimeInMin <= 6 * 60 {
        return "3"
    }else if spentTimeInMin <= 12 * 60 {
        return "4"
    }else if spentTimeInMin <= 24 * 60 {
        return "5"
    }else if spentTimeInMin <= 72 * 60 {
        return "6"
    }
    // if larger than 3 days, just for now
    return "9"
}

// for some reason, previous method wasn't working, probably due to my changes
// so I copied this one
extension TimeInterval { //got this off the internet to convert an NSTimeInterval into a readable time String. NSTI is just a Double.
    //https://stackoverflow.com/questions/30771820/how-to-convert-timeinterval-into-minutes-seconds-and-milliseconds-in-swift
    var hourMinuteSecondMS: String {
        String(format:"%d:%02d", hour, minute)
    }
    
    var activeHourMin: String {
        
        if hour < 24 {
            return "Deleting in \(String(format:"%d:%02d", hour, minute))"
        }else{
            return "Expires in: \(String(format:"%d:%02d", hour, minute))"
        }
        
        
    }
    
    
    var hour: Int {
        Int((self/3600).truncatingRemainder(dividingBy: 3600))
    }
    var minute: Int {
        Int((self/60).truncatingRemainder(dividingBy: 60))
    }
}

/// Returns an age Int based on the years elapsed between the passed bithday Date and today.
func ageIfBorn(on birthday: Date) -> Int {
    
    // ensure the date string is passed in the following format
    let currentCalendar = Calendar.current
    
    guard let birthday = currentCalendar.ordinality(of: .day, in: .era, for: birthday) else {
        return 0
    }
    
    guard let today = currentCalendar.ordinality(of: .day, in: .era, for: Date()) else {
        return 0
    }
    
    let age = (today - birthday) / 365
    return age
}

/// Returns the value of the "distance" that a specified age is from the specified age range.
/// Ex: If age = 25 and age range = 31 to 55, age distance = 6
public func ageDistance(of age: Int, from minAge: Int, to maxAge: Int) -> Int {
    let distance = ((abs(minAge-age)+(minAge-age))/2) + ((abs(age-maxAge)+(age-maxAge))/2)
    return distance
}

/// Returns the value of the "distance" that a specified birthday (and calculated age) is from the specified age range.
/// Ex: If calculated age = 25 and age range = 31 to 55, age distance = 6
public func ageDistance(of birthday: Double, from minAge: Int, to maxAge: Int) -> Int {
    let age = getAgeFromBdaySeconds(birthday)
    let distance = ((abs(minAge-age)+(minAge-age))/2) + ((abs(age-maxAge)+(age-maxAge))/2)
    return distance
}


/// crops a button into a circle
func makeCircle(button: UIButton){
    button.layer.cornerRadius = button.frame.size.height / 2
    button.layer.masksToBounds = true
}

/// Crops the view that's passed in into a circle
func makeCircle(view: UIView, alpha: CGFloat){
    print("Making Circle")
    view.layer.cornerRadius = view.frame.size.height / 2
    view.layer.masksToBounds = true
    
    view.backgroundColor = UIColor.systemBackground.withAlphaComponent(alpha)
    
    //view.alpha = alpha // this isn't technically required to make it into a circle but it's more efficient to have this command here rather than doing it in interface builder
    
}

/// Adds an outside border to a view of the specified color
func addCircleBorder(view: UIView, color: UIColor) {
    view.layer.borderWidth = 4.0
    view.layer.borderColor = color.cgColor
    view.clipsToBounds = true
}

/// removes the border that addCircleBorder added to the view
func removeCircleBorder(view: UIView){
    view.layer.borderWidth = 0.0
    view.clipsToBounds = true
}


func makeCircleInverse(view: UIView, alpha: CGFloat){
    view.layer.cornerRadius = view.frame.size.height / 2
    view.layer.masksToBounds = true
    
    view.backgroundColor = UIColor.label.withAlphaComponent(alpha)
    
    //view.alpha = alpha // this isn't technically required to make it into a circle but it's more efficient to have this command here rather than doing it in interface builder
    
}

/////// Displays a "cover view" on top of either ReviewAskVC or ReviewCompareVC to hide content and disable access to underlying controls
//func display(coverView: UIView, mainView: UIView) {
//    // this would look better if we animated a fade in of the coverView (and a fade out lower down)
//    coverView.isHidden = false
//    mainView.bringSubviewToFront(coverView)
//}
//
///// Hides the cover view. Does the opposite of display(coverView...)
//func hide(coverView: UIView, mainView: UIView) {
//    mainView.sendSubviewToBack(coverView)
//    coverView.isHidden = true
//}

//
///// Called when the client cannot access any more Questions for the local user to review. This could be the result of either connectivity or there simply being no questions left in the database that the local user has not reviewed yet.
//func informUserNoQuestions(coverView: UIView, coverViewLabel: UILabel, mainView: UIView ) {
//    // animate coverview darkening
//    coverView.alpha = 0.1
//    UIView.animate(withDuration: 0.5, delay: 0.0, options: UIView.AnimationOptions.beginFromCurrentState, animations: {
//        display(coverView: coverView, mainView: mainView)
//        coverView.alpha = 1.0
//    }, completion: {
//        finished in
//    })
//    coverViewLabel.text = "Connecting to Server"
//    coverViewLabel.isHidden = false
//    if unreviewedQuestionsRemainInDatabase == false { // i.e. user has reviewed all questions
//        // MARK: This if-else logic may be deprecated. Probably can be refactored for better efficiency.
//        if unreviewedQuestionsRemainInDatabase == true {
//            //we were able to loadAssignedQuestions successfully this time, just reload the view.
//            coverViewLabel.isHidden = false
//            hide(coverView: coverView, mainView: mainView)
//            viewController.loadNextQuestion()
//        } else {
//            // we know for sure that the database has no more questions in it to review
//            tapCoverViewToSegue = true
//            coverViewLabel.text = "You have reviewed all currently available photos! Congratulations! Tap to return to main menu."
//            // we want to unlock all of the user's Questions because with nothing to review, they won't be able to unlock them any other way
//            // MARK: May be a better way to do this. We don't want the user to just be able to go on airplane mode, try to review others, then get all their questions unlocked for them .
//            // MARK: Probably should check for connectivity before allowing this to happen. 
//            // LATER
//            
//        }
//    } else {
//        // loadAssignedQuestions never encountered a nil value from the database and therefore
//        //  the reason for the array being out of questions is a lack of connectivity, not a lack of questions left to review
//        // Notify user of connectivity problem and reroute the user back to the mainVC.
//        tapCoverViewToSegue = true
//        coverViewLabel.text = "Connectivity issues are preventing retrieval of more photos. Tap to return to main menu"
//    }
//} // end of informUserNoAvailableQuestions()


/// Calculates the caption's autolayout constraint for its distance from the top of the imageView it is being displayed over.
/// Normally this constraint will actually be within a View that is acting as a container for the imageView, scrollView, and captionTextField
public func calcCaptionTextFieldTopConstraint(imageViewFrameHeight: CGFloat, captionYLocation: CGFloat) -> CGFloat {
    // As you can see, all this does it multiply the values
    // This is because the yLocation is just a fraction between 0 and 1
    //  that represents the percentage of the way down the outside view
    //  that the caption should appear
    // The property 'imageViewFrameHeight' could be misleading because
    //  it could also be the height of the external "helper view" that contains
    //  a scrollView which in turn contains an imageView.
    // The reason it works normally to call the method using the imageView's
    //  height is because this method is normally invoked upon loading the
    //  view controller and the scrollView's zoomScale is normally 1.0 at that
    //  point in the code's execution.
    return imageViewFrameHeight * captionYLocation
}


/// Sets up an image with its accompanying caption correctly
public func loadCaptions(within helperView: UIView?, caption: Caption, captionTextField: UITextField?, captionTopConstraint: NSLayoutConstraint?) {
    if let thisHelperView = helperView,
       let thisTopConstraint = captionTopConstraint,
       let thisTextField = captionTextField {
        
        thisTextField.isHidden = !caption.exists
        thisTextField.text = caption.text
        thisTopConstraint.constant = calcCaptionTextFieldTopConstraint(imageViewFrameHeight: thisHelperView.frame.height, captionYLocation: CGFloat(caption.yLocation))
    }
}

// This is different now since I added the 100 bars in IB. It will be much simpler,
// Basically we will just multiply (one minus the percentage) times the 100 bar width in order to get the trailing constraint of'
//   whichever view we are dealing with. This will work in Compare VC and AskVC and for normal and strong bars alike. 
public func calcTrailingConstraint(percentYes: Int, hundredBarWidth: CGFloat) -> CGFloat {
    
    //Converts the percentage Int value into a decimal CGFloat that is < 1:
    let decimalPercentYes: CGFloat = CGFloat(percentYes) / 100.0
    
    print("decimalPercentYes: \(decimalPercentYes)")
    
    //Calculates how wide we need the bar we are setting up to be:
    let neededBarWidth = hundredBarWidth * decimalPercentYes
    
    //Calculates the size of the trailing constraint of the bar being set up:
    let constraintSize = hundredBarWidth - neededBarWidth
    
    return constraintSize
    
}

public func flipBarLabelsAsRequired(hundredBarWidth: CGFloat, yesTrailingConstraint: NSLayoutConstraint, yesPercentageLabel: UILabel, yesLabelLeadingConstraint: NSLayoutConstraint, strongYesTrailingConstraint: NSLayoutConstraint, strongYesPercentageLabel: UILabel, strongYesLabelTrailingConstraint: NSLayoutConstraint) {
    
    // Switch the yesPercentageLabel to the inside of the bar if there isn't enough space to display it on the outside:
    if (yesTrailingConstraint.constant < yesPercentageLabel.frame.size.width) {
        // this flips the label over to the other side by giving the constraint a negative constant
        yesLabelLeadingConstraint.constant = -1 * yesPercentageLabel.frame.size.width * 1.3
        // this changes the text color
        yesPercentageLabel.textColor = UIColor.black
        
        if ((strongYesTrailingConstraint.constant - yesTrailingConstraint.constant) < (yesPercentageLabel.frame.size.width * 1.3)){
            print("inside the fixer nested if - system knows there is not enough room for both labels")
            // in layman's terms:
            // If the space left for the label is too small,
            //  hide the strong label
            strongYesPercentageLabel.isHidden = true
        }
        
    } else { // this just sets it back to normal in case we flipped the label over and it needs to go back
        yesLabelLeadingConstraint.constant = 0.5
        yesPercentageLabel.textColor = UIColor.white
    }
    
    // Switch the strongYesPercentageLabel to the outside of the bar if there isn't enough space to display it on the inside:
    if ((hundredBarWidth - strongYesTrailingConstraint.constant) < yesPercentageLabel.frame.size.width) {
        // this flips the label over to the other side by giving the constraint a negative constant
        strongYesLabelTrailingConstraint.constant = -1 * strongYesPercentageLabel.frame.size.width // 0.5 is just a little extra padding
        // this changes the text color
        strongYesPercentageLabel.textColor = UIColor.blue
        strongYesPercentageLabel.isHidden = false
        
        if ((yesTrailingConstraint.constant - strongYesTrailingConstraint.constant) < (yesPercentageLabel.frame.size.width * 1.3)){
            print("inside the fixer nested if - system knows there is not enough room for both labels")
            
            // hide the strong label if there's not enough room to display it:
            strongYesPercentageLabel.isHidden = true
            
            
        }
    }
    
} // end of public func flipBarLabelsAsRequired(..)


/* The old header. Can be deleted once new rating display functionality is fully working */
//public func displayData(dataSet: ConsolidatedAskDataSet,
//                        totalReviewsLabel: UILabel,
//                        yesPercentageLabel: UILabel,
//                        strongYesPercentageLabel: UILabel,
//                        hundredBarView: UIView,
//                        yesTrailingConstraint: NSLayoutConstraint,
//                        yesLabelLeadingConstraint: NSLayoutConstraint,
//                        strongYesTrailingConstraint: NSLayoutConstraint,
//                        strongYesLabelTrailingConstraint: NSLayoutConstraint) {
//    
//}
///// ^^^^ This will all go away soon

// We are using this for asks. We are using DataDisplayTool.displayIcons for compares. That one is more elegant. Eventually we should write a .displayIcons method that works for ConsolidatedAskDataSet as well so that our functionality is consistent.
/// Takes a ConsolidatedAskDataSet, as well as the outlets it affects, and displays the passed data set in an understandable format to the user.
public func displayData(dataSet: ConsolidatedAskDataSet,
                        totalReviewsLabel: UILabel,
                        displayTool: DataDisplayTool,
                        displayBottom: Bool,
                        ratingValueLabel: UILabel,
                        dataFilterType: dataFilterType){
    
    totalReviewsLabel.text = configureNumReviewsLabel(with: dataSet.numReviews, for: dataFilterType)
    
    // Change this to the tangerine score version
    displayTool.displayIcons(forConsolidatedDataSet: dataSet, forBottom: displayBottom)
    
    
//    if dataSet.numReviews < 1 {
//        ratingValueLabel.text = ""
//    } else {
//        ratingValueLabel.text = String(dataSet.rating)
//    }
} // end of displayData(Ask)

/// Returns an 's' to be added to a word if the specified number of items is any number besides 1, in which case there should be no 's'.
public func addPluralS(numberOfItems: Int) -> String {
    if numberOfItems != 1 {
        return "s"
    } else {
        return ""
    }
}


/// Takes in a filter type (TD, Friends, or All Reviews) and the number of reviews for that category, and returns the string that should be displayed by the numReviews label in the data display tool.
public func configureNumReviewsLabel(with numReviews: Int, for dataFilterType: dataFilterType) -> String {
    let S: String = addPluralS(numberOfItems: numReviews)
//    var pluralS: String {
//        if numReviews > 1 || numReviews < 1 {
//            return "s"
//        } else {
//            return ""
//        }
//    }
    
    switch dataFilterType {
    case .targetDemo:
        return "\(numReviews) Review\(S)"
    case .friends:
        return "\(numReviews) Review\(S)"
    case .allUsers:
        return "\(numReviews) Total Review\(S)"
    }
}

// There used to be a displayData(dataSat: ConsolidatedAskDataSet...) here. It has since been deleted.


/// converts the enum value to a text value that's useful in labels:
public func selectionToText(selection: yesOrNo) -> String {
    switch selection {
    case .yes: return "YES"
    case .no: return "NO"
    }
}

// MARK: The below methods should be modified to throw an error, not just default to yes or top. Especially since it's the heart of the entire value proposition of the app.

/// Takes a String that is presumably a yes or a no and converts it to a .yes or .no enum value. Needs to throw an error or nil value if it fails rather than just defaulting to "yes" like it currently does.
public func textToYesOrNo(selectionText: String) -> yesOrNo! {
    if selectionText == "yes" || selectionText == "no" {
        return yesOrNo(rawValue: selectionText)!
    } else {
        return yesOrNo(rawValue: "yes")!
    }
}

/// Takes a String that is presumably a top or bottom and converts it to a .top or .no enum value. Needs to throw an error or nil value if it fails rather than just defaulting to "top" like it currently does.
public func textToTopOrBottom(selectionText: String) -> topOrBottom! {
    if selectionText == "top" || selectionText == "bottom" {
        return topOrBottom(rawValue: selectionText)!
    } else {
        return topOrBottom(rawValue: "top")!
    }
}

/// Takes the selection property of a CompareReview and the associated Compare, and returns the image that the selection refers to. Ex: if the reviewer voted for the top image, this method will return the top image.

/// Takes the selection property of an CompareReview and the associated Compare and returns the title of the image that the selection refers to. Ex: if the reviewer voted for the top image, this method will return the top image's title.


/// This method is for AskReviews when the .strong property is TRUE. It takes the strong property and returns an emoji for either of the two outcomes. Fire for strong yes and snowflake for strong no. Nothing if the property is nil.
public func strongToText(strong: yesOrNo?) -> String {
    if let strong = strong { // strong is an optional property
        switch strong {
        case .yes: return "🔥"
        case .no: return "❄️" // I have not yet implemented any strong No's
        }
    } else { // .strong is nil
        return ""
    }
}

/// This method is for CompareReviews. It takes the strongYes and strongNo properties of the review and returns emojis associated with either one.
public func strongToText(strongYes: Bool, strongNo: Bool) -> String {
    var stringToReturn: String = ""
    if strongYes == true {
        stringToReturn = stringToReturn + "🔥"
    }
    if strongNo == true {
        stringToReturn = stringToReturn + "❄️"
    }
    
    // It's possible that the label could have both emojis
    // This would be a situation where the user loved the one they voted for
    //  and really hated the one they didn't.
    // I'm not sure if I'll ever even use the strong no.
    // It is currently unimplemented.
    
    return stringToReturn
}

/// Takes a rating value Double from 0 to 5 and returns the closest number of tangerine emoji's to that value.
public func reviewerRatingToTangerines(rating: Double) -> String {
    switch rating {
    case 0..<0.5: return "" + String(format:"%.1f", rating)
    case 0.5..<1.5: return "🍊" + String(format:"%.1f", rating)
    case 1.5..<2.5: return "🍊🍊" + String(format:"%.1f", rating)
    case 2.5..<3.5: return "🍊🍊🍊" + String(format:"%.1f", rating)
    case 3.5..<4.5: return "🍊🍊🍊🍊" + String(format:"%.1f", rating)
    case 4.5..<5.1: return "🍊🍊🍊🍊🍊" + String(format:"%.1f", rating)
    default: return String(format:"%.1f", rating)
    }
}




// an awesome website for color conversion is: http://uicolor.xyz/#/hex-to-ui
/// Takes an orientation and returns a color value to be displayed in various locations to help the user quickly distinguish the orientation of a reviewer.
public func orientationSpecificColor(userOrientation: String) -> UIColor {
    
    let orientations = Constants.ORIENTATIONS
    
    switch userOrientation {
    case orientations[0]:
        return UIColor(red:0.92, green:0.63, blue:0.89, alpha:1.0) //pink
        
    case orientations[1]:
        return UIColor(red:0.48, green:0.65, blue:0.93, alpha:1.0) //blue
        
    case orientations[2]:
        return UIColor(red:0.71, green:0.36, blue:0.89, alpha:1.0) //purple
        
    case orientations[3]:
        return UIColor(red:0.48, green:0.93, blue:0.55, alpha:1.0) //green
        
    case orientations[4]:
        return UIColor(red: 0.75, green: 0.75, blue: 0.75, alpha: 1.00) //silver
    default:
        return UIColor(red: 0.75, green: 0.75, blue: 0.75, alpha: 1.00) //silver
        
    } // end switch
    
}

/// unwraps a user's profile picture (it's an optional) and returns a generic profile image if the profile pic was nil.
public func returnProfilePic(image: UIImage?) -> UIImage {
    if let thisImage = image {
        return thisImage
    } else {
        return #imageLiteral(resourceName: "generic_user")
    }
}

/// Takes a friend's name and returns their locally stored User object if available; otherwise, returns a generic User object with the friend's userName.

/// Returns the index Int? of a User object correlated with the userName passed in.


// MARK: There is some redundancy in the index(of:) vs indexOf methods. Can be examined and cleaned up.

/// Searches an array of Questions for those with a particular questionName and returns the index, or nil if not found.


/// Returns an "s" to be appended to the end of a word if the Int passed in is greater than one
public func sIfNeeded(number: Int) -> String {
    if number > 1 {
        return "s"
    } else {
        return ""
    }
}


/// takes a String and an array of strings, deletes all instances of the String from the passed array, and returns an updated array that contains no instances of the passed String
public func removeIf(element: String, memberOf: [String]) -> [String] {
    var arrayToReturn: [String] = memberOf
    var searchAgain: Bool = true
    
    while searchAgain {
        if let idx = arrayToReturn.firstIndex(of: element) {
            arrayToReturn.remove(at: idx)
        } else {
            // keeps looking for more instances of the String element until we are certain there are none left
            searchAgain = false
        }
    }
    
    return arrayToReturn
}

/// takes a questionName in the form of a String and an array of Questions, and removes any Questions in the array with that particular questionName. Then it returns an array identical to the one passed in, except that it no longer contains Questions with the passed questionName (if it ever did).


/// Takes an array of Reviews and searches for, and then removes all instances of the specified ReviewID, then returns a new array of Reviews that is identical to the one passed in except that it no longer contains Reviews with the passed ReviewID (if it ever did).


/// Returns the Int number of years that the actualAge is outside of the specified age range.
public func ageProximity(actualAge: Int, minAge: Int, maxAge: Int) -> Int {
    
    if actualAge < minAge {
        return minAge - actualAge
    } else if maxAge < actualAge {
        return actualAge - maxAge
    } else {
        return 0
    }
}

/// keeps the trailingReviewedQuestionNamesArray up to date and at the proper length. Called in downloadQuestions(toReview) in FBManager.swift
public func updateTrailingReviewedQuestionNamesArray(with questionName: String) {
    
    // push questionName into queue:
    trailingReviewedQuestionNamesArray.append(questionName)
    
    // check array length and remove head of array
    if trailingReviewedQuestionNamesArray.count >= trailingReviewedQuestionNamesArrayCountLimit {
        trailingReviewedQuestionNamesArray.removeFirst()
    }
}

// currently being called in ActiveQuestionsVC ViewDidAppear()
/// Updates the myFriendNames list of Strings containing the local user's friends' userNames.
///  myFriendNames is declared here in DataModels (up with the other public variables)
public func fetchMyFriendNamesFromRealm() {
    
    // MARK: MM! Implement here
    
    
    // Realm or firestore - up to you- it looked like you had something similar to this in realm with [PersonList] except that was a list of PersonList objects, not strings
    
    // myFriendNames = list of strings with all userNames of the local User's friends (requested or blocked should not be included, only actual friendships)
    
    myFriendNames = RealmManager.sharedInstance.getAllFriendUserNames()
    print("Realm myFriendNames =>", myFriendNames)
    
}

// Currently calling from MainVC line who knows not sure yet
/// Updates the myFriendNames list by fetching only the friend userName Strings from firestore.
public func fetchMyFriendNamesFromFirestore(){
    print("Syncing Friendlist from Data Models")
    // reset the db
    Firestore.firestore()
        .collection(FirebaseManager.shared.getUsersCollection())
        .document(myProfile.username)
        .collection(Constants.USERS_LIST_SUB_COLLECTION)
        .whereField(Constants.USER_STATUS_KEY, isEqualTo: Status.FRIEND.description)
        .getDocuments { (querySnaps, error) in
            
            if error != nil {
                print("Sync error \(String(describing: error?.localizedDescription))")
                return
            }
            
            // fetch the personsList
            if let docs = querySnaps?.documents{
                if docs.count > 0 {
                    
                    //reset my list of friend names
                    myFriendNames = []
                    
                    for item in docs{
                        // save the friend names
                        let status = getStatusFromString(item.data()[Constants.USER_STATUS_KEY] as! String)
                        if status == .FRIEND{
                            // LATER:: CRITICAL
                            // item.documentID is your friend's name
                            myFriendNames.append(item.documentID)
                        }
                        
                        let prefs = UserDefaults.standard
                        prefs.set(myFriendNames.count, forKey: Constants.UD_USER_FRIEND_COUNT)
                        
                    }
                    print("Sync done")
                    
                }
            }// end if let
            
        } // end of firebase
}


// also used in FriendsVC
public func getStatusFromString(_ statusString: String) -> Status{
    switch statusString {
    case Status.REQUESTED.description:
        return .REQUESTED
    case Status.INVITED.description:
        return .INVITED
    case Status.BLOCKED.description:
        return .BLOCKED
    case Status.FRIEND.description:
        return .FRIEND
    case Status.PENDING.description:
        return .PENDING
    case Status.REGISTERED.description:
        return .REGISTERED
    case Status.GOT_BLOCKED.description:
        return .GOT_BLOCKED
    default:
        return .NONE
    }
}


/// cycles through the local friend list (myFriendNames - declared in DataModels) to see if userName is friends with the local user
public func friends(with userName: String) -> Bool {
    print("inside func friends(with userName: String) -> Bool")
    
    print("myFriendNames is: \(myFriendNames)")
    print("userName being checked is \(userName)")
    // loops through the list and returns true if it finds userName in the local list of friends
    for friend in myFriendNames {
        print("IN LOOP. Checking if \(userName) == \(friend)")
        print("Bool result of whether \(userName) == \(friend) is \(userName == friend)")
        if userName == friend {
            return true
        }
    }
    //returns false if userNames wasn't found in the list of localUser's friends
    return false
}



// LATER
/// This method ensures the assignedQuestions array "buffer" keeps enough Questions to review in it to avoid unnecesary performance delays.
//public func loadAssignedQuestions(completion: @escaping (Error?) -> Void) {
//    // Called in MainController, ReviewAsk, ReviewCompare viewDidLoad methods
//    // Called in ReviewAsk, ReviewCompare loadNextQuestion methods
//    // MARK: The method should be modified to check the age of the questions and purge the assignedQuestions array and reload new ones if they are too old.
//    unreviewedQuestionsRemainInDatabase = true
//
//    while assignedQuestions.count > assignedQuestionsBufferLimit.1 {
//        assignedQuestions.removeFirst()
//        completion(nil)
//    }
//    /// determines whether the assignedQuestions array is below the min required quantity
//    if assignedQuestions.count < assignedQuestionsBufferLimit.0 {
//        let numQuestionsNeeded = assignedQuestionsBufferLimit.1 - assignedQuestions.count
//
//        // Bypassing fetchNewQuestions here, going straight to FB call
//        FBManager.shared.downloadQuestions(toReview: numQuestionsNeeded) { (newQuestions, error) in
//            if let error = error {
//                print("fetchNewQuestions: Error querying the questions collection.")
//                completion(error)
//            } else if let newQuestions = newQuestions {
//                assignedQuestions.append(contentsOf: newQuestions)
//                completion(nil)
//            } else {
//                print("neither an error or an array of new questions was returned by the completion of downloadQuestions(toReview)")
//            }
//        }
//    }
//
//    if (assignedQuestionsBufferLimit.0 <= assignedQuestions.count && assignedQuestions.count <= assignedQuestionsBufferLimit.1) {
//        completion(nil) // this happens if assignedQuestions.count was between the two limits (aka what we want). It means the method did essentially nothing but verify we had a desired number of Questions in the assignedQuestions array.
//    }
//    completion(nil)
//
//}// end of loadAssignedQuestions()

/// Returns true or false depending on whether the passed orientation and age combination fall within the parameters specified by the passed TargetDemo
public func memberOf(targetDemo: TargetDemo, reviewerOrientation: String, and reviewerAge: Int) -> Bool {
    
    if reviewerAge < targetDemo.min_age_pref || reviewerAge > targetDemo.max_age_pref {
        return false
    }
    
    switch reviewerOrientation {
    case Constants.ORIENTATIONS[0]:
        if targetDemo.straight_woman_pref {return true}
    case Constants.ORIENTATIONS[1]:
        if targetDemo.straight_man_pref {return true}
    case Constants.ORIENTATIONS[2]:
        if targetDemo.gay_woman_pref {return true}
    case Constants.ORIENTATIONS[3]:
        if targetDemo.gay_man_pref {return true}
    case Constants.ORIENTATIONS[4]:
        if targetDemo.other_pref {return true}

    default:
        return false // this could also happen if there is a typo somewhere since we stopped using the isOrientation enum to constrain the value of this field.
    }
    
    return false
}

/// Returns a Bool indicating whether the specified orientation is one of the preferred orientations in the passed TargetDemo.
public func inTargetOrientation(targetDemo: TargetDemo, orientation: String) -> Bool {
    switch orientation {
    case Constants.ORIENTATIONS[0]:
        if targetDemo.straight_woman_pref {return true}
    case Constants.ORIENTATIONS[1]:
        if targetDemo.straight_man_pref {return true}
    case Constants.ORIENTATIONS[2]:
        if targetDemo.gay_woman_pref {return true}
    case Constants.ORIENTATIONS[3]:
        if targetDemo.gay_man_pref {return true}
    case Constants.ORIENTATIONS[4]:
        if targetDemo.other_pref {return true}
    default:
        return false // this could also happen if there is a typo somewhere since we stopped using the isOrientation enum to constrain the value of this field.
    }
    print("Error- switch statement did not resolve correctly inside inTargetOrientation (DataModels).")
    return false
}



/// Used so that we can have one pullConsolidatedData method for both Ask's and Compare's.
public protocol isConsolidatedDataSet {
    var rating: Double {get}
    var numReviews: Int {get}
}


// If we implement strongYes and strongNo functionality again, we need to change the value of the below constants to be:
//let strongYesConstant = 5
//let yesConstant = 4
//let noConstant = 1
//let strongNoConstant = 0
//////////////////////////////// Probably should be moved up to the top at some point /////
// MARK: Rating Constant Values
let strongYesConstant = 5
let yesConstant = 5
let noConstant = 0
let strongNoConstant = 0
// These are used in ConsolidatedAskDataSet and ConsolidatedCompareDataSet to calculate a 1-5 rating for the Question
////////////////////////////////

/// This is an object that contains all necessary fields to display aggregated Ask review data that the local user can easily interpret. We can create these data sets for different groups of reviewers, for example, all reviewers in local user's target demo or all reviewers who are friends with the local user.
public struct ConsolidatedAskDataSet: isConsolidatedDataSet {
    let percentYes: Int
    var percentNo: Int { return 100 - percentYes }
    let percentStrongYes: Int
    let percentStrongNo: Int
    let averageAge: Double
    let percentSW: Int
    let percentSM: Int
    let percentGW: Int
    let percentGM: Int
    let percentOT: Int
    public let numReviews: Int
    
    // this one is for asks, but for compare data sets (see below) the 'rating' computed property returns a double that represents a percentage (* 100 so it's cleaner looking)
    public var rating: Double {
        let rawRating = (percentStrongYes * strongYesConstant) +
        ((percentYes - percentStrongYes) * yesConstant) +
        ((percentNo - percentStrongNo) * noConstant) +
        (percentStrongNo * strongNoConstant)
        let ratingToReturn = Double(rawRating) / 100 // rawRating is out of 500, rating to return is out of 5
        return ratingToReturn.roundToPlaces(1) // returns the double with only one decimal place
    }
    
    /// Takes a UILabel and populates it with the number of reviews included in a particular Consolidated **ASK** DataSet
    public func populateNumReviews(label: UILabel) {
        let S: String = addPluralS(numberOfItems: numReviews)
        label.text = "(\(String(numReviews)) Review\(S))"

    }
}


/// This is an object that contains all necessary fields to display aggregated Compare review data that the local user can easily interpret. We can create these data sets for different groups of reviewers, for example, all reviewers in local user's target demo or all reviewers who are friends with the local user.
public struct ConsolidatedCompareDataSet: isConsolidatedDataSet {
    // Keeps these values consistent with the ones defined above
    /// We use these for computing the top image's rating, the bottom image is just 5 minus the top (essentially the inverse)
    let countTop: Int
    let countBottom: Int
    
    let strongYesTopConstant = strongYesConstant
    let yesTopConstant = yesConstant
    let yesBottomConstant = noConstant
    let strongYesBottomConstant = strongNoConstant // a strong yes for the bottom is essentially a strong no for the top
    
    let percentTop: Int
    var percentBottom: Int {
        if numReviews < 1 {
            return 0
        } else {
            return 100 - percentTop
        }
    }
    let percentStrongYesTop: Int
    let percentStrongYesBottom: Int
    // We are currently not implementing 'strong no' functionality but leave these fields here in case we opt to later.
    //let percentStrongNoTop: Int
    //let percentStrongNoBottom: Int
    let averageAge: Double
    let percentSW: Int
    let percentSM: Int
    let percentGW: Int
    let percentGM: Int
    let percentOT: Int
    public let numReviews: Int
    var winner: CompareWinner {
        let enumValueToReturn: CompareWinner
        switch percentTop {
        case 51...100: enumValueToReturn = .photo1Won
        case 0...49: enumValueToReturn = .photo2Won
        default: enumValueToReturn = .itsATie // the only other case could be 50% so this is why it's a tie.
        }
        // ensures that zero reviews yields a tie
        if numReviews < 1 {
            return .itsATie
        } else {
            return enumValueToReturn
        }
    }
    
    
    // MARK: Simplify this
    // The way that this number is being arrived at is  convoluted and unclear. Do a deep dive and simplify it. One issue is this StrongYes vs normal yes madness. We really should just get rid of strong yes most likely. It should be an add on not a primary feature. If we remove strongYes, we will need to adjust the strongYesConstant and associated constants so that a Yes counts as a 5 rather than a 4 like it is right now.
    /// returns the rating of the top pic of the ConsolidatedCompareDataSet in 0 to 5 format
    public var rating: Double {
        let topPercent = /*(percentStrongYesTop * strongYesTopConstant) +*/
        (percentTop * strongYesTopConstant)
        let ratingToReturn: Double = Double(topPercent) / 100 // divided by 100, * 5, same thing as divide by 20
        return ratingToReturn.roundToPlaces(1) // returns the double with only one decimal place
    }
    
    /// Accepts 2 labels (the top and bottom numReviews or numVotes labels for a given dataset, and loads their text with a string containing the number of votes for the top and bottom photos respectively.
    public func populateNumVotesLabels(topLabel: UILabel?, bottomLabel: UILabel?) {
        //populate top label
        if let tL = topLabel {
            let S: String = addPluralS(numberOfItems: countTop)
            tL.text = "(\(String(countTop)) Vote\(S))"
        }
        //populate bottom label
        if let bL = bottomLabel {
            let S: String = addPluralS(numberOfItems: countBottom)
            bL.text = "(\(String(countBottom)) Vote\(S))"
        }
    }
}



/// This looks at the passed Question's reviewCollection and returns a ConsolidatedCompareDataSet (EDIT: Looks like it's also pulling from ASK dataSets now) from the reviews created by the group of reviewers in the passed filterType.

public func pullConsolidatedData(from reviewCollection: ReviewCollection, filteredBy filterType: dataFilterType, type questionType: QType) -> isConsolidatedDataSet {
    
    // MARK: This should be named "dataSetToReturn"
    // we don't want to only return the targetDemo data. The whole point of having multiple heart displays is that we DONT do that.
    var requestedDataSet: isConsolidatedDataSet
    var requestedDemo: TargetDemo
    
    var friendsOnly: Bool
    
    switch filterType {
    case .targetDemo:
        friendsOnly = false
        requestedDemo = RealmManager.sharedInstance.getTargetDemo()
    case .friends:
        friendsOnly = true
        requestedDemo = TargetDemo(returnAllUsers: true)
    case .allUsers:
        friendsOnly = false
        requestedDemo = TargetDemo(returnAllUsers: true)
        
    }
    
    print("PULL CD FRIENDS ONLY? \(friendsOnly)")
    
    switch questionType {
    case .ASK:
        print("Getting ask data")
        requestedDataSet = reviewCollection.pullConsolidatedAskData(requestedDemo: requestedDemo, friendsOnly: friendsOnly)
    case .COMPARE:
        requestedDataSet = reviewCollection.pullConsolidatedCompareData(requestedDemo: requestedDemo, friendsOnly: friendsOnly)
    }
        
    // to use this on the receiving end, we will have to cast this to the right type of consolidated data set (ask or compare).
    return requestedDataSet
}
/// Takes the selection property of an CompareReview and the associated Compare and returns the title of the image that the selection refers to. Ex: if the reviewer voted for the top image, this method will return the top image's title.
public func selectionTitle(selection: topOrBottom, compare: Question) -> String {
    switch selection {
    case .top: return compare.title_1
    case .bottom: return compare.title_2
    }
}

/// This object combines all the outlets required to display data from a ConsolidatedDataSet.
public struct DataDisplayTool {
    // To use this tool, cut and paste the graphical hearts in their container to the place you want to use it,
    //  then link up the heart images as outlets.
    // Create a dataDisplayTool object in the ViewController source code using the 5 heart images.
    // To display the right number of hearts, call the displayIcons() method for the particular dataDisplayTool object,
    //  passing the appropriate data set and set the forBottom flag to true only if these 5 hearts will be displaying
    //  data for the second (bottom) image of a compare.
    
    
    let goodImage: UIImage = #imageLiteral(resourceName: "Heart Yellow")
    let halfImage: UIImage = #imageLiteral(resourceName: "Heart Half Yellow")
    let badImage: UIImage = #imageLiteral(resourceName: "Heart Black 2")
    
    let icon0: UIImageView
    let icon1: UIImageView
    let icon2: UIImageView
    let icon3: UIImageView
    let icon4: UIImageView
    let inverseOrientation: Bool // used to reverse the direction of the control to be displayed for a compare cell in a tableView
    
    let ratingValueLabel: UILabel
    // rating is a Double from 0.0 to 5.0
    
    /// Hides or changes the icons based on whether there are reviews or not
    func configureIconsFor(zeroReviews: Bool) {
        icon0.isHidden = zeroReviews
        icon1.isHidden = zeroReviews
        icon2.isHidden = zeroReviews
        icon3.isHidden = zeroReviews
        if zeroReviews {
            icon4.image = UIImage(systemName: "person.badge.clock")!
            icon4.tintColor = UIColor(red: 255.0, green: 255.0, blue: 255.0, alpha: 0.9)//white
        }
    }
    
    /// Displays the appropriate configuration of 'good' and 'bad' images in order to graphically convey the contents of the ConsolidatedDataSet to the local user.
    /// Currently only being used for Asks. Compares use the older displayData method. This method is set up to also work with Compares, if we decide to implement it for displaying compare data as well. 9/28/21: It seems like this is being used for compares now as well.
//    func displayIcons(dataSet: isConsolidatedDataSet, forBottom bottom: Bool){
//
//        /// Sets the value equal to bottom (from the input parameters) so that if this set of display icons IS on the bottom, the displayed rating will be the inverse (ex: if the top image got one heart, the bottom image should show 4 hearts)
//        var displayInverseRating = bottom
//
//        /// We use this to determine whether to set the zero review configuration for the DataDisplayTool
//        let questionHasZeroReviews: Bool = dataSet.numReviews < 1
//
//        let imageViews: [UIImageView] = [icon0, icon1, icon2, icon3, icon4]
//
//        // calculate percentage rating based on aggregated yes and strong yes data:
//        var ratingValue: Double = dataSet.rating // this returns the score for the top (for compare Compares) or only image (as in an Ask)
//
//
//        // this is the value in 0.0 to 5.0
//        var ratingToDisplay =  dataSet.rating
//
//
//        // If there are no reviews, we'll set displayInverseRating = false, because we don't want to invert the heart values and display 5 yellow hearts for the bottom one, since there aren't any reviews. We want 5 black on the top and the bottom. So this is the lone case when the bottom should be the same as the top, not the inverse.
////        if questionHasZeroReviews {
////            displayInverseRating = false
////        }
//
//        if displayInverseRating { // if we're displaying the bottom image's results, use the inverse
//            ratingValue = 5.0 - ratingValue
//            ratingToDisplay = 5.0 - dataSet.rating
//        }
//
//
//        ratingValueLabel.text = (round(ratingToDisplay * 10) / 10.0).description // rounded to the .1 decimal place and converted to a String
//
//        var imageIndexValue: Double = 0.0
//        for imageView in imageViews {
//            // ex: for position 2 (the 3rd heart), if the rating is 2.5, the imageIndexValue of 2 will be subtracted leaving 0.5
//            //  meaning that 0.5 is less than 0.9 and will therefore display the bad image aka black (empty) heart.
//            if (ratingValue - imageIndexValue) > 0.9 {
//                imageView.image = goodImage
//            } else if (ratingValue - imageIndexValue) > 0.4 {
//                imageView.image = halfImage
//                // Checks to see if we have the DataDisplayTool arranged from right to left, then flips the halfImage as required.
//                if inverseOrientation == true {
//                    imageView.image = halfImage.withHorizontallyFlippedOrientation()
//                }
//            } else {
//                imageView.image = badImage
//            }
//            imageIndexValue += 1
//        }
//        // Pass the Bool questionHasZeroReviews to determine the final config of the data display tool
//        configureIconsFor(zeroReviews: questionHasZeroReviews)
//    }
    
    
    func displayIcons(forConsolidatedDataSet dataSet: isConsolidatedDataSet, forBottom bottom: Bool) {
        self.populateDataDisplayTool(withRating: dataSet.rating, numReviews: dataSet.numReviews, forBottom: bottom)
    }
    
    func displayIcons(forTangerineScore tangerineScore: TangerineScore, forBottom bottom: Bool) {
        self.populateDataDisplayTool(withRating: tangerineScore.score, numReviews: tangerineScore.numReviews, forBottom: bottom)
    }
    
    // Refactor of displayIcons() on 8/25/22
    /// Displays the appropriate configuration of 'good' and 'bad' images in order to graphically convey the contents of the specified rating (from 0.0 to 5.0)
    func populateDataDisplayTool(withRating rating: Double, numReviews: Int, forBottom bottom: Bool){
        

        /// We use this to determine whether to set the zero review configuration for the DataDisplayTool.
        if numReviews < 1 {
            ratingValueLabel.text = ""
            configureIconsFor(zeroReviews: true)
            return
            // if the question has zero reviews, there is no point in excecuting the rest of this method.
        }
        
        /// Sets the value equal to bottom (from the input parameters) so that if this set of display icons IS on the bottom, the displayed rating will be the inverse (ex: if the top image got one heart, the bottom image should show 4 hearts)
        let displayInverseRating = bottom
        

        let imageViews: [UIImageView] = [icon0, icon1, icon2, icon3, icon4]
        
        // this is the score for the top (for compare Compares) or only image (as in an Ask)
        // copying 'rating' to a var enables us to invert it later as required
        var ratingValue: Double = rating
        
        
        if displayInverseRating { // if we're displaying the bottom image's results, use the inverse
            ratingValue = 5.0 - rating
//            ratingToDisplay = 5.0 - rating
        }
        
        // populate ratingValueLabel
//        if numReviews < 1 {
//            ratingValueLabel.text = ""
//            print("numReviews less than one, setting empty string")
//        } else {
            // currently displays all values at percent. To go back to 0.0 to 5.0 rating display, uncomment next line:
            //ratingValueLabel.text = (round(ratingValue * 10) / 10.0).description)
            // rounded to the .1 decimal place and converted to a String
        ratingValueLabel.text = "\(Int(round(ratingValue * 10 * 20) / 10.0).description)%"
//        }
        
        var imageIndexValue: Double = 0.0
        for imageView in imageViews {
            imageView.isHidden = false //added 9Nov22 because for some reason these imageViews were being arbitrarily hidden here and there. There is still the potential that a deeper underlying problem exists because we are never intentionally hiding these individual imageViews at any point yet they are being hidden even so. 
            
            // ex: for position 2 (the 3rd heart), if the rating is 2.5, the imageIndexValue of 2 will be subtracted leaving 0.5
            //  meaning that 0.5 is less than 0.9 and will therefore display the bad image aka black (empty) heart.
            if (ratingValue - imageIndexValue) > 0.9 {
                imageView.image = goodImage
            } else if (ratingValue - imageIndexValue) > 0.4 {
                imageView.image = halfImage
                // Checks to see if we have the DataDisplayTool arranged from right to left, then flips the halfImage as required.
                if inverseOrientation == true {
                    imageView.image = halfImage.withHorizontallyFlippedOrientation()
                }
            } else {
                imageView.image = badImage
            }
            imageIndexValue += 1
        }
    }
    
    
}

/// The Caption object contains all elements needed to display a text caption on a Question image that has been submitted for review. Unlike the image's title, which is private, the caption can be seen by any user viewing the Question.
public struct Caption {
    var text: String
    //this way we can check to see if a caption exists for the give Ask or Compare
    var exists: Bool {
        if text == "" { return false }
        else { return true }
    }
    /// specifies where the caption should appear vertically within the image's ImageView.
    var yLocation: Double //a number <= 1 and >= 0 that specifies where on the image the caption y value should be in terms of a ratio. 0.0 is the top and 1.0 is the bottom, 0.5 is the center. We must convert to this number when setting it and convert from it to use it to position the caption correctly.
}

/// This object holds various versions of a Question image after it has been picked but before it has been finalized and submitted for review. It allows the local user to undo changes in the zoom, crop and blur.
public struct imageBeingEdited {
    var iBEtitle: String
    var iBEcaption: Caption
    var iBEimageCleanUncropped: UIImage
    var iBEimageBlurredUncropped: UIImage
    var iBEimageBlurredCropped: UIImage
    var iBEContentOffset: CGPoint
    var iBEZoomScale: CGFloat
    
    /// deprecated
    var blursAdded: Bool = false
    
    /// TRUE when the image has been blurred, either manually or automatically.
    /// Compares the clean image to the one that holds blurs to determine whether they are different (i.e. blurred).
    var isBlurred: Bool {
        return !(iBEimageCleanUncropped == iBEimageBlurredUncropped)
    }
}
/// This enum helps the client keep track of which stage of Compare Question creation that it is currently in (using the compareBeingEdited object below).
public enum compareImageState: String {
    case noPhotoTaken          // state 0
    case firstPhotoTaken       // state 1
    case secondPhotoTaken      // state 2
    case reEditingFirstPhoto   // state 3
    case reEditingSecondPhoto  // state 4
}

/// This object is used to hold elements of a Compare before it is submitted for review, and to track which phase of creation it is in.
public struct compareBeingEdited {
    var isAsk: Bool
    var imageBeingEdited1: imageBeingEdited?
    var imageBeingEdited2: imageBeingEdited?
    var creationPhase: compareImageState = .noPhotoTaken //intializing here is kind of pointless, the auto generated intialiizer method forces us to store something new again to it anyway
}


// -----------------------------------------------------------------------------------
// MARK: BREAKDOWN
// The below functionality pertaining to the Breakdown object is currently not being used for anything. This was a very early way I organized review data. Feel free to either implement, modify, or delete.
// Here we set up the necessary structure to organize and store information about the breakdown of votes from various demographics

protocol hasOrientation {
    //  avgAge might not exist if there are no votes from that category yet
    var avgAge: Double? {get set}
    var numVotes: Int {get}
}

// These ask and compare demos almost seem to be depricated since we are using question now.
// They are semi-useful but unnecessary analyisis tools for the user.

// an AskDemo object represents a specifc demographic's numbers within an Ask's Breakdown
class AskDemo: hasOrientation {
    var avgAge: Double? = nil
    var rating: Double = 0.0
    var numVotes: Int = 0
    
}

// a CompareDemo object represents a specifc demographic's numbers within an Compare's Breakdown
class CompareDemo: hasOrientation {
    var avgAge: Double? = nil
    var votesForOne: Int = 0
    var votesForTwo: Int = 0
    var numVotes: Int {
        return votesForOne + votesForTwo
    }
}

// MARK: This object can be phased out but doing so will be a little tedious. 
/// All breakdown really does for us is give us the average age and number of votes. This was originally intended to provide much more information using reviews but has since been largely replaced by the consolidated compare and ask datasets.
struct Breakdown {
    
    let straightWomen: hasOrientation
    let straightMen: hasOrientation
    let gayWomen: hasOrientation
    let gayMen: hasOrientation
    
    // The total number of ratings or votes that this compare or ask has received
    var numVotes: Int {
        return straightMen.numVotes + straightWomen.numVotes +  gayWomen.numVotes + gayMen.numVotes
    }
    
    var avgAge: Double {
        // These are the components of the overall average age that each demographic makes up.
        // For example, if only straight people have rated the ask, the gay components will be zero
        // In this same case, if the avg straight man was 30 and the avg straight woman was 20
        // and there were an equal number of male and female raters, the value for
        // straightMenAverageAgeWeighted would be 15 (because 30*.5 = 15) and the value for
        // straightWomenAverageAgeWeighted would be 10 (because 20*.5 = 10) and
        // when we add all 4 components together at the end (10 + 15 + 0 + 0), we get 25, which is the correct answer
        let straightWomenAverageAgeWeighted: Double
        let straightMenAverageAgeWeighted: Double
        let gayWomenAverageAgeWeighted: Double
        let gayMenAverageAgeWeighted: Double
        
        // these if lets are necessary to unwrap avgAge which is optional
        if let swAA = straightWomen.avgAge {
            // this is actually a fraction, not a percentage because it is less than one
            // to technically be a percentage we would multiply this number by 100:
            let percentStraightWomen = Double(straightWomen.numVotes/self.numVotes)
            straightWomenAverageAgeWeighted = percentStraightWomen * swAA
        } else {
            // if the avgAge value for a demographic is nil, we store zero to the
            // straightWomenAverageAgeWeighted component because there are no votes from that demo.
            straightWomenAverageAgeWeighted = 0
        }
        if let smAA = straightMen.avgAge {
            let percentStraightMen = Double(straightMen.numVotes/self.numVotes)
            straightMenAverageAgeWeighted = percentStraightMen * smAA
        } else {
            straightMenAverageAgeWeighted = 0
        }
        if let gwAA = gayWomen.avgAge {
            let percentGayWomen = Double(gayWomen.numVotes/self.numVotes)
            gayWomenAverageAgeWeighted = percentGayWomen * gwAA
        } else {
            gayWomenAverageAgeWeighted = 0
        }
        if let gmAA = gayMen.avgAge {
            let percentGayMen = Double(gayMen.numVotes/self.numVotes)
            gayMenAverageAgeWeighted = percentGayMen * gmAA
        } else {
            gayMenAverageAgeWeighted = 0
        }
        
        return straightWomenAverageAgeWeighted + straightMenAverageAgeWeighted + gayWomenAverageAgeWeighted + gayMenAverageAgeWeighted
    }
    
}

/// Sets the user properties for firebase analytics so that we can sort our analytics data by these different categories.
/// Contains username, age, and orientation.
public func updateAnalyticsUserProperties() {
    // we also store the cohortID as a user property elsewhere in the code.
    
    let birthday: String = String(describing: getAgeFromBdaySeconds(myProfile.birthday))
    
    Analytics.setUserProperty(myProfile.username, forName: Constants.USERNAME_PROPERTY)
    Analytics.setUserProperty(birthday, forName: Constants.AGE_PROPERTY)
    Analytics.setUserProperty(myProfile.orientation, forName: Constants.ORIENTATION_PROPERTY)
}


/// remove / empty all collection related to question
/// called from logout button tap
/// ensures that when user log in using same/different id
/// it doesn't show cached data
public func resetQuestionRelatedThings(){
    
    rawQuestions.removeAll()
    filteredQuestionsToReview.removeAll()
    myActiveQuestions.removeAll() // we are removing realm on logout, no point of keeping this either
    questionReviewed.removeAll()
    questionOnTheScreen = nil
    seedQuestions.removeAll()
    
}



/// limit of search from firestore
public var searchLimit = 20
/// Min number of Questions to keep on the device to review at all times (firestore contents permitting).
public var minNumberOfQuestionsInReviewQueue = 8 // we need minimum x question always ready to go, always less than limit to avoid seeing blank

/// fetches Questions sent from the friends only
public func fetchQuestionFromFriends(action:  @escaping ()->Void){
    var query2 : Query! // for recipients key
    
    /// This query looks for Questions that were sent from a friend and that were not created by the localUser
    query2 = Firestore.firestore().collection(FirebaseManager.shared.getQuestionsCollection())
        .whereField(Constants.QUES_RECEIP_KEY, arrayContains: myProfile.username)
        .whereField(Constants.QUES_CREATOR, isNotEqualTo: myProfile.username)
    
    // for questions from friends
    query2.getDocuments { (snapshot, error) in
        defer{
            print("Exiting from Friends' Query: \(rawQuestions.count)")
            
            if rawQuestions.count >=  searchLimit{
                print("The entire review queue is filled with QFF's. Filtering questions from friends query.")
                filterQuestionsAndPrioritize {
                    print("FILTER DONE FROM QFF")
                    action()
                }
            }else{
                print("Not enough QFF, fetching normal (Questions from the community)")
                fetchQuestionsFromTheCommunity(passedRawQuestions: rawQuestions){
                    action()
                }
            }
        } // end of deferred actions
        
        // usual error handling
        if error != nil{
            print("An error occured while getting questions")
        }
        // process the data fetched by the QFF "Questions From Friends" query:
        if let snaps = snapshot?.documents{
            if snaps.count > 0 {
                print("Total questions from friends fetched: \(snaps.count)")
                
                for item in snaps{
                    let doc = item.data()
                    
                    // create a question object
                    let question = Question(firebaseDict: doc)
                    
                    if question.is_circulating == false{
                        print("Returning from question:\(question.question_name) not in circulation")
                        continue
                    }
                    
                    // to prevent already reviewed ones
                    if let _ = questionReviewed[question.question_name]{
                        print("This QFF is already reviewed and in qReviewed, not adding to raw")
                    }else{
                        // save to local db
                        rawQuestions.insert(question)
                    }
                    
                } // end of for loop of snaps
            }
            
        } // end if let processing data from QFF query
        
    } // end firestore (query2.getDocuments)
}


/// This function fetches Questions From the Community (QFC) for the local user to review.
public func fetchQuestionsFromTheCommunity(passedRawQuestions: Set<Question>,action: @escaping ()->Void){ //previously named 'fetchQuestion()'
    print("FETCHING QUESTION")
    var locallyScopedRawQuestions = passedRawQuestions
    var query : Query!
    
    // set the query based on pagination
    query = Firestore.firestore().collection(FirebaseManager.shared.getQuestionsCollection())
        .whereField(Constants.QUES_USERS_NOT_REVIEWED_BY_KEY, arrayContains: myProfile.username)
        .order(by: Constants.QUES_REVIEWS)
        .limit(to: searchLimit)
    
    // for other questions from the community that were not sent to localUser by his/her friends
    query.getDocuments { (snapshot, error) in
        defer{
            print("Exiting from Normal Query: \(rawQuestions.count)")
            filterQuestionsAndPrioritize {
                print("FILTER DONE")
                action()
            }
        }
        // usual error handling
        if error != nil{
            print("An error occured while fetching community questions from firestore")
        }
        
        if let snaps = snapshot?.documents{
            if snaps.count > 0 {
                print("Total number of questions fetched: \(snaps.count)")
                
                for item in snaps{
                    let doc = item.data()
                    
                    // create a question object
                    let question = Question(firebaseDict: doc)
                    
                    if question.creator.elementsEqual(myProfile.username) || !question.is_circulating {
                        print("Returning from question:\(question.question_name) created by me:\(question.creator.elementsEqual(myProfile.username)) or not in circulation:\(question.is_circulating == false) or by seed \(question.creator)")
                        continue
                    }

                    if question.creator == Constants.QUESTION_CREATOR_SEED {
                        seedQuestions.insert(question)
                        continue
                    }
                    
                    // to prevent already reviewed ones
                    if let q = questionReviewed[question.question_name]{
                        print("This question \(q) is already reviewed and in qReviewed, not adding to raw")
                    }else{
                        // save to local db
                        locallyScopedRawQuestions.insert(question)
                    }
                    
                } // end of for loop of snaps
                
                // snaps.count > 0 ends here
            }else{
                print("Got 0 question")
            }
            
        } // end if let processing data from QFC query
        rawQuestions = locallyScopedRawQuestions
    } // end firestore (query.getDocuments) closure
} // end fetchQuestionsFromTheCommunity()


public func getFilenameFrom(qName name: String, type questionType: QType,secondPhoto isSecondPhoto: Bool = false) -> String{
    
    // if it's photo of ask or 1st photo of Compare
    // then it is image 1
    
    if questionType == .ASK || !isSecondPhoto{
        
        return name+"_image_1.jpg"
        
    }else{
        
        return name+"_image_2.jpg"
        
    }
    
    
}


// for easy access
// https://us-central1-fir-poc-1594b.cloudfunctions.net/add_sample_questions
/// Checks and fetches question if required.
/// Called from MainVC (as well as BlueVC).
///

// MARK: Why is this not running while the user is reviewing?
public func checkForQuestionsToFetch(action: @escaping ()->Void){
    
    // check for question in data, if not enough, fetch more
    let questionCount = filteredQuestionsToReview.count //RealmManager.sharedInstance.getQuestionCount()
    
    print("checkForQuestionToFetch filteredQuestionsToReview: \(questionCount)")
    
    // only fetch new question when we do not have enough (right now: 5)
    
    if questionCount < minNumberOfQuestionsInReviewQueue {
        print("We have less than minimum \(minNumberOfQuestionsInReviewQueue) question => Fetching")
        
        // to fetch q from friends
        fetchQuestionFromFriends(){
            action()
        }
    }
    
}


/// This function will filter the questions as per the doc
/// Matches specialty first then ages.
public func filterQuestionsAndPrioritize(isFromLive: Bool = false, onComplete: () -> Void){
    
    
    print("Before filter we have \(rawQuestions.count) question in raw Q")
    // if we have 0 question, add the seeds if possible
    if rawQuestions.count == 0 {
        rawQuestions = seedQuestions
        seedQuestions.removeAll() // we remove the seed
    }
    

    
    var tempFilterQ = [PrioritizedQuestion]()
    
    // to reset the count so it doesn't add up old counts
    qFFCount = 0
    // load the ones matches specialty
    // check against my specialty
    for item in rawQuestions {
        
        // might look duplicate, but ensures that even if the question was in top, we have the count correct
        if item.recipients.contains(myProfile.username){
            qFFCount += 1
        }
        
        if let _ = questionReviewed[item.question_name]{
            // found one that we reviewed, so skip it
            print("Skipped FILTERING \(item.question_name) cause already reviewed")
            continue
        }
        
        // by any chance if we have question that's reviewed
        if !item.usersNotReviewedBy.contains(myProfile.username) && !item.recipients.contains(myProfile.username){
            print("Skipped FILTERING \(item.question_name) cause NO LIST contains my name")
            //RealmManager.sharedInstance.deleteQuestionItemForId(item.question_name)
            continue
        }
        
        
        if let qOS = questionOnTheScreen, item.question_name.elementsEqual(qOS.question.question_name){
            
                print("Question currently on Display \(item.question_name) Needs to on top, so -999")
                // we are reviewing this one
                // we'll add that later anyways
                continue
            
        }
        
        // make the question the toppest, no exception
        if item.recipients.contains(myProfile.username){
            // create a question with priority
            print("QFF \(item.question_name) added to list and move to next loop")
            let pq = PrioritizedQuestion()
            pq.question = item
            pq.priority = -99
            tempFilterQ.append(pq)
            continue
        }
        
        
        print("CONTINUE FILTERING \(item.question_name)")
        // check the num of reviews first
        let orientations = Constants.ORIENTATIONS
        var priorityStr = ""
        
        // check number of reviews
        
        if (item.reviews > 2){
            priorityStr.append("1")
        }else{
            priorityStr.append("0")
        }
        
        
        var speMatched = false
        
        //static let ORIENTATIONS = ["Straight Woman","Straight Man","Lesbian","Gay Man","Other"]
        switch myProfile.orientation {
        case orientations[0]:
            if item.targetDemo!.straight_woman_pref {
                speMatched = true
            }
            break
        case orientations[1]:
            
            if item.targetDemo!.straight_man_pref{
                speMatched = true
            }
            break
        case orientations[2]:
            if item.targetDemo!.gay_woman_pref {
                speMatched = true
            }
            break
        case orientations[3]:
            if item.targetDemo!.gay_man_pref {
                speMatched = true
            }
            break
        case orientations[4]:
            if item.targetDemo!.other_pref {
                speMatched = true
            }
            break
        default:
            print("Orientation getting default")
            speMatched = false
        } // end switch
        
        // add the spe matched question
        if !speMatched {
            priorityStr.append("1")
        }else{
            priorityStr.append("0")
        }
        
        // make the age from bday
        let cal = Calendar.current
        let ageComponent = cal.dateComponents([.year], from: Date(timeIntervalSince1970: myProfile.birthday), to: Date())
        let myAge = ageComponent.year!
        
        
        let ageDistance = ((abs(item.targetDemo!.min_age_pref - myAge) + (item.targetDemo!.min_age_pref-myAge)) / 2) + ((abs(myAge - item.targetDemo!.max_age_pref) + (myAge - item.targetDemo!.max_age_pref)) / 2)
        
        if ageDistance < 10 {
            priorityStr.append("0\(ageDistance)")
        }else{
            priorityStr.append("\(ageDistance)")
        }
        
        
        // add the number of reviews it got
        if item.reviews < 10{
            priorityStr.append("0\(item.reviews)")
        }else{
            priorityStr.append("\(item.reviews)")
        }
        
        
        // for the last one
        priorityStr.append(calcTimeSpent(item.created))
        
        // create a question with priority
        let pq = PrioritizedQuestion()
        pq.question = item
        pq.priority = Double.init(priorityStr)
        
        //RealmManager.sharedInstance.addOrUpdatePrioritizeQuestion(object: pq)
        tempFilterQ.append(pq)
        
    } // end of for loop of questionToReview
    
    
    // so when we're on live, we already have some unsolved question that we can't lose
    // as live only fetches question posted upto 5 mins ago
    // if we don't keep the filteredQTR, we'll lose them for this review
        
    // clear old items
    if !filteredQuestionsToReview.isEmpty && !isFromLive{
        filteredQuestionsToReview.removeAll()
    }else{
        // swap to question to tempFilterQ now, so existing questions gets filtered with newQ
        tempFilterQ.append(contentsOf: filteredQuestionsToReview)
        
        // create a set to get the unique question
        // it prevents duplicating items from live
        var tempSet = Set(tempFilterQ)
        // remove the old collection
        tempFilterQ.removeAll()
        // make temp unique
        tempFilterQ.append(contentsOf: tempSet)
        // remove the temp
        tempSet.removeAll()
        
        // now remove all
        filteredQuestionsToReview.removeAll()
    }
    
    // this line ensures that we have the question that we are seeing on top
    // on live we want to skip putting the top question again, because it's already in the filteredQTR
    if let displayedQuestion = questionOnTheScreen, !isFromLive {
        print("Adding Top Q to filteredQTR")
        filteredQuestionsToReview.append(displayedQuestion)
    }
   
   
   
    filteredQuestionsToReview.append(contentsOf: tempFilterQ.sorted{ $0.priority < $1.priority})

    
    // NOW DOWNLOAD IMAGES IN FIFO
    print("After filter we have \(filteredQuestionsToReview.count) filtered question")
    
    print("==== Printing Filtered DB ====")
    
    for item in filteredQuestionsToReview{
        print("\(item.question.question_name) \(String(describing: item.priority))")
        // Ask or Compare both has same name for first question, so download one regardless of the qType
        let storage = FirebaseStorage.Storage.storage()
        let gsReference1 = storage.reference(forURL: item.question.imageURL_1)

        //get the download url from gs url
        gsReference1.downloadURL { downloadUrl, downloadError in
            guard let downloadUrl = downloadUrl else {return}

            if ImageCache.default.isCached(forKey: downloadUrl.absoluteString) {
                print("Ask Image Already Downloaded for \(item.question.question_name)")
                return
            }


            KingfisherManager.shared.retrieveImage(with: ImageResource(downloadURL: downloadUrl)) { result in
                switch result {
                    case .success(_):
                        print("Ask Download Success: \(item.question.question_name)")
                    case .failure(let error):
                        print("Ask Download Failed: \(item.question.question_name) Error:\(error.localizedDescription)")
                }
            }
        }

        
        // Then check if it's compare so we may download the second image
        if item.question.type == .COMPARE {
            let gsReference2 = storage.reference(forURL: item.question.imageURL_2)
            //get the download url from gs url
            gsReference2.downloadURL { downloadUrl, downloadError in
                guard let downloadUrl = downloadUrl else {return}

                if ImageCache.default.isCached(forKey: downloadUrl.absoluteString) {
                    print("Compare Image Already Downloaded for \(item.question.question_name)")
                    return
                }

                KingfisherManager.shared.retrieveImage(with: ImageResource(downloadURL: downloadUrl)) { result in
                    switch result {
                        case .success(_):
                            print("Compare Download Success: \(item.question.question_name)")
                        case .failure(let error):
                            print("Compare Download Failed: \(item.question.question_name) Error:\(error.localizedDescription)")
                    }
                }
            }
        } // end .Compare check
    } // end for

    print("==== Finished Printing Filtered DB ====")
    
    tempFilterQ.removeAll()
    
    rawQuestions.removeAll()
    
    
    // return to the caller
    onComplete()
    
    
    
}

// add lockedQuestionCount += 1
// add toReview += 3

public func updateCountOnNewQues(){
    
    // if user have credits, we don't increase the locked count or obligatory count
    // instead we use the credit and reduce the credit itself
    // and firebase doesn't need to know about it, just make the question NOT LOCKED
    
    if myProfile.reviewCredits >= obligatoryReviewsPerQuestion {
        // we decreased the credit
        decreaseCreditFromUser(by: obligatoryReviewsPerQuestion)
        // now we update firebase and local collection
        unlockMyLocalQuestion()
        
        
    }else {
        lockedQuestionsCount += 1
        obligatoryQuestionsToReviewCount += obligatoryReviewsPerQuestion
        
        // these lines may be redundant now since inside of updateNumLockedQuestionsInFirestore, we update obligatoryQuestionsToReviewCount (and by method call obligatoryQuestionsToReviewCount)
        //    prefs.set(lockedQuestionsCount, forKey: Constants.UD_LOCKED_QUESTION_KEY)
        //    prefs.set(obligatoryQuestionsToReviewCount, forKey: Constants.UD_QUESTION_TO_REVIEW_KEY)
        
        
        // add to firebase as well
        updateNumLockedQuestionsInFirestore()
        
        //    Firestore.firestore()
        //    .collection(FirebaseManager.shared.getUsersCollection())
        //        .document(myProfile.username)
        //    .collection(Constants.USERS_PRIVATE_SUB_COLLECTION)
        //        .document(Constants.USERS_PRIVATE_INFO_DOC).updateData([
        //            Constants.UD_LOCKED_QUESTION_KEY : FieldValue.increment(Int64(1)),
        //            Constants.UD_QUESTION_TO_REVIEW_KEY: FieldValue.increment(Int64(obligatoryReviewsPerQuestion)),
        //        ])
        //
    }
}

// add lockedQuestionCount -= 1
// add toReview -= 3

public func updateCountOnDeleteQuestion(){
    
    
    lockedQuestionsCount -= 1
    obligatoryQuestionsToReviewCount -= obligatoryReviewsPerQuestion
    
    
    // these lines may be redundant now since inside of updateNumLockedQuestionsInFirestore, we update obligatoryQuestionsToReviewCount (and by method call obligatoryQuestionsToReviewCount)
    //    prefs.set(lockedQuestionsCount, forKey: Constants.UD_LOCKED_QUESTION_KEY)
    //    prefs.set(obligatoryQuestionsToReviewCount, forKey: Constants.UD_QUESTION_TO_REVIEW_KEY)
    
    
    // add to firebase as well
    updateNumLockedQuestionsInFirestore()
    
    //    Firestore.firestore()
    //        .collection(FirebaseManager.shared.getUsersCollection())
    //        .document(myProfile.username)
    //        .collection(Constants.USERS_PRIVATE_SUB_COLLECTION)
    //        .document(Constants.USERS_PRIVATE_INFO_DOC).updateData([
    //            Constants.UD_LOCKED_QUESTION_KEY : FieldValue.increment(Int64(-1)),
    //            Constants.UD_QUESTION_TO_REVIEW_KEY: FieldValue.increment(Int64(-obligatoryReviewsPerQuestion)),
    //        ])
    
}

/// called when user reviews any question
public func updateCountOnReviewQues(){
    // User review, no matter the result, update the time first
    updateLastReviewedTime()
    
    if lockedQuestionsCount <= 0 /*|| questionsToReviewCount <= 0*/{
        // MARK: This is part of the lockedQuestionsCount problem
        lockedQuestionsCount = 0
        obligatoryQuestionsToReviewCount = 0
        // credit a review
        increaseCreditToUser(by: 1)
        
        updateNumLockedQuestionsInFirestore()
        incrementTotalUserNumReviewsInFirestore()
        return
    }
    print("Updating Count")
    
    //    let prefs = UserDefaults.standard
    
    obligatoryQuestionsToReviewCount -= 1
    
    //    prefs.set(obligatoryQuestionsToReviewCount, forKey: Constants.UD_QUESTION_TO_REVIEW_KEY)
    
    // additional criteria added to ensure there are questions to unlock, and questions at all.
    if obligatoryQuestionsToReviewCount % obligatoryReviewsPerQuestion == 0 && /*obligatoryQuestionsToReviewCount > 0 &&*/ myActiveQuestions.count > 0 {
        // he just unlocked one question
        lockedQuestionsCount -= 1
        //        prefs.set(lockedQuestionsCount, forKey: Constants.UD_LOCKED_QUESTION_KEY)
        // lockedQues = 5, toRev = 15
        // locked = 4, toRev = 12 => total = 6
        // need the 1th index now
        // total - locked = 2nd Question
        // 2nd Question index = 1
        unlockMyLocalQuestion()
        
    }
    
    // add to firebase as well
    updateNumLockedQuestionsInFirestore()
    incrementTotalUserNumReviewsInFirestore()
    
}

func unlockMyLocalQuestion(){
    let quesToUpdateIndex = (myActiveQuestions.count - lockedQuestionsCount) - 1
    
    // also unlock the question in firebase
    if let question = myActiveQuestions[quesToUpdateIndex].question{
        print("Unlocking question \(question.question_name)")
        
        //unlock the question locally:
        myActiveQuestions[quesToUpdateIndex].question.isLocked = false
        
        //unlock the question on the server:
        Firestore.firestore()
            .collection(FirebaseManager.shared.getQuestionsCollection())
            .document(question.question_name).updateData([
                "isLocked":false
            ])
    }
}

/// called from updateCountOnReviewQues, when locked question is zero, so we give him credit
func increaseCreditToUser(by credit: Int){
    print("Credit Added by \(credit)")
    // increase online
    Firestore.firestore()
        .collection(FirebaseManager.shared.getUsersCollection())
        .document(myProfile.username).updateData([
            Constants.USER_CREDIT_KEY:FieldValue.increment(Int64(credit))
        ])
    
    // increase online
    let creditNow = myProfile.reviewCredits
    let realm = try! Realm()
    do{
        try realm.write {
            myProfile.reviewCredits = (creditNow+credit)
        }
    } catch let error as NSError{
        print(error.localizedDescription)
    }
    
    // Log Analytics Event
    Analytics.logEvent(Constants.REVIEW_CREDIT_EARNED, parameters: nil)
}

// calling this function will update the field
func updateLastReviewedTime(){
    
    Firestore.firestore()
        .collection(FirebaseManager.shared.getUsersCollection())
        .document(myProfile.username).updateData([
            Constants.USER_LAST_REVIEWED_KEY: FieldValue.serverTimestamp()
        ])
    
}


// should minus credit from user in any instances
func decreaseCreditFromUser(by credit: Int){
    print("Credit Removed by \(credit)")
    // decrease online
    Firestore.firestore()
        .collection(FirebaseManager.shared.getUsersCollection())
        .document(myProfile.username).updateData([
            Constants.USER_CREDIT_KEY:FieldValue.increment(Int64(-credit))
        ])
    // decrease local
    let creditNow = myProfile.reviewCredits
    let realm = try! Realm()
    do{
        try realm.write {
            myProfile.reviewCredits = (creditNow-credit)
        }
    } catch let error as NSError{
        print(error.localizedDescription)
    }
    
}

/// Adds +1 to the user's review count in firestore. Called from updateCountOnReviewQues() here in DataModels. 
public func incrementTotalUserNumReviewsInFirestore() {
    //increment on the server
    Firestore.firestore()
        .collection(FirebaseManager.shared.getUsersCollection())
        .document(myProfile.username).updateData([
            Constants.USER_REVIEW_KEY:FieldValue.increment(Int64(1))
        ])
    //increment on the client
    //    let prefs = UserDefaults.standard
    //    prefs.
    //    Constants.USER_REVIEW_KEY
    let reviewsIveDone = myProfile.reviews
    let profileToUpdate = RealmManager.sharedInstance.getProfile()
    
    do {
        let database = try Realm()
        database.beginWrite()
        profileToUpdate.reviews = reviewsIveDone + 1
        database.add(profileToUpdate, update: .modified)
        
        try database.commitWrite()
    } catch {
        print("Error occured while updating realm")
    }
    
    
    //example:
    //    Firestore.firestore()
    //        .collection(FirebaseManager.shared.getUsersCollection())
    //        .document(myProfile.username)
    //        .collection(Constants.USERS_PRIVATE_SUB_COLLECTION)
    //        .document(Constants.USERS_PRIVATE_INFO_DOC).updateData([
    //            Constants.UD_LOCKED_QUESTION_KEY : FieldValue.increment(Int64(-1)),
    //            Constants.UD_QUESTION_TO_REVIEW_KEY: FieldValue.increment(Int64(-obligatoryReviewsPerQuestion)),
    //        ])
    
    
    
    
    
}

/// sync's the local values of lockedQuestionsCount and questionsToReviewCount internally, and then to the server
public func updateNumLockedQuestionsInFirestore() {
    syncObligatoryQuestionsToReviewCount()
    Firestore.firestore()
        .collection(FirebaseManager.shared.getUsersCollection())
        .document(myProfile.username)
        .collection(Constants.USERS_PRIVATE_SUB_COLLECTION)
        .document(Constants.USERS_PRIVATE_INFO_DOC).setData([
            Constants.UD_LOCKED_QUESTION_KEY : lockedQuestionsCount,
            Constants.UD_QUESTION_TO_REVIEW_KEY: obligatoryQuestionsToReviewCount,
        ],merge: true)
}

/// Counts the number of locked questions in myActiveQuestions and stores that value to lockedQuestionsCount to ensure they are the same
public func syncLockedQuestionsCount() {
    print("syncing locked questions count")
    let prefs = UserDefaults.standard
    var countedLockedQuestions = 0
    for question in myActiveQuestions {
        if question.question.isLocked {
            print("locked Question found: \(question.question.question_name)")
            countedLockedQuestions += 1
        }
    }
    //ensures this number never falls below 0
    if countedLockedQuestions < 0 {
        lockedQuestionsCount = 0
        prefs.set(lockedQuestionsCount,forKey: Constants.UD_LOCKED_QUESTION_KEY)
    } else {
        lockedQuestionsCount = countedLockedQuestions
        prefs.set(lockedQuestionsCount,forKey: Constants.UD_LOCKED_QUESTION_KEY)
    }
    print("number of locked questions found: \(lockedQuestionsCount)")
    
    // I'm not 100% whether we should be using these lines too or if the above functionality performs the same functions sicne those properties of Constants seem to be {get set}
    // same uncertainty goes for syncObligatoryQuestionsToReviewCount()
    //    prefs.set(lockedQuestionsCount, forKey: Constants.UD_LOCKED_QUESTION_KEY)
    //    prefs.set(obligatoryQuestionsToReviewCount, forKey: Constants.UD_QUESTION_TO_REVIEW_KEY)
}

/// Resets the obligatoryQuestionsToReviewCount to the right number using the number of locked questions left, and the remaining reviews required to unlock the next question
public func syncObligatoryQuestionsToReviewCount() {
    // Check and apply reviewCredits
    applyReviewCredits()
    
    print("synching obligatory questions to review count. calling syncLockedQuestionsCount()")
    syncLockedQuestionsCount()
    print("syncLockedQuestionsCount() complete. Back inside syncObligatoryQuestionsToReviewCount() now.")
    let prefs = UserDefaults.standard
    
    var obligatoryReviewsToUnlockNextQuestion = obligatoryQuestionsToReviewCount % obligatoryReviewsPerQuestion
    if obligatoryReviewsToUnlockNextQuestion <= 0 && lockedQuestionsCount > 0 {
        obligatoryReviewsToUnlockNextQuestion = obligatoryReviewsPerQuestion
    } else if lockedQuestionsCount <= 0 {
        print("No more locked Questions. Setting obligatoryReviewsToUnlockNextQuestion to 0")
        obligatoryReviewsToUnlockNextQuestion = 0
    }
    
    print("obligatoryReviewsToUnlockNextQuestion calculated to be \(obligatoryReviewsToUnlockNextQuestion)")
    
    let valueToUpdateWith = ((lockedQuestionsCount - 1) * obligatoryReviewsPerQuestion) + obligatoryReviewsToUnlockNextQuestion
    if valueToUpdateWith < 0 {
        obligatoryQuestionsToReviewCount = 0
        prefs.set(obligatoryQuestionsToReviewCount, forKey: Constants.UD_QUESTION_TO_REVIEW_KEY)
    } else {
        obligatoryQuestionsToReviewCount = valueToUpdateWith
        prefs.set(obligatoryQuestionsToReviewCount, forKey: Constants.UD_QUESTION_TO_REVIEW_KEY)
    }
    print("obligatoryQuestionsToReviewCount calculated to be \(obligatoryQuestionsToReviewCount). \nend of syncObligatoryQuestionsToReviewCount()")
}

// this function checks the reviewCredits user has and unlocks questions accordingly
public func applyReviewCredits(){
    let userCredits = myProfile.reviewCredits
    
    if userCredits < obligatoryReviewsPerQuestion {
        // if we have less than what we need, no need to proceed
        return
    }else{
        // unlock some questions if we have
        if lockedQuestionsCount > 0 {
            let numberOfQuestionCanBeUnlocked = userCredits % obligatoryReviewsPerQuestion
            // reduce locked question
            lockedQuestionsCount -= numberOfQuestionCanBeUnlocked
            // reduce the obligatoryQues
            obligatoryQuestionsToReviewCount -= (numberOfQuestionCanBeUnlocked * obligatoryReviewsPerQuestion)
            // we used credits, so update it as well
            decreaseCreditFromUser(by: numberOfQuestionCanBeUnlocked * obligatoryReviewsPerQuestion)
        }
        
    }
}


// to fetch question I made

public func fetchActiveQuestions(completion: @escaping ([ActiveQuestion]?, Error?) -> Void ){
    
    var tempActiveQuestions = [ActiveQuestion]()
    
    let dg = DispatchGroup()
    
    Firestore.firestore().collection(FirebaseManager.shared.getQuestionsCollection())
        .whereField(Constants.QUES_CREATOR, isEqualTo: myProfile.username)
        .order(by: Constants.USER_CREATED_KEY,descending: false)
        .getDocuments { snapshots, error in
            
            if error != nil{
                
                completion(nil, error)
            }
            
            if let snaps = snapshots?.documents{
                if snaps.count > 0 {
                    print("Total my question fetched \(snaps.count)")
                    for item in snaps{
                        
                        
                        let doc = item.data()
                        // create a question object
                        let question = Question(firebaseDict: doc)
                        
                        tempActiveQuestions.append(ActiveQuestion(question: question))
                        // try fetching the review here as well
                        dg.enter()
                        fetchReviewFor(question) { q, e in
                            // do anything?
                            dg.leave()
                        }
                        
                        dg.enter()
                        // we are checking if we had these image saved already, if not, we'll download

                        let storage = FirebaseStorage.Storage.storage()
                        let gsReference1 = storage.reference(forURL: question.imageURL_1)

                        //get the download url from gs url
                        gsReference1.downloadURL { downloadUrl, downloadError in
                            guard let downloadUrl = downloadUrl else {return}
                            KingfisherManager.shared.retrieveImage(with: ImageResource(downloadURL: downloadUrl)) { result in
                                dg.leave()
                            }
                        }

                        
                        if question.type == .COMPARE {

                            dg.enter()
                            let gsReference2 = storage.reference(forURL: question.imageURL_2)
                            //get the download url from gs url
                            gsReference2.downloadURL { downloadUrl, downloadError in
                                guard let downloadUrl = downloadUrl else {return}
                                KingfisherManager.shared.retrieveImage(with: ImageResource(downloadURL: downloadUrl)) { result in
                                    dg.leave()
                                }
                            }

                            
                        } // end of ask compare
                        
                        
                    } // end for loop
                    // we'll filter the soft criteria now
                    
                    // this prevents blank screen while we load
                    // good for us
                    
                    // if temp and already fetched size is same, no update.
                    // cause all we are doing is just fetching active question

                    // With recent updates to our Questions and Admin App, I commented out this condition
                    // so whenever a change is made, we get that. Also, if a new question is posted and a old one
                    // gets removed, this condition might prevent that since the count will remain the same.
                    // Checked this one, by playing with is_circulating field. Looks good
                    // MM : March 28, 2023

                    //if myActiveQuestions.count != tempActiveQuestions.count {
                        print("Updating Active question")
                        if myActiveQuestions.count > 0 {
                            myActiveQuestions.removeAll()
                        }
                        myActiveQuestions = tempActiveQuestions
                        tempActiveQuestions.removeAll()
                        
                    //}
                    
                    // update or not check the locked status
                    for ques in myActiveQuestions{
                        let numToU = reviewsRequiredToUnlock(question: ques.question)
                        
                        if numToU == 0 {
                            // it's unlocked
                            ques.question.isLocked = false
                        }
                        
                    }
                    
                    // when all dg has done the work, then we'll return to caller, mainly AQVC
                    // cause we need with updated review in questions
                    dg.notify(queue: .main){
                        // call the caller
                        completion(myActiveQuestions,nil)
                    }
                    
                    
                } // end snaps.count > 0
                else{
                    // both are nil now, no error plus no data
                    
                    completion(nil,nil)
                    
                }
                
            } // end snap.docs
            
            
        } // end firebasecheckForQuestionToFetch questionCount: 7
} // end fetch active


func fetchReviewFor(_ question: Question, completion: @escaping ([ActiveQuestion]?, Error?) -> Void){
    
    downloadReviewCollection(for: question.question_name, questionType: question.type == .ASK ? .ask : .compare) { qCollection, error in
        
        if let error = error{
            completion(nil, error)
        }
        
        if let reviewCollection = qCollection, let id = index(of: question.question_name, in: myActiveQuestions){
            print("Refreshed Review Collection")
            myActiveQuestions[id].reviewCollection = reviewCollection
            completion(myActiveQuestions,nil)
        } // end if let check
        
        
    }// end function call
    
} // end download Reviews for


/// Takes a questionName, locates that Question's 'reviews' collection in firestore, downloads all the collection's documents, converts them to reviews, and returns an optional ReviewCollection object.
func downloadReviewCollection(for questionName: String, questionType: askOrCompare, completion: @escaping (ReviewCollection?, Error?) -> Void) {
    var reviewList: [isAReview] = []
    let dispatchGroup = DispatchGroup()
    
    // MARK: A query here that only downloads reviews that we don't already have in memory would be helpful
    
    // download reviewcollection from the specific path
    let _: Void = Firestore.firestore().collection(FirebaseManager.shared.getQuestionsCollection()).document(questionName).collection(Constants.QUES_REVIEWS).getDocuments { (snapshot, error) in
        if let error = error {
            completion(nil, error)
        } else if let snapshot = snapshot {
            
        
        snapshotLoop: for doc in snapshot.documents {
            dispatchGroup.enter()
            
            
            // I'm pondering the guard-let increase in robstness here, since these are reviews that have already been performed on the question, the only variables that really matter are the selection, and the info relating to target demo (and to a lesser extent reviewer rating - which will come into play more when we start incorporating this into how much the review is weighted based on who reviews it).
            // The simplest way to handle this is to just eliminate the whole review if it has a download issue. A more sophisticated solution would be a guard-let on each property. Maybe that can come later.
            
            // MARK: These field stores and those like them need to be converted to unwrapping methods to prevent crashes
            guard let qN = doc.get("questionName") as? String,
                  let c = doc.get("comments") as? String,
                  let rUN = doc.get("reviewerUserName") as? String,
                  let rDN = doc.get("reviewerDisplayName") as? String,
                  let rPPU = doc.get("reviewerProfilePictureURL") as? String,
                  !rPPU.isEmpty, // it was our crash, need to make sure it exists
                  let rBTS = doc.get("reviewerBirthday") as? Int64,
                  let rO =  doc.get("reviewerOrientation") as? String, // "string Reviewer Orientation"
                  let _ = doc.get("reviewerSignUpDate") as? Int64,
                  let rRR = doc.get("reviewerReviewsRated") as? Int,
                  //let rA = doc.get("reviewerAverage") as? Double, // maybe bring this back later
                  let rS = doc.get("reviewerScore") as? Double,
                  let selection = doc.get("selection") as? String
                    
            else {print("unwrapped a nil optional field in the review after downloading. Skipping this review for questionName: \(questionName)")
                dispatchGroup.leave();
                continue }
            
            // For some reason we were having issues with this reviewer average property coming up as nil.
            //   This will need to be addressed at some point.
            //                var rA: Double //reviewer average
            //                if let ra = doc.get("reviewerAverage") as? Double {
            //                    rA = ra
            //                } else {
            //                    print("The reviewerAverage was nil for a review by \(rUN) for questionID: \(questionName). Setting default rA of 2.5 for this review.")
            //                    rA = 2.5
            //                }
            
            //let rO = textToOrientation(userDemo:sRO) //converts the string to an enum. If it doesn't match, defaults to SW
            
            
            // If either of these cases are true, the selection string literal is not one of the enum options and the review is essentially worthless.
            // Therefore, in either case, we break out of the loop and go back up to the top without creating and appending a review from this document.
            switch questionType {
            case .ask:
                if !(selection == "yes" || selection == "no") {
                    dispatchGroup.leave()
                    continue
                }
            case .compare:
                if !(selection == "top" || selection == "bottom") {
                    dispatchGroup.leave()
                    continue
                }
            }
            
            // Image download request for the reviewing user's profile picture:
            //let imageRef = Storage.storage().reference(forURL: rPPU)
            
            //imageRef.getData(maxSize: 2 * 1024 * 1024) { data, err in
                var profileImageToReturn: UIImage
                var reviewer: Profile
                let reviewToAppend: isAReview
                
                //if let err = err {
                    
                    if let nilImage = UIImage(named: "tangerineImage2") {
                        profileImageToReturn = nilImage
                        reviewer = Profile(
                            pid: 0,
                            birthday: Double(rBTS),
                            display_name: rDN,
                            username: rUN,
                            profile_pic: rPPU,
                            reviews: rRR,
                            rating: rS,
                            created: 0,
                            orientation: rO,
                            phone_number: "0",
                        isSeeder: false)
#warning("We're forcing seeder as false here, reviewer shouldn't be a seeder")
                        
                        
                        switch questionType {
                        case .ask:
                            // strong is normally an optional enum but we pass it as a string and let the initializer handle that
                            let strong = doc.get("strong") as! String
                            reviewToAppend = AskReview(selection: selection, strong: strong, reviewer: reviewer, comments: c, questionName: qN)
                            
                        case .compare:
                            let strongYes = doc.get("strongYes") as! Bool
                            let strongNo = doc.get("strongNo") as! Bool
                            reviewToAppend = CompareReview(selection: selection, strongYes: strongYes, strongNo: strongNo, reviewer: reviewer, comments: c, questionName: qN)
                        }
                        reviewList.append(reviewToAppend)
                        
                    }
                    dispatchGroup.leave()
                    //completion(nil, err)
//                } else if let data = data {
//                    if let unwrappedImage = UIImage(data: data) {
//                        profileImageToReturn = unwrappedImage
//                        reviewer = Profile(
//                            pid: 0,
//                            birthday: Double(rBTS),
//                            display_name: rDN,
//                            username: rUN,
//                            profile_pic: rPPU,
//                            reviews: rRR,
//                            rating: rS,
//                            created: 0,
//                            orientation: rO,
//                            phone_number: "0")
//                        switch questionType {
//                        case .ask:
//                            // strong is normally an optional enum but we pass it as a string and let the initializer handle that
//                            let strong = doc.get("strong") as! String
//                            reviewToAppend = AskReview(selection: selection, strong: strong, reviewer: reviewer, comments: c, questionName: qN)
//
//                        case .compare:
//                            let strongYes = doc.get("strongYes") as! Bool
//                            let strongNo = doc.get("strongNo") as! Bool
//                            reviewToAppend = CompareReview(selection: selection, strongYes: strongYes, strongNo: strongNo, reviewer: reviewer, comments: c, questionName: qN)
//                        }
//                        reviewList.append(reviewToAppend)
//
//                    }
//                    dispatchGroup.leave()
//                }
                
//            } //end of imageRef.getData closure
            
        } // end of for loop
            
            dispatchGroup.notify(queue: .main) {
                
                let reviewCollectionToBeReturned: ReviewCollection = ReviewCollection(reviewList: reviewList, type: questionType)
                
                completion(reviewCollectionToBeReturned, nil)
                
            }
        } // end of snapshot unwrap
    } // end of query completion handler
    
    // Overview of what the above 'downloadReviewCollection' method does in order:
    // - find out the type of ReviewCollection it is (ask or compare)
    // - declare and initialize a new array of the type of Reviews
    // - loop through the documents
    // - download all the elements common to both types of reviews
    // - switch case on reviewCollection type
    // - download remaining elements unique to type
    // - create Review using initializer method
    // - append newReview to the array
} // end of downloadReviewCollection(for questionName)




public func reviewsRequiredToUnlock(question: Question) -> Int {
    
    // if obligatory reviews accidentally got below zero, just set it to 0:
    if obligatoryQuestionsToReviewCount < 0 { obligatoryQuestionsToReviewCount = 0}
    
    // if obligatoryReviewsToUnlockNextQuestion is 0 or less, but we still have at least one locked question, reset obligatoryReviewsToUnlockNextQuestion to one so we don't end up with a tableView row that says "review 0 pictures to unlock this question."
    if lockedQuestionsCount > 0 && obligatoryQuestionsToReviewCount < 1 {
        obligatoryQuestionsToReviewCount = 1
    }
    
    //first see if the question is locked or not
    if !question.isLocked {
        //if the question is not locked, there are zero reviews required to unlock it.
        return 0
    }
    
    // tells how many reviews user has to do before getting access to a specific Question's review results
    //let theseLockedQuestionNames = self.privateInfo.lockedQuestionNames
    
    guard let indexOfQuestionName = index(of: question.question_name, in: myActiveQuestions) else {
//        print("returning zero in reviewsRequiredToUnlock because questionName: \(question.question_name) with title was not found in the lockedQuestionNames list.") // print statement is depricated
        
        return 0 //in this case, the container is not in the list and is therefore already unlocked. We return 0 to indicate that. // comment deprecated
    }
    // locked = 5, to unlock = 15
    // active = 7
    // so unlocked ones are 0, 1
    // find 0 and 1 here
    // 7 - 5 = 2 questions
    
    
    let unlockedQuestionsCount = (myActiveQuestions.count - lockedQuestionsCount)
    
    // index - un gives a number
    // my calculation shows if that result is below zero, then it's an unlocked question
    // else just do the math
    
    // each set of obligatoryReviewsPerQuestion has 3 now
    // so when do 1/2 of them, we need to minus them.
    // find how many done in current chunk
    let reviewDoneInChunk = (lockedQuestionsCount * obligatoryReviewsPerQuestion) - obligatoryQuestionsToReviewCount
    
    
    let result = indexOfQuestionName - unlockedQuestionsCount
    
    if result < 0 {
        return 0
    }else{
        // for index 2, when I have 2 un que,
        //      3 * 0 + 3 = 3 should be
        return ((obligatoryReviewsPerQuestion * result) + obligatoryReviewsPerQuestion - reviewDoneInChunk)
    }
    
} // end reviewReqToUnlock

public func updateQFFFromServer(with username: String = "") {


  Firestore.firestore()
    .collection(FirebaseManager.shared.getUsersCollection())
    .document(username.isEmpty ? myProfile.username : username)
    .collection(Constants.USERS_PRIVATE_SUB_COLLECTION)
    .document(Constants.USERS_PRIVATE_INFO_DOC)
    .addSnapshotListener({ snapshot, error in
      if snapshot != nil && error == nil {
        qFFCount = snapshot?["qff_count"] as? Int ?? 0
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.QFF_NOTI_NAME), object: nil)
      }
    })

}

// New Func for qff_count and fr_count on firebase
// doesn't have to exist in local db or elsewhere on client

public func increaseQFFCountOf(username name: String){
    Firestore.firestore()
        .collection(FirebaseManager.shared.getUsersCollection())
        .document(name)
        .collection(Constants.USERS_PRIVATE_SUB_COLLECTION)
        .document(Constants.USERS_PRIVATE_INFO_DOC)
        .updateData([
            Constants.USER_QFF_COUNT_KEY: FieldValue.increment(Int64(1)),
            Constants.USER_QFF_FROM_KEY: myProfile.display_name
        ]){ error in
            
            if error == nil {
                print("Added QFF Count to \(name)")
            }
            
        }
    
}

public func decreaseQFFCountOf(username name: String){
    Firestore.firestore()
        .collection(FirebaseManager.shared.getUsersCollection())
        .document(name)
        .collection(Constants.USERS_PRIVATE_SUB_COLLECTION)
        .document(Constants.USERS_PRIVATE_INFO_DOC)
        .updateData([
            Constants.USER_QFF_COUNT_KEY: FieldValue.increment(Int64(-1)),
        ]){ error in
            
            if error == nil {
                print("Removed QFF Count to \(name)")
            }
            
        }
    
}

public func increaseFRCountOf(username name: String){
    Firestore.firestore()
        .collection(FirebaseManager.shared.getUsersCollection())
        .document(name)
        .collection(Constants.USERS_PRIVATE_SUB_COLLECTION)
        .document(Constants.USERS_PRIVATE_INFO_DOC)
        .updateData([
            Constants.USER_FR_COUNT_KEY: FieldValue.increment(Int64(1)),
            Constants.USER_FR_FROM_KEY: myProfile.username
        ]){ error in
            
            if error == nil {
                print("Added FR Count to \(name)")
            }
        }
}

public func decreaseFRCountOf(username name: String){
    Firestore.firestore()
        .collection(FirebaseManager.shared.getUsersCollection())
        .document(name)
        .collection(Constants.USERS_PRIVATE_SUB_COLLECTION)
        .document(Constants.USERS_PRIVATE_INFO_DOC)
        .updateData([
            Constants.USER_FR_COUNT_KEY: FieldValue.increment(Int64(-1))
        ]){ error in
            
            if error == nil {
                print("Removed FR Count to \(name)")
            }
        }
}


/// called from MainVC, FriendRequestVC and Where we answer a q from friend, probably here 
public func updateBadgeCount(){
    
    var totalBadge = qFFCount + friendReqCount
    if totalBadge < 0 {totalBadge = 0}
    UIApplication.shared.applicationIconBadgeNumber = totalBadge
    print("Updated badge count to: \(totalBadge)")
}


public func resetLocalAndRealmDB(){
    // update the user defaults
    print("resetLocalAndRealmDB() called")
    
    if let appDomain = Bundle.main.bundleIdentifier {
        UserDefaults.standard.removePersistentDomain(forName: appDomain)
    }
    UserDefaults.standard.synchronize()
    
    
    do {
        let database = try Realm()
        database.beginWrite()
        database.deleteAll()
        try database.commitWrite()
        
        
    } catch {
        print("Error occured while updating realm")
    }
    
    print("successfully reached end of resetLocalAndRealmDB() instructions")
}

/// Reports are objects created in a Question's reportCollection when reviewing Users flag the Question for negative content.
//public func sendMLReport(for type: reportType, of questionName: String) {
//
//    print("Sending ml report")
//    Firestore.firestore().collection(FirebaseManager.shared.getQuestionsCollection()).document(questionName)
//            .updateData([
//                "reportList.\(type.rawValue)" :  FieldValue.increment(Int64(1))
//            ])
//}

public func sendReport(for type: reportType, of questionName: String) {

    Firestore.firestore().collection(FirebaseManager.shared.getQuestionsCollection()).document(questionName)
        .updateData([
            "reportList.\(type.rawValue)" :  FieldValue.increment(Int64(1))
            ])
}

