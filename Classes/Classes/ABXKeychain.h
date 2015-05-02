//
// Altered Version of https://github.com/nicklockwood/FXKeychain
// Altered to not conflict with any existing uses of the library
//
//  FXKeychain.h
//
//  Version 1.5 beta
//
//  Created by Nick Lockwood on 29/12/2012.
//  Copyright 2012 Charcoal Design
//
//  Distributed under the permissive zlib License
//  Get the latest version from here:
//
//  https://github.com/nicklockwood/FXKeychain
//
//  This software is provided 'as-is', without any express or implied
//  warranty.  In no event will the authors be held liable for any damages
//  arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//  claim that you wrote the original software. If you use this software
//  in a product, an acknowledgment in the product documentation would be
//  appreciated but is not required.
//
//  2. Altered source versions must be plainly marked as such, and must not be
//  misrepresented as being the original software.
//
//  3. This notice may not be removed or altered from any source distribution.
//

#import <Foundation/Foundation.h>

#import <Security/Security.h>


#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wobjc-missing-property-synthesis"


#ifndef APPBOTKEYCHAIN_USE_NSCODING
#if TARGET_OS_IPHONE
#define APPBOTKEYCHAIN_USE_NSCODING 1
#else
#define APPBOTKEYCHAIN_USE_NSCODING 0
#endif
#endif


typedef NS_ENUM(NSInteger, ABXKeychainAccess)
{
    ABXKeychainAccessibleWhenUnlocked = 0,
    ABXKeychainAccessibleAfterFirstUnlock,
    ABXKeychainAccessibleAlways,
    ABXKeychainAccessibleWhenUnlockedThisDeviceOnly,
    ABXKeychainAccessibleAfterFirstUnlockThisDeviceOnly,
    ABXKeychainAccessibleAlwaysThisDeviceOnly
};


@interface ABXKeychain : NSObject

+ (instancetype)defaultKeychain;

@property (nonatomic, readonly) NSString *service;
@property (nonatomic, readonly) NSString *accessGroup;
@property (nonatomic, assign) ABXKeychainAccess accessibility;

- (id)initWithService:(NSString *)service
          accessGroup:(NSString *)accessGroup
        accessibility:(ABXKeychainAccess)accessibility;

- (id)initWithService:(NSString *)service
          accessGroup:(NSString *)accessGroup;

- (BOOL)setObject:(id)object forKey:(id)key;
- (BOOL)setObject:(id)object forKeyedSubscript:(id)key;
- (BOOL)removeObjectForKey:(id)key;
- (id)objectForKey:(id)key;
- (id)objectForKeyedSubscript:(id)key;

@end


#pragma GCC diagnostic pop
