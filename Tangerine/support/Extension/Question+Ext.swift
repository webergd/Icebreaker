//
//  Question+Ext.swift
//  SocialApp
//
//  Created by Mahmudul Hasan on 2021-12-26.
//

import Foundation

extension Question: Hashable {
    public static func == (lhs: Question, rhs: Question)-> Bool{
        return lhs.question_name == rhs.question_name
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(question_name)
    }
}
