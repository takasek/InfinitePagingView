//
//  InfinitePagingView.m
//  InfinitePagingView
//
//  Created by SHIGETA Takuji
//

/*
 The MIT License (MIT)

 Copyright (c) 2012 SHIGETA Takuji

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
*/

#import "InfinitePagingView.h"

@implementation IPScrollView

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    return YES;
}

@end

@interface InfinitePagingView()
@property (nonatomic, strong) NSArray *defaultPageViews;
@property (nonatomic, strong) NSMutableArray *pageViews;
@property (nonatomic, assign) NSInteger lastIndexOfArray;
@end

@implementation InfinitePagingView

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    if (nil == _innerScrollView) {
        _currentPageIndex = 0;
        _loopEnabled = YES;
        self.userInteractionEnabled = YES;
        self.clipsToBounds = YES;
        _innerScrollView = [[IPScrollView alloc] initWithFrame:frame];
        _innerScrollView.delegate = self;
        _innerScrollView.backgroundColor = [UIColor clearColor];
        _innerScrollView.clipsToBounds = NO;
        _innerScrollView.pagingEnabled = YES;
        _innerScrollView.scrollEnabled = YES;
        _innerScrollView.showsHorizontalScrollIndicator = NO;
        _innerScrollView.showsVerticalScrollIndicator = NO;
        [self addSubview:_innerScrollView];
        self.pageSize = frame.size;
    }
}

-(NSInteger)offsetWithPageIndex:(int)targetPageIndex basePageIndex:(int)basePageIndex
{
    NSInteger offset = basePageIndex - targetPageIndex;
    
    if (offset < -floor(_pageViews.count / 2)) {
        offset += _pageViews.count;
    } else if (offset > floor(_pageViews.count / 2)) {
        offset -= _pageViews.count;
    }
    
    return offset;
}

#pragma mark - value affected by horizontal/vertical direction
- (CGRect)scrollViewFrame
{
    CGFloat left_margin = (self.frame.size.width - self.pageSize.width) / 2;
    return CGRectMake(left_margin, 0.f, self.pageSize.width, self.frame.size.height);
}

- (CGSize)scrollViewContentSize
{
    return CGSizeMake(self.frame.size.width * self.pageViews.count, self.frame.size.height);
}

- (CGPoint)pageViewCenterAtPageIndex:(int)idx
{
    return CGPointMake(idx * (self.innerScrollView.frame.size.width) + (self.innerScrollView.frame.size.width / 2), self.innerScrollView.center.y);
}

- (CGRect)rectToVisibleWithOffset:(NSInteger)moveDirection
{
    if (0 != fmodf(self.innerScrollView.contentOffset.x, self.pageSize.width)) return CGRectNull;
    return CGRectMake(self.innerScrollView.contentOffset.x - self.innerScrollView.frame.size.width * moveDirection,
                      self.innerScrollView.contentOffset.y,
                      self.innerScrollView.frame.size.width, self.innerScrollView.frame.size.height);
}

- (NSInteger)pageIndexWithContentOffset:(CGPoint)offset
{
    return offset.x / self.innerScrollView.frame.size.width;
}

- (CGPoint)contentOffsetAtPageIndex:(int)idx
{
    return CGPointMake(self.pageSize.width * idx, 0.f);
}

#pragma mark - Public methods
- (void)enumeratePageViewsUsingBlock:(void (^)(UIView *pageView, NSUInteger pageIndex, NSInteger currentPageIndex, BOOL *stop))block
{
    [_defaultPageViews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        block(obj, idx, _currentPageIndex, stop);
    }];
}

- (void)addPageView:(UIView *)pageView
{
    if (nil == _defaultPageViews) {
        _defaultPageViews = [NSArray array];
    }
    
    _defaultPageViews = [_defaultPageViews arrayByAddingObject:pageView];
    
    _pageViews = [_defaultPageViews mutableCopy];
    
    _lastIndexOfArray = _currentPageIndex = floor(_pageViews.count / 2);
    
    [self layoutPages];
}

- (void)scrollToPreviousPage
{
    [self scrollToDirection:1 animated:YES];
    //[self performSelector:@selector(scrollViewDidEndDecelerating:) withObject:_innerScrollView afterDelay:0.5f]; // delay until scroll animation end.
}

- (void)scrollToNextPage
{
    [self scrollToDirection:-1 animated:YES];
    //[self performSelector:@selector(scrollViewDidEndDecelerating:) withObject:_innerScrollView afterDelay:0.5f]; // delay until scroll animation end.
}

- (void)scrollToPage:(NSUInteger)pageIndex
{
    NSInteger direction = [self offsetWithPageIndex:pageIndex basePageIndex:_currentPageIndex];
    
    NSLog(@"last:%d current:%d target:%d direction:%d", _lastIndexOfArray, _currentPageIndex, pageIndex, direction);
    [self scrollToDirection:direction animated:YES];
    //[self performSelector:@selector(scrollViewDidEndDecelerating:) withObject:_innerScrollView afterDelay:0.5f]; // delay until scroll animation end.
}


- (void)layoutSubviews {
    [super layoutSubviews];
    [self layoutPages];
}

#pragma mark - Private methods

- (void)layoutPages
{
    
    _innerScrollView.frame = [self scrollViewFrame];
    _innerScrollView.contentSize = [self scrollViewContentSize];
    
    [_pageViews enumerateObjectsUsingBlock:^(UIView *pageView, NSUInteger idx, BOOL *stop) {
        pageView.center = [self pageViewCenterAtPageIndex:idx];
        [_innerScrollView addSubview:pageView];
    }];
    
    _innerScrollView.contentOffset = [self contentOffsetAtPageIndex:_lastIndexOfArray];
}

- (void)scrollToDirection:(NSInteger)moveDirection animated:(BOOL)animated
{
    CGRect adjustScrollRect = [self rectToVisibleWithOffset:moveDirection];

    [_innerScrollView scrollRectToVisible:adjustScrollRect animated:animated];
}

#pragma mark - UIScrollViewDelegate methods

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if (nil != _delegate && [_delegate respondsToSelector:@selector(pagingView:willBeginDragging:)]) {
        [_delegate pagingView:self willBeginDragging:_innerScrollView];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (nil != _delegate && [_delegate respondsToSelector:@selector(pagingView:didScroll:)]) {
        [_delegate pagingView:self didScroll:_innerScrollView];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (nil != _delegate && [_delegate respondsToSelector:@selector(pagingView:didEndDragging:)]) {
        [_delegate pagingView:self didEndDragging:_innerScrollView];
    }
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView
{
    if (nil != _delegate && [_delegate respondsToSelector:@selector(pagingView:willBeginDecelerating:)]) {
        [_delegate pagingView:self willBeginDecelerating:_innerScrollView];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    [self scrollViewDidEndDecelerating:_innerScrollView];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if(_loopEnabled==NO) return;
 
    NSInteger pageIndex = [self pageIndexWithContentOffset:_innerScrollView.contentOffset];
    
    NSInteger moveDirection = pageIndex - _lastIndexOfArray;
    if (moveDirection == 0) {
        return;
        
    } else if (moveDirection > 0.f) {
        for (NSUInteger i = 0; i < abs((int)moveDirection); ++i) {
            UIView *leftView = [_pageViews objectAtIndex:0];
            [_pageViews removeObjectAtIndex:0];
            [_pageViews insertObject:leftView atIndex:_pageViews.count];
        }
        pageIndex -= moveDirection;
    } else if (moveDirection < 0) {
        for (NSUInteger i = 0; i < abs((int)moveDirection); ++i) {
            UIView *rightView = [_pageViews lastObject];
            [_pageViews removeLastObject];
            [_pageViews insertObject:rightView atIndex:0];
        }
        pageIndex += abs((int)moveDirection);
    }
    if (pageIndex > _pageViews.count - 1) {
        pageIndex = _pageViews.count - 1;
    }
    
    [_pageViews enumerateObjectsUsingBlock:^(UIView *pageView, NSUInteger idx, BOOL *stop) {
        pageView.center = [self pageViewCenterAtPageIndex:idx];
    }];
    
    [self scrollToDirection:moveDirection animated:NO];

    _lastIndexOfArray = pageIndex;

    _currentPageIndex += moveDirection;
    
    NSLog(@"last:%d current:%d direction:%d", _lastIndexOfArray, _currentPageIndex, moveDirection);
    if (_currentPageIndex < 0) {
        _currentPageIndex = _pageViews.count - 1;
    } else if (_currentPageIndex >= _pageViews.count) {
        _currentPageIndex = 0;
    }
    if (nil != _delegate && [_delegate respondsToSelector:@selector(pagingView:didEndDecelerating:atPageIndex:)]) {
        [_delegate pagingView:self didEndDecelerating:_innerScrollView atPageIndex:_currentPageIndex];
    }
}

@end


@implementation VerticalInfinitePagingView

- (CGRect)scrollViewFrame
{
    CGFloat top_margin  = (self.frame.size.height - self.pageSize.height) / 2;
    return CGRectMake(0.f, top_margin, self.frame.size.width, self.pageSize.height);
}

- (CGSize)scrollViewContentSize
{
    return CGSizeMake(self.frame.size.width, self.frame.size.height * self.pageViews.count);
}

- (CGPoint)pageViewCenterAtPageIndex:(int)idx
{
    return CGPointMake(self.innerScrollView.center.x, idx * (self.innerScrollView.frame.size.height) + (self.innerScrollView.frame.size.height / 2));
}

- (CGRect)rectToVisibleWithOffset:(NSInteger)moveDirection
{
    if (0 != fmodf(self.innerScrollView.contentOffset.y, self.pageSize.height)) return CGRectNull;
    return CGRectMake(self.innerScrollView.contentOffset.x,
                      self.innerScrollView.contentOffset.y - self.innerScrollView.frame.size.height * moveDirection,
                      self.innerScrollView.frame.size.width, self.innerScrollView.frame.size.height);
}

- (NSInteger)pageIndexWithContentOffset:(CGPoint)offset
{
    return offset.y / self.innerScrollView.frame.size.height;
}

- (CGPoint)contentOffsetAtPageIndex:(int)idx
{
    return CGPointMake(0.f, self.pageSize.height * idx);
}

@end
