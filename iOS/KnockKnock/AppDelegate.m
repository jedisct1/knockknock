//
//  AppDelegate.m
//  KnockKnock
//
//  Created by Frank Denis on 5/20/12.
//  Copyright (c) 2012 Frank Denis. All rights reserved.
//

#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonHMAC.h>

#import "AppDelegate.h"

#define kFW_HOST @"proxy.example.com"
#define kFW_PORT 9000
#define kFW_KEY  "super secret shared key"

@implementation NSString (NSStringAdditions)

static const char base64EncodingTable[64] = {
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P',
    'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f',
    'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v',
    'w', 'x', 'y', 'z', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '+', '/'
};

+ (NSString *) base64StringFromData: (NSData *)data length: (int)length {
    unsigned long ixtext, lentext;
    long ctremaining;
    unsigned char input[3], output[4];
    short i, charsonline = 0, ctcopy;
    const unsigned char *raw;
    NSMutableString *result;
    
    lentext = [data length]; 
    if (lentext < 1U) {
        return @"";
    }
    result = [NSMutableString stringWithCapacity: lentext];
    raw = [data bytes];
    ixtext = 0; 
    
    for (;;) {
        ctremaining = lentext - ixtext;
        if (ctremaining <= 0) {
            break;
        }
        for (i = 0; i < 3; i++) { 
            unsigned long ix = ixtext + i;
            if (ix < lentext) {
                input[i] = raw[ix];
            } else {
                input[i] = 0;
            }
        }
        output[0] = (input[0] & 0xFC) >> 2;
        output[1] = ((input[0] & 0x03) << 4) | ((input[1] & 0xF0) >> 4);
        output[2] = ((input[1] & 0x0F) << 2) | ((input[2] & 0xC0) >> 6);
        output[3] = input[2] & 0x3F;
        ctcopy = 4;
        switch (ctremaining) {
            case 1:
                ctcopy = 2; 
                break;
            case 2: 
                ctcopy = 3; 
                break;
        }
        
        for (i = 0; i < ctcopy; i++) {
            [result appendString: [NSString stringWithFormat: @"%c", base64EncodingTable[output[i]]]];
        }
        
        for (i = ctcopy; i < 4; i++) {
            [result appendString: @"="];
        }
        
        ixtext += 3;
        charsonline += 4;
        
        if ((length > 0) && (charsonline >= length)) {
            charsonline = 0;
        }
    }     
    return result;
}

@end

@implementation AppDelegate

CLLocationManager *locMan;
CLLocation *recentLocation;

- (NSString *)token
{
    unsigned char hmac[CC_SHA256_DIGEST_LENGTH];
    const char *key = kFW_KEY;
    char *message;
    
    asprintf(&message, "%llu", (unsigned long long) time(NULL) & ~0xFFFF);
    CCHmac(kCCHmacAlgSHA256, key, strlen(key), message, strlen(message), hmac);
    free(message);
    NSData *token = [NSData dataWithBytes: hmac length: sizeof(hmac)];
    
    return [NSString base64StringFromData: token length: token.length];
}

- (void)knock
{
    NSInputStream *inputStream;
    NSOutputStream *outputStream;
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocketToHost(NULL, (CFStringRef) kFW_HOST, kFW_PORT, &readStream, &writeStream);
    inputStream = (NSInputStream *)CFBridgingRelease(readStream);
    outputStream = (NSOutputStream *)CFBridgingRelease(writeStream);
    [inputStream setDelegate:self];
    [outputStream setDelegate:self];
    [inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [inputStream open];
    [outputStream open];
    NSString *query = [NSString stringWithFormat: @"GET /knock HTTP/1.1\r\n"
                       @"Host: %@\r\n"
                       @"User-Agent: KnockKnock\r\n"
                       @"Connection: close\r\n"
                       @"X-Token: %@\r\n"
                       @"\r\n", kFW_HOST, [self token]];
    NSData *queryData = [[NSData alloc] initWithData:[query dataUsingEncoding:NSASCIIStringEncoding]];
    [outputStream write:[queryData bytes] maxLength:[queryData length]];
}

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
    [self knock];
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    locMan = [[CLLocationManager alloc] init];
    locMan.delegate = self;
    locMan.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
    [locMan startMonitoringSignificantLocationChanges];
    
    [self knock];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [self knock];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    
}

@end
