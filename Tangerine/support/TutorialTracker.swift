//
//  Tutorial.swift
//  Tangerine
//
//  Created by Wyatt Weber on 12/5/22.
//

import Foundation


/// A simplified interface for accessing the UserDefaults Tutorial Phase and track a user's progress through all the steps.
public struct TutorialTracker {
    
    var ud = UserDefaults.standard
    
    /// This is the phase that the user has to do next
    enum TutorialPhase: String, CaseIterable {
        case step0_Intro //0
        case step1_ReviewOthers //1
        case step2_PostQuestion //2
        case step3_AddFriends //3
        case step4_ViewResults //4
        case step5_Complete
        
        
    }
    
    /// Takes a String, makes sure it's one of the tutorial phase options, and returns a TutorialPhase.
    /// Returns phase 0 (intro) as a default.
    ///     This makes it more robust since when there is no TutorialPhase in the UserDefaults, vetting it's value will return the intro, which is what we want.
    func vetTutorial(phase: String?) -> TutorialPhase {
        guard let phaseToVet = phase else {
            
            print("no tutorial phase stored, defaulting to step0_Intro.")
            // (else) default toward showing the whole thing from the beginning
            return TutorialPhase.step0_Intro
        }
        for phz in TutorialPhase.allCases {
            if phz.rawValue == phaseToVet {
                print("setting phase to \(phz.rawValue)")
                return phz
            }
        }
        // (else) default toward showing the whole thing from the beginning
        print("defaulting to step0_Intro")
        return TutorialPhase.step0_Intro
    }
    
    func setTutorial(phase: TutorialPhase) {
        let phaseToSave: String = vetTutorial(phase: phase.rawValue).rawValue
        self.ud.set(phaseToSave, forKey: Constants.UD_TUTORIAL_PORTION_LAST_SEEN)
        print("Tutorial Phase is now \(phaseToSave)")
    }
    
    /// Pulls the user's current Tutorial Phase from UserDefaults
    func getTutorialPhase() -> TutorialTracker.TutorialPhase {
        let phase = UserDefaults.standard.string(forKey: Constants.UD_TUTORIAL_PORTION_LAST_SEEN)
        let phaseToReturn = vetTutorial(phase: phase)
        return phaseToReturn
    }
    
    
    /// updates the current tutorial phase to the next phase in sequence
    func incrementTutorialFrom(currentPhase: TutorialPhase) {
        let tPArray: [TutorialPhase] = TutorialPhase.allCases
        var returnNext = false
        
        // defaults to complete in case it's done already
        var phaseToSet: TutorialPhase = .step5_Complete
        
        for phz in tPArray {
            if returnNext == true {
                // true was set in the last iteration so now it iterated to the next phase and we will set that as the current phase
                phaseToSet = phz
            }
            if phz == currentPhase {
                // set returnNext to true so that next iteration it will set the subesquent phase
                returnNext = true
            }
        }
        
        setTutorial(phase: phaseToSet)
    }
}
