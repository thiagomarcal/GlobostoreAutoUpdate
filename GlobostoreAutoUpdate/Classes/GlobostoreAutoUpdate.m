//
//  GlobostoreAutoUpdate.m
//  GlobostoreAutoUpdate
//
//  Created by Thiago Marçal on 5/17/18.
//  Copyright © 2018 Thiago Marçal. All rights reserved.
//

#import "GlobostoreAutoUpdate.h"
#import <UIKit/UIKit.h>

@implementation GlobostoreAutoUpdate

UIViewController *viewTemplate;

-(void)placePostRequestWithURL:(NSString *)action withData:(NSDictionary *)dataToSend withHandler:(void (^)(NSURLResponse *response, NSData *data, NSError *error))ourBlock {
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"globostore" ofType:@"plist"];
    NSMutableDictionary *plistdict = [NSMutableDictionary dictionaryWithContentsOfFile:filePath];
    NSString *appKey = plistdict[@"appKey"];
    
    
    NSString *urlString = [NSString stringWithFormat:@"%@", action];
    NSLog(@"%@", urlString);
    
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    NSError *error;
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dataToSend options:0 error:&error];
    
    NSString *jsonString;
    if (! jsonData) {
        NSLog(@"Got an error: %@", error);
    } else {
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        
        NSData *requestData = [NSData dataWithBytes:[jsonString UTF8String] length:[jsonString lengthOfBytesUsingEncoding:NSUTF8StringEncoding]];
        
        [request setHTTPMethod:@"POST"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [request setValue:@"application/json; charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
        [request setValue:appKey forHTTPHeaderField:@"appkey"];
        [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[requestData length]] forHTTPHeaderField:@"Content-Length"];
        [request setHTTPBody: requestData];
        
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:ourBlock];
    }
}

- (void) api:(NSDictionary *)data
    calledBy:(id)calledBy
 withSuccess:(SEL)successCallback
  andFailure:(SEL)failureCallback {
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"globostore" ofType:@"plist"];
    NSMutableDictionary *plistdict = [NSMutableDictionary dictionaryWithContentsOfFile:filePath];
    NSString *versionUrl = plistdict[@"versionUrl"];
    
    [self placePostRequestWithURL:versionUrl
                         withData:data
                      withHandler:^(NSURLResponse *response, NSData *rawData, NSError *error) {
                          NSString *string = [[NSString alloc] initWithData:rawData
                                                                   encoding:NSUTF8StringEncoding];
                          
                          NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
                          NSInteger code = [httpResponse statusCode];
                          NSLog(@"%ld", (long)code);
                          
                          if (!(code >= 200 && code < 300)) {
                              NSLog(@"ERROR (%ld): %@", (long)code, string);
                              [calledBy performSelector:failureCallback withObject:string];
                          } else {
                              NSLog(@"OK");
                              
                              NSDictionary *result = [NSDictionary dictionaryWithObjectsAndKeys:
                                                      string, @"version",
                                                      nil];
                              
                              [calledBy performSelector:successCallback withObject:rawData];
                          }
                      }];
}

- (void) validateCurrentVersion: (UIViewController *)view {
    
    viewTemplate = view;
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"globostore" ofType:@"plist"];
    NSMutableDictionary *plistdict = [NSMutableDictionary dictionaryWithContentsOfFile:filePath];
    
    NSString *appId = plistdict[@"appId"];
    NSString *appOs = plistdict[@"appOs"];
    NSString *method = plistdict[@"method"];
    NSString *service = plistdict[@"service"];
    
    NSMutableDictionary *dataToSend=[NSMutableDictionary dictionaryWithDictionary:@{@"request" :@{@"app_id" :appId,@"os":appOs}, @"method": method, @"service": service}];
    
    [self api:dataToSend
     calledBy:self
  withSuccess:@selector(apiDidEnd:)
   andFailure:@selector(apiFailure:)];
    
}

- (void)apiDidEnd:(id)result{
    
    NSLog(@"loginDidEnd:");
    NSError* error;
    NSDictionary* responseDataDict = [NSJSONSerialization JSONObjectWithData:result
                                                                     options:kNilOptions
                                                                       error:&error];
    
    NSString *remoteVersion = responseDataDict[@"version"][@"version"];
    NSString *path = responseDataDict[@"version"][@"download"];
    
    // Load Storage
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"globostore" ofType:@"plist"];
    NSMutableDictionary *plistdict = [NSMutableDictionary dictionaryWithContentsOfFile:filePath];
    
    NSString *localVersion = plistdict[@"localVersion"];
    NSString *downloadUrl = plistdict[@"downloadUrl"];
    
    NSString *bundleVersion = [NSString stringWithFormat:@"%@",[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    
    if (localVersion == nil || localVersion != remoteVersion || bundleVersion != remoteVersion) {
        
        NSString *itms = @"itms-services://?action=download-manifest&url=";
        NSString *origin = [NSString stringWithFormat: @"%@%@", itms, downloadUrl];
        NSString *dowloadPath = [NSString stringWithFormat: @"%@%@", origin, path];
        
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        [prefs setObject:dowloadPath forKey:@"downloadPath"];
        
        [plistdict setObject:dowloadPath forKey:@"downloadPath"];
        [plistdict setObject:remoteVersion forKey:@"remoteVersion"];
        [plistdict writeToFile:filePath atomically:YES];
        
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Atualização" message:@"Nova versão disponível, pressione ok pra atualizar o seu aplicativo."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                                  [self handleAlert];
                                                              }];
        
        [alert addAction:defaultAction];
        [viewTemplate presentViewController:alert animated:YES completion:nil];
        
    }
    
}

- (void)apiFailure:(id)result{
    NSLog(@"loginFailure:");
    // Do your actions
}


- (void) handleAlert {
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"globostore" ofType:@"plist"];
        NSMutableDictionary *plistdict = [NSMutableDictionary dictionaryWithContentsOfFile:filePath];
        NSString *downloadPath = plistdict[@"downloadPath"];
        NSString *remoteVersion = plistdict[@"remoteVersion"];
    
        UIApplication *application = [UIApplication sharedApplication];
        NSURL *URL = [NSURL URLWithString:downloadPath];
        [application openURL:URL options:@{} completionHandler:^(BOOL success) {
            if (success) {
                NSLog(@"Opened url");
                [plistdict setObject:remoteVersion forKey:@"localVersion"];
                [plistdict writeToFile:filePath atomically:YES];
            }
        }];
}

@end

