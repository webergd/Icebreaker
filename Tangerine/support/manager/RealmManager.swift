//
//  RealmManager.swift
//  SocialApp
//
//  Created by Mahmudul Hasan on 2021-04-15.
//

import UIKit
import RealmSwift

class RealmManager {
    // the database object
    private var database:Realm!
    // singleton
    static let sharedInstance = RealmManager() 
    
    // init
    private init() {
        do {
            database = try Realm()
        } catch {
            print("Error occured while initializing realm")
        }
    }
    
    /************************************************************ FRIEND *****************************************************************/
    
    // adding a object
    func addOrUpdateFriend(object: Friend, sendStatus: SendStatus)   {
        // check for optional
        if let database = database{
            do {
                // do our writing
                try database.write {
                    // modified allows write + update
                    object.sendStatus = sendStatus
                    database.add(object, update: .modified)
                    
                    print("Added new object for \(sendStatus.rawValue)")
                }
            } catch {
                print("Error writing to realm")
            }
            
        }
        
    } // end of add
    
    func getFriend(_ username: String) -> Friend? {
        let data = database.object(ofType: Friend.self, forPrimaryKey: username)
        
        return data
    }
    
    func getAllFriends()->[Friend]{
        let data = database.objects(Friend.self)
        
        if data.count > 0{
            return data.map{$0}
        }
        // if null return an empty array
        return [Friend]()
    } // end of get all friends
    
    
    func getAllFriendUserNames()->[String]{
        let data = database.objects(Friend.self)
        
        if data.count > 0{
            return data.map{$0.username}
        }
        // if null return an empty array
        return [String]()
    } // end of get all friends
    
    
    
  
    // removing object
    func deleteFriendItem(object: Friend)   {
        if let database = database{
            do {
                try database.write {
                    database.delete(object)
                }
            } catch {
                print("Error deleting from realm")
            }
        }
    } // end of delete
    
    // fetch data recent items
    func getRecentItems() -> [Friend]{
        let data = database.objects(Friend.self)
        
        if data.count > 0{
            return data.filter("sendStatus = %@",SendStatus.RECENT.rawValue).compactMap{$0}
        }
        // if null return an empty array
        return [Friend]()
    } // end of recent
    
    // get the default items
    func getDefaultItems() -> [Friend]{

        let data = database.objects(Friend.self)
        
        if data.count > 0{
            print("Realm got \(data.count) for D friend")
            return data.filter("sendStatus = %@",SendStatus.DEFAULT.rawValue).compactMap{$0}
        }
        // if null return an empty array
        return [Friend]()
    } // end of getDefault
    
    // remove all friends marked as Default in database
    func removeAllDefault(_ data: [Friend]){
       
        if data.count > 0 {
            print("Removing \(data.count) default items")
            do {
                // do our writing
                try database.write {
                    // modified allows write + update
                    database.delete(data)
                    print("Removed Default objects")
                }
            } catch {
                print("Error writing to realm")
            } // end do
        }// end if
        
        
    } // end remove all default
    
    // remove all friends marked as recent in database
    func removeAllRecent(_ data: [Friend]){
       
        
        if data.count > 0 {
            print("Removing \(data.count) recent items")
            do {
                // do our writing
                try database.write {
                    // modified allows write + update
                    database.delete(data)
                    print("Removed Recent objects")
                }
            } catch {
                print("Error writing to realm")
            } // end of do
        } // end if
        
    } // end remove all recent
    
    /***********************************************************   PROFILE aka USER *******************************************************************/
    
    // add profile object
    
    func addOrUpdateProfile(_ object : Profile)   {
        // check for optional
        if let database = database{
            
            do {
                // do our writing
                try database.write {
                    // modified allows write + update
                    database.add(object, update: .modified)
                    
                    print("Profile added or updated")
                }
            } catch {
                print("Error writing to realm")
            }
            
        }
        
    } // end of add
    
    // fetch profile
    
    func getProfile()-> Profile{
        //Wyatt repair attempt 2/16/23, delete as desired
//        if let db = database{
//            return db.object(ofType: Profile.self, forPrimaryKey: 0) ?? Profile()
//        } else {
//            return Profile()
//        }
        
        
        let data = database.object(ofType: Profile.self, forPrimaryKey: 0)

        return data ?? Profile()
    }
    
    /****************************************************************  PERSON LIST aka FRIEND LIST**************************************************************/
    

    
    func getPersonList() -> [PersonList]{
        let data = database.objects(PersonList.self)
        
        if data.count > 0{
            return data.compactMap{$0}
        }
        // if null return an empty array
        return [PersonList]()
    }
    
    func getRequestedPersonList() -> [PersonList]{
        let data = database.objects(PersonList.self)
        
        if data.count > 0{
            return data.filter("status = %@",Status.REQUESTED.rawValue).compactMap{$0}
        }
        // if null return an empty array
        return [PersonList]()
    }
    
    func getBothBlockedPersonList() -> [PersonList]{
        let data = database.objects(PersonList.self)
        
        if data.count > 0{
            return data.filter("status = %@ OR status = %@",Status.BLOCKED.rawValue,Status.GOT_BLOCKED.rawValue).compactMap{$0}
        }
        // if null return an empty array
        return [PersonList]()
    }
    
    
    /***********************************************************  TARGET DEMO *******************************************************************/
     
    /// Returns a TargetDemo object containing the local member's target demographic preferences consisting of age range and orientation(s).
    func getTargetDemo()-> TargetDemo {
        let prefs = UserDefaults.standard
        
        let minimumAge = prefs.integer(forKey: Constants.UD_MIN_AGE_INT)
        let maximumAge = prefs.integer(forKey: Constants.UD_MAX_AGE_INT)
        
        
        // with default value
        let straightWomenPreferred = prefs.bool(forKey: Constants.UD_ST_WOMAN_Bool)
        let gayMenPreferred = prefs.bool(forKey: Constants.UD_GMAN_Bool)
        let straightMenPreferred = prefs.bool(forKey: Constants.UD_ST_MAN_Bool)
        let gayWomenPreferred = prefs.bool(forKey: Constants.UD_GWOMAN_Bool)
        let otherOrientationsPreffered = prefs.bool(forKey: Constants.UD_OTHER_Bool)
        
        return TargetDemo(straight_woman_pref: straightWomenPreferred, straight_man_pref: straightMenPreferred, gay_woman_pref: gayWomenPreferred, gay_man_pref: gayMenPreferred, other_pref: otherOrientationsPreffered, min_age_pref: minimumAge, max_age_pref: maximumAge)
    }


}
