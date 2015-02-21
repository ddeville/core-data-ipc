//
//  LLPersistentStoreNotification.m
//  Application
//
//  Created by Damien DeVille on 2/21/15.
//  Copyright (c) 2015 Damien DeVille. All rights reserved.
//

#import "LLPersistentStoreNotification.h"

static NSString * const LLPersistentStoreNotificationUserInfoKey = @"userInfo";
static NSString * const LLPersistentStoreNotificationPersistentStoreIdentifierKey = @"persistentStoreIdentifier";
static NSString * const LLPersistentStoreNotificationSenderProcessIdentifierKey = @"senderProcessIdentifier";

@interface LLPersistentStoreNotification ()

@property (readwrite, strong, nonatomic) NSDictionary *userInfo;

@property (readwrite, copy, nonatomic) NSString *persistentStoreIdentifier;
@property (readwrite, assign, nonatomic) pid_t senderProcessIdentifier;

@end

@implementation LLPersistentStoreNotification

+ (BOOL)supportsSecureCoding
{
	return YES;
}

- (id)initWithCoder:(NSCoder *)decoder
{
	self = [super init];
	if (self == nil) {
		return nil;
	}
	
	NSArray *classes = @[[NSDictionary class], [NSSet class], [NSURL class], [NSString class]];
	_userInfo = [decoder decodeObjectOfClasses:[NSSet setWithArray:classes] forKey:LLPersistentStoreNotificationUserInfoKey];
	_persistentStoreIdentifier = [decoder decodeObjectOfClass:[NSString class] forKey:LLPersistentStoreNotificationPersistentStoreIdentifierKey];
	_senderProcessIdentifier = [[decoder decodeObjectOfClass:[NSNumber class] forKey:LLPersistentStoreNotificationSenderProcessIdentifierKey] intValue];
	
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeObject:self.userInfo forKey:LLPersistentStoreNotificationUserInfoKey];
	[coder encodeObject:self.persistentStoreIdentifier forKey:LLPersistentStoreNotificationPersistentStoreIdentifierKey];
	[coder encodeInt32:self.senderProcessIdentifier forKey:LLPersistentStoreNotificationSenderProcessIdentifierKey];
}

@end

@implementation NSManagedObjectContext (LLPersistentStoreNotification)

+ (LLPersistentStoreNotification *)createPersistentStoreNotificationFromChangeNotification:(NSNotification *)notification persistentStoreIdentifier:(NSString *)persistentStoreIdentifier
{
	NSParameterAssert([notification.name isEqualToString:NSManagedObjectContextDidSaveNotification]);
	
	NSDictionary *userInfo = notification.userInfo;
	if (userInfo == nil) {
		return nil;
	}
	
	NSMutableDictionary *notificationUserInfo = [NSMutableDictionary dictionaryWithCapacity:[userInfo count]];
	
	[userInfo enumerateKeysAndObjectsUsingBlock:^ (id key, NSSet *managedObjects, BOOL *stopUserInfo) {
		if ([managedObjects count] == 0) {
			return;
		}
		
		if (![key isKindOfClass:[NSString class]]) {
			return;
		}
		
		NSMutableSet *managedObjectURIRepresentations = [NSMutableSet setWithCapacity:[managedObjects count]];
		
		[managedObjects enumerateObjectsUsingBlock:^ (NSManagedObject *managedObject, BOOL *stop) {
			[managedObjectURIRepresentations addObject:[[managedObject objectID] URIRepresentation]];
		}];
		
		[notificationUserInfo setObject:managedObjectURIRepresentations forKey:key];
	}];
	
	LLPersistentStoreNotification *persistentStoreNotification = [[LLPersistentStoreNotification alloc] init];
	persistentStoreNotification.userInfo = notificationUserInfo;
	persistentStoreNotification.persistentStoreIdentifier = persistentStoreIdentifier;
	persistentStoreNotification.senderProcessIdentifier = [[NSProcessInfo processInfo] processIdentifier];
	
	return persistentStoreNotification;
}

- (void)mergeChangesFromPersistentStoreNotification:(LLPersistentStoreNotification *)persistentStoreNotification
{
	NSParameterAssert(persistentStoreNotification != nil);
	
	NSNotification *notification = [self _createChangeNotificationFromPersistentStoreNotification:persistentStoreNotification];
	[self mergeChangesFromContextDidSaveNotification:notification];
}

- (NSNotification *)_createChangeNotificationFromPersistentStoreNotification:(LLPersistentStoreNotification *)persistentStoreNotification
{
	NSDictionary *userInfo = persistentStoreNotification.userInfo;
	if (userInfo == nil) {
		return nil;
	}
	
	NSMutableDictionary *notificationUserInfo = [NSMutableDictionary dictionaryWithCapacity:userInfo.count];
	
	[userInfo enumerateKeysAndObjectsUsingBlock:^ (id key, NSSet *managedObjectURIRepresentations, BOOL *stopUserInfo) {
		if (managedObjectURIRepresentations.count == 0) {
			return;
		}
		
		NSMutableSet *managedObjects = [NSMutableSet setWithCapacity:managedObjectURIRepresentations.count];
		
		[managedObjectURIRepresentations enumerateObjectsUsingBlock:^ (NSURL *managedObjectURIRepresentation, BOOL *stop) {
			NSManagedObject *managedObject = [self _fetchCleanManagedObjectForURI:managedObjectURIRepresentation];
			if (managedObject == nil) {
				managedObject = [self _managedObjectForURI:managedObjectURIRepresentation];
			}
			
			if (managedObject == nil) {
				return;
			}
			
			[managedObjects addObject:managedObject];
		}];
		
		[notificationUserInfo setObject:managedObjects forKey:key];
	}];
	
	return [NSNotification notificationWithName:NSManagedObjectContextDidSaveNotification object:nil userInfo:notificationUserInfo];
}

- (NSManagedObject *)_fetchCleanManagedObjectForURI:(NSURL *)URIRepresentation
{
	NSManagedObject *managedObject = [self _managedObjectForURI:URIRepresentation];
	if (managedObject == nil) {
		return nil;
	}
	
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:[managedObject entity]];
	
	NSPredicate *predicate = [NSComparisonPredicate predicateWithLeftExpression:[NSExpression expressionForEvaluatedObject] rightExpression:[NSExpression expressionForConstantValue:managedObject] modifier:NSDirectPredicateModifier type:NSEqualToPredicateOperatorType options:(NSComparisonPredicateOptions)0];
	[fetchRequest setPredicate:predicate];
	
	return [(id)[self executeFetchRequest:fetchRequest error:nil] firstObject];
}

- (NSManagedObject *)_managedObjectForURI:(NSURL *)URIRepresentation
{
	NSManagedObjectID *managedObjectID = [self.persistentStoreCoordinator managedObjectIDForURIRepresentation:URIRepresentation];
	if (managedObjectID == nil) {
		return nil;
	}
	
	return [self objectWithID:managedObjectID];
}

@end
