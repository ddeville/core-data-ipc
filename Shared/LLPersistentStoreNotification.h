//
//  LLPersistentStoreNotification.h
//  Application
//
//  Created by Damien DeVille on 2/21/15.
//  Copyright (c) 2015 Damien DeVille. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LLPersistentStoreNotification : NSObject <NSSecureCoding>

@property (readonly, strong, nonatomic) NSDictionary *userInfo;

@property (readonly, copy, nonatomic) NSString *persistentStoreIdentifier;
@property (readonly, assign, nonatomic) pid_t senderProcessIdentifier;

@end

@interface NSManagedObjectContext (LLPersistentStoreNotification)

+ (LLPersistentStoreNotification *)createPersistentStoreNotificationFromChangeNotification:(NSNotification *)notification persistentStoreIdentifier:(NSString *)persistentStoreIdentifier;
- (void)mergeChangesFromPersistentStoreNotification:(LLPersistentStoreNotification *)persistentStoreNotification;

@end

