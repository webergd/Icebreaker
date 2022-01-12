//
//  AddFriendCell.swift
//  SocialApp
//
//  Created by Mahmudul Hasan on 2021-04-04.
//

import UIKit

class FriendCell: UITableViewCell {
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
