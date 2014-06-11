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

@interface IPScrollView : UIScrollView
@end

@implementation IPScrollView

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    return YES;
}

@end

@interface InfinitePagingView()
@property (nonatomic, strong) NSArray *pageViews;
@property (nonatomic, strong) IPScrollView *innerScrollView;
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
        _pageSize = frame.size;
    }
}

-(NSInteger)shiftedPageIndex:(int)baseIndex offset:(int)offset
{
    NSInteger result = baseIndex + offset;
    
    if (result < 0) {
        result += self.pageViews.count;
    } else if (result >= self.pageViews.count) {
        result -= self.pageViews.count;
    }
    
    return result;
}

-(NSInteger)offsetWithPageIndex:(int)targetPageIndex basePageIndex:(int)basePageIndex
{
    NSInteger offset = targetPageIndex - basePageIndex;
    
    if (offset < -floor(self.pageViews.count / 2)) {
        offset += self.pageViews.count;
    } else if (offset > floor(self.pageViews.count / 2)) {
        offset -= self.pageViews.count;
    }
    
    return offset;
}

-(NSInteger)viewOrderWithPageIndex:(NSInteger)pageIndex
{
    if (!_loopEnabled) return pageIndex;
    
    NSInteger offset = [self offsetWithPageIndex:pageIndex basePageIndex:self.currentPageIndex];
    NSInteger orderOfCurrentPageIndex = floor(self.pageViews.count/2);
    return orderOfCurrentPageIndex + offset;
}

- (NSInteger)pageIndexWithPageViewOrigin:(CGPoint)origin
{
    NSInteger order = [self pageOrderWithPageViewOrigin:origin];

    if (!_loopEnabled) return order;
    
    NSInteger orderOfCurrentPageIndex = floor(self.pageViews.count/2);
    return [self shiftedPageIndex:_currentPageIndex offset:(order-orderOfCurrentPageIndex)];
}



#pragma mark - value affected by horizontal/vertical direction
- (CGRect)scrollViewFrame
{
    CGFloat left_margin = (self.frame.size.width - self.pageSize.width) / 2;
    return CGRectMake(left_margin, 0.f, self.pageSize.width, self.frame.size.height);
}

- (CGSize)scrollViewContentSize
{
    return CGSizeMake(self.pageSize.width * self.pageViews.count, self.frame.size.height);
}

- (CGPoint)pageViewOriginAtPageIndex:(int)pageIndex
{
    return CGPointMake(self.pageSize.width * [self viewOrderWithPageIndex:pageIndex], 0.f);
}

- (NSInteger)pageOrderWithPageViewOrigin:(CGPoint)origin
{
    return origin.x / self.pageSize.width;
}



#pragma mark - Public methods

- (UIScrollView *)innerScrollView
{
    return _innerScrollView;
}

- (void)addPageView:(UIView *)pageView
{
    _pageViews = [(_pageViews ? _pageViews : [NSArray array]) arrayByAddingObject:pageView];
    
    [self layoutPages];
}

- (void)scrollToPreviousPage
{
    [self scrollToPage:[self shiftedPageIndex:_currentPageIndex offset:+1] animated:YES];
}

- (void)scrollToNextPage
{
    [self scrollToPage:[self shiftedPageIndex:_currentPageIndex offset:-1] animated:YES];
}

- (void)scrollToPage:(NSUInteger)pageIndex
{
    [self scrollToPage:pageIndex animated:YES];
}

- (void)enumeratePageViewsUsingBlock:(void (^)(UIView *pageView, NSUInteger pageIndex, NSInteger currentPageIndex, BOOL *stop))block
{
    [_pageViews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        block(obj, idx, _currentPageIndex, stop);
    }];
}

- (UIView *)pageViewAtIndex:(int)pageIndex
{
    return [_pageViews objectAtIndex:pageIndex];
}

#pragma mark - Private methods

- (void)layoutSubviews {
    [super layoutSubviews];
    [self layoutPages];
}

- (void)layoutPages
{
    _innerScrollView.frame = [self scrollViewFrame];
    _innerScrollView.contentSize = [self scrollViewContentSize];
    _innerScrollView.contentOffset = [self pageViewOriginAtPageIndex:_currentPageIndex];
    
    __block UIScrollView *weakScrollView = _innerScrollView;
    [_pageViews enumerateObjectsUsingBlock:^(UIView *pageView, NSUInteger idx, BOOL *stop) {
        pageView.frame = ({
            CGRect frame = pageView.frame;
            frame.origin = [self pageViewOriginAtPageIndex:idx];
            frame.origin.x += (self.pageSize.width - frame.size.width) / 2;
            frame.origin.y += (self.pageSize.height - frame.size.height) / 2;
            frame;
        });
        [weakScrollView addSubview:pageView];
    }];
}

- (void)scrollToPage:(NSInteger)pageIndex animated:(BOOL)animated
{
    CGRect rect = CGRectZero;
    rect.origin = [self pageViewOriginAtPageIndex:pageIndex];
    rect.size = self.pageSize;
    
    [_innerScrollView scrollRectToVisible:rect animated:animated];
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
    NSInteger pageIndex = [self pageIndexWithPageViewOrigin:_innerScrollView.contentOffset];
    [self reloadPageViewsWithPageIndex:pageIndex];
}

-(void)reloadPageViewsWithPageIndex:(NSInteger)pageIndex
{
    if (_currentPageIndex == pageIndex) return;
    
    _currentPageIndex = pageIndex;
    
    if (_loopEnabled) {
        [self layoutPages];
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
    return CGSizeMake(self.pageSize.width, self.frame.size.height * self.pageViews.count);
}

- (CGPoint)pageViewOriginAtPageIndex:(int)pageIndex
{
    return CGPointMake(0.f, self.pageSize.height * [self viewOrderWithPageIndex:pageIndex]);
}

- (NSInteger)pageOrderWithPageViewOrigin:(CGPoint)origin
{
    return origin.y / self.pageSize.height;
}

@end
