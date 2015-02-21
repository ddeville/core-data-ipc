//
//  LLDataController.h
//  Application
//
//  Created by Damien DeVille on 2/21/15.
//  Copyright (c) 2015 Damien DeVille. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LLDataController : NSObject

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (readonly, strong, nonatomic) NSString *persistentStoreIdentifier;

- (BOOL)setup:(NSError **)errorRef;
- (BOOL)teardown:(NSError **)errorRef;

@end
