//
//  WeakReference.h
//  MessagesKit
//
//  Created by Kevin Wooten on 12/4/15.
//  Copyright © 2015 reTXT Labs, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface WeakReference<ObjectType> : NSObject

@property(nonatomic, weak) ObjectType currentReference;
@property(nonatomic, assign) ObjectType originalReference;

+(instancetype) weakReferenceWithValue:(ObjectType)value;

-(instancetype) initWithValue:(ObjectType)value track:(BOOL)track;

@end
