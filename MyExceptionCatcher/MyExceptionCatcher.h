//
//  MyExceptionCatcher.h
//  MyExceptionCatcher
//
//  Created by Petey Mi on 4/27/15.
//  Copyright (c) 2015 Petey Mi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MyExceptionCatcher : NSObject

+(void)exceptionCatcherWriteToFile:(NSString*)filePath;
+(void)exceptionSendByMail:(BOOL)send must:(BOOL)must;

@end
