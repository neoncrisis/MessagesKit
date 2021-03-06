//
//  MessageOperations.swift
//  MessagesKit
//
//  Created by Kevin Wooten on 7/28/15.
//  Copyright (c) 2015 reTXT Labs, LLC. All rights reserved.
//

import Foundation
import PSOperations
import PromiseKit


typealias Resolver = (Any?) -> Void


class MessageAPIOperation: Operation {
  
  
  let api : MessageAPI
  
  internal var resolver : Resolver?
  
  internal var resolverPromise : Promise<Any?>?
  
  internal var resolveResult : Any? {
    return nil
  }
  
  init(api: MessageAPI) {
    self.api = api
    
    super.init()
    
    addCondition(NoFailedDependencies())
    addCondition(RequireAccessToken(api: api))
  }
  
  override func finished(errors: [NSError]) {
    
    for error in errors {
      
      let transError = translateError(error)
      
      if transError == MessageAPIError.AuthenticationError {
        
        api.signOut()
        
      }
      
    }
    
    if let resolver = resolver {
      if let error = errors.first {
        resolver(error)
      }
      else {
        resolver(resolveResult)
      }
    }
    
  }

  func promise() -> Promise<Any?> {
    
    if let resolverPromise = resolverPromise {
      return resolverPromise
    }
    
    let (promise, fulfill, reject) = Promise<Any?>.pendingPromise()
    self.resolverPromise = promise
    
    resolver = { result in
      if let error = result as? ErrorType {
        reject(error)
      }
      else {
        fulfill(result)
      }
    }
    
    return promise
  }
  
}


class MessageAPIGroupOperation: GroupOperation {
  
  
  let api : MessageAPI
  
  internal var resolver : Resolver?

  internal var resolverPromise : Promise<Any?>?
  
  internal var resolveResult : Any? {
    return nil
  }
  
  init(api: MessageAPI) {
    self.api = api
    
    super.init(operations: [])
    
    addCondition(NoFailedDependencies())
    addCondition(RequireAccessToken(api: api))
  }
  
  override func finished(errors: [NSError]) {
    
    for error in errors {
      
      let transError = translateError(error)
      
      if transError == MessageAPIError.AuthenticationError {
        
        api.signOut()
        
      }
      
    }
    
    if let resolver = resolver {
      if let error = errors.first {
        resolver(error)
      }
      else {
        resolver(resolveResult)
      }
    }
    
  }
  
  func promise() -> Promise<Any?> {
    
    if let resolverPromise = resolverPromise {
      return resolverPromise
    }
    
    let (promise, fulfill, reject) = Promise<Any?>.pendingPromise()
    self.resolverPromise = promise
    
    resolver = { result in
      if let error = result as? ErrorType {
        reject(error)
      }
      else {
        fulfill(result)
      }
    }
    
    return promise
  }
  
}
