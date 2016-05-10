//
//  FMResultSet+Utils.m
//  MessagesKit
//
//  Created by Kevin Wooten on 4/20/16.
//  Copyright © 2016 reTXT Labs LLC. All rights reserved.
//

#import "FMResultSet+Utils.h"

#import "Messages+Exts.h"
#import "BlobDataReference.h"
#import "DataReferences.h"



@interface DataReferenceInflater : NSObject <NSKeyedUnarchiverDelegate>

@property(nonatomic, retain) DBManager *db;
@property(nonatomic, copy) NSString *owner;

-(instancetype) initWithDB:(DBManager *)db owner:(NSString *)owner;

@end


@interface DataReferenceDeflater : NSObject <NSKeyedArchiverDelegate>

@property(nonatomic, retain) DBManager *db;

-(instancetype) initWithDB:(DBManager *)db;

@end




@implementation FMResultSet (Model)

-(NSURL *) URLForColumn:(NSString *)columnName
{
  NSString *val = [self stringForColumn:columnName];
  return val ? [NSURL URLWithString:val] : nil;
}

-(NSURL *) URLForColumnIndex:(int)columnIdx
{
  NSString *val = [self stringForColumnIndex:columnIdx];
  return val ? [NSURL URLWithString:val] : nil;
}

-(Id *) idForColumn:(NSString *)columnName
{
  NSData *val = [self dataForColumn:columnName];
  return val ? [Id idWithData:val] : nil;
}

-(Id *) idForColumnIndex:(int)columnIdx
{
  NSData *val = [self dataForColumnIndex:columnIdx];
  return val ? [Id idWithData:val] : nil;
}

-(CGSize) sizeForColumn:(NSString *)columnName
{
  NSString *val = [self stringForColumn:columnName];
  return val ? CGSizeFromString(val) : CGSizeZero;
}

-(CGSize) sizeForColumnIndex:(int)columnIdx
{
  NSString *val = [self stringForColumnIndex:columnIdx];
  return val ? CGSizeFromString(val) : CGSizeZero;
}

-(id<DataReference>) dataReferenceForColumn:(NSString *)columnName forOwner:(NSString *)owner usingDB:(DBManager *)db
{
  NSData *data = [self dataForColumn:columnName];
  if (!data) {
    return nil;
  }
  
  id<NSKeyedUnarchiverDelegate> uaDelegate = [[DataReferenceInflater alloc] initWithDB:db owner:owner];
  NSKeyedUnarchiver *ua = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
  ua.delegate = uaDelegate;
  
  return [ua decodeObjectForKey:NSKeyedArchiveRootObjectKey];
}

-(id<DataReference>) dataReferenceForColumnIndex:(int)columnIndex forOwner:(NSString *)owner usingDB:(DBManager *)db
{
  NSData *data = [self dataForColumnIndex:columnIndex];
  if (!data) {
    return nil;
  }
  
  id<NSKeyedUnarchiverDelegate> uaDelegate = [[DataReferenceInflater alloc] initWithDB:db owner:owner];
  NSKeyedUnarchiver *ua = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
  ua.delegate = uaDelegate;
  
  return [ua decodeObjectForKey:NSKeyedArchiveRootObjectKey];
}

-(id) nillableObjectForColumnIndex:(int)columnIndex
{
  id val = [self objectForColumnIndex:columnIndex];
  if (val == [NSNull null]) {
    return nil;
  }
  return val;
}

@end




@implementation DataReferenceInflater

-(instancetype) initWithDB:(DBManager *)db owner:(NSString *)owner
{
  self = [self init];
  if (self) {
    self.db = db;
    self.owner = owner;
  }
  return self;
}

-(id)unarchiver:(NSKeyedUnarchiver *)unarchiver didDecodeObject:(id)object
{
  if ([object isKindOfClass:BlobDataReference.class]) {
    BlobDataReference *blobRef = (id)object;
    blobRef.db = self.db;
  }
  return object;
}

@end


@implementation DataReferenceDeflater

-(instancetype) initWithDB:(DBManager *)db
{
  self = [self init];
  if (self) {
    self.db = db;
  }
  return self;
}

@end
