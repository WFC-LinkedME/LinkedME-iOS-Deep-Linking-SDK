//
//  LMServerRequestQueue.m
//  iOS-Deep-Linking-SDK
//
//  Created on 9/6/14.
//
//

#import "LMServerRequestQueue.h"
#import "LMPreferenceHelper.h"
#import "LMCloseRequest.h"
#import "LMOpenRequest.h"

NSString * const LINKEDME_QUEUE_FILE = @"LKMEServerRequestQueue";
NSUInteger const LINKEDME_WRITE_TIMEOUT = 3;

@interface LMServerRequestQueue()

@property (nonatomic, strong) NSMutableArray *queue;
@property (nonatomic) dispatch_queue_t asyncQueue;
@property (strong, nonatomic) NSTimer *writeTimer;

@end



@implementation LMServerRequestQueue

- (id)init {
    if (self = [super init]) {
        self.queue = [NSMutableArray array];
        self.asyncQueue = dispatch_queue_create("brnch_persist_queue", NULL);
    }
    return self;
}

- (void)enqueue:(LMServerRequest *)request {
    @synchronized(self.queue) {
        if (request) {
            [self.queue addObject:request];
            [self persistEventually];
        }
    }
}

- (void)insert:(LMServerRequest *)request at:(unsigned int)index {
    @synchronized(self.queue) {
        if (index > self.queue.count) {
            [[LMPreferenceHelper preferenceHelper] log:FILE_NAME line:LINE_NUM message:@"无效的队列操作：索引超出范围"];
            return;
        }
        
        if (request) {
            [self.queue insertObject:request atIndex:index];
            [self persistEventually];
        }
    }
}

- (LMServerRequest *)dequeue {
    LMServerRequest *request = nil;
    
    @synchronized(self.queue) {
        if (self.queue.count > 0) {
            request = [self.queue objectAtIndex:0];
            [self.queue removeObjectAtIndex:0];
            [self persistEventually];
        }
    }
    
    return request;
}

- (NSInteger)queueDepth {
    @synchronized (self) {
        return (NSInteger) self.queue.count;
    }
}

- (LMServerRequest *)removeAt:(unsigned int)index {
    LMServerRequest *request = nil;
    @synchronized(self.queue) {
        if (index >= self.queue.count) {
            [[LMPreferenceHelper preferenceHelper] log:FILE_NAME line:LINE_NUM message:@"无效的队列操作：索引超出范围!"];
            return nil;
        }
        
        request = [self.queue objectAtIndex:index];
        [self.queue removeObjectAtIndex:index];
        [self persistEventually];
    }
    
    return request;
}

- (void)remove:(LMServerRequest *)request {
    [self.queue removeObject:request];
    [self persistEventually];
}

- (LMServerRequest *)peek {
    return [self peekAt:0];
}

- (LMServerRequest *)peekAt:(unsigned int)index {
    if (index >= self.queue.count) {
        [[LMPreferenceHelper preferenceHelper] log:FILE_NAME line:LINE_NUM message:@"Invalid queue operation: index out of bound!"];
        return nil;
    }
    
    LMServerRequest *request = nil;
    request = [self.queue objectAtIndex:index];
    
    return request;
}

- (unsigned int)size {
    return (unsigned int)self.queue.count;
}

- (NSString *)description {
    return [self.queue description];
}

- (void)clearQueue {
    [self.queue removeAllObjects];
    [self persistEventually];
}


/*
 *检查当前状态是安装还是打开
 *return YES 打开
 */
- (BOOL)containsInstallOrOpen {
    for (int i = 0; i < self.queue.count; i++) {
        LMServerRequest *req = [self.queue objectAtIndex:i];
        // Install extends open, so only need to check open.
        if ([req isKindOfClass:[LMOpenRequest class]]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)removeInstallOrOpen {
    @synchronized (self.queue) {
        for (int i = 0; i < self.queue.count; i++) {
            LMOpenRequest *req = [self.queue objectAtIndex:i];
            if ([req isKindOfClass:[LMOpenRequest class]]) {
                req.callback = nil;
                [self remove:req];
                return YES;
            }
        }
        return NO;
    }
}

- (LMOpenRequest *)moveInstallOrOpenToFront:(NSInteger)networkCount {
    BOOL requestAlreadyInProgress = networkCount > 0;

    LMServerRequest *openOrInstallRequest;
    for (int i = 0; i < self.queue.count; i++) {
        LMServerRequest *req = [self.queue objectAtIndex:i];
        if ([req isKindOfClass:[LMOpenRequest class]]) {
            
            if (i == 0 || (i == 1 && requestAlreadyInProgress)) {
                return (LMOpenRequest *)req;
            }

            openOrInstallRequest = [self removeAt:i];
            break;
        }
    }
    
    if (!openOrInstallRequest) {
        NSLog(@"[Linkedme Warning] 尝试将其移到最前，队列中没有安装或打开请求");
        return nil;
    }
    
    if (!requestAlreadyInProgress || !self.queue.count) {
        [self insert:openOrInstallRequest at:0];
    }
    else {
        [self insert:openOrInstallRequest at:1];
    }
    
    return (LMOpenRequest *)openOrInstallRequest;
}

- (BOOL)containsClose {
    for (int i = 0; i < self.queue.count; i++) {
        LMServerRequest *req = [self.queue objectAtIndex:i];
        if ([req isKindOfClass:[LMCloseRequest class]]) {
            return YES;
        }
    }

    return NO;
}


#pragma mark - Private method

- (void)persistEventually {
    if (!self.writeTimer.valid) {
        self.writeTimer = [NSTimer scheduledTimerWithTimeInterval:LINKEDME_WRITE_TIMEOUT target:self selector:@selector(persistToDisk) userInfo:nil repeats:NO];
    }
}

- (void)persistImmediately {
    [self.writeTimer invalidate];
    
    [self persistToDisk];
}

- (void)persistToDisk {
    NSArray *requestsToPersist = [self.queue copy];
    dispatch_async(self.asyncQueue, ^{
        @try {
            NSMutableArray *encodedRequests = [[NSMutableArray alloc] init];
            for (LMServerRequest *req in requestsToPersist) {
                // Don't persist these requests
                if ([req isKindOfClass:[LMCloseRequest class]]) {
                    continue;
                }

                NSData *encodedReq = [NSKeyedArchiver archivedDataWithRootObject:req];
                [encodedRequests addObject:encodedReq];
            }
            
            if (![NSKeyedArchiver archiveRootObject:encodedRequests toFile:[self queueFile]]) {
                NSLog(@"[Linkedme Warning] 无法将队列持久保存到磁盘");
            }
        }
        @catch (NSException *exception) {
            NSLog(@"[Linkedme Warning] 尝试保存队列时发生异常。 异常信息:\n\n%@", [self exceptionString:exception]);
        }
    });
}

- (void)retrieve {
    NSMutableArray *queue = [[NSMutableArray alloc] init];
    NSArray *encodedRequests;
    
    // Capture exception while loading the queue file
    @try {
        encodedRequests = [NSKeyedUnarchiver unarchiveObjectWithFile:[self queueFile]];
    }
    @catch (NSException *exception) {
        NSLog(@"[Linkedme Warning] 尝试加载队列文件时发生异常。 异常信息:\n\n%@", [self exceptionString:exception]);
        self.queue = queue;
        return;
    }

    for (NSData *encodedRequest in encodedRequests) {
        LMServerRequest *request;

        // 在解析单个请求对象时捕获异常
        @try {
            request = [NSKeyedUnarchiver unarchiveObjectWithData:encodedRequest];
        }
        @catch (NSException *exception) {
            NSLog(@"[Linkedme Warning] 尝试解析排队的请求时发生异常，将其丢弃。");
            continue;
        }
        
        // Throw out invalid request types
        if (![request isKindOfClass:[LMServerRequest class]]) {
            NSLog(@"[Linkedme Warning] 找到一个无效的请求对象，将其丢弃。");
            continue;
        }
        
        // Throw out persisted close requests
        if ([request isKindOfClass:[LMCloseRequest class]]) {
            continue;
        }

        [queue addObject:request];
    }
    
    self.queue = queue;
}

- (NSString *)exceptionString:(NSException *)exception {
    return [NSString stringWithFormat:@"Name: %@\nReason: %@\nStack:\n\t%@\n\n", exception.name, exception.reason, [exception.callStackSymbols componentsJoinedByString:@"\n\t"]];
}

- (NSString *)queueFile {
    return [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:LINKEDME_QUEUE_FILE];
}

#pragma mark - Singleton method

+ (id)getInstance {
    static LMServerRequestQueue *sharedQueue = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedQueue = [[LMServerRequestQueue alloc] init];
        [sharedQueue retrieve];
        [[LMPreferenceHelper preferenceHelper] log:FILE_NAME line:LINE_NUM message:@"Retrieved from Persist: %@", sharedQueue];
    });
    
    return sharedQueue;
}

@end
