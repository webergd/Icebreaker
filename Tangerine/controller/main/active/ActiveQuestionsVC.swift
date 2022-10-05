//
//  ActiveQuestionsVC.swift
// MARK: This file needs a more accurate name -> it holds Asks and Compares
//  A better name is QuestionsTableViewController
//
//  Created by Wyatt Weber on 7/14/16.
//  Copyright © 2016 Insightful Inc. All rights reserved.
//

import UIKit
import Firebase

// This class has known memory leak issues. As of now we call self.view.window?.rootViewController?.dismiss(animated: true, completion: nil) when returning to main. This is not a perfect fix and still results in high memory usage (about 250 to 400).

var pullControl : UIRefreshControl! // for our pull2Refresh

///This really should be called QuestionTableViewController because it's the main table view that holds the local user's Asks AND Compares
///
class ActiveQuestionsVC: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        //allows the row height to resize to fit the autolayout constraints
        tableView.rowHeight = UITableView.automaticDimension
        //it won't necessarily follow this exact value, it's just an estimate that's required for the above line to work:
        tableView.estimatedRowHeight = 200

        // enables swipe navigation
        let swipeViewGesture = UISwipeGestureRecognizer(target: self, action: #selector(ActiveQuestionsVC.userSwiped))
        tableView.addGestureRecognizer(swipeViewGesture)
  
        // Default unused options that came with the Class:
        // Uncomment the following line to preserve selection between presentations:
        // self.clearsSelectionOnViewWillAppear = false
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller:
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        

    }
    
    // refreshes the active list
    @objc private func refreshActiveQuestion(){
        tableView.refreshControl?.beginRefreshing()
        fetchActiveQuestions { questions, error in
            self.tableView.reloadData()
            self.tableView.refreshControl?.endRefreshing()
            print("Refreshed ActiveQ")
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        print("AP View did appear")
        
        // the P2R
        pullControl = UIRefreshControl()
        pullControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        pullControl.addTarget(self, action: #selector(refreshActiveQuestion), for: .valueChanged)
        tableView.refreshControl = pullControl
        addTitleToVC()
       
        // refresh reviews from firebase
        
        if myActiveQuestions.count > 0 {
            
            print("AP VDA count \(myActiveQuestions.count)")
            // get the reviews now
            refreshActiveQuestion()
            
            // let's show how to dismiss the view now
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { // `0.7` is the desired number of seconds.
                self.showHelpSwipeToReturnPopover()
            }
            
        }else{
            self.showNoMoreQuestions("No active Questions. Tap the camera icon to upload a photo to be reviewed!")
        }
        
        // commented this out because Realm only gets updated in the FriendsVC, and the user may not have loaded that view yet. So Realm will still show no usernames in myFriendList.
//        // update the local friend names list so that we can determine whether we are friends with reviewers to count their reviews in the correct displays. 
//        fetchMyFriendNamesFromRealm()
        
    } // end view did appear
    
    
    /// displays a popover animation explaining to the member how to dismiss the tableview by swiping right
    func showHelpSwipeToReturnPopover(){
        
        let didTappedDontShowAgainOnAlert = UserDefaults.standard.bool(forKey: Constants.UD_VIEW_RESULT_ALERT_PREF)
        
        if !didTappedDontShowAgainOnAlert {
            // Load Storyboard
            let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            // Instantiate View Controller
            let controller = storyboard.instantiateViewController(withIdentifier: "swipe_to_right_vc") as! SwipeFromRightVC
            controller.modalPresentationStyle = .overFullScreen
            controller.modalTransitionStyle = .crossDissolve
            
            self.present(controller, animated: true, completion: nil)
        }

        
    }
    
    
    
    // shows a dialog when an error occurs and there isn't any more questions
    // will make global later
    func showNoMoreQuestions(_ message: String){
        
        let alertVC = UIAlertController(title: "Complete 🐿️", message: message, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction.init(title: "OK", style: .cancel, handler: { (action) in
            self.dismissToRight()
//            self.dismissWithAnimatingRight()
        }))
    
        self.present(alertVC, animated: true)
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        //return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        
        return myActiveQuestions.count
    }
    
    // doesn't seem to do anything...
//    func tableView(tableView: UITableView, titleForHeaderInSection section:Int) -> String?
//    {
//      return "My Active Questions"
//    }
    
    
    /// delete a row by swiping on the row and tapping delete
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {

        if editingStyle == .delete {
            
            let questionIDToDelete: String = myActiveQuestions[indexPath.row].question.question_name
            myActiveQuestions.remove(at: indexPath.row)
            print("we are deleting \(questionIDToDelete)")
            
            // delete from firestore
            Firestore.firestore().collection(Constants.QUESTIONS_COLLECTION).document(questionIDToDelete).delete { error in
                if let error = error {
                    print("An error occured \(error.localizedDescription)")
                    return
                }
                
                // update the counts
                updateCountOnDeleteQuestion()
                // reload the tableview
                self.tableView.reloadData()
                print("Successfully deleted \(questionIDToDelete) from firestore")
            }
                // delete the table view row
                tableView.deleteRows(at: [indexPath], with: .fade)

                if myActiveQuestions.count < 1 {
                    // segues back to main if the last Question row was deleted
//                    dismissWithAnimatingRight()
                    self.dismissToRight()
                } else {
                    //updates the rows to reflect the new number of reviews required to unlock them, if applicable:
                    self.tableView.reloadData()
                }
            
        } //else if editingStyle == .insert {
            // Not used in our example, but if you were adding a new row, this is where you would do it.
        //}
    } 

    /// Sets up each cell row in the table, that's why it returns one cell
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if let question = myActiveQuestions[indexPath.row].question{
            let reviewCollection = myActiveQuestions[indexPath.row].reviewCollection
            print("Number of reviews in reviewCollection: \(reviewCollection.reviews.count)")
            let isLocked: Bool = question.isLocked
            print("Question is Locked? \(isLocked)")
            
            // Calculate a Tangerine Score to pass to the cell (works for both Ask or Compare):
            let tangerineScore: TangerineScore = reviewCollection.calcTangerineScore(inputs: TangerineScoreInputs(), requestedDemo: RealmManager.sharedInstance.getTargetDemo())
            
            // here we build a single ASK CELL: - - - - - - -
            if question.type == .ASK {
                let cellIdentifier: String = "AskTableViewCell"
                let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! AskTableViewCell
                
                if tangerineScore.numReviews < 1 {
                    cell.td100Bar.isHidden = true
                    cell.ratingValueLabel.isHidden = true
                } else {
                    cell.td100Bar.isHidden = false
                    cell.ratingValueLabel.isHidden = false
                }

                cell.titleLabel.text = question.title_1
                
                // pass the calculated Tangerine Score to the Ask Cell being created by AskTableViewCell
                cell.displayAskCellData(tangerineScore: tangerineScore)

                let timeRemaining = calcTimeRemaining(question.created, forActiveQ: true)
                cell.timeRemainingLabel.text = "\(timeRemaining)"
                

                if reviewCollection.reviews.count > 0 {
                    cell.numVotesLabel.text = "(\(reviewCollection.reviews.count) review)"
                    if reviewCollection.reviews.count > 1 {
                        cell.numVotesLabel.text = "(\(reviewCollection.reviews.count) reviews)" // add an s if more than one vote
                    }
                } else {
                    cell.numVotesLabel.text = "No Reviews Yet"
                }

                cell.reviewsRequiredToUnlockLabel.isHidden = true //defaults to hidden
                cell.lockLabel.isHidden = true

                let reviewsNeeded: Int = reviewsRequiredToUnlock(question: question)

                // for compares, this functionality is performed by the .lockCell() method in the CompareTableViewCell.swift. For Ask's, we do it right here:
                if question.isLocked {
                    cell.rating100Bar.isHidden = true
                    cell.ratingValueLabel.isHidden = true
                    cell.reviewsRequiredToUnlockLabel.isHidden = false
                    cell.lockLabel.isHidden = false
                    cell.reviewsRequiredToUnlockLabel.text = "Please review \(reviewsNeeded) more users to unlock your results."
                    cell.wearItImageView.isHidden = true
                    cell.wearItLabel.isHidden = true
                    removeCircleBorder(view: cell.photoImageView)
                }

                // started Loading, show it
                cell.photoImageView.showActivityIndicator()
                
                // Crops the ask image into a circle
                
                                          downloadOrLoadFirebaseImage(
                                              ofName: getFilenameFrom(qName: question.question_name, type: question.type),
                                              forPath: question.imageURL_1, asThumb: true) { image, error in
                                              if let error = error{
                                                  print("Error: \(error.localizedDescription)")
                                                  return
                                              }
                                            
                                                  // Loading done, hide it
                                            cell.photoImageView.hideActivityIndicator()
                                            print("ATVC ASK Image Downloaded for \(question.question_name)")
                                            cell.photoImageView.image = image!
                                          }
                                          
                
                
                makeCircle(view: cell.photoImageView, alpha: 1.0)
                
                
                return cell

            // here we build a dual COMPARE CELL: - - - - - - -
            }else  if question.type == .COMPARE {
                
                let cellIdentifier: String = "CompareTableViewCell"
                let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! CompareTableViewCell
                
                makeCircle(view: cell.image1, alpha: 1.0)
                makeCircle(view: cell.image2, alpha: 1.0)
                
                // Calculate a Tangerine Score to pass to the cell:
                let tangerineScore: TangerineScore = reviewCollection.calcTangerineScore(inputs: TangerineScoreInputs(), requestedDemo: RealmManager.sharedInstance.getTargetDemo())
                
                // started Loading, show it
                cell.image1.showActivityIndicator()
                
                downloadOrLoadFirebaseImage(
                    ofName: getFilenameFrom(qName: question.question_name, type: question.type),
                    forPath: question.imageURL_1, asThumb: true) { image, error in
                        if let error = error{
                            print("Error: \(error.localizedDescription)")
                            return
                        }
                        // Loading done, hide it
                        cell.image1.hideActivityIndicator()
                        print("ATVC Compare Image1 Downloaded for \(question.question_name)")
                        cell.image1.image = image!
                    }
                
                
                // started Loading, show it
                cell.image2.showActivityIndicator()
                
                downloadOrLoadFirebaseImage(
                    ofName: getFilenameFrom(qName: question.question_name, type: question.type,secondPhoto: true),
                    forPath: question.imageURL_2, asThumb: true) { image, error in
                        if let error = error{
                            print("Error: \(error.localizedDescription)")
                            return
                        }
                        // Loading done, hide it
                        cell.image2.hideActivityIndicator()
                        print("ATVC Compare Image2 Downloaded for \(question.question_name)")
                        cell.image2.image = image!
                    }
                
                //LATER find what compare does if empty
                cell.title1Label.text = question.title_1
                cell.title2Label.text = question.title_2
                
                cell.displayCompareCellData(tangerineScore: tangerineScore)
                
                
                //                cell.displayCellData(dataSet: compareCellDataSet)
                
                cell.reviewsRequiredToUnlockLabel.isHidden = true //defaults to hidden
                
                let reviewsNeeded: Int = reviewsRequiredToUnlock(question: question)
                
                if reviewCollection.reviews.count > 0 {
                    cell.numVotesLabel.text = "(\(reviewCollection.reviews.count) review)"
                    if reviewCollection.reviews.count > 1 {
                        cell.numVotesLabel.text = "(\(reviewCollection.reviews.count) reviews)" // add an s if more than one vote
                    }
                }
                
                cell.percentImage1Label.text = "\(tangerineScore.percentTop)%"
                cell.percentImage2Label.text = "\(tangerineScore.percentBottom)%"
                if reviewCollection.reviews.count < 0 || tangerineScore.numReviews < 1 {
                    cell.percentImage1Label.text = "?"
                    cell.percentImage2Label.text = "?"
                }
                
                
                if tangerineScore.numReviews < 1 {
                    cell.lockCell(isLocked, reviewsNeeded: reviewsNeeded)
                    cell.numVotesLabel.text = "No Reviews Yet"
                    cell.numVotesLabel.font = cell.numVotesLabel.font.withSize(11.0)
                    
                    cell.leftTD100Bar.isHidden = true
                    cell.rightTD100Bar.isHidden = true
                    cell.percentImage1Label.isHidden = true
                    cell.percentImage2Label.isHidden = true
                    
                } else {
                    // all cell locking functionality for a Compare cell is called from the cell vc itself. This is different than the Ask cell, which is all called here in AskTableVC. This should be standardized later for consistency.
                    cell.lockCell(isLocked, reviewsNeeded: reviewsNeeded)
                    cell.numVotesLabel.font = cell.numVotesLabel.font.withSize(12.0)
                }
                
                // calculates and displays the time the Question has left to be in circulation:
                let timeRemaining = calcTimeRemaining(question.created,forActiveQ: true)
                cell.timeRemainingLabel.text = "\(timeRemaining)"
                
                
//                makeCircle(view: cell.image1, alpha: 1.0)
//                makeCircle(view: cell.image2, alpha: 1.0)
                
                //                //Add border to images
                //                addCircleBorder(view: cell.image1, color: .systemOrange)
                //                addCircleBorder(view: cell.image2, color: .systemOrange)
                
//                cell.rightWearItImageView.image = UIImage(named: "gear.badge.questionmark")
                print("rightWearItImageView.isHidden = \(cell.rightWearItImageView.isHidden)")
                print("rightWearItImageView.alpha = \(cell.rightWearItImageView.alpha)")
                
                
                return cell
                
            }  else {
                //should there be error handling in here? This could be much prettier I think..
                let cell: UITableViewCell? = nil
                return cell!
            }
            
        }else {
            return UITableViewCell()
        }
        
    }
    
    //                      ----------
    // MARK: We should add a downswipe to reload the tableView functionality
    //                      ----------
    
    @objc func userSwiped(gesture: UIGestureRecognizer) {
        
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            if swipeGesture.direction == UISwipeGestureRecognizer.Direction.right {
                // go back to previous view by swiping right
                returnToMain() // added the original code there
                //                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    // it will dismiss the vc with animating right
//    func dismissWithAnimatingRight(){
//        let transition = CATransition()
//        transition.duration = 0.5
//        transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
//        transition.type = CATransitionType.push
//        transition.subtype = CATransitionSubtype.fromLeft
//        self.view.window!.layer.add(transition, forKey: nil)
//        self.dismiss(animated: false, completion: nil)
//    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        
        // Tells the system which storyboard to look at
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        
        if let indexPath = self.tableView.indexPathForSelectedRow {
            let passedQuestion = myActiveQuestions[indexPath.row]
            // prevents the segue to the Question's details if the Question is still locked:
            if passedQuestion.question.isLocked == true {
                return
            }
            
            // Determines which type of question it is and then set the target VC to the right one (askVC or compareVC as req)
            if passedQuestion.question.type == .ASK {
                let controller = storyboard.instantiateViewController(withIdentifier: "askViewController") as! AskViewController
                // Pass the selected object to the new view controller:
                controller.question = passedQuestion
                controller.modalPresentationStyle = .fullScreen
                self.presentFromRight(controller)
//                self.present(vc, animated: true, completion: nil)
            } else if passedQuestion.question.type == .COMPARE {
                let controller = storyboard.instantiateViewController(withIdentifier: "compareViewController") as! CompareViewController
                // Pass the selected object to the new view controller:
                controller.question = passedQuestion
                controller.modalPresentationStyle = .fullScreen
                self.presentFromRight(controller)
            }
        }


    } // end of did select row
    
    
    
    // May have to move items from here up into didSelectRowForIndexPath above ***********
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        print("PREPARE")
        //LATER

//        if let indexPath = self.tableView.indexPathForSelectedRow {
//
//            let passedQuestion = myActiveQuestions[indexPath.row]
//            // prevents the segue to the Question's details if the Question is still locked:
//            if passedQuestion.question.isLocked == true {
//                return
//            }
//
//            print("Moving to next for question: \(passedQuestion.question.question_name)")
//            if passedQuestion.question.type == .ASK {
//                let controller = segue.destination as! AskViewController
//                // Pass the selected object to the new view controller:
//                controller.question = passedQuestion
//            } else if passedQuestion.question.type == .COMPARE {
//                let controller = segue.destination as! CompareViewController
//                // Pass the selected object to the new view controller:
//                controller.question = passedQuestion
//            }
//
//        }
    }
    
    /// Determines whether the segue should be performed or not
    override func shouldPerformSegue(withIdentifier identifier: String?, sender: Any?) -> Bool {
        print("SHOULD PERFORM")
        //LATER
       //  prevents the system from trying to segue to the details for a Question that no longer exists:
        guard let indexPath = self.tableView.indexPathForSelectedRow else {
            print("no Question value exists for cell selected")
            return false
        }
        
        // prevents the segue to the Question's details if the Question is still locked:
        // short
        if myActiveQuestions[indexPath.row].question.isLocked == true {
            return false
        }
        
        
        // This is a new if statement. Delete to go back to how it was. 9/30/21
//        if let ident = identifier {
//            if ident == "tableViewToAskVCSegue" {
//                self.presentFromRight(<#T##viewControllerToPresent: UIViewController##UIViewController#>)
//            }
//        }

//        if let passedQuestion = myActiveQuestions[indexPath.row].question{
//            // prevents segue to details of a locked Question:
//            if let ident = identifier {
//                if ident == "tableViewToAskVCSegue" || ident == "tableViewToCompareVCSegue" {
//                    if passedQuestion.isLocked == true {
//                        tableView.deselectRow(at: indexPath, animated: true)
//                        return false
//                    } else {
//                        return true
//                    }
//                }
//            }
//        }

        return true
    }
    
    /// This pops all existing view controllers all the way down to login view to break the strong references that cause a memory leak otherwise. There is most likely a better solution involving a weak var declaration in AVCameraViewController. The issue seems to be eminating from that VC after the continue button is tapped.
    @objc func dismissAllViewControllers() {
        print("running dismissAllViewControllers() in AskTableVC")
        self.performSegue(withIdentifier: "unwindToMainVC", sender: self)
//        self.view.window?.rootViewController?.dismiss(animated: false, completion: nil)
    }
    
    // Delete to go back to how it was. 9/30/21
    override func showDetailViewController(_ vc: UIViewController, sender: Any?) {
        self.presentFromRight(vc)
    }
    

    @objc func returnToMain(){
        self.dismissToRight()
        dismissAllViewControllers()
    }
    
    @objc func showHelp() {
        let alertController = UIAlertController(title: "Tap a row to view its details.", message: "\nSwipe RIGHT to RETURN to main. \n\n-Swipe LEFT on a row to DELETE it.", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Got It", style: .default)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func addTitleToVC(){
       
        let navBar = UINavigationBar(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 44))


        let navItem = UINavigationItem(title: "My Active Questions")
        let backBtn = UIBarButtonItem(image: UIImage(systemName: "arrow.backward"), style: .done, target: nil, action: #selector(returnToMain))
        
        let helpBtn = UIBarButtonItem(image: UIImage(systemName: "questionmark.circle"), style: .done, target: nil, action: #selector(showHelp))

        navItem.leftBarButtonItem = backBtn
        
        navItem.rightBarButtonItem = helpBtn

        navBar.setItems([navItem], animated: true)
        view.addSubview(navBar)

    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
    
    
    // Default unused options that came with the TableView:
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */
}
 





















