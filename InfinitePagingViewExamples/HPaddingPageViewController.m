//
//  HPaddingPageViewController.m
//  InfinitePagingView
//
//  Created by SHIGETA Takuji
//  Copyright (c) 2012 qnote,Inc. All rights reserved.
//

#import "HPaddingPageViewController.h"
#import "InfinitePagingView.h"

@interface HPaddingPageViewController()
@property (nonatomic, strong) InfinitePagingView *pagingView;

@end

@implementation HPaddingPageViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    CGFloat naviBarHeight = self.navigationController.navigationBar.frame.size.height;

    self.view.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];

    // pagingView
    InfinitePagingView *pagingView = [[InfinitePagingView alloc] initWithFrame:CGRectMake(0.f, self.view.center.y - 100 - naviBarHeight, self.view.frame.size.width, 200.f)];
    pagingView.backgroundColor = [UIColor blackColor];
    pagingView.pageSize = CGSizeMake(120.f, 200.f);
    [self.view addSubview:pagingView];
    
    for (NSUInteger i = 0; i < 15; ++i) {
        UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"%d.JPG", i+1]];
        UIImageView *page = [[UIImageView alloc] initWithImage:image];
        page.frame = CGRectMake(0.f, 0.f, 100.f, pagingView.frame.size.height);
        page.contentMode = UIViewContentModeScaleAspectFit;
        
        page.userInteractionEnabled = YES;

        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setTitle:[NSString stringWithFormat:@"%d",i] forState:UIControlStateNormal];
        btn.tintColor = [UIColor redColor];
        [btn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        [btn setFrame:CGRectMake(0,0, 40, 20)];
        btn.tag = i;
        [btn addTarget:self action:@selector(sayMeow:) forControlEvents:UIControlEventTouchUpInside];
        
        [page addSubview:btn];
        
        [pagingView addPageView:page];
        
        UIButton *jumpButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [jumpButton setFrame:CGRectMake(i*20, 20, 20, 15)];
        [jumpButton setAttributedTitle:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%d", i] attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:12.f]}]
                              forState:UIControlStateNormal];
        jumpButton.tag = i;
        [jumpButton addTarget:self action:@selector(jump:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:jumpButton];
        
    }
    _pagingView = pagingView;
    
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
    
    [_pagingView enumeratePageViewsUsingBlock:^(UIView *pageView, NSUInteger pageIndex, NSUInteger currentPageIndex, BOOL *stop) {
        if (pageIndex == currentPageIndex) return;
        
        [UIView animateWithDuration:2.f animations:^{
            pageView.alpha = 0;
        } completion:^(BOOL finished) {
            pageView.alpha = 1;
        }];
    }];
}

-(void)jump:(UIButton*)btn {
    NSInteger targetPage = btn.tag;
    [_pagingView scrollToPage:targetPage];
}

@end
