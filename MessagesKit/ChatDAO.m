//
//  ChatDAO.m
//  MessagesKit
//
//  Created by Kevin Wooten on 7/7/14.
//  Copyright (c) 2014 reTXT Labs, LLC. All rights reserved.
//

#import "ChatDAO.h"

#import "MessageDAO.h"
#import "DAO+Internal.h"
#import "NSObject+Utils.h"

@import ObjectiveC;
@import YOLOKit;


@implementation ChatDAO

+(void) initialize
{
  class_duplicateMethod(self, @selector(fetchChatWithId:), @selector(fetchObjectWithId:));
  class_duplicateMethod(self, @selector(fetchChatWithId:returning:error:), @selector(fetchObjectWithId:returning:error:));
  class_duplicateMethod(self, @selector(fetchAllChatsMatching:error:), @selector(fetchAllObjectsMatching:error:));
  class_duplicateMethod(self, @selector(fetchAllChatsMatching:parameters:error:), @selector(fetchAllObjectsMatching:parameters:error:));
  class_duplicateMethod(self, @selector(fetchAllChatsMatching:parametersNamed:error:), @selector(fetchAllObjectsMatching:parametersNamed:error:));
  class_duplicateMethod(self, @selector(fetchAllChatsMatching:offset:limit:sortedBy:error:), @selector(fetchAllObjectsMatching:offset:limit:sortedBy:error:));
  class_duplicateMethod(self, @selector(insertChat:error:), @selector(insertObject:error:));
  class_duplicateMethod(self, @selector(updateChat:error:), @selector(updateObject:error:));
  class_duplicateMethod(self, @selector(upsertChat:error:), @selector(upsertObject:error:));
  class_duplicateMethod(self, @selector(deleteChat:error:), @selector(deleteObject:error:));
  class_duplicateMethod(self, @selector(deleteAllChatsInArray:error:), @selector(deleteAllObjectsInArray:error:));
  class_duplicateMethod(self, @selector(deleteAllChatsAndReturnError:), @selector(deleteAllObjectsAndReturnError:));
  class_duplicateMethod(self, @selector(deleteAllChatsMatching:error:), @selector(deleteAllObjectsMatching:error:));
  class_duplicateMethod(self, @selector(deleteAllChatsMatching:parameters:error:), @selector(deleteAllObjectsMatching:parameters:error:));
  class_duplicateMethod(self, @selector(deleteAllChatsMatching:parametersNamed:error:), @selector(deleteAllObjectsMatching:parametersNamed:error:));
}

-(instancetype) initWithDBManager:(DBManager *)dbManager
{
  __block DBTableInfo *tableInfo;
  [dbManager.pool inReadableDatabase:^void(FMDatabase *db) {
    tableInfo = [DBTableInfo loadTableInfo:db tableName:@"chat"];
  }];
  
  self = [super initWithDBManager:dbManager
                        tableInfo:tableInfo
                        rootClass:[Chat class]
                   derivedClasses:@[[UserChat class], [GroupChat class]]];
  if (self) {

    _aliasFieldIdx = [tableInfo findField:@"alias"];
    _localAliasFieldIdx = [tableInfo findField:@"localAlias"];
    _lastMessageFieldIdx = [tableInfo findField:@"lastMessage"];
    _clarifiedCountFieldIdx = [tableInfo findField:@"clarifiedCount"];
    _updatedCountFieldIdx = [tableInfo findField:@"updatedCount"];
    _startedDateFieldIdx = [tableInfo findField:@"startedDate"];
    _totalMessagesFieldIdx = [tableInfo findField:@"totalMessages"];
    _totalSentFieldIdx = [tableInfo findField:@"totalSent"];
    _customTitleFieldIdx = [tableInfo findField:@"customTitle"];
    _membersFieldIdx = [tableInfo findField:@"members"];
    _activeMembersFieldIdx = [tableInfo findField:@"activeMembers"];
    _draftFieldIdx = [tableInfo findField:@"draft"];
    
  }

  return self;
}

-(void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(NSString *) name
{
  return @"Chat";
}

-(id) dbIdForId:(id)id
{
  return [id data];
}

-(BOOL) fetchChatForAlias:(NSString *)alias localAlias:(NSString *)localAlias returning:(Chat *__autoreleasing  _Nullable * _Nonnull)chat error:(NSError * _Nullable __autoreleasing * _Nullable)error
{
  __block BOOL valid = NO;

  [self.dbManager.pool inReadableDatabase:^(FMDatabase *db) {

    FMResultSet *resultSet = [db executeQuery:[self.tableInfo.fetchAllSQL stringByAppendingString:@" WHERE lower(alias) = ? AND lower(localAlias) = ?"]
                                  valuesArray:@[alias.lowercaseString, localAlias.lowercaseString]
                                        error:error];
    if (!resultSet) {
      return;
    }
    
    if ([resultSet next]) {      
      Chat *found = [self load:resultSet error:error];
      if (!found) {
        return;
      }
      *chat = found;
    }
    
    valid = YES;

    [resultSet close];
  }];

  return valid;
}

-(BOOL) updateChat:(Chat *)chat withLastMessage:(Message *)message error:(NSError **)error
{
  __block BOOL updated = NO;
  __block int count = 0;

  [self.dbManager.pool inWritableDatabase:^(FMDatabase *db) {

    chat.lastMessage = message;

    if (![db executeUpdate:@"UPDATE chat SET lastMessage = ?, totalMessages = ?, totalSent = ?  WHERE id = ?"
              valuesArray:@[message.dbId, @(chat.totalMessages), @(chat.totalSent), chat.dbId]
                     error:error]) {
      return;
    }
    
    count = db.changes;
    updated = YES;
  }];

  if (count > 0) {
    [self updated:chat];
  }

  return updated;
}

-(BOOL) updateChat:(Chat *)chat withLastSentMessage:(Message *)message error:(NSError **)error
{
  chat.totalSent += 1;
  chat.totalMessages += 1;

  return [self updateChat:chat withLastMessage:message error:error];
}

-(BOOL) updateChat:(Chat *)chat withLastReceivedMessage:(Message *)message error:(NSError **)error
{
  chat.totalMessages += 1;

  return [self updateChat:chat withLastMessage:message error:error];
}

-(BOOL) updateChat:(GroupChat *)chat addGroupMember:(NSString *)alias error:(NSError **)error
{
  if ([chat.members containsObject:alias]) {
    return YES;
  }

  return [self updateChat:chat
              withMembers:[chat.members setByAddingObject:alias]
            activeMembers:[chat.activeMembers setByAddingObject:alias]
                    error:error];
}

-(BOOL) updateChat:(GroupChat *)chat removeGroupMember:(NSString *)alias error:(NSError **)error
{
  if (![chat.members containsObject:alias]) {
    return YES;
  }

  return [self updateChat:chat
              withMembers:chat.members
            activeMembers:chat.activeMembers.without(alias)
                    error:error];
}

-(BOOL) updateChat:(GroupChat *)chat withMembers:(NSSet *)members activeMembers:(NSSet *)activeMembers error:(NSError **)error
{
  __block BOOL valid = NO;
  __block BOOL updated = NO;

  [self.dbManager.pool inWritableDatabase:^(FMDatabase *db) {

    chat.members = members;
    chat.activeMembers = activeMembers;

    valid = [db executeUpdate:@"UPDATE chat SET members = ?, activeMembers = ? WHERE id = ?"
                  valuesArray:@[members.join(@","), activeMembers.join(@","), chat.dbId]
                        error:error];
    if (!valid) {
      return;
    }
    
    updated = db.changes > 0;
  }];
  
  if (updated) {
    [self updated:chat];
  }

  return valid;
}

-(BOOL) deleteObject:(Model *)model error:(NSError * _Nullable __autoreleasing * _Nullable)error
{
  __block BOOL deleted;

  [self.dbManager.pool inTransaction:^(FMDatabase *db, BOOL *rollback) {

    deleted = [super deleteObject:model error:error];

    if (deleted) {

      MessageDAO *dao = self.dbManager[@"Message"];

      if (![dao deleteAllMessagesForChat:(id)model error:error]) {
        deleted = NO;
        return;
      }
    }

  }];

  return deleted;
}

-(BOOL) updateChat:(Chat *)chat withClarifiedCount:(int)clarifiedCount
{
  __block BOOL updated;

  [self.dbManager.pool inWritableDatabase:^(FMDatabase *db) {

    chat.clarifiedCount = clarifiedCount;

    if ([db executeUpdate:@"UPDATE chat SET clarifiedCount = ? WHERE id = ?",
         @(clarifiedCount), chat.dbId])
    {
      updated = db.changes > 0;
    }

  }];

  if (updated) {

    [self updated:chat];
  }

  return updated;
}

-(BOOL) updateChat:(Chat *)chat withUpdatedCount:(int)updatedCount
{
  __block BOOL updated;

  [self.dbManager.pool inWritableDatabase:^(FMDatabase *db) {

    chat.updatedCount = updatedCount;

    if ([db executeUpdate:@"UPDATE chat SET updatedCount = ? WHERE id = ?",
         @(updatedCount), chat.dbId])
    {
      updated = db.changes > 0;
    }

  }];

  if (updated) {

    [self updated:chat];
  }

  return updated;
}

-(BOOL) resetUnreadCountsForChat:(Chat *)chat
{
  __block BOOL updated;

  [self.dbManager.pool inWritableDatabase:^(FMDatabase *db) {

    chat.updatedCount = 0;
    chat.clarifiedCount = 0;

    if ([db executeUpdate:@"UPDATE chat SET updatedCount = ?, clarifiedCount = ? WHERE id = ?", @(chat.updatedCount),
         @(chat.clarifiedCount), chat.dbId])
    {
      updated = db.changes > 0;
    }

  }];

  if (updated) {

    [self updated:chat];
  }

  return updated;
}

@end


@implementation UserChat (DAO)

+(ChatType) typeCode
{
  return ChatTypeUser;
}

@end

@implementation GroupChat (DAO)

+(ChatType) typeCode
{
  return ChatTypeGroup;
}

@end
