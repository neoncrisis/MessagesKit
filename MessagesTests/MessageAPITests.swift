//
//  MessageAPITest.swift
//  ReTxt
//
//  Created by Kevin Wooten on 3/13/16.
//  Copyright © 2016 reTXT Labs, LLC. All rights reserved.
//

import XCTest
@testable import Messages


class MessageAPITest: XCTestCase {
  
  static let documentDirectoryURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).last!
  
  let testClientA = try! TestClient(baseURL: RTServerAPI.baseURL())
  let testClientB = try! TestClient(baseURL: RTServerAPI.baseURL())
  
  var api : MessageAPI!

  override func setUp() {
    super.setUp()
    
    let x = expectationWithDescription("signIn")
    
    firstly {
      return MessageAPI.findProfileWithId(testClientA.userId, password: testClientA.password)
    }
    .then { profile in
      return MessageAPI.signInWithProfile(profile as! RTUserProfile, deviceId: self.testClientA.devices[0].deviceInfo.id, password: self.testClientA.password)
    }
    .then { creds -> Void in
      let creds = creds.authorizeWithEncryptionIdentity(self.testClientA.encryptionIdentity, signingIdentity: self.testClientA.signingIdentity)
      self.api = try MessageAPI(credentials: creds, documentDirectoryURL: MessageAPITest.documentDirectoryURL)
    }
    .always {
      x.fulfill()
    }
    .error { caught in
      fatalError("Error signing in: \(caught)")
    }
   
    waitForExpectationsWithTimeout(5, handler: { error in
      if let error = error {
        fatalError("Sign in timed out: \(error)")
      }
    })
    
  }
  
  override func tearDown() {
    
    testClientA.devices.forEach { $0.clearHistory() }
    testClientB.devices.forEach { $0.clearHistory() }
    
    super.tearDown()
  }

  func testReceiveUserStatus() throws {

    let x = expectationWithDescription("Receiving user status")
    
    let _ = try api.loadUserChatForAlias(testClientB.devices[0].preferredAlias, localAlias: testClientA.devices[0].preferredAlias)
    
    NSNotificationCenter.defaultCenter()
      .addObserverForName(MessageAPIUserStatusDidChangeNotification, object: api, queue: nil, usingBlock: { not in
        if not.userInfo?[MessageAPIUserStatusDidChangeNotification_InfoKey] is RTUserStatusInfo {
          x.fulfill()
        }
      })
    
    sleep(2); // Wait for access token generation and websocket connect
    
    try! testClientB.sendUserStatus(.Typing, from: testClientB.devices[0].preferredAlias, to: testClientA.devices[0].preferredAlias)
    
    waitForExpectationsWithTimeout(15, handler: nil)
  }

}
