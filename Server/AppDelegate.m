//
//  AppDelegate.m
//  Server
//
//  Created by Damien DeVille on 2/20/15.
//  Copyright (c) 2015 Damien DeVille. All rights reserved.
//

#import "AppDelegate.h"

#import <objc/runtime.h>
#import <Shared/Shared.h>

@interface AppDelegate () <NSXPCListenerDelegate, LLServer>

@property (strong, nonatomic) IBOutlet NSWindow *window;
@property (strong, nonatomic) IBOutlet NSTableView *tableView;
@property (strong, nonatomic) IBOutlet NSArrayController *contentController;

@property (strong, nonatomic) LLDataController *dataController;

@property (strong, nonatomic) NSXPCListener *listener;
@property (strong, nonatomic) NSMutableArray *clients;

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
	
	self.clients = [NSMutableArray array];
	[self _setupServerConnection];
}

#pragma mark - Actions

- (IBAction)add:(id)sender
{
	LLPerson *person = [NSEntityDescription insertNewObjectForEntityForName:LLPersonEntityName inManagedObjectContext:self.dataController.managedObjectContext];
	person.name = @"Untitled Name";
	[self.dataController.managedObjectContext save:NULL];
}

- (IBAction)remove:(id)sender
{
	LLPerson *person = self.contentController.selectedObjects.firstObject;
	if (!person) {
		NSBeep();
		return;
	}
	
	[self.dataController.managedObjectContext deleteObject:person];
	[self.dataController.managedObjectContext save:NULL];
}

#pragma mark - Notifications

- (void)managedObjectContextDidSave:(NSNotification *)notification
{
	LLPersistentStoreNotification *persistentStoreNotification = [NSManagedObjectContext createPersistentStoreNotificationFromChangeNotification:notification persistentStoreIdentifier:self.dataController.persistentStoreIdentifier];
	[self.clients makeObjectsPerformSelector:@selector(persistentStoreUpdated:) withObject:persistentStoreNotification];
}

#pragma mark - NSXPCListenerDelegate

- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)connection
{
	[[NSOperationQueue mainQueue] addOperationWithBlock:^ {
		[self _acceptClientConnection:connection];
	}];
	
	return YES;
}

#pragma mark - LLServer

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

#pragma mark - NSToolbarItemValidation

- (BOOL)validateToolbarItem:(NSToolbarItem *)toolbarItem
{
	if (sel_isEqual(toolbarItem.action, @selector(add:))) {
		return YES;
	}
	if (sel_isEqual(toolbarItem.action, @selector(remove:))) {
		return (self.contentController.selectionIndexes.count != 0);
	}
	return NO;
}

#pragma mark - Private

- (void)_setupServerConnection
{
	NSXPCListener *listener = [[NSXPCListener alloc] initWithMachServiceName:LLConnectionMachServiceName()];
	listener.delegate = self;
	self.listener = listener;
	
	[listener resume];
}

- (void)_acceptClientConnection:(NSXPCConnection *)connection
{
	connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(LLServer)];
	[connection.exportedInterface setClasses:[NSSet setWithArray:@[[LLPersistentStoreNotification class]]] forSelector:@selector(persistentStoreUpdated:) argumentIndex:0 ofReply:NO];
	connection.exportedObject = self;
	
	connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(LLClient)];
	[connection.remoteObjectInterface setClasses:[NSSet setWithArray:@[[LLPersistentStoreNotification class]]] forSelector:@selector(persistentStoreUpdated:) argumentIndex:0 ofReply:NO];
	id <LLClient> client = connection.remoteObjectProxy;
	
	[self.clients addObject:client];
	
	connection.invalidationHandler = ^ {
		[self.clients removeObject:client];
	};
	
	[connection resume];
	
	[client checkin];
}

@end
