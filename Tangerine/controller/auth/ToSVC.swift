//
//  ToSVC.swift
//  SocialApp
//
//  Created by Mahmudul Hasan on 2021-03-26.
//

import UIKit

class ToSVC: UIViewController {
    
    var tosTV: UITextView!
    
    @objc func closeTapped() {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Terms of Service"
        view.backgroundColor = .systemBackground
        
        configureNavItem()
        configureTOSText()

    }
    
    func configureNavItem(){
        let closeButton = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeTapped))
        self.navigationItem.leftBarButtonItem = closeButton
    }
    
    func configureTOSText(){
        tosTV = UITextView()
        tosTV.font = UIFont.systemFont(ofSize: 14)
        tosTV.textColor = .label
        tosTV.autocapitalizationType = .sentences
        
        tosTV.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tosTV)
        
        NSLayoutConstraint.activate([
            tosTV.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0),
            tosTV.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            tosTV.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            tosTV.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20)
        ])
        
        // terms is saved in support>TermsOfService folder/group
        tosTV.text = terms
    }


}
