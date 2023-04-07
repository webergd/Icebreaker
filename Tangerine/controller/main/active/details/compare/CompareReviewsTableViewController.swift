//
//  CompareReviewsTableViewController.swift
//  
//
//  Created by Wyatt Weber on 6/23/17.
//  Copyright © 2017 Insightful Inc. All rights reserved.
//
//  This is a table view containing a row for every review the Compare has received.
//  The rows can be tapped to segue to a detailed view of the Review to include any comments the reviewer left.

import UIKit

class CompareReviewsTableViewController: UITableViewController {
    
    @IBOutlet var compareReviewsTableView: UITableView!
    
    var currentReviews = [CompareReview]()
    
    var sortType: dataFilterType? {
        didSet {
        }
    }
    
    var question: ActiveQuestion? {
        didSet {
            // Update the view.
            self.viewDidLoad()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let thisQuestion = self.question,
           let thisSortType = self.sortType {
            
            // stores the sorted array to currentReviews
            currentReviews = thisQuestion.reviewCollection.filterReviews(by: thisSortType) as! [CompareReview]
            
        } else {
            print("container was nil")
        }
        
        //allows the row height to resize to fit the autolayout constraints
        tableView.rowHeight = UITableView.automaticDimension
        //it won't necessarily follow this, it's just an estimate that's required for the above line to work:
        tableView.estimatedRowHeight = 150
        
        let swipeViewGesture = UISwipeGestureRecognizer(target: self, action: #selector(CompareReviewsTableViewController.userSwiped))
        compareReviewsTableView.addGestureRecognizer(swipeViewGesture)
        
        
        // Unused default options:
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    
    // This happens when the main tableView is displayed again when navigating back to it from asks and compares
    override func viewDidAppear(_ animated: Bool) {
        
        // I'm not sure if any code inside viewDidAppear() is necessary
        // It looks like the cellForRow at index path stuff executes automatically
        
    }
    
    // MARK:  - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        //return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return currentReviews.count
    }
    
    
    //This sets up the cell row in the table and returns one cell
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cellIdentifier: String = "CompareReviewsTableViewCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! CompareReviewsTableViewCell
        let review = currentReviews[indexPath.row]
        
        // MARK: Need an if statement so if user is not a friend, profile picture and name are hidden
        cell.reviewerImageView.setFirebaseImage(for: review.reviewer.profile_pic)
        
        
        cell.reviewerNameLabel.text = review.reviewerName
        
        cell.reviewerAgeLabel.text = String(review.reviewerAge)
        
        cell.strongExistsLabel.text = strongToText(strongYes: review.strongYes, strongNo: review.strongNo)
        
        if let thisQuestion = question {
            cell.selectionImageView.image = selectionImage(selection: review.selection, compare: thisQuestion.question)
            cell.selectionTitleLabel.text = selectionTitle(selection: review.selection, compare: thisQuestion.question)
        }
        // sets the cell background color according to the reviewers orientation
        cell.cellBackgroundView.backgroundColor = orientationSpecificColor(userOrientation: review.reviewerOrientation)
        
        switch review.comments {
        case "": cell.commentExistsLabel.text = ""
        default: cell.commentExistsLabel.text = "📋"
        }
        
        return cell
        
        
    }
    
    
    
    
    // MARK: - Navigation
    
    // MARK: NEEDS TO BE UNCOMMENTED AND WORKED ON:
    
    @objc func userSwiped() {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        // Pass the specific review's info, along with the required info from the Compare
        if let indexPath = self.tableView.indexPathForSelectedRow {
            
            let passedReview = currentReviews[indexPath.row]
            
            let controller = segue.destination as! CompareReviewDetailsViewController
            // Pass the selected review to the next view controller:
            controller.review = passedReview
            
            if let passedCompare = question{
                controller.compare = passedCompare
            }
        }
    }
    
    // Unused extra methods and options:
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
    
} // end of the class for this VC

