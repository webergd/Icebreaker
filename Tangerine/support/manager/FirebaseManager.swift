//
//  FirebaseManager.swift
//  Tangerine
//
//  Created by Mahmudul Hasan on 2022-12-25.
//

import Foundation
//https://us-central1-fir-poc-1594b.cloudfunctions.net/copyUserToSandbox
/// Sets and manages firebase sandbox and live paths
class FirebaseManager {

  private let USERS_COLLECTION = "USERS"
  private let QUESTIONS_COLLECTION = "QUESTIONS"

  private let USERS_SANDBOX_COLLECTION = "sbUSERS"
  private let QUESTIONS_SANDBOX_COLLECTION = "sbQUESTIONS"

  /// Singleton instance that manages the sandbox status and paths
  static let shared = FirebaseManager()
  /// Controls the internal paths and values, based on the value it holds
  private var shouldUseSandbox = true

  /// Default Initializer
  private init(){

  }

  /// Sets the sandbox status of the app, whether it should use the sandbox or not, use the getter to see the status
  /// - Parameter status: **Bool**: indicates the sandbox status
  func setSandbox(_ status: Bool) {
    self.shouldUseSandbox = status
    print("Sandbox: \(status)")
  }

  /// Prints and returns the type of "server" this app is currently using
  /// - Returns: true if app is using sandbox, false otherwise
  func isSandboxRunning() -> Bool {
    print("Sandbox: \(self.shouldUseSandbox)")
    return self.shouldUseSandbox
  }

  /// Returns the collection name for users based on the sandbox status
  /// - Returns: User Collection name
  func getUsersCollection()-> String {
    shouldUseSandbox ? USERS_SANDBOX_COLLECTION : USERS_COLLECTION
  }

  /// Returns the collection name for questions based on the sandbox status
  /// - Returns: Question Collection name
  func getQuestionsCollection()-> String {
    shouldUseSandbox ? QUESTIONS_SANDBOX_COLLECTION : QUESTIONS_COLLECTION
  }

}
