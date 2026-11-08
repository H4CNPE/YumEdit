#import "SigningGroups.h"
#import <dlfcn.h>

NSArray<NSString *> *YumEditSigningGroups(void) {
    void *security = dlopen("/System/Library/Frameworks/Security.framework/Security", RTLD_NOW);
    if (!security) return @[];
    void *(*createTask)(CFAllocatorRef) = dlsym(security, "SecTaskCreateFromSelf");
    CFTypeRef (*copyEntitlement)(void *, CFStringRef, CFErrorRef *) =
        dlsym(security, "SecTaskCopyValueForEntitlement");
    if (!createTask || !copyEntitlement) {
        dlclose(security);
        return @[];
    }
    void *task = createTask(kCFAllocatorDefault);
    if (!task) {
        dlclose(security);
        return @[];
    }
    CFTypeRef value = copyEntitlement(task, CFSTR("com.apple.security.application-groups"), NULL);
    CFRelease(task);
    dlclose(security);
    if (!value) return @[];
    if (CFGetTypeID(value) != CFArrayGetTypeID()) {
        CFRelease(value);
        return @[];
    }
    NSArray *rawGroups = CFBridgingRelease(value);
    NSMutableArray<NSString *> *groups = [NSMutableArray array];
    for (id candidate in rawGroups) {
        if ([candidate isKindOfClass: NSString.class] && [candidate hasPrefix: @"group."]) {
            [groups addObject: candidate];
        }
    }
    return groups;
}
