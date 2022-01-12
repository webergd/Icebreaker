//
//  ProfileVC.swift
//  SocialApp
//
//  Created by Mahmudul Hasan on 2021-04-11.
//

import UIKit

class ProfileVC: UIViewController {

    /************************************************************ Organization of Code ************************************************/
    /*
     - Outlets
     - Storyboard Actions
     - Custom methods
     - View Controller methods
     */
    /******************************************************************************************************************************/
    
    // user default
    var userDefault : UserDefaults!
    
    @IBOutlet weak var profileImage: UIImageView!
    
    @IBOutlet weak var displaynameL: UILabel!
    @IBOutlet weak var usernameL: UILabel!
    @IBOutlet weak var ageSpecialtyL: UILabel!
    
    
    
    
    
    @IBOutlet weak var scoreL: UILabel!
    
    @IBOutlet weak var totalReviewL: UILabel!
    
    @IBOutlet weak var friendCountL: UILabel!
    
    @IBOutlet weak var memberSinceL: UILabel!
    
    
    /******************************************************************************************************************************/
    
    @IBAction func backBtnPressed(_ sender: UIButton) {
        self.tabBarController?.dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func editUserPressed(_ sender: UIButton) {
        segueToEditUserProfile()
    }
    
    @objc func userTappedProfileImage(_ pressImageGesture: UITapGestureRecognizer){
        print("userTappedProfileImage called")
        segueToEditUserProfile()
    }
    
    func segueToEditUserProfile() {
        print("Edit info")
        let story = UIStoryboard.init(name: "Main", bundle: nil)
        let vc = story.instantiateViewController(identifier: "editprofile_vc") as! EditProfileVC
        
        vc.modalPresentationStyle = .fullScreen
        
        self.present(vc, animated: true, completion: nil)
    }
    
    /******************************************************************************************************************************/
    
    func setupUI(){
        print("Setting up UI of Profile")
        // put some border on profile picture
        profileImage.layer.borderWidth = 1.0
        profileImage.layer.borderColor = UIColor.systemBlue.cgColor
        profileImage.layer.cornerRadius = 4.0
        
        
        displaynameL.text = myProfile.display_name
        usernameL.text = myProfile.username
        
        
        ageSpecialtyL.text = "\(getAgeFromBdaySeconds(myProfile.birthday)) year old \(myProfile.orientation)"
        
        scoreL.text = "(\(myProfile.rating))"
        totalReviewL.text = "\(myProfile.reviews.roundedWithAbbreviations) Total Reviews"
        
        let friendCount = userDefault.integer(forKey: Constants.UD_USER_FRIEND_COUNT)
        friendCountL.text = "\(friendCount) Friends"
        
        // format the member since date
        let dateFormatterGet = DateFormatter()
        dateFormatterGet.dateFormat = "MM-dd-yyyy"
        let memberS = dateFormatterGet.string(from: Date(timeIntervalSince1970: Double(myProfile.created)))
        memberSinceL.text = "Member since \(memberS)"
        
        print(getFilenameFrom(qName: myProfile.username, type: .ASK))
        print(myProfile.profile_pic)
   
        downloadOrLoadFirebaseImage(
            ofName: getFilenameFrom(qName: myProfile.username, type: .ASK),
            forPath: myProfile.profile_pic) { image, error in
            if let error = error{
                print("Error: \(error.localizedDescription)")
                return
            }
            
            print("Profile Image Downloaded for MYSELF")
            self.profileImage.image = image
        }
        
    }
    
    
    /******************************************************************************************************************************/
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        userDefault = UserDefaults.standard
        // Do any additional setup after loading the view.
        
        // For tapping the image to edit profile:
        let tapProfileImageGesture = UITapGestureRecognizer(target: self, action: #selector(ProfileVC.userTappedProfileImage(_:) ))
        profileImage.isUserInteractionEnabled = true
        profileImage.addGestureRecognizer(tapProfileImageGesture)
        
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupUI()
    }
    


}
