//
//  AskReviewsTableViewController.swift
//  
//
//  Created by Wyatt Weber on 6/21/17.
//  Copyright © 2017 Insightful Inc. All rights reserved.
//
//  This is a table view containing a row for every review the Ask has received.
//  The rows can be tapped to segue to a detailed view of the Review to include any comments the reviewer left.

import UIKit

class AskReviewsTableViewController: UITableViewController {
    
    @IBOutlet var askReviewsTableView: UITableView!

    var currentReviews = [AskReview]()

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
        
        // I also need something that sorts the reviews by who they are from
        if let thisQuestion = self.question,
            let thisSortType = self.sortType {
            
            print("storing the sorted array to currentReviews")
            currentReviews = thisQuestion.reviewCollection.filterReviews(by: thisSortType) as! [AskReview]
                        
        } else {
            print("container was nil")
        }
        
        
        //load the sample data
        
        //allows the row height to resize to fit the autolayout constraints
        tableView.rowHeight = UITableView.automaticDimension
        //it won't necessarily follow this, it's just an estimate that's required for the above line to work:
        tableView.estimatedRowHeight = 150
        
        let swipeViewGesture = UISwipeGestureRecognizer(target: self, action: #selector(AskReviewsTableViewController.userSwiped))
        askReviewsTableView.addGestureRecognizer(swipeViewGesture)

        
        // Unused default options:
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        // Creates a row for each review in the Ask's reviewCollection
        var index = 0
        for _ in currentReviews {
            let indexPath = IndexPath(row: index, section: 0)
            
            tableView.cellForRow(at: indexPath)
            index += 1
        }
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        //return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return currentReviews.count
    }
    
    
    // Sets up the cell row in the table, that's why it returns one cell
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
                 
        let cellIdentifier: String = "AskReviewsTableViewCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! AskReviewsTableViewCell
        let review = currentReviews[indexPath.row]
        
        // MARK: Need an if statement so if user is not a friend, profile picture and name are hidden
        
        downloadOrLoadFirebaseImage(
            ofName: getFilenameFrom(qName: review.reviewer.username, type: .ASK),
            forPath: review.reviewer.profile_pic) { image, error in
            if let error = error{
                print("Error: \(error.localizedDescription)")
                return
            }
            
            print("ARTVC Ask Image Downloaded for \(review.reviewer.username)")
            cell.reviewerImageView.image = image!
        }
        
        cell.reviewerNameLabel.text = review.reviewerName
        
        cell.reviewerAgeLabel.text = String(review.reviewerAge)
        cell.voteLabel.text = selectionToText(selection: review.selection)
        cell.strongExistsLabel.text = strongToText(strong: review.strong)
        cell.cellBackgroundView.backgroundColor = orientationSpecificColor(userOrientation: review.reviewerOrientation)

        switch review.comments {
        case "": cell.commentExistsLabel.text = ""
        default: cell.commentExistsLabel.text = "📋"
        }
            
        return cell


    }
    
    @objc func userSwiped() {
        self.dismissToRight()
        
//        self.dismiss(animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Pass the specific review's info, along with the required info from the container's ask
        if let indexPath = self.tableView.indexPathForSelectedRow {
            
            let passedReview = currentReviews[indexPath.row]
            
            let controller = segue.destination as! AskReviewDetailsViewController
            // Pass the selected review to the next view controller:
            controller.review = passedReview
            
            if let passedAsk = question?.question {
                controller.ask = passedAsk
            }
        }
    }

} // end of the class for this VC

























