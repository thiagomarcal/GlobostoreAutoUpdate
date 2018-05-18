//
//  GlobostoreViewController.m
//  GlobostoreAutoUpdate
//
//  Created by thiagomarcal on 05/17/2018.
//  Copyright (c) 2018 thiagomarcal. All rights reserved.
//

#import "GlobostoreViewController.h"
#import <GlobostoreAutoUpdate/GlobostoreAutoUpdate.h>

@interface GlobostoreViewController ()

@end

@implementation GlobostoreViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    GlobostoreAutoUpdate *autoupdate = [[GlobostoreAutoUpdate alloc] init];
    [autoupdate validateCurrentVersion:self];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
