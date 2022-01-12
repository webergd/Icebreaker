//
//  ActiveQuestion.swift
//  SocialApp
//
//  Created by Mahmudul Hasan on 2021-07-10.
//

import Foundation

public struct ActiveQuestion {
    var question : Question!
    var reviewCollection : ReviewCollection = ReviewCollection(type: .ask)
    
}
