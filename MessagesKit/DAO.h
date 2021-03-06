//
//  DAO.h
//  MessagesKit
//
//  Created by Kevin Wooten on 7/7/14.
//  Copyright (c) 2014 reTXT Labs, LLC. All rights reserved.
//

#import "Model.h"


NS_ASSUME_NONNULL_BEGIN


@interface DAO<ObjectType : Model *> : NSObject

@property (readonly, weak, nonatomic) DBManager *dbManager;
@property (readonly, nonatomic) NSString *name;
@property (readonly, nonatomic) DBTableInfo *tableInfo;
@property (readonly, nonatomic) NSDictionary<NSString *, NSString *> *classTableNames;

-(BOOL) managesClass:(Class)modelClass;

-(id) dbIdForId:(id)id;

-(nullable __kindof ObjectType) fetchObjectWithId:(id)id NS_REFINED_FOR_SWIFT;
-(BOOL) fetchObjectWithId:(id)id returning:(ObjectType __nullable *__nonnull)msg error:(NSError **)error;
-(NSArray<__kindof ObjectType> *) fetchAllObjectsMatching:(nullable NSString *)where error:(NSError **)error;
-(NSArray<__kindof ObjectType> *) fetchAllObjectsMatching:(nullable NSString *)where parameters:(nullable NSArray *)parameters error:(NSError **)error;
-(NSArray<__kindof ObjectType> *) fetchAllObjectsMatching:(nullable NSString *)where parametersNamed:(nullable NSDictionary *)parameters error:(NSError **)error;;
-(NSArray<__kindof ObjectType> *) fetchAllObjectsMatching:(NSPredicate *)predicate
                                                  offset:(NSUInteger)offset limit:(NSUInteger)limit
                                                sortedBy:(nullable NSArray<NSSortDescriptor *> *)sortDescriptors
                                                   error:(NSError **)error;;

-(nullable __kindof ObjectType) refreshObject:(ObjectType)object;

-(BOOL) insertObject:(ObjectType)model error:(NSError **)error;
-(BOOL) updateObject:(ObjectType)model error:(NSError **)error;
-(BOOL) upsertObject:(ObjectType)model error:(NSError **)error;
-(BOOL) deleteObject:(ObjectType)model error:(NSError **)error;
-(BOOL) deleteAllObjectsInArray:(NSArray<__kindof ObjectType> *)models error:(NSError **)error;
-(BOOL) deleteAllObjectsAndReturnError:(NSError **)error;
-(BOOL) deleteAllObjectsMatching:(nullable NSString *)where error:(NSError **)error;
-(BOOL) deleteAllObjectsMatching:(nullable NSString *)where parameters:(nullable NSArray *)parameters error:(NSError **)error;
-(BOOL) deleteAllObjectsMatching:(nullable NSString *)where parametersNamed:(nullable NSDictionary<NSString *, NSObject *> *)parameters error:(NSError **)error;

-(void) clearCache;

@end



@interface Model (DAO)

+(int32_t) typeCode;

@end


NS_ASSUME_NONNULL_END
