//
//  PrioritizeQuestion.swift
//  SocialApp
//
//  Created by Mahmud on 2021-07-26.
//

import Foundation
import RealmSwift

/// an object containing a Question and a priority number
public class PrioritizedQuestion: Hashable {
    
    public static func == (lhs: PrioritizedQuestion, rhs: PrioritizedQuestion) -> Bool {
        return lhs.question.question_name == rhs.question.question_name
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(question.question_name)
    }
    
    var question : Question!
    var priority : Double!
    
    
}
