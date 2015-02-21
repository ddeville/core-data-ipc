//
//  LLConstants.m
//  Applications
//
//  Created by Damien DeVille on 2/20/15.
//  Copyright (c) 2015 Damien DeVille. All rights reserved.
//

#import "LLConstants.h"

#import <pwd.h>
#import <Security/Security.h>

static NSString *LLDefaultSecurityApplicationGroupIdentifier(void)
{
	SecTaskRef task = NULL;
	
	NSString *applicationGroupIdentifier = nil;
	do {
		task = SecTaskCreateFromSelf(kCFAllocatorDefault);
		if (task == NULL) {
			break;
		}
		
		CFTypeRef applicationGroupIdentifiers = SecTaskCopyValueForEntitlement(task, CFSTR("com.apple.security.application-groups"), NULL);
		if (applicationGroupIdentifiers == NULL) {
			break;
		}
		
		if (CFGetTypeID(applicationGroupIdentifiers) != CFArrayGetTypeID() || CFArrayGetCount(applicationGroupIdentifiers) == 0) {
			CFRelease(applicationGroupIdentifiers);
			break;
		}
		
		CFTypeRef firstApplicationGroupIdentifier = CFArrayGetValueAtIndex(applicationGroupIdentifiers, 0);
		CFRelease(applicationGroupIdentifiers);
		
		if (CFGetTypeID(firstApplicationGroupIdentifier) != CFStringGetTypeID()) {
			break;
		}
		
		applicationGroupIdentifier = CFBridgingRelease(CFRetain(firstApplicationGroupIdentifier));
	} while (0);
	
	if (task != NULL) {
		CFRelease(task);
	}
	
	return applicationGroupIdentifier;
}

NSString *LLConnectionMachServiceName(void)
{
	return [LLDefaultSecurityApplicationGroupIdentifier() stringByAppendingString:@".connection"];
}

NSURL *LLDataPersistentStoreLocation(void)
{
	NSURL *groupContainerURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:LLDefaultSecurityApplicationGroupIdentifier()];
	return [groupContainerURL URLByAppendingPathComponent:@"store.sqlite"];
}
