//
//  VideoMessage.h
//  MessagesKit
//
//  Created by Kevin Wooten on 1/3/14.
//  Copyright (c) 2014 reTXT Labs, LLC. All rights reserved.
//

#import "Message.h"


NS_ASSUME_NONNULL_BEGIN


@interface VideoMessage : Message

@property (copy, nullable, nonatomic) NSData *thumbnailData;
@property (assign, nonatomic) CGSize thumbnailSize;

@property (copy, nonatomic) id<DataReference> data;

-(instancetype) init NS_UNAVAILABLE;
-(instancetype) initWithId:(Id *)id chat:(Chat *)chat NS_UNAVAILABLE;

-(instancetype) initWithId:(Id *)id chat:(Chat *)chat data:(id<DataReference>)data thumbnailData:(nullable NSData *)thumbnailData NS_DESIGNATED_INITIALIZER;
-(instancetype) initWithId:(Id *)id chat:(Chat *)chat data:(id<DataReference>)data;
-(instancetype) initWithChat:(Chat *)chat data:(id<DataReference>)data thumbnailData:(nullable NSData *)thumbnailData;
-(instancetype) initWithChat:(Chat *)chat data:(id<DataReference>)data;

-(BOOL) isEquivalentToVideoMessage:(VideoMessage *)videoMessage;

+(nullable NSData *) generateThumbnailWithVideoData:(id<DataReference>)videoData atFrameTime:(NSString *)frameTime size:(CGSize *)size error:(NSError **)error;

@end


NS_ASSUME_NONNULL_END
