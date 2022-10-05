//
//  ProfileVC.swift
//  SocialApp
//
//  Created by Mahmudul Hasan on 2021-04-11.
//

import UIKit
import FirebaseAuth

class ProfileVC: UIViewController {
    
    // MARK: UI Items
    var scrollView: UIScrollView!
    var contentView: UIView!
    var backBtn: UIButton!
    // user default
    var userDefault : UserDefaults!
    
    var profileImage: UIImageView!
    
    var displaynameL: UILabel!
    var usernameL: UILabel!
    var ageSpecialtyL: UILabel!
    
    var editProfileButton: UIButton!
    
    var reviewerScoreText: UILabel!
    var scoreL: UILabel!
    
    var totalReviewL: UILabel!
    
    var totalCreditL: UILabel!
    
    var friendCountL: UILabel!
    
    var memberSinceL: UILabel!
    
    
    
    // MARK: Actions
    
    @objc func backBtnPressed(_ sender: UIButton) {
        self.tabBarController?.dismiss(animated: true, completion: nil)
    }
    
    
    @objc func editUserPressed(_ sender: UIButton) {
        segueToEditUserProfile()
    }
    
    @objc func userTappedProfileImage(_ pressImageGesture: UITapGestureRecognizer){
        print("userTappedProfileImage called")
        segueToEditUserProfile()
    }
    
    func segueToEditUserProfile() {
        print("Edit info")
        
        let vc = EditProfileVC()
        
        vc.modalPresentationStyle = .fullScreen
        
        self.present(vc, animated: true, completion: nil)
    }
    
    // sign out the current user and take him to login screen
    @objc func onLogoutTapped() {
        
        
        do {
            try Auth.auth().signOut()
            // clear the realm db
            // update the local db
            
            resetLocalAndRealmDB()
            
            resetQuestionRelatedThings() // detailed on declaration of this func => Cmd+Click (Jump to Definition)
            // Move to login
            
            
            let vc = LoginVC()
            vc.modalPresentationStyle = .fullScreen
            
            self.present(vc, animated: true, completion: nil)
            
            
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
        
    }
    
    
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
        var S = addPluralS(numberOfItems: Int(myProfile.rating))
        totalReviewL.text = "\(myProfile.reviews.roundedWithAbbreviations) Total Review\(S)"
        
        S = addPluralS(numberOfItems: myProfile.reviewCredits)
        totalCreditL.text = "\(myProfile.reviewCredits) Review Credit\(S) 🐿️"
        
        let friendCount = userDefault.integer(forKey: Constants.UD_USER_FRIEND_COUNT)
        S = addPluralS(numberOfItems: friendCount)
        friendCountL.text = "\(friendCount) Friend\(S)"
        
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
    
    
    
    // MARK: Delegates
    // MARK: VC Methods
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        // proUI
        
        
        configureScrollView()
        
        configureProfileImageView()
        configureDisplayNameLabel()
        configureUsernameLabel()
        configureAgeLabel()
        
        configureEditProfileButton()
        configureReviewerScoreTextLabel()
        configureReviewScoreLabel()
        
        configureTotalReviewsLabel()
        configureFriendsCountLabel()
        configureMemberSinceLabel()
        configureLogoutButton()
        
        configureBackButton()
        
        
        userDefault = UserDefaults.standard
        // Do any additional setup after loading the view.
        
        // For tapping the image to edit profile:
        let tapProfileImageGesture = UITapGestureRecognizer(target: self, action: #selector(ProfileVC.userTappedProfileImage(_:) ))
        profileImage.isUserInteractionEnabled = true
        profileImage.addGestureRecognizer(tapProfileImageGesture)
        
        // Gesture Recognizers to enable user to tap on Display Name or username for an explanation
        let tapDisplaynameL = UITapGestureRecognizer(target: self, action: #selector(ProfileVC.userTappedDisplayNameL))
        displaynameL.isUserInteractionEnabled = true
        displaynameL.addGestureRecognizer(tapDisplaynameL)
        
        let tapUsernameL = UITapGestureRecognizer(target: self, action: #selector(ProfileVC.userTappedDisplayNameL))
        usernameL.isUserInteractionEnabled = true
        usernameL.addGestureRecognizer(tapUsernameL)
        
        // Gesture Recognizer to enable user to tap on Review Credits for an explanation
        let tapTotalCreditL = UITapGestureRecognizer(target: self, action: #selector(ProfileVC.userTappedTotalCreditL))
        totalCreditL.isUserInteractionEnabled = true
        totalCreditL.addGestureRecognizer(tapTotalCreditL)
        
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupUI()
    }
    
    /// Fires when user taps displaynameL. Provides an explanation.
    @objc func userTappedDisplayNameL(sender: UITapGestureRecognizer) {
        let alertVC = UIAlertController(title: "Your Display Name is \(myProfile.display_name)", message: "This is the name other members can see, and  use to search for you. You can change it in your settings. \n\nYour username (\(myProfile.username)) is what you use to login. That can't be changed.", preferredStyle: .alert)
        let gotItAction = UIAlertAction(title: "Got It", style: .default)
        alertVC.addAction(gotItAction)
        
        present(alertVC, animated: true, completion: nil)
    }
    
    /// Fires when user taps totalCreditL. Provides an explanation.
    @objc func userTappedTotalCreditL(sender: UITapGestureRecognizer) {
        print("review credits label tapped")
        let numCredits = myProfile.reviewCredits//"You have" + credits + " "
        let alertVC = UIAlertController(title: "You have \(numCredits) Review Credits", message: "They will be applied to unlocking any future pictures you post for review. \n\nFor example, if you have 3 review credits, the next picture you post will be automatically unlocked for you.", preferredStyle: .alert)
        let gotItAction = UIAlertAction(title: "Got It", style: .default)
        alertVC.addAction(gotItAction)
        
        present(alertVC, animated: true, completion: nil)
    }
    
    
    
    // MARK: PROGRAMMATIC UI
    func configureBackButton(){
        backBtn = UIButton()
        backBtn.setImage(UIImage(systemName: "arrow.backward"), for: .normal)
        
        backBtn.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backBtn)
        
        
        
        NSLayoutConstraint.activate([
            backBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,constant: 10),
            backBtn.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor,constant: 8),
            backBtn.heightAnchor.constraint(equalToConstant: 40),
            backBtn.widthAnchor.constraint(equalToConstant: 40)
            
        ])
        
        backBtn.addTarget(self, action: #selector(backBtnPressed), for: .touchUpInside)
    }
    
    func configureScrollView(){
        scrollView = UIScrollView()
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        contentView = UIView()
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 0),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: 0),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: 50),
            
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor)
        ])
    }
    
    
    func configureProfileImageView(){
        profileImage = UIImageView()
        profileImage.image = UIImage(named: "generic_user")
        
        profileImage.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(profileImage)
        
        NSLayoutConstraint.activate([
            profileImage.widthAnchor.constraint(equalToConstant: 150),
            profileImage.heightAnchor.constraint(equalToConstant: 150),
            profileImage.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            profileImage.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
        ])
    }
    
    func configureDisplayNameLabel(){
        displaynameL = UILabel()
        displaynameL.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        displaynameL.textColor = .label
        displaynameL.textAlignment = .center
        
        displaynameL.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(displaynameL)
        
        NSLayoutConstraint.activate([
            displaynameL.topAnchor.constraint(equalTo: profileImage.bottomAnchor),
            displaynameL.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
        ])
    }
    
    func configureUsernameLabel(){
        usernameL = UILabel()
        usernameL.font = UIFont.systemFont(ofSize: 17)
        usernameL.textColor = .label
        usernameL.textAlignment = .center
        
        usernameL.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(usernameL)
        
        NSLayoutConstraint.activate([
            usernameL.topAnchor.constraint(equalTo: displaynameL.bottomAnchor, constant: 4),
            usernameL.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
        ])
    }
    
    func configureAgeLabel(){
        ageSpecialtyL = UILabel()
        ageSpecialtyL.font = UIFont.systemFont(ofSize: 18)
        ageSpecialtyL.textColor = .label
        ageSpecialtyL.textAlignment = .center
        
        ageSpecialtyL.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(ageSpecialtyL)
        
        NSLayoutConstraint.activate([
            ageSpecialtyL.topAnchor.constraint(equalTo: usernameL.bottomAnchor, constant: 12),
            ageSpecialtyL.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
        ])
    }
    
    
    func configureEditProfileButton(){
        editProfileButton = UIButton()
        editProfileButton.setTitle("    Edit Profile and Target Demographic     ", for: .normal)
        editProfileButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        editProfileButton.setTitleColor(.white, for: .normal)
        editProfileButton.backgroundColor = .systemBlue
        editProfileButton.layer.cornerRadius = 15.0
        
        
        editProfileButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(editProfileButton)
        
        NSLayoutConstraint.activate([
            editProfileButton.topAnchor.constraint(equalTo: ageSpecialtyL.bottomAnchor, constant: 15),
            editProfileButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
        ])
        
        editProfileButton.addTarget(self, action: #selector(editUserPressed), for: .touchUpInside)
    }
    
    func configureReviewerScoreTextLabel(){
        reviewerScoreText = UILabel()
        //reviewerScoreText.text = "Reviewer Score"
        reviewerScoreText.font = UIFont.systemFont(ofSize: 17)
        reviewerScoreText.textColor = .label
        reviewerScoreText.isHidden = true
        
        reviewerScoreText.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(reviewerScoreText)
        
        NSLayoutConstraint.activate([
            reviewerScoreText.topAnchor.constraint(equalTo: editProfileButton.bottomAnchor, constant: 20),
            reviewerScoreText.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
        ])
    }
    
    func configureReviewScoreLabel(){
        scoreL = UILabel()
        scoreL.font = UIFont.systemFont(ofSize: 20)
        scoreL.textColor = .label
        scoreL.textAlignment = .center
        scoreL.isHidden = true
        scoreL.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(scoreL)
        
        NSLayoutConstraint.activate([
            scoreL.topAnchor.constraint(equalTo: reviewerScoreText.bottomAnchor),
            scoreL.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            scoreL.widthAnchor.constraint(greaterThanOrEqualToConstant: 100)
        ])
    }
    
    // with Credits
    func configureTotalReviewsLabel(){
        totalReviewL = UILabel()
        totalCreditL = UILabel()
        
        totalReviewL.font = UIFont.systemFont(ofSize: 18)
        totalReviewL.textColor = .label
        totalReviewL.textAlignment = .center
        
        totalCreditL.font = UIFont.systemFont(ofSize: 18)
        totalCreditL.textColor = .label
        totalCreditL.textAlignment = .center
        
        totalReviewL.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(totalReviewL)
        
        totalCreditL.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(totalCreditL)
        
        NSLayoutConstraint.activate([
            totalReviewL.topAnchor.constraint(equalTo: scoreL.bottomAnchor, constant: 32),
            totalReviewL.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            totalCreditL.topAnchor.constraint(equalTo: totalReviewL.bottomAnchor, constant: 32),
            totalCreditL.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
        ])
    }
    
    func configureFriendsCountLabel(){
        friendCountL = UILabel()
        friendCountL.font = UIFont.systemFont(ofSize: 18)
        friendCountL.textColor = .label
        friendCountL.textAlignment = .center
        
        friendCountL.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(friendCountL)
        
        NSLayoutConstraint.activate([
            friendCountL.topAnchor.constraint(equalTo: totalCreditL.bottomAnchor, constant: 32),
            friendCountL.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
        ])
    }
    
    func configureMemberSinceLabel(){
        memberSinceL = UILabel()
        memberSinceL.font = UIFont.systemFont(ofSize: 13)
        memberSinceL.textColor = .label
        memberSinceL.textAlignment = .center
        
        memberSinceL.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(memberSinceL)
        
        NSLayoutConstraint.activate([
            memberSinceL.topAnchor.constraint(equalTo: friendCountL.bottomAnchor, constant: 64),
            memberSinceL.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
        ])
    }
    
    func configureLogoutButton(){
        let logoutButton = UIButton()
        logoutButton.setTitle("Logout", for: .normal)
        logoutButton.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        logoutButton.setTitleColor(.systemRed, for: .normal)
        
        logoutButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(logoutButton)
        
        NSLayoutConstraint.activate([
            logoutButton.topAnchor.constraint(equalTo: memberSinceL.bottomAnchor, constant: 20),
            logoutButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            logoutButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
        ])
        
        logoutButton.addTarget(self, action: #selector(onLogoutTapped), for: .touchUpInside)
    }
    
}
