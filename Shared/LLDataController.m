//
//  LLDataController.m
//  Application
//
//  Created by Damien DeVille on 2/21/15.
//  Copyright (c) 2015 Damien DeVille. All rights reserved.
//

#import "LLDataController.h"

#import "LLConstants.h"

@interface LLDataController ()

@property (readwrite, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readwrite, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end

@implementation LLDataController

- (id)init
{
	self = [super init];
	if (self == nil) {
		return nil;
	}
	
	NSURL *modelLocation = [[NSBundle bundleForClass:[self class]] URLForResource:@"Model" withExtension:@"momd"];
	NSManagedObjectModel *managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelLocation];
	
	NSPersistentStoreCoordinator *persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
	_persistentStoreCoordinator = persistentStoreCoordinator;
	
	NSManagedObjectContext *managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
	managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator;
	_managedObjectContext = managedObjectContext;
	
	return self;
}

- (NSString *)persistentStoreIdentifier
{
	return [self.persistentStoreCoordinator persistentStoreForURL:LLDataPersistentStoreLocation()].identifier;
}

- (BOOL)setup:(NSError **)errorRef
{
	NSPersistentStore *persistentStore = [self.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:LLDataPersistentStoreLocation() options:nil error:errorRef];
	return (persistentStore != nil);
}

- (BOOL)teardown:(NSError **)errorRef
{
	NSPersistentStore *persistentStore = [self.persistentStoreCoordinator persistentStoreForURL:LLDataPersistentStoreLocation()];
	return [self.persistentStoreCoordinator removePersistentStore:persistentStore error:errorRef];
}

@end
