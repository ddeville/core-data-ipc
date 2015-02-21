//
//  LLConnection.h
//  Application
//
//  Created by Damien DeVille on 2/20/15.
//  Copyright (c) 2015 Damien DeVille. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LLPersistentStoreNotification;

@protocol LLConnection <NSObject>

- (void)checkin;

- (void)persistentStoreUpdated:(LLPersistentStoreNotification *)notification;

@end

@protocol LLServer <LLConnection>

@end

@protocol LLClient <LLConnection>

@end
