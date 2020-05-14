//
//  ViewController.m
//  MPIBackgroundTaskProtectionDemo
//
//  Created by Bear on 2020/4/29.
//  Copyright © 2020 Bear. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor redColor];

    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:NSLocalizedString(@"button", nil) forState:UIControlStateNormal];
    button.frame = (CGRect){CGPointMake(200, 200), CGSizeMake(40, 40)};
    [self.view addSubview:button];
    [button addTarget:self action:@selector(buttonAction) forControlEvents:UIControlEventTouchUpInside];
}

- (void)buttonAction {
    self.view.backgroundColor = [UIColor blackColor];
}

@end
