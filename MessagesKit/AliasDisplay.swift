//
//  AliasDisplay.swift
//  MessagesKit
//
//  Created by Kevin Wooten on 5/11/16.
//  Copyright © 2016 reTXT Labs LLC. All rights reserved.
//

import PromiseKit


public typealias AliasDisplayUpdateHandler = @convention(block) () -> Void


@objc public protocol AliasDisplay {
  
  var fullName : String { get }
  
  var familiarName : String { get }
  
  var initials : String? { get }
  
  var avatar : UIImage? { get }
  
  var updateHandler : AliasDisplayUpdateHandler? { get set }
  
}


@objc public protocol AliasDisplayProvider {
  
  func displayForAlias(alias: String) -> AliasDisplay

}


public typealias AliasDisplayInitializer = @convention(block) (String) -> AliasDisplay

@objc public class AliasDisplayManager : NSObject {
  
  private static var _sharedProvider : AliasDisplayProvider = DefaultAliasDisplayProvider()
  private static var _defaultDisplayInitializer = { alias -> AliasDisplay in return DefaultAliasDisplay(alias: alias) }
  
  public static func initialize(provider provider: AliasDisplayProvider) {
    _sharedProvider = provider
  }
  
  public static func initialize(provider provider: AliasDisplayProvider, defaultDisplayInitializer: AliasDisplayInitializer?) {
    _sharedProvider = provider
    _defaultDisplayInitializer = defaultDisplayInitializer ?? _defaultDisplayInitializer
  }
  
  public static var sharedProvider : AliasDisplayProvider {
    return _sharedProvider
  }
  
  public static func defaultDisplayForAlias(alias: String) -> AliasDisplay {
    return _defaultDisplayInitializer(alias)
  }
  
}
