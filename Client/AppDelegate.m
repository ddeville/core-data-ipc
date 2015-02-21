//
//  AppDelegate.m
//  Client
//
//  Created by Damien DeVille on 2/20/15.
//  Copyright (c) 2015 Damien DeVille. All rights reserved.
//

#import "AppDelegate.h"

#import <Shared/Shared.h>

@interface AppDelegate () <LLClient>

@property (strong, nonatomic) IBOutlet NSWindow *window;
@property (strong, nonatomic) IBOutlet NSTableView *tableView;
@property (strong, nonatomic) IBOutlet NSArrayController *contentController;

@property (strong, nonatomic) LLDataController *dataController;

@property (strong, nonatomic) NSXPCConnection *connection;
@property (strong, nonatomic) id <LLServer> server;

@end

@implementation AppDelegate

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:_dataController.managedObjectContext];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
	self.dataController = [[LLDataController alloc] init];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managedObjectContextDidSave:) name:NSManagedObjectContextDidSaveNotification object:self.dataController.managedObjectContext];
	[self.dataController setup:NULL];
	
	self.contentController.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
	
	[self _setupClientConnection];
}

#pragma mark - Notifications

- (void)managedObjectContextDidSave:(NSNotification *)notification
{
	LLPersistentStoreNotification *persistentStoreNotification = [NSManagedObjectContext createPersistentStoreNotificationFromChangeNotification:notification persistentStoreIdentifier:self.dataController.persistentStoreIdentifier];
	[self.server persistentStoreUpdated:persistentStoreNotification];
}

#pragma mark - LLClient

- (void)checkin
{
	// no-op
}

- (void)persistentStoreUpdated:(LLPersistentStoreNotification *)notification
{
	[[NSOperationQueue mainQueue] addOperationWithBlock:^ {
		if ([notification.persistentStoreIdentifier isEqualToString:self.dataController.persistentStoreIdentifier]) {
			[self.dataController.managedObjectContext mergeChangesFromPersistentStoreNotification:notification];
		}
	}];
}

#pragma mark - NSControlSubclassNotifications

- (void)controlTextDidEndEditing:(NSNotification *)notification
{
	NSInteger row = [self.tableView rowForView:notification.object];
	if (row == NSNotFound) {
		NSBeep();
		return;
	}
	
	[self.dataController.managedObjectContext save:NULL];
}

#pragma mark - Private

- (void)_setupClientConnection
{
	NSXPCConnection *connection = [[NSXPCConnection alloc] initWithMachServiceName:LLConnectionMachServiceName() options:(NSXPCConnectionOptions)0];
	self.connection = connection;
	
	connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(LLClient)];
	[connection.exportedInterface setClasses:[NSSet setWithArray:@[[LLPersistentStoreNotification class]]] forSelector:@selector(persistentStoreUpdated:) argumentIndex:0 ofReply:NO];
	connection.exportedObject = self;
	
	connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(LLServer)];
	[connection.remoteObjectInterface setClasses:[NSSet setWithArray:@[[LLPersistentStoreNotification class]]] forSelector:@selector(persistentStoreUpdated:) argumentIndex:0 ofReply:NO];
	self.server = [connection remoteObjectProxyWithErrorHandler:^ (NSError *error) {
		self.server = nil;
	}];
	
	[connection resume];
	
	[self.server checkin];
}

@end
