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
@property (nonatomic, assign) CGSize defaultPageSize;
@property (nonatomic, assign) CGSize maximumPageSize;
@property (nonatomic, assign) BOOL sizeFixingEnabled;

@property (nonatomic, strong) NSArray *pageViews;
@property (nonatomic, strong) NSArray *pageSizes;
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
        _innerScrollView.pagingEnabled = NO; //manages paging by itself
        _innerScrollView.scrollEnabled = YES;
        _innerScrollView.showsHorizontalScrollIndicator = NO;
        _innerScrollView.showsVerticalScrollIndicator = NO;
        [self addSubview:_innerScrollView];
        _defaultPageSize = _maximumPageSize = frame.size;
    }
}

- (void)setPageSize:(CGSize)pageSize
{
    _defaultPageSize = _maximumPageSize = pageSize;
    
    NSMutableArray *newPageSizes = @[].mutableCopy;
    for (int i=0; i<_pageSizes.count; i++) {
        [newPageSizes addObject:[NSValue valueWithCGSize:pageSize]];
    }
    [self setPageSizes:newPageSizes.copy];
}

- (CGSize)pageSizeAtIndex:(NSUInteger)index
{
    return [(NSValue*)_pageSizes[index] CGSizeValue];
}

-(NSUInteger)shiftedPageIndex:(NSUInteger)baseIndex offset:(NSInteger)offset
{
    NSInteger result = baseIndex + offset;
    
    if (result < 0) {
        result += self.pageViews.count;
    } else if (result >= self.pageViews.count) {
        result -= self.pageViews.count;
    }
    
    return result;
}

-(NSInteger)offsetWithPageIndex:(NSUInteger)targetPageIndex basePageIndex:(NSUInteger)basePageIndex
{
    NSInteger offset = targetPageIndex - basePageIndex;
    
    if (offset < -floor(self.pageViews.count / 2)) {
        offset += self.pageViews.count;
    } else if (offset > floor(self.pageViews.count / 2)) {
        offset -= self.pageViews.count;
    }
    
    return offset;
}

-(NSUInteger)viewOrderWithPageIndex:(NSUInteger)pageIndex
{
    if (!_loopEnabled) return pageIndex;
    
    NSInteger offset = [self offsetWithPageIndex:pageIndex basePageIndex:self.currentPageIndex];
    NSUInteger orderOfCurrentPageIndex = floor(self.pageViews.count/2);
    return orderOfCurrentPageIndex + offset;
}

- (NSUInteger)pageIndexWithPageViewOrigin:(CGPoint)origin
{
    CGPoint center = ({
        CGPoint point = _innerScrollView.contentOffset;
        point.x += _innerScrollView.frame.size.width/2;
        point.y += _innerScrollView.frame.size.height/2;
        point;
    });
    return [self pageIndexWithPointInContent:center];
}

- (NSUInteger)pageIndexWithPointInContent:(CGPoint)point
{
    NSUInteger order = [self pageOrderWithPointInContent:point];

    if (!_loopEnabled) return order;
    
    NSUInteger orderOfCurrentPageIndex = floor(self.pageViews.count/2);
    return [self shiftedPageIndex:_currentPageIndex offset:(order-orderOfCurrentPageIndex)];
}



#pragma mark - value affected by horizontal/vertical direction
- (CGRect)scrollViewFrame
{
    CGFloat left_margin = (self.frame.size.width - self.maximumPageSize.width) / 2;
    return CGRectMake(left_margin, 0.f, self.maximumPageSize.width, self.frame.size.height);
}

- (CGSize)scrollViewContentSize
{
    CGSize size = CGSizeMake(0, self.frame.size.height);
    for (NSValue *val in self.pageSizes) {
        size.width += [val CGSizeValue].width;
    }
    return size;
}

- (CGRect)pageViewFrameAtPageIndex:(NSUInteger)pageIndex ofContent:(BOOL)ofContent
{
    NSUInteger order = [self viewOrderWithPageIndex:pageIndex];
    
    CGRect result = CGRectZero;
    result.size = self.maximumPageSize;
    for (int i=0; i<order;i++) {
        result.origin.x += [self pageSizeAtIndex:i].width;
    }
    if (ofContent) {
        CGSize mySize = [self pageViewAtIndex:pageIndex].frame.size;
        result.origin.x += (result.size.width - mySize.width) / 2;
        result.origin.y += (result.size.height - mySize.height) / 2;
        result.size = mySize;
    }
    
    return result;
}


- (NSUInteger)pageOrderWithPointInContent:(CGPoint)point
{
    return point.x / self.innerScrollView.frame.size.width;
}



#pragma mark - Public methods

- (UIScrollView *)innerScrollView
{
    return _innerScrollView;
}

- (void)addPageView:(UIView *)pageView
{
    [self addPageView:pageView pageSize:_defaultPageSize];
}

- (void)addPageView:(UIView *)pageView pageSize:(CGSize)pageSize
{
    _currentPageIndex = _pageViews.count;
    _pageViews = [(_pageViews ? _pageViews : @[]) arrayByAddingObject:pageView];
    _pageSizes = [(_pageSizes ? _pageSizes : @[]) arrayByAddingObject:[NSValue valueWithCGSize:pageSize]];
    
    if (CGSizeEqualToSize(_defaultPageSize, CGSizeZero))
    _maximumPageSize = CGSizeMake(MAX(_maximumPageSize.width, pageSize.width),
                                  MAX(_maximumPageSize.height, pageSize.height));
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

- (void)enumeratePageViewsUsingBlock:(void (^)(UIView *pageView, NSUInteger pageIndex, NSUInteger currentPageIndex, BOOL *stop))block
{
    [_pageViews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        block(obj, idx, _currentPageIndex, stop);
    }];
}

- (UIView *)pageViewAtIndex:(NSUInteger)pageIndex
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
    _innerScrollView.contentOffset = [self pageViewFrameAtPageIndex:_currentPageIndex ofContent:NO].origin;
    
    __block UIScrollView *weakScrollView = _innerScrollView;
    [_pageViews enumerateObjectsUsingBlock:^(UIView *pageView, NSUInteger idx, BOOL *stop) {
        pageView.frame = [self pageViewFrameAtPageIndex:idx ofContent:YES];
        [weakScrollView addSubview:pageView];
    }];
    
    if (nil != _delegate && [_delegate respondsToSelector:@selector(pagingViewDidLayoutPages:)]) {
        [_delegate pagingViewDidLayoutPages:self];
    }
}

- (void)scrollToPage:(NSUInteger)pageIndex animated:(BOOL)animated
{
    [_innerScrollView scrollRectToVisible:[self pageViewFrameAtPageIndex:pageIndex ofContent:NO] animated:animated];
}

-(void)setCurrentPageIndex:(NSUInteger)currentPageIndex
{
    if (_currentPageIndex == currentPageIndex) return;
    
    _currentPageIndex = currentPageIndex;
    
    if (_loopEnabled) {
        [self layoutPages];
    }
    
    if (nil != _delegate && [_delegate respondsToSelector:@selector(pagingView:didSetPageIndex:)]) {
        [_delegate pagingView:self didSetPageIndex:currentPageIndex];
    }
}

- (void)fixScrollViewToNearestPage
{
    NSUInteger pageIndex = [self pageIndexWithPageViewOrigin:_innerScrollView.contentOffset];
    [self scrollToPage:pageIndex animated:YES];
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
    
    [self performSelector:@selector(fixScrollViewToNearestPage) withObject:nil afterDelay:0.0];
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView
{
    //invalidate decelerating
    [scrollView setContentOffset:scrollView.contentOffset animated:NO];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if (nil != _delegate && [_delegate respondsToSelector:@selector(pagingView:didEndDecelerating:atPageIndex:)]) {
        [_delegate pagingView:self didEndDecelerating:_innerScrollView];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    NSUInteger pageIndex = [self pageIndexWithPageViewOrigin:_innerScrollView.contentOffset];
    [self setCurrentPageIndex:pageIndex];
}
     

@end


@implementation VerticalInfinitePagingView
- (CGRect)scrollViewFrame
{
    CGFloat top_margin = (self.frame.size.height - self.maximumPageSize.height) / 2;
    return CGRectMake(0.f, top_margin, self.frame.size.width, self.maximumPageSize.height);
}

- (CGSize)scrollViewContentSize
{
    CGSize size = CGSizeMake(self.frame.size.width, 0);
    for (NSValue *val in self.pageSizes) {
        size.height += [val CGSizeValue].height;
    }
    return size;
}

- (CGRect)pageViewFrameAtPageIndex:(NSUInteger)pageIndex ofContent:(BOOL)ofContent
{
    NSUInteger order = [self viewOrderWithPageIndex:pageIndex];
    
    CGRect result = CGRectZero;
    result.size = self.maximumPageSize;
    for (int i=0; i<order;i++) {
        result.origin.y += [self pageSizeAtIndex:i].height;
    }
    if (ofContent) {
        CGSize mySize = [self pageViewAtIndex:pageIndex].frame.size;
        result.origin.x += (result.size.width - mySize.width) / 2;
        result.origin.y += (result.size.height - mySize.height) / 2;
        result.size = mySize;
    }
    
    return result;
}

- (NSUInteger)pageOrderWithPointInContent:(CGPoint)point
{
    return point.y / self.innerScrollView.frame.size.height;
}


@end
