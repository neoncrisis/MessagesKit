//
//  NotificationDAO.h
//  MessagesKit
//
//  Created by Kevin Wooten on 7/8/14.
//  Copyright (c) 2014 reTXT Labs, LLC. All rights reserved.
//

#import "DAO.h"
#import "Chat.h"
#import "Notification.h"


NS_ASSUME_NONNULL_BEGIN


@interface NotificationDAO : DAO

@property (nonatomic, assign) int chatIdFieldIdx;
@property (nonatomic, assign) int dataFieldIdx;

-(nullable NSArray<__kindof Notification *> *) fetchAllNotificationsForChat:(Chat *)chat error:(NSError **)error;

@end


@interface NotificationDAO (Generics)

-(nullable __kindof Notification *) fetchNotificationWithId:(Id *)id NS_REFINED_FOR_SWIFT;
-(BOOL) fetchNotificationWithId:(Id *)id returning:(Notification *__nullable *__nonnull)msg error:(NSError **)error;
-(nullable NSArray<__kindof Notification *> *) fetchAllNotificationsMatching:(nullable NSString *)where error:(NSError **)error;
-(nullable NSArray<__kindof Notification *> *) fetchAllNotificationsMatching:(nullable NSString *)where parameters:(nullable NSArray *)parameters error:(NSError **)error;
-(nullable NSArray<__kindof Notification *> *) fetchAllNotificationsMatching:(nullable NSString *)where parametersNamed:(nullable NSDictionary *)parameters error:(NSError **)error;
-(nullable NSArray<__kindof Notification *> *) fetchAllNotificationsMatching:(NSPredicate *)predicate
                                                                        offset:(NSUInteger)offset limit:(NSUInteger)limit
                                                                      sortedBy:(nullable NSArray<NSSortDescriptor *> *)sortDescriptors
                                                                         error:(NSError **)error;

-(BOOL) insertNotification:(Notification *)model error:(NSError **)error;
-(BOOL) updateNotification:(Notification *)model error:(NSError **)error;
-(BOOL) upsertNotification:(Notification *)model error:(NSError **)error;
-(BOOL) deleteNotification:(Notification *)model error:(NSError **)error;
-(BOOL) deleteAllNotificationsInArray:(NSArray<Notification *> *)models error:(NSError **)error;
-(BOOL) deleteAllNotificationsAndReturnError:(NSError **)error;
-(BOOL) deleteAllNotificationsMatching:(nullable NSString *)where error:(NSError **)error;
-(BOOL) deleteAllNotificationsMatching:(nullable NSString *)where parameters:(nullable NSArray *)parameters error:(NSError **)error;
-(BOOL) deleteAllNotificationsMatching:(nullable NSString *)where parametersNamed:(nullable NSDictionary *)parameters error:(NSError **)error;

@end


NS_ASSUME_NONNULL_END