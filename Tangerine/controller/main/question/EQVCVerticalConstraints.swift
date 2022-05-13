//
//  EQVCVerticalConstraints.swift
//  Tangerine
//
//  Created by Wyatt Weber on 4/29/22.
//

import Foundation
import CoreGraphics

public class EQVCVerticalConstraints {
    
    let scrollAndCompareHousingViewHeight: CGFloat
    let scrollHousingViewHeight: CGFloat
    
    var photoBeingEdited: topOrBottom {
        switch currentCompare.creationPhase {
        case .firstPhotoTaken: return .top
        case .reEditingFirstPhoto: return .top
        case .secondPhotoTaken: return .bottom
        case .reEditingSecondPhoto: return .bottom
        default: return .top
        }
    }
    
    init(titleTextFieldHeight: CGFloat, screenWidth: CGFloat, captionTextFieldHeight: CGFloat, scrollAndCompareHousingViewHeight: CGFloat) {
        // calculate scrollHousingViewHeight:
        // title + scrollView + captionButton
        print("initializing the EQVC Vertical Constraints object")
        print("titleTextFieldHeight to be used is: \(String(describing: titleTextFieldHeight))")
        print("screenWidth = \(screenWidth) \ncaptionTextFieldHeight = \(captionTextFieldHeight)")
        self.scrollHousingViewHeight = titleTextFieldHeight + screenWidth + captionTextFieldHeight + 6
        print("scrollHousingViewHeight = \(scrollHousingViewHeight)")
        // we use captionTextFieldHeight instead of the caption button's height because the button derives its height from the captionTextField's height.
        
        // calculate scrollAndCompareHousingViewHeight:
        // Total screen height minue qTypeLabel.height and publishButton.height
//        self.scrollAndCompareHousingViewHeight = screenHeight - (questionTypeLabelHeight + publishButtonHeight)
        self.scrollAndCompareHousingViewHeight = scrollAndCompareHousingViewHeight
    }
    
    //calculate compareHousingViewHeight
    // This is the leftover vertical space that will vary based on the size of the phone that the member is using. The bigger the better so that the otherImageThumbnail can be seen clearly.
    var compareHousingViewHeight: CGFloat {
        return self.scrollAndCompareHousingViewHeight - self.scrollHousingViewHeight
    }
    
    // calculate thumbnail image width
    // The thumbnail is a 1:1 aspect ratio so width == height.
    // We want to leave a buffer around the image so we'll make it a percentage of the housingView
    var thumbnailImageWidth: CGFloat {
        return self.compareHousingViewHeight * 0.8
    }
    
    /// changes based on Case and available screen height
    var scrollHousingViewTopConstraint: CGFloat {
        switch photoBeingEdited {
        case .top:
            return CGFloat(0.0) // the scrollHousingView is all the way at the top
        case .bottom:
            return self.compareHousingViewHeight// scrollHousingView should start at the bottom of the compareHousingView
        }
    }
    
    /// changes based on Case and available screen height
    var compareHousingViewTopConstraint: CGFloat {
        switch photoBeingEdited {
        case .top:
            print("comparetopheight\(String(describing: scrollHousingViewHeight))")
            return self.scrollHousingViewHeight
        case .bottom:
            return CGFloat(0.0)
        }
    }
}
