//
//  RTRecipient.h
//  MessagesKit
//
//  Created by Kevin Wooten on 7/21/15.
//  Copyright (c) 2015 reTXT Labs, LLC. All rights reserved.
//

#import "RTMessages.h"


@interface RTRecipient : NSObject

@property (assign, nonatomic) RTAliasType aliasType;
@property (strong, nonatomic) NSString *alias;
@property (strong, nonatomic) NSString *name;

@end