//
//  ViewController.m
//  MyExceptionCatcher
//
//  Created by Petey Mi on 4/27/15.
//  Copyright (c) 2015 Petey Mi. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
//-(void)close
//{
//    abort();
//}

-(IBAction)btClick:(id)sender
{
//    [self performSelectorInBackground:@selector(close) withObject:nil];
    [self performSelector:@selector(close)];
}
@end
