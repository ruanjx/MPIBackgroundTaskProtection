//
//  UIApplication+MPIBackgroundTaskTrace.m
//  MPIBackgroundTaskProtectionDemo
//
//  Created by Bear on 2020/4/29.
//  Copyright © 2020 Bear. All rights reserved.
//

#import "UIApplication+MPIBackgroundTaskProtection.h"
#import <objc/runtime.h>
#import <pthread.h>
#import <Foundation/Foundation.h>

@implementation UIApplication (MPIBackgroundTaskProtection)

static NSMutableSet<NSNumber *> *taskIDs;
static pthread_mutex_t _lock;

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self mpi_swizzleInstanceMethod:@selector(beginBackgroundTaskWithName:expirationHandler:)
                                   with:@selector(mpi_beginBackgroundTaskWithName:expirationHandler:)];
        
        [self mpi_swizzleInstanceMethod:@selector(beginBackgroundTaskWithExpirationHandler:)
                                   with:@selector(mpi_beginBackgroundTaskWithExpirationHandler:)];
        
        [self mpi_swizzleInstanceMethod:@selector(endBackgroundTask:)
                                   with:@selector(mpi_endBackgroundTask:)];
        
        taskIDs = [NSMutableSet set];
        
        pthread_mutexattr_t attr;
        pthread_mutexattr_init (&attr);
        pthread_mutexattr_settype (&attr, PTHREAD_MUTEX_RECURSIVE);
        pthread_mutex_init (&_lock, &attr);
        pthread_mutexattr_destroy (&attr);
    });
}

- (UIBackgroundTaskIdentifier)mpi_beginBackgroundTaskWithExpirationHandler:(void(^ __nullable)(void))handler {
    __block UIBackgroundTaskIdentifier identifier = [self mpi_beginBackgroundTaskWithExpirationHandler:^{
        if (handler) {
            handler();
        }
        
        [self endBackgroundTask:identifier];
    }];

    [self taskIDsAddIdentifier:identifier];
    return identifier;
}

- (UIBackgroundTaskIdentifier)mpi_beginBackgroundTaskWithName:(nullable NSString *)taskName expirationHandler:(void(^ __nullable)(void))handler {
    __block UIBackgroundTaskIdentifier identifier = [self mpi_beginBackgroundTaskWithExpirationHandler:^{
        if (handler) {
            handler();
        }
        
        [self endBackgroundTask:identifier];
    }];

    [self taskIDsAddIdentifier:identifier];
    return identifier;
}

- (void)mpi_endBackgroundTask:(UIBackgroundTaskIdentifier)identifier {
    if (![self taskIDsContainerIdentifier:identifier]) {
        return;
    }

    [self mpi_endBackgroundTask:identifier];
    [self taskIDsRemoveIdentifier:identifier];
}

#pragma mark - Private

+ (BOOL)mpi_swizzleInstanceMethod:(SEL)originalSel with:(SEL)newSel {
    Method originalMethod = class_getInstanceMethod(self, originalSel);
    Method newMethod = class_getInstanceMethod(self, newSel);
    if (!originalMethod || !newMethod) return NO;
    
    class_addMethod(self,
                    originalSel,
                    class_getMethodImplementation(self, originalSel),
                    method_getTypeEncoding(originalMethod));
    class_addMethod(self,
                    newSel,
                    class_getMethodImplementation(self, newSel),
                    method_getTypeEncoding(newMethod));
    
    method_exchangeImplementations(class_getInstanceMethod(self, originalSel),
                                   class_getInstanceMethod(self, newSel));
    return YES;
}

- (void)taskIDsRemoveIdentifier:(UIBackgroundTaskIdentifier)identifier {
    pthread_mutex_lock(&_lock);
    [taskIDs removeObject:@(identifier)];
    pthread_mutex_unlock(&_lock);
}

- (void)taskIDsAddIdentifier:(UIBackgroundTaskIdentifier)identifier {
    pthread_mutex_lock(&_lock);
    [taskIDs addObject:@(identifier)];
    pthread_mutex_unlock(&_lock);
}

- (BOOL)taskIDsContainerIdentifier:(UIBackgroundTaskIdentifier)identifier {
    BOOL result;
    pthread_mutex_lock(&_lock);
    result = [taskIDs containsObject:@(identifier)];
    pthread_mutex_unlock(&_lock);
    return result;
}

@end
