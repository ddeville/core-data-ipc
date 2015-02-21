//
//  Person.h
//  Application
//
//  Created by Damien DeVille on 2/21/15.
//  Copyright (c) 2015 Damien DeVille. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString * LLPersonEntityName;

@interface LLPerson : NSManagedObject

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *company;

@end
