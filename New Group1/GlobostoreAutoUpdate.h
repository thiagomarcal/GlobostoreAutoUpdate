//
//  GlobostoreAutoUpdate.h
//  GlobostoreAutoUpdate
//
//  Created by Thiago Marçal on 5/17/18.
//  Copyright © 2018 Thiago Marçal. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GlobostoreAutoUpdate : NSObject

- (void)placePostRequestWithURL:(NSString *)action withData:(NSDictionary *)dataToSend;
- (void) api:(NSDictionary *)data;
- (void) validateCurrentVersion;

@end
