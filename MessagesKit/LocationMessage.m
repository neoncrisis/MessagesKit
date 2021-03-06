//
//  LocationMessage.m
//  MessagesKit
//
//  Created by Kevin Wooten on 1/3/14.
//  Copyright (c) 2014 reTXT Labs, LLC. All rights reserved.
//

#import "LocationMessage.h"

#import "MemoryDataReference.h"
#import "DataReferences.h"

#import "TBase+Utils.h"
#import "MessageDAO.h"
#import "Messages+Exts.h"
#import "NSObject+Utils.h"
#import "NSMutableDictionary+Utils.h"

@import MapKit;


const CGSize kLocationMessageThumbnailSize = {110, 150};

const CGFloat kLocationMessageThumbnailCompressionQuality = 1.0f; // 1.0 max, 0.0 min


@implementation LocationMessage

-(instancetype) initWithId:(Id *)id chat:(Chat *)chat longitude:(double)longitude latitude:(double)latitude
{
  self = [super initWithId:id chat:chat];
  if (self) {
    
    self.longitude = longitude;
    self.latitude = latitude;
    
  }
  return self;
}

-(instancetype) initWithChat:(Chat *)chat longitude:(double)longitude latitude:(double)latitude
{
  return [self initWithId:[Id generate] chat:chat longitude:longitude latitude:latitude];
}

-(id) copy
{
  LocationMessage *copy = [super copy];
  copy.latitude = self.latitude;
  copy.longitude = self.longitude;
  copy.thumbnailData = self.thumbnailData;
  copy.title = self.title;
  return copy;
}

-(BOOL) isEquivalent:(id)object
{
  if (![object isKindOfClass:[LocationMessage class]]) {
    return NO;
  }

  return [self isEquivalentToLocationMessage:object];
}

-(BOOL) isEquivalentToLocationMessage:(LocationMessage *)locationMessage
{
  return [super isEquivalentToMessage:locationMessage] &&
         (self.latitude == locationMessage.latitude) &&
         (self.longitude == locationMessage.longitude) &&
         isEqual(self.thumbnailData, locationMessage.thumbnailData) &&
         isEqual(self.title, locationMessage.title);
}

-(NSString *) alertText
{
  return @"Sent you a location";
}

-(NSString *) summaryText
{
  return @"New location";
}

-(enum MsgType) payloadType
{
  return MsgTypeLocation;
}

-(BOOL) load:(FMResultSet *)resultSet dao:(MessageDAO *)dao error:(NSError **)error
{
  if (![super load:resultSet dao:dao error:error]) {
    return NO;
  }
  
  self.latitude = [resultSet doubleForColumnIndex:dao.data1FieldIdx];
  self.longitude = [resultSet doubleForColumnIndex:dao.data2FieldIdx];
  self.thumbnailData = [resultSet dataForColumnIndex:dao.data3FieldIdx];
  self.title = [resultSet stringForColumnIndex:dao.data4FieldIdx];
  
  return YES;
}

-(BOOL) save:(NSMutableDictionary *)values dao:(DAO *)dao error:(NSError **)error
{
  if (![super save:values dao:dao error:error]) {
    return NO;
  }
  
  [values setNillableObject:@(self.latitude) forKey:@"data1"];
  [values setNillableObject:@(self.longitude) forKey:@"data2"];
  [values setNillableObject:self.thumbnailData forKey:@"data3"];
  [values setNillableObject:self.title forKey:@"data4"];
  
  return YES;
}

-(BOOL) exportPayloadIntoData:(id<DataReference> *)payloadData withMetaData:(NSDictionary **)metaData error:(NSError **)error
{

  *metaData = nil;

  Location *location = [Location new];
  location.title = self.title;
  location.longitude = self.longitude;
  location.latitude = self.latitude;

  NSData *data = [TBaseUtils serializeToData:location error:error];
  if (!data) {
    return NO;
  }
  
  *payloadData = [MemoryDataReference.alloc initWithData:data ofMIMEType:@"application/x-thrift"];
  
  return YES;
}

-(BOOL) importPayloadFromData:(id<DataReference>)payloadData withMetaData:(NSDictionary *)metaData error:(NSError **)error
{
  NSData *data = [DataReferences readAllDataFromReference:payloadData error:error];
  if (!data) {
    return NO;
  }
  
  Location *location = [TBaseUtils deserialize:[Location new]
                                        fromData:data
                                           error:error];
  if (!location) {
    return NO;
  }

  self.longitude = location.longitude;
  self.latitude = location.latitude;
  self.title = location.title;
  self.thumbnailData = nil;
  
  return YES;
}

+(void) generateThumbnailData:(LocationMessage *)msg completion:(void (^)(NSData *data, NSError *error))completionBlock
{
  [self generateThumbnailData:msg try:0 completion:completionBlock];
}

+(void) generateThumbnailData:(LocationMessage *)msg try:(NSInteger)try completion:(void (^)(NSData *data, NSError *error))completionBlock
{
  MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(CLLocationCoordinate2DMake(msg.latitude, msg.longitude), 300, 300);

  MKMapSnapshotOptions *options = [[MKMapSnapshotOptions alloc] init];
  options.region = viewRegion;
  options.scale = [UIScreen mainScreen].scale;
  options.size = CGSizeMake(kLocationMessageThumbnailSize.width * options.scale,
                            kLocationMessageThumbnailSize.height * options.scale);

  MKMapSnapshotter *snapshotter = [[MKMapSnapshotter alloc] initWithOptions:options];
  [snapshotter startWithQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0) completionHandler:^(MKMapSnapshot *snapshot, NSError *error) {

    if (!error) {

      UIImage *image = snapshot.image;
      __block MKAnnotationView *pin;
      dispatch_sync(dispatch_get_main_queue(), ^{ pin = [[MKPinAnnotationView alloc] initWithAnnotation:nil reuseIdentifier:@""]; });

      UIImage *pinImage = pin.image;
      UIGraphicsBeginImageContextWithOptions(image.size, YES, image.scale);

      [image drawAtPoint:CGPointMake(0, 0)];

      CGPoint point = [snapshot pointForCoordinate:CLLocationCoordinate2DMake(msg.latitude, msg.longitude)];
      CGPoint pinCenterOffset = pin.centerOffset;
      point.x -= pin.bounds.size.width / 2.0;
      point.y -= pin.bounds.size.height / 2.0;
      point.x += pinCenterOffset.x;
      point.y += pinCenterOffset.y;
      [pinImage drawAtPoint:point];

      UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
      UIGraphicsEndImageContext();

      NSData *data = UIImageJPEGRepresentation(finalImage, kLocationMessageThumbnailCompressionQuality);

      completionBlock(data, nil);

    }
    else if (try < 3) {

      NSInteger nextTry = try+1;

      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [self generateThumbnailData:msg try:nextTry completion:completionBlock];
      });

    }
    else {

      completionBlock(nil, error);

    }

  }];

}

@end
