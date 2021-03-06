//
//  ContactMessage.m
//  MessagesKit
//
//  Created by Kevin Wooten on 1/3/14.
//  Copyright (c) 2014 reTXT Labs, LLC. All rights reserved.
//

#import "ContactMessage.h"

#import "MessageDAO.h"
#import "MemoryDataReference.h"
#import "DataReferences.h"
#import "Messages+Exts.h"
#import "NSObject+Utils.h"
#import "NSMutableDictionary+Utils.h"

@import AddressBook;


@implementation ContactMessage

-(instancetype) initWithId:(Id *)id chat:(Chat *)chat vcardData:(NSData *)vcardData
{
  self = [super initWithId:id chat:chat];
  if (self) {
    
    self.vcardData = vcardData;
    
  }
  return self;
}

-(instancetype) initWithChat:(Chat *)chat vcardData:(NSData *)vcardData
{
  return [self initWithId:[Id generate] chat:chat vcardData:vcardData];
}

-(id) copy
{
  ContactMessage *copy = [super copy];
  copy.vcardData = self.vcardData;
  copy.firstName = self.firstName;
  copy.lastName = self.lastName;
  copy.extraLabel = self.extraLabel;
  return copy;
}

-(BOOL) isEquivalent:(id)object
{
  if (![object isKindOfClass:[ContactMessage class]]) {
    return NO;
  }

  return [self isEquivalentToContactMessage:object];
}

-(BOOL) isEquivalentToContactMessage:(ContactMessage *)contactMessage
{
  return
  [super isEquivalentToMessage:contactMessage] &&
  isEqual(self.vcardData, contactMessage.vcardData) &&
  isEqual(self.firstName, contactMessage.firstName) &&
  isEqual(self.lastName, contactMessage.lastName) &&
  isEqual(self.extraLabel, contactMessage.extraLabel);
}

-(NSString *) alertText
{
  return [NSString stringWithFormat:@"Sent you a contact for %@", self.fullName];
}

-(NSString *) fullName
{
  NSMutableArray *names = [NSMutableArray array];
  
  if (self.firstName) {
    [names addObject:self.firstName];
  }
  
  if (self.lastName) {
    [names addObject:self.lastName];
  }
  
  return [names componentsJoinedByString:@" "];
}

-(NSString *) summaryText
{
  return [NSString stringWithFormat:@"Contact: %@", self.fullName];
}

-(BOOL) load:(FMResultSet *)resultSet dao:(MessageDAO *)dao error:(NSError **)error
{
  if (![super load:resultSet dao:dao error:error]) {
    return NO;
  }
  
  self.vcardData = [resultSet dataForColumnIndex:dao.data1FieldIdx];
  self.firstName = [resultSet stringForColumnIndex:dao.data2FieldIdx];
  self.lastName = [resultSet stringForColumnIndex:dao.data3FieldIdx];
  self.extraLabel = [resultSet stringForColumnIndex:dao.data4FieldIdx];
  
  return YES;
}

-(BOOL) save:(NSMutableDictionary *)values dao:(DAO *)dao error:(NSError **)error
{
  if (![super save:values dao:dao error:error]) {
    return NO;
  }
  
  [values setNillableObject:self.vcardData forKey:@"data1"];
  [values setNillableObject:self.firstName forKey:@"data2"];
  [values setNillableObject:self.lastName forKey:@"data3"];
  [values setNillableObject:self.extraLabel forKey:@"data4"];
  
  return YES;
}

-(MsgType) payloadType
{
  return MsgTypeContact;
}

-(BOOL) exportPayloadIntoData:(id<DataReference> *)payloadData withMetaData:(NSDictionary **)metaData error:(NSError **)error
{
  *metaData = @{};
  *payloadData = [MemoryDataReference.alloc initWithData:self.vcardData ofMIMEType:@"text/vcard"];
  
  return YES;
}

-(BOOL) importPayloadFromData:(id<DataReference>)payloadData withMetaData:(NSDictionary *)metaData error:(NSError **)error
{

  self.vcardData = [DataReferences readAllDataFromReference:payloadData error:error];
  if (!self.vcardData) {
    return NO;
  }

  NSArray *createdPeople = (__bridge_transfer NSArray *)ABPersonCreatePeopleInSourceWithVCardRepresentation(NULL, (__bridge CFDataRef)self.vcardData);
  ABRecordRef person = (__bridge ABRecordRef)[createdPeople firstObject];

  self.firstName = (__bridge_transfer NSString *)ABRecordCopyValue(person, kABPersonFirstNameProperty);
  self.lastName = (__bridge_transfer NSString *)ABRecordCopyValue(person, kABPersonLastNameProperty);

  // Try company, job title, then nickname
  self.extraLabel = (__bridge_transfer NSString *)ABRecordCopyValue(person, kABPersonOrganizationProperty);
  if (!self.extraLabel) {
    self.extraLabel = (__bridge_transfer NSString *)ABRecordCopyValue(person, kABPersonJobTitleProperty);
  }
  if (!self.extraLabel) {
    self.extraLabel = (__bridge_transfer NSString *)ABRecordCopyValue(person, kABPersonNicknameProperty);
  }

  return YES;
}

@end
