
#import "LMApplication.h"
#import "LMKeychain.h"

static NSString*const kLinkedMEKeychainService          = @"LinkedMEKeychainService";
static NSString*const kLinkedMEKeychainDevicesKey       = @"LinkedMEKeychainDevices";
static NSString*const kLinkedMEKeychainFirstBuildKey    = @"LinkedMEKeychainFirstBuild";
static NSString*const kLinkedMEKeychainFirstInstalldKey = @"LinkedMEKeychainFirstInstall";

#pragma mark - LMApplication

@implementation LMApplication

// LMApplication checks a few values in keychain
// Checking keychain from main thread early in the app lifecycle can deadlock.  INTENG-7291
+ (void)loadCurrentApplicationWithCompletion:(void (^)(LMApplication *application))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        LMApplication *tmp = [LMApplication currentApplication];
        if (completion) {
            completion(tmp);
        }
    });
}

+ (LMApplication*) currentApplication {
    static LMApplication *bnc_currentApplication = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        bnc_currentApplication = [LMApplication createCurrentApplication];
    });
    return bnc_currentApplication;
}

+ (LMApplication*) createCurrentApplication {
    LMApplication *application = [[LMApplication alloc] init];
    if (!application) return application;
    NSDictionary *info = [NSBundle mainBundle].infoDictionary;

    application->_bundleID = [NSBundle mainBundle].bundleIdentifier;
    application->_displayName = info[@"CFBundleDisplayName"];
    application->_shortDisplayName = info[@"CFBundleName"];

    application->_displayVersionString = info[@"CFBundleShortVersionString"];
    application->_versionString = info[@"CFBundleVersion"];

    application->_firstInstallBuildDate = [LMApplication firstInstallBuildDate];
    application->_currentBuildDate = [LMApplication currentBuildDate];

    application->_firstInstallDate = [LMApplication firstInstallDate];
    application->_currentInstallDate = [LMApplication currentInstallDate];

    NSString*group =  [LMKeychain securityAccessGroup];
    if (group) {
        NSRange range = [group rangeOfString:@"."];
        if (range.location != NSNotFound) {
            application->_teamID = [[group substringToIndex:range.location] copy];
        }
    }

    return application;
}

+ (NSDate*) currentBuildDate {
    NSURL *appURL = nil;
    NSURL *bundleURL = [NSBundle mainBundle].bundleURL;
    NSDictionary *info = [NSBundle mainBundle].infoDictionary;
    NSString *appName = info[(__bridge NSString*)kCFBundleExecutableKey];
    if (appName.length > 0 && bundleURL) {
        appURL = [bundleURL URLByAppendingPathComponent:appName];
    } else {
        NSString *path = [[NSProcessInfo processInfo].arguments firstObject];
        if (path) appURL = [NSURL fileURLWithPath:path];
    }
    if (appURL == nil)
        return nil;

    NSError *error = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDictionary *attributes = [fileManager attributesOfItemAtPath:appURL.path error:&error];
    if (error) {
        NSLog(@"Can't get build date: %@.", error);
        return nil;
    }
    NSDate * buildDate = [attributes fileCreationDate];
    if (buildDate == nil || [buildDate timeIntervalSince1970] <= 0.0) {
        NSLog(@"Invalid build date: %@.", buildDate);
    }
    return buildDate;
}

+ (NSDate*) firstInstallBuildDate {
    NSError *error = nil;
    NSDate *firstBuildDate =
        [LMKeychain retrieveValueForService:kLinkedMEKeychainService
            key:kLinkedMEKeychainFirstBuildKey
            error:&error];
    if (firstBuildDate)
        return firstBuildDate;

    firstBuildDate = [self currentBuildDate];
    error = [LMKeychain storeValue:firstBuildDate
        forService:kLinkedMEKeychainService
        key:kLinkedMEKeychainFirstBuildKey
        cloudAccessGroup:nil];
    if (error) NSLog(@"Keychain store: %@.", error);
    return firstBuildDate;
}


+ (NSDate *) currentInstallDate {
    NSDate *installDate = [NSDate date];
    
    #if !TARGET_OS_TV
    // tvOS always returns a creation date of Unix epoch 0 on device
    installDate = [self creationDateForLibraryDirectory];
    #endif
    
    if (installDate == nil || [installDate timeIntervalSince1970] <= 0.0) {
        NSLog(@"Invalid install date, using [NSDate date].");
    }
    return installDate;
}

+ (NSDate *)creationDateForLibraryDirectory {
    NSError *error = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *directoryURL = [[fileManager URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] firstObject];
    NSDictionary *attributes = [fileManager attributesOfItemAtPath:directoryURL.path error:&error];
    if (error) {
        NSLog(@"Can't get creation date for Library directory: %@", error);
       return nil;
    }
    return [attributes fileCreationDate];
}

+ (NSDate*) firstInstallDate {
    // check keychain for stored install date, on iOS this is lost on app deletion.
    NSError *error = nil;
    NSDate* firstInstallDate = [LMKeychain retrieveValueForService:kLinkedMEKeychainService key:kLinkedMEKeychainFirstInstalldKey error:&error];
    if (firstInstallDate) {
        return firstInstallDate;
    }
    
    // check filesytem for creation date
    firstInstallDate = [self currentInstallDate];
    
    // save filesystem time to keychain
    error = [LMKeychain storeValue:firstInstallDate forService:kLinkedMEKeychainService key:kLinkedMEKeychainFirstInstalldKey cloudAccessGroup:nil];
    if (error) {
        NSLog(@"Keychain store: %@.", error);
    }
    return firstInstallDate;
}

- (NSDictionary*) deviceKeyIdentityValueDictionary {
    @synchronized (self.class) {
        NSError *error = nil;
        NSDictionary *deviceDictionary =
            [LMKeychain retrieveValueForService:kLinkedMEKeychainService
                key:kLinkedMEKeychainDevicesKey
                error:&error];
        
        if (error) NSLog(@"While retrieving deviceKeyIdentityValueDictionary: %@.", error);
        if (!deviceDictionary) deviceDictionary = @{};
        return deviceDictionary;
    }
}

@end


