//
//  Constants.swift
//  SocialApp
//
//  Created by Mahmudul Hasan on 2021-03-26.
//

import UIKit


class Constants {

  static let TOS_URL = "https://letstangerine.com/termsOfUse"
   
    // static variables
    static let SYS_PERSON_ICON = "person.crop.circle"

    
    // this username will only be used during signup
    static var username = ""
    
    //Constants
    
    // for phone auth
    static let CUSTOM_EMAIL_DOMAIN = "@tangerine.com"
    // for phone auth, for saving in UD
    static let VERIFICATION_ID = "phone_auth_verify"
    // for phone auth, for saving in UD
    //static let PHONE_NUMBER = "phone_auth_pn"
    
    static let ORIENTATIONS = ["straight woman","straight man","lesbian","gay man","other"]

    
    
    
    // References
    
    static let USERS_PRIVATE_SUB_COLLECTION = "private"
    static let USERS_PRIVATE_INFO_DOC = "info"
    
    static let USERS_LIST_SUB_COLLECTION = "connection_list"
    
    

    static let QUESTION_REVIEWED = "q_reviewed"
    
    
    
    // Storage Refs
    
    static let PROFILES_FOLDER = "profiles"

    
    
    // FIELDS IN USERS
    static let USER_CREATED_KEY = "created"
    static let USER_ORIENTATION_KEY = "orientation"
    
    static let USER_NUMBER_KEY = "phone_number"
    static let USER_BIRTHDAY_KEY = "bday"
    
    static let USER_DNAME_KEY = "dname_lower"
    static let USER_IMAGE_KEY = "profile_pic"
    static let USER_RATING_KEY = "rating"
    static let USER_REVIEW_KEY = "reviews"
    // NEW > Jun, 22
    static let USER_CREDIT_KEY = "reviewCredits"
    static let USER_LAST_REVIEWED_KEY = "lastReviewedTime"
    
    // NEW > Sept 6
    static let USER_QFF_COUNT_KEY = "qff_count"
    static let USER_QFF_FROM_KEY = "qf_user"
    static let USER_FR_COUNT_KEY = "fr_count"
    static let USER_FR_FROM_KEY = "fr_from"
    
    // New > Dec 13
  static let USER_UN_INDEX_KEY = "username_index"
    // USE UD target demo keys for firestore
    
    // ENDS OF USERS FIELDS
    
    
    
    
    
    
    
    
    
    // KEYS FOR PRIVATE > INFO
    static let USER_TD_KEY = "target_demo"
    
    // required for question related item
    // fetch with TD from main
    static let UD_LOCKED_QUESTION_KEY = "number_of_locked_question"
    static let UD_QUESTION_TO_REVIEW_KEY  = "question_to_review"
    static let UD_LAST_REVIEWS_QUESTION_ID = "last_reviewed_id"
    
    
    
    
    
    
    
    
    // KEYS FOR LIST > CONNECTIONS
    static let USER_STATUS_KEY = "status" // my friend
    
    
    
    
    
    
    
    
    
    
    
    // KEYS FOR Questions Collection
    
    static let QUES_TYPE_KEY = "type"
    /// "recipients" are friends of the Question Creator that he/she sent it to.
    static let QUES_RECEIP_KEY = "recipients"
    static let QUES_IN_CIRCULATION = "is_circulating"
    static let QUES_CREATOR = "creator"
    static let QUES_REPORTS = "reports"
    static let QUES_USERS_NOT_REVIEWED_BY_KEY = "usersNotReviewedBy"
    
    // KEYS FOR reviews > ID
    static let QUES_REVIEWS = "reviews"
    
    
    
    
    
    
    
    
    // MARK: for userDefaults

    
    // USED IN DISPLAY NAME, NOT USERNAME
    // We'll use auth display name as username
    static let UD_USER_DISPLAY_NAME = "dname"
    static let UD_USER_FRIEND_COUNT = "fcount"
    
    // THESE ARE USED IN TARGET DEMO
    static let UD_NO_PREF_Bool = "no_pref"
    
    static let UD_ST_WOMAN_Bool = "straight_woman_pref"
    static let UD_ST_MAN_Bool = "straight_man_pref"
    static let UD_GWOMAN_Bool = "gay_woman_pref"
    static let UD_GMAN_Bool = "gay_man_pref"
    static let UD_OTHER_Bool = "other"
    
    static let UD_MIN_AGE_INT = "min_age"
    static let UD_MAX_AGE_INT = "max_age"
    
    // END OF TARGET DEMO UD
    
    // Profile > Notification
    static let UD_NOTIFY_RECEIVE_ANSWER_Bool = "notify_rec_answer"
    static let UD_NOTIFY_FRIEND_REQ_Bool = "notify_friend_req"
    static let UD_NOTIFY_FRIEND_QUES_Bool = "notify_friend_ques"
    
    // end Profile > Notification
    
    // for signup done and login persistence
    static let UD_SIGNUP_DONE_Bool = "signup_done"
    static let UD_SHOULD_PERSIST_LOGIN_Bool = "shouldPlogin"
    // end signup done and login persistence
    
    // Tutorial Mode Bools
    static let UD_SKIP_MAINVC_TUTORIAL_Bool = "skipStartOrDismissTutorial"
    static let UD_SKIP_REVIEW_ASK_TUTORIAL_Bool = "skipReviewAskTutorial"
    static let UD_SKIP_REVIEW_COMPARE_TUTORIAL_Bool = "skipReviewCompareTutorial"
    static let UD_SKIP_AVCAM_TUTORIAL_Bool = "skipAVCamTutorial"
    static let UD_SKIP_EDIT_QUESTION_TUTORIAL_Bool = "skipEditQTutorial"
    static let UD_SKIP_SEND_TO_FRIENDS_TUTORIAL_Bool = "skipSendToFriendsTutorial"
    static let UD_SKIP_FRIENDSVC_TUTORIAL_Bool = "skipFriendsVCTutorial"
    static let UD_SKIP_ADD_FRIENDS_TUTORIAL_Bool = "skipAddFriendsTutorial"
    static let UD_SKIP_ACTIVE_Q_TUTORIAL_Bool = "skipActiveQTutorial"
    static let UD_SKIP_MY_ASK_TUTORIAL_Bool = "skipMyAskTutorial"
    static let UD_SKIP_MY_COMPARE_TUTORIAL_Bool = "skipMyCompareTutorial"
    
    /// This way we can keep track of where we are in the tutorial in terms of the primary functions being introduced from the main screen.
    /// This will work in conjunction with an enum
    static let UD_TUTORIAL_PORTION_LAST_SEEN = "tutorialPortionLastSeen"

    
    
    //Implemented in sendToFriendsVC and sets the "default to these Friends next time" toggle switch to whatever the member had it set at last time
    static let UD_DEFAULT_TO_THESE_FRIENDS_SWITCH_SETTING = "defaultToTheseFriendsSwitchSetting"
    
    
    
    
    static let QFF_NOTI_NAME = "NOTIFICATION_NAME.QFF"
    // To be reused in our programmaticUI
    // MARK: UI Items
    // MARK: Actions
    // MARK: Delegates
    // MARK: VC Methods
    // MARK: PROGRAMMATIC UI
}
