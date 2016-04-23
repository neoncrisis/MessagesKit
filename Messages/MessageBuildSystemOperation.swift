//
//  MessageBuildSystemOperation.swift
//  ReTxt
//
//  Created by Kevin Wooten on 7/23/15.
//  Copyright (c) 2015 reTXT Labs, LLC. All rights reserved.
//

import Foundation
import Operations


/*
  Builds the deliverable message.
*/
class MessageBuildSystemOperation: Operation {
  
  
  let msgType : RTMsgType
  
  let chat : RTChat
  
  let metaData : [String: String]

  let target : RTSystemMsgTarget
  
  var transmitContext : MessageTransmitContext
  
  let api : RTMessageAPI
  
  
  init(msgType: RTMsgType, chat: RTChat, metaData: [String: String], target: RTSystemMsgTarget, transmitContext: MessageTransmitContext, api: RTMessageAPI) {
    
    self.msgType = msgType
    self.chat = chat
    self.metaData = metaData
    self.target = target
    
    self.transmitContext = transmitContext
    self.api = api
    
    super.init()
    
    addCondition(NoFailedDependencies())
  }
  
  override func execute() {
    
    do {
      
      let msgPack = RTMsgPack()
      msgPack.id = RTId.generate()
      msgPack.type = msgType
      msgPack.sender = chat.localAlias
      msgPack.metaData = (metaData as NSDictionary).mutableCopy() as! NSMutableDictionary
      
      if let groupChat = chat as? RTGroupChat {
        msgPack.chat = RTId(string: groupChat.alias)
      }
      
      // Add recipient envelopes
      
      let signer = RTMsgSigner.defaultSignerWithKeyPair(api.credentials.signingIdentity.keyPair)

      msgPack.envelopes = []
      
      if target.contains(.Recipients) {
        
        // Select between all or just active recipients
        let recipients = target.contains(.Inactive) ? chat.allRecipients : chat.activeRecipients
        
        // Add recipient envelopes
        for recipient in recipients {
          
          // Skip sender (added at end)
          if recipient == chat.localAlias {
            continue
          }
          
          let envelope = RTEnvelope(
            recipient:recipient,
            key:nil,
            signature: try signer.signWithId(msgPack.id, type: msgType, sender: chat.localAlias, recipient: recipient, chatId: msgPack.chat, msgKey: nil),
            fingerprint: nil)
          
          msgPack.envelopes.addObject(envelope)
        }
        
      }
      
      if target.contains(.CC) {
        
        // Add sender envelope (for CC)
        
        let ccEnvelope = RTEnvelope(
          recipient: chat.localAlias,
          key: nil,
          signature: try signer.signWithId(msgPack.id, type: msgType, sender: chat.localAlias, recipient: chat.localAlias, chatId: msgPack.chat, msgKey: nil),
          fingerprint: nil)
        
        
        msgPack.envelopes.addObject(ccEnvelope)
        
      }
      
      if target == .CC {
        msgPack.metaData!["recipient"] = chat.alias
      }

      transmitContext.msgPack = msgPack
      transmitContext.encryptedData = nil
      
      finish()
      
    }
    catch let error as NSError {
      finishWithError(error)
    }
    
  }
  
  override var description : String {
    return "Send: Build"
  }
  
}
