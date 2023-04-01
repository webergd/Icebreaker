//
//  RemoteConfigManager.swift
//  Tangerine
//
//  Created by Wyatt Weber on 1/16/23.
//

import Foundation
import FirebaseRemoteConfig



public func setupRemoteConfigDefaults() {
    let defaultValues = [
        Constants.RO_ON_TOP: "false" as NSObject, // this split test is complete. Just a placeholder.
        // Add defaults for next A-B Test Split Test:
        Constants.SKIP_BUTTON_SHOWN: "true" as NSObject //before the split test goes live, change this to false
    ]
    RemoteConfig.remoteConfig().setDefaults(defaultValues)
}

public func fetchRemoteConfig() {
    // FIXME: Remove this before we launch
    // Set per this stack overflow: https://stackoverflow.com/questions/56693336/isdevelopermodeenabled-is-deprecated-this-no-longer-needs-to-be-set-during-d
    // instead of 5:00 of this video: https://www.youtube.com/watch?v=3mDzJoDJIqc
    let remoteConfigSettings = RemoteConfigSettings()
    remoteConfigSettings.minimumFetchInterval = 0
    
    
    RemoteConfig.remoteConfig().fetch(withExpirationDuration: 0) { (status, error) in
        guard error == nil else {
            print("Error fetching remote values: \(error!)")
            return
        }
        print("Successfully retrieved remote values from the cloud")
        RemoteConfig.remoteConfig().activate()
//        updateViewWithRCValues()
    }
}

//public func updateViewWithRCValues() {
//    
//}

