//
//  MyExceptionCatcher.m
//  MyExceptionCatcher
//
//  Created by Petey Mi on 4/27/15.
//  Copyright (c) 2015 Petey Mi. All rights reserved.
//

#import "MyExceptionCatcher.h"
#import <UIKit/UIKit.h>
#include <libkern/OSAtomic.h>
#include <execinfo.h>

#define  UncaughtExceptionHandlerSignalExceptionName  @"UncaughtExceptionHandlerSignalExceptionName"
#define  UncaughtExceptionHandlerSignalKey  @"UncaughtExceptionHandlerSignalKey"
#define  UncaughtExceptionHandlerAddressesKey  @"UncaughtExceptionHandlerAddressesKey"
#define  UncaughtExceptionHandlerSkipAddressCount  4
#define  UncaughtExceptionHandlerReportAddressCount  5

@implementation MyExceptionCatcher
{
    BOOL _dismissed;
    NSString* _content;
}
static NSString* gFilePath = nil;
static BOOL gSendByMail = NO;
static BOOL gSendByMailMust = NO;

volatile int32_t UncaughtExceptionCount = 0;
const int32_t UncaughtExceptionMaximum = 10;

void MyUncaughtExceptionHander(NSException* exception)
{
    int32_t exceptionCount = OSAtomicIncrement32(&UncaughtExceptionCount);
    if (exceptionCount > UncaughtExceptionMaximum) {
        return;
    }
    NSArray* callStack = [MyExceptionCatcher backtrace];
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionaryWithDictionary:[exception userInfo]];
    [userInfo setValue:callStack forKey:UncaughtExceptionHandlerAddressesKey];
    
    [[[MyExceptionCatcher alloc] init] performSelectorOnMainThread:@selector(handleException:)
                                                        withObject:[NSException exceptionWithName:exception.name reason:exception.reason
                                                          userInfo:userInfo]
                                                     waitUntilDone:YES];
}

void MySignalExceptionHandler(int signal)
{
    int32_t exceptionCount = OSAtomicIncrement32(&UncaughtExceptionCount);
    if (exceptionCount > UncaughtExceptionMaximum) {
        return;
    }
    
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionaryWithObject:@(signal) forKey:UncaughtExceptionHandlerSignalKey];
    NSArray* callStack = [MyExceptionCatcher backtrace];
    [userInfo setValue:callStack forKey:UncaughtExceptionHandlerAddressesKey];
    
    [[[MyExceptionCatcher alloc] init] performSelectorOnMainThread:@selector(handleException:)
                                                        withObject:[NSException exceptionWithName:UncaughtExceptionHandlerSignalExceptionName reason:[NSString stringWithFormat:@"Signal %d was raised.", signal] userInfo:userInfo]
                                                     waitUntilDone:YES];
}
void InstallUncaughtExceptionHandler()
{
    signal(SIGABRT, MySignalExceptionHandler);
    signal(SIGILL, MySignalExceptionHandler);
    signal(SIGSEGV, MySignalExceptionHandler);
    signal(SIGFPE, MySignalExceptionHandler);
    signal(SIGBUS, MySignalExceptionHandler);
    signal(SIGPIPE, MySignalExceptionHandler);
}

+(void)InstallUncaughtExceptionHandler
{
    InstallUncaughtExceptionHandler();
}

+(void)exceptionCatcherWriteToFile:(NSString*)filePath
{
    gFilePath = filePath;
    NSSetUncaughtExceptionHandler(&MyUncaughtExceptionHander);
    [MyExceptionCatcher InstallUncaughtExceptionHandler];
}

+(void)exceptionSendByMail:(BOOL)send must:(BOOL)must
{
    gSendByMail = send;
    gSendByMailMust = must;
    [MyExceptionCatcher exceptionCatcherWriteToFile:nil];
}

+(NSArray*)backtrace
{
    void* callStack[128];
    int frames = backtrace(callStack, 128);
    
    char** strs = backtrace_symbols(callStack, frames);
    
    NSMutableArray* backtrace = [NSMutableArray arrayWithCapacity:frames];
    for (int index = UncaughtExceptionHandlerSkipAddressCount; index < UncaughtExceptionHandlerSkipAddressCount + UncaughtExceptionHandlerReportAddressCount; index++) {
        [backtrace addObject:[NSString stringWithUTF8String:strs[index]]];
    }
    free(strs);
    return backtrace;
}

- (void)alertView:(UIAlertView *)anAlertView clickedButtonAtIndex:(NSInteger)anIndex
{
    if (anIndex == 1)
    {
//        NSString *urlStr = [NSString stringWithFormat:@"mailto://xxx@sina.com.cn?subject=bug报告&body=感谢您的配合!<br><br><br>"
//                            "错误详情:<br>%@<br>--------------------------<br>%@<br>---------------------<br>%@",
//                            name,reason,[arr componentsJoinedByString:@"<br>"]];
//        NSURL *url = [NSURL URLWithString:[urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
//        [[UIApplication sharedApplication] openURL:url];
    }
    _dismissed = YES;
}

-(void)exception:(NSException*)exception
{
    NSArray* array = [exception.userInfo objectForKey:UncaughtExceptionHandlerAddressesKey];
    NSString* reason = [exception reason];
    NSString* name = [exception name];
    
    NSString *content = [NSString stringWithFormat:@"Application information:\n%@ =============Exception crash report=============\nname:%@\nreason:%@\ncallStackSymbols:\n%@", self.appInfo,
                     name,reason,[array componentsJoinedByString:@"\n"]];
    if (gFilePath == nil || gFilePath.length == 0) {
        gFilePath = [self applicationDocumentsDirectory];
    }
    
    [content writeToFile:gFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

-(void)handleException:(NSException*)exception
{
    [self exception:exception];
    
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:exception.name
                                                    message:exception.reason
                                                   delegate:self
                                          cancelButtonTitle:@"OK" otherButtonTitles:@"Send", nil];
    [alert show];
    
    CFRunLoopRef runLoop = CFRunLoopGetCurrent();
    CFArrayRef allModes = CFRunLoopCopyAllModes(runLoop);
    while (!_dismissed) {
        for (NSString* mode in (__bridge NSArray*) allModes) {
            CFRunLoopRunInMode((CFStringRef)mode, 0.001, false);
        }
    }
    
    CFRelease(allModes);
    
    NSSetUncaughtExceptionHandler(NULL);
    
    signal(SIGABRT, SIG_DFL);
    signal(SIGILL, SIG_DFL);
    signal(SIGSEGV, SIG_DFL);
    signal(SIGFPE, SIG_DFL);
    signal(SIGBUS, SIG_DFL);
    signal(SIGPIPE, SIG_DFL);
    
    if ([exception.name isEqualToString:UncaughtExceptionHandlerSignalExceptionName]) {
        kill(getpid(), [[exception.userInfo objectForKey:UncaughtExceptionHandlerSignalKey] intValue]);
    } else {
        [exception raise];
    }
}

-(NSString*)applicationDocumentsDirectory {
     return [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"Exception.text"];
}

-(NSString*)appInfo
{
    NSString *appInfo = [NSString stringWithFormat:@"App : %@ %@(%@)\nDevice : %@\nOS Version : %@ %@\nUDID : %@\n",
                         [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"],
                         [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                         [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"],
                         [UIDevice currentDevice].model,
                         [UIDevice currentDevice].systemName,
                         [UIDevice currentDevice].systemVersion,
                         [UIDevice currentDevice].identifierForVendor.UUIDString];

    return appInfo;
}

@end
