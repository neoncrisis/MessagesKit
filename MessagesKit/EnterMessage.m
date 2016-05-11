//
//  EnterMessage.m
//  MessagesKit
//
//  Created by Francisco Rimoldi on 03/07/14.
//  Copyright (c) 2014 reTXT Labs, LLC. All rights reserved.
//

#import "EnterMessage.h"

#import "MessageDAO.h"
#import "MemoryDataReference.h"
#import "Messages+Exts.h"
#import "NSObject+Utils.h"
#import "NSMutableDictionary+Utils.h"


@implementation EnterMessage

-(instancetype) initWithId:(Id *)id chat:(Chat *)chat alias:(NSString *)alias
{
  self = [super initWithId:id chat:chat];
  if (self) {
    
    self.alias = alias;
    
  }
  return self;
}

-(instancetype) initWithChat:(Chat *)chat alias:(NSString *)alias
{
  return [self initWithId:[Id generate] chat:chat alias:alias];
}

-(BOOL) load:(FMResultSet *)resultSet dao:(MessageDAO *)dao error:(NSError *__autoreleasing *)error
{
  if (![super load:resultSet dao:dao error:error]) {
    return NO;
  }

  self.alias = [resultSet stringForColumnIndex:dao.data1FieldIdx];
  
  return YES;
}

-(BOOL) save:(NSMutableDictionary *)values dao:(DAO *)dao error:(NSError *__autoreleasing *)error
{
  if (![super save:values dao:dao error:error]) {
    return NO;
  }
  
  [values setNillableObject:self.alias forKey:@"data1"];
  
  return YES;
}

-(BOOL) isEquivalent:(id)object
{
  if (![object isKindOfClass:[EnterMessage class]]) {
    return NO;
  }

  return [self isEquivalentToEnterMessage:object];
}

-(BOOL) isEquivalentToEnterMessage:(EnterMessage *)enterMessage
{
  return [super isEquivalentToMessage:enterMessage] &&
         isEqual(self.alias, enterMessage.alias);
}

-(id) copy
{
  EnterMessage *copy = [super copy];
  copy.alias = self.alias;
  return copy;
}

-(NSString *) alertText
{
  //FIXME
//  Contact *contact = [AddressBook.sharedInstance findContactWithAlias:self.alias];
//
//  NSString *name = contact ? contact.name : [self.alias formattedAliasWithDefaultRegion:nil];
//
//  return [NSString stringWithFormat:@"%@ has joined a group chat", name];
  return nil;
}

-(NSString *) summaryText
{
  //FIXME
//  Contact *contact = [AddressBook.sharedInstance findContactWithAlias:self.alias];
//
//  NSString *name = contact ? contact.name : [self.alias formattedAliasWithDefaultRegion:nil];
//
//  return [NSString stringWithFormat:@"%@ has joined", name];
  return nil;
}

-(BOOL) exportPayloadIntoData:(id<DataReference>  _Nonnull __autoreleasing *)payloadData withMetaData:(NSDictionary *__autoreleasing  _Nonnull *)metaData error:(NSError * _Nullable __autoreleasing *)error
{
  *metaData = @{@"member" : self.alias};
  *payloadData = [[MemoryDataReference alloc] initWithData:[NSData data]];
  
  return YES;
}

-(BOOL) importPayloadFromData:(id<DataReference>)payloadData withMetaData:(NSDictionary *)metaData error:(NSError * _Nullable __autoreleasing *)error
{
  self.alias = metaData[@"member"];
  
  return YES;
}

-(enum MsgType) payloadType
{
  return MsgTypeEnter;
}

@end