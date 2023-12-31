//
//  QFriendCell.swift
//  SocialApp
//
//  Created by Mahmudul Hasan on 2021-04-19.
//

import UIKit

/// This is a cell for sending a Question to a friend
class QFriendCell: UITableViewCell {

    @IBOutlet weak var display_name: UILabel!
    
    @IBOutlet weak var user_name: UILabel!
    
    @IBOutlet weak var rating: UILabel!
    
    @IBOutlet weak var profileImage: UIImageView!
    var isCQCell = true
    
    //MARK: DEPRECATED
    // Age is no longer displayed for friends
    @IBOutlet weak var age: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
        if selected && isCQCell{
            contentView.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.5)
           } else {
               contentView.backgroundColor = UIColor.systemBackground
           }
    }
    
    func setbackground(_ color : UIColor){
        contentView.backgroundColor = color
    }
}
