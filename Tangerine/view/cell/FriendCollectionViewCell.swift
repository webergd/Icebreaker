//
//  FriendCollectionViewCell.swift
//  Tangerine
//
//  Created by Mahmudul Hasan on 2022-06-26.
//

import UIKit

class FriendCollectionViewCell: UICollectionViewCell {

    static let reuseID = "friendCCell"
    var item: Person!
    
    @IBOutlet weak var delete_width: NSLayoutConstraint!
    
    var handleClick: (() -> Void)? = nil
    var handleDelete: (() -> Void)? = nil
    // for the image on left
    @IBOutlet weak var profileImageView: UIImageView!
    
    // for display name
    @IBOutlet weak var title: UILabel!
    
    // for user name
    @IBOutlet weak var subtitle: UILabel!
    
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    
    @IBAction func onButtonClicked(_ sender: UIButton) {
        handleClick?()
    }
    
    @IBAction func onDeleteClicked(_ sender: UIButton) {
        handleDelete?()
    }

}
