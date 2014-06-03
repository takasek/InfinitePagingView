//
//  HPaddingPageViewController.m
//  InfinitePagingView
//
//  Created by SHIGETA Takuji
//  Copyright (c) 2012 qnote,Inc. All rights reserved.
//

#import "HPaddingPageViewController.h"
#import "InfinitePagingView.h"


@implementation HPaddingPageViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    CGFloat naviBarHeight = self.navigationController.navigationBar.frame.size.height;

    self.view.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];

    // pagingView
    InfinitePagingView *pagingView = [[InfinitePagingView alloc] initWithFrame:CGRectMake(0.f, self.view.center.y - 100 - naviBarHeight, self.view.frame.size.width, 200.f)];
    pagingView.backgroundColor = [UIColor blackColor];
    pagingView.pageSize = CGSizeMake(120.f, self.view.frame.size.height);
    [self.view addSubview:pagingView];
    
    for (NSUInteger i = 0; i < 15; ++i) {
        UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"%d.JPG", i+1]];
        UIImageView *page = [[UIImageView alloc] initWithImage:image];
        page.frame = CGRectMake(0.f, 0.f, 100.f, pagingView.frame.size.height);
        page.contentMode = UIViewContentModeScaleAspectFit;
        
        page.userInteractionEnabled = YES;

        UIButton *btn = [UIButton buttonWithType:UIButtonTypeInfoDark];
        btn.tintColor = [UIColor redColor];
        btn.tag = i;
        [btn addTarget:self action:@selector(sayMeow:) forControlEvents:UIControlEventTouchUpInside];
        
        [page addSubview:btn];
        
        [pagingView addPageView:page];
    }
    
    // label
    UILabel *labelName = [[UILabel alloc] initWithFrame:CGRectMake(0.f, pagingView.frame.origin.y - 50.f, self.view.frame.size.width, 65.f)];
    labelName.textAlignment = UITextAlignmentCenter;
    labelName.textColor = [UIColor whiteColor];
    labelName.backgroundColor = [UIColor clearColor];
    labelName.text = @"⇦ ⇨";
    labelName.font = [UIFont boldSystemFontOfSize:50.f];
    [self.view addSubview:labelName];

    // for ios 7
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
}

-(void)sayMeow:(UIButton*)btn {
    NSString *str = [NSString stringWithFormat:@"[%d]Meow!", btn.tag];
    [[[UIAlertView alloc] initWithTitle:nil
                               message:str
                              delegate:nil
                     cancelButtonTitle:@"OK"
                     otherButtonTitles:nil] show];
}

@end
