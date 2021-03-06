//
//  GCD.swift
//  MessagesKit
//
//  Created by Kevin Wooten on 10/2/15.
//  Copyright © 2015 reTXT Labs, LLC. All rights reserved.
//

import Foundation


public class GCD {
  

  public class var mainQueue : dispatch_queue_t {
    return dispatch_get_main_queue()
  }
  
  public class var userInteractiveQueue : dispatch_queue_t {
    return dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)
  }
  
  public class var userInitiatedQueue : dispatch_queue_t {
    return dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)
  }
  
  public class var utilityQueue : dispatch_queue_t {
    return dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)
  }
  
  public class var backgroundQueue : dispatch_queue_t {
    return dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)
  }
  
}




public extension dispatch_queue_t {
  
  public func async(block: dispatch_block_t) {
    dispatch_async(self, block)
  }
  
  public func after(delay: Float, block: dispatch_block_t) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(Float(NSEC_PER_SEC) * delay)), self, block)
  }
  
  public func sync(block: dispatch_block_t) {
    dispatch_sync(self, block)
  }
  
  public func sync<T>(block: () throws -> T) rethrows -> T {
    
    var res : T?
    var error : ErrorType?
    
    dispatch_sync(self) {
      do {
        res = try block()
      }
      catch let caught {
        error = caught
      }
    }
    
    if let error = error {
      try { throw error }()
    }
    
    return res!
  }
  
  public func sync<T>(block: () throws -> T?) rethrows -> T? {
    
    var res : T??
    var error : ErrorType?
    
    dispatch_sync(self) {
      do {
        res = try block()
      }
      catch let caught {
        error = caught
      }
    }
    
    if let error = error {
      try { throw error }()
    }
    
    return res!
  }
  
}
