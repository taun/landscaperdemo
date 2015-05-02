//
//  ABXIssue.m
//
//  Created by Stuart Hall on 21/05/2014.
//  Copyright (c) 2014 Appbot. All rights reserved.
//

#import "ABXIssue.h"

#include <sys/types.h>
#include <sys/sysctl.h>
#import <mach/mach.h>
#import <mach/mach_host.h>

@implementation ABXIssue

+ (NSURLSessionDataTask*)submit:(NSString*)email
                       feedback:(NSString*)feedback
                    attachments:(NSArray*)attachments
                       metaData:(NSDictionary*)metaData
                       complete:(void(^)(ABXResponseCode responseCode, NSInteger httpCode, NSError *error))complete
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:[self systemInfo]];
    if (feedback.length > 0) {
        [params setObject:feedback forKey:@"issue"];
    }
    if (email.length > 0) {
        [params setObject:email forKey:@"email"];
    }
    if (metaData) {
        [params setObject:metaData forKey:@"meta_data"];
    }
    if (attachments.count > 0) {
        [params setObject:[attachments valueForKeyPath:@"identifier"] forKey:@"attachment_ids"];
    }
    
    return [[ABXApiClient instance] POST:@"issues"
                                  params:params
                                complete:^(ABXResponseCode responseCode, NSInteger httpCode, NSError *error, id JSON) {
                                    if (complete) {
                                        complete(responseCode, httpCode, error);
                                    }
                                }];
}

#pragma mark - System Info

+ (NSDictionary*)systemInfo
{
    NSUInteger totalMemory;
    NSUInteger freeMemory = [self freeMemory:&totalMemory];
    
    uint64_t totalSpace;
    uint64_t freeSpace = [self freeDiskspace:&totalSpace];
    
    return @{ @"os_version" : [@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion] ?: @""],
              @"app_version" : NSBundle.mainBundle.infoDictionary[@"CFBundleVersion"] ?: @"",
              @"app_version_short" : NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"] ?: @"",
              @"app_name" : NSBundle.mainBundle.infoDictionary[@"CFBundleDisplayName"] ?: @"",
              @"device" : [self platform] ?: @"",
              @"language" : [[NSLocale preferredLanguages] firstObject] ?: @"",
              @"locale" : [[NSLocale currentLocale] localeIdentifier] ?: @"",
              @"jailbroken" : @([self isJailbroken]),
              @"free_memory" : @(freeMemory),
              @"total_memory" : @(totalMemory),
              @"free_space" : @(freeSpace),
              @"total_space" : @(totalSpace) };
}

+ (NSString *)platform
{
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithUTF8String:machine];
    free(machine);
    return platform;
}

+ (NSUInteger)freeMemory:(NSUInteger*)totalMemory
{
    mach_port_t           host_port = mach_host_self();
    mach_msg_type_number_t   host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    vm_size_t               pagesize;
    vm_statistics_data_t     vm_stat;
    
    host_page_size(host_port, &pagesize);
    
    host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size);
    
    NSUInteger  mem_used = (vm_stat.active_count + vm_stat.inactive_count + vm_stat.wire_count) * pagesize;
    NSUInteger   mem_free = vm_stat.free_count * pagesize;
    NSUInteger   mem_total = mem_used + mem_free;
    
    *totalMemory = mem_total;
    
    return mem_free;
}

+ (uint64_t)freeDiskspace:(uint64_t*)totalDiskspace
{
    uint64_t totalSpace = 0;
    uint64_t totalFreeSpace = 0;
    NSError *error = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject] error: &error];
    
    if (dictionary) {
        NSNumber *fileSystemSizeInBytes = [dictionary objectForKey: NSFileSystemSize];
        NSNumber *freeFileSystemSizeInBytes = [dictionary objectForKey:NSFileSystemFreeSize];
        totalSpace = [fileSystemSizeInBytes unsignedLongLongValue];
        totalFreeSpace = [freeFileSystemSizeInBytes unsignedLongLongValue];
    }
    
    *totalDiskspace = totalSpace;
    
    return totalFreeSpace;
}

// All credit to https://github.com/itruf/crackify
+ (BOOL)isJailbroken
{
#if !TARGET_IPHONE_SIMULATOR
	//Check for Cydia.app
	BOOL yes;
	if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/%@%@%@%@%@%@%@", @"App", @"lic",@"ati", @"ons/", @"Cyd", @"ia.", @"app"]]
		|| [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/%@%@%@%@%@%@", @"pr", @"iva",@"te/v", @"ar/l", @"ib/a", @"pt/"] isDirectory:&yes]
		||  [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/%@%@%@%@%@%@", @"us", @"r/l",@"ibe", @"xe", @"c/cy", @"dia"] isDirectory:&yes]) {
		//Cydia installed
		return YES;
	}
    
	//Try to write file in private
	NSError *error;
    
	static NSString *str = @"Jailbreak test string";
    
	[str writeToFile:@"/private/test_jail.txt" atomically:YES
			encoding:NSUTF8StringEncoding error:&error];
    
	if (error == nil) {
		// Writed
		return YES;
	}
    else {
		[[NSFileManager defaultManager] removeItemAtPath:@"/private/test_jail.txt" error:nil];
	}
#endif
	return NO;
}


@end
