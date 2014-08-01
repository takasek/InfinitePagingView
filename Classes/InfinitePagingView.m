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
@property (nonatomic, assign) CGSize maximumPageSize;

@property (nonatomic, strong) NSArray *pageViews;
@property (nonatomic, strong) NSArray *pageSizes;
@property (nonatomic, strong) IPScrollView *innerScrollView;
@end

@implementation InfinitePagingView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self _setup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self _setup];
    }
    return self;
}

- (void)_setup
{
    _currentPageIndex = 0;
    _loopEnabled = YES;
    self.userInteractionEnabled = YES;
    self.clipsToBounds = YES;
    _innerScrollView = [IPScrollView new];
    _innerScrollView.delegate = self;
    _innerScrollView.backgroundColor = [UIColor clearColor];
    _innerScrollView.clipsToBounds = NO;
    _innerScrollView.pagingEnabled = NO; //manages paging by itself
    _innerScrollView.scrollEnabled = YES;
    _innerScrollView.showsHorizontalScrollIndicator = NO;
    _innerScrollView.showsVerticalScrollIndicator = NO;
    [self addSubview:_innerScrollView];
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    
    if (CGSizeEqualToSize(_defaultPageSize, CGSizeZero)) {
        _defaultPageSize = _maximumPageSize = frame.size;
    }
}


- (void)addPageView:(UIView *)pageView
{
    [self addPageView:pageView pageSize:_defaultPageSize];
}

- (void)addPageView:(UIView *)pageView pageSize:(CGSize)pageSize
{
    _pageViews = [(_pageViews ?: @[]) arrayByAddingObject:pageView];
    _pageSizes = [(_pageSizes ?: @[]) arrayByAddingObject:[NSValue valueWithCGSize:pageSize]];
    
    if (CGSizeEqualToSize(_defaultPageSize, CGSizeZero)) {
        _maximumPageSize = CGSizeMake(MAX(_maximumPageSize.width, pageSize.width),
                                      MAX(_maximumPageSize.height, pageSize.height));
    }
    [self setNeedsLayout];
}

- (UIView *)pageViewAtIndex:(NSUInteger)pageIndex
{
    if (_pageViews.count > pageIndex) {
        return _pageViews[pageIndex];
    } else {
        return nil;
    }
}

- (void)setDefaultPageSize:(CGSize)pageSize
{
    _defaultPageSize = _maximumPageSize = pageSize;
    
    _pageSizes = ({
        NSMutableArray *newPageSizes = @[].mutableCopy;
        for (int i=0; i<_pageSizes.count; i++) {
            [newPageSizes addObject:[NSValue valueWithCGSize:pageSize]];
        }
        newPageSizes.copy;
    });
}

- (CGSize)pageSizeAtIndex:(NSUInteger)pageIndex
{
    if (_pageSizes.count > pageIndex) {
        return [(NSValue*)_pageSizes[pageIndex] CGSizeValue];
    } else {
        return CGSizeZero;
    }
}

-(NSUInteger)shiftedPageIndex:(NSUInteger)baseIndex offset:(NSInteger)offset
{
    NSInteger result = baseIndex + offset;
    
    if (result < 0) {
        result += _pageViews.count;
    } else if (result >= _pageViews.count) {
        result -= _pageViews.count;
    }
    
    return result;
}

-(NSInteger)offsetWithPageIndex:(NSUInteger)targetPageIndex basePageIndex:(NSUInteger)basePageIndex
{
    NSInteger offset = targetPageIndex - basePageIndex;
    
    if (offset < -floor(_pageViews.count / 2)) {
        offset += _pageViews.count;
    } else if (offset > floor(_pageViews.count / 2)) {
        offset -= _pageViews.count;
    }
    
    return offset;
}

-(NSUInteger)viewOrderWithPageIndex:(NSUInteger)pageIndex
{
    if (!_loopEnabled) {
        return pageIndex;
    }
    
    NSInteger offset = [self offsetWithPageIndex:pageIndex basePageIndex:_currentPageIndex];
    NSUInteger orderOfCurrentPageIndex = floor(_pageViews.count/2);
    return orderOfCurrentPageIndex + offset;
}

- (NSUInteger)pageIndexShownCurrently
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
    for (int i=0; i<_pageSizes.count; i++) {
        CGRect frame = [self pageViewFrameAtIndex:i ofContent:NO];
        if (CGRectContainsPoint(frame, point)) {
            return i;
        }
    }
    return NSNotFound;
}

- (CGRect)pageViewFrameAtIndex:(NSUInteger)pageIndex ofContent:(BOOL)ofContent
{
    if (!_pageViews.count) return CGRectZero;
    
    CGRect result = CGRectZero;
    result.origin = [self pageOriginAtIndex:pageIndex];
    result.size = [self pageSizeAtIndex:pageIndex];
    
    if (ofContent) {
        CGSize mySize = [self pageViewAtIndex:pageIndex].frame.size;
        result.origin.x += (result.size.width - mySize.width) / 2;
        result.origin.y += (result.size.height - mySize.height) / 2;
        result.size = mySize;
    }
    
    return result;
}


- (void)layoutSubviews
{
    [super layoutSubviews];
    [self layoutPages];
}

- (void)layoutPages
{
    if (!_pageViews.count || _currentPageIndex == NSNotFound) return;
    
    _innerScrollView.frame = [self scrollViewFrameAtIndex:_currentPageIndex];
    _innerScrollView.contentSize = [self scrollViewContentSize];
    _innerScrollView.contentOffset = [self pageOriginAtIndex:_currentPageIndex];
    
    [_pageViews enumerateObjectsUsingBlock:^(UIView *pageView, NSUInteger idx, BOOL *stop) {
        pageView.frame = [self pageViewFrameAtIndex:idx ofContent:YES];
        [_innerScrollView addSubview:pageView];
    }];
    
    if (nil != _delegate && [_delegate respondsToSelector:@selector(pagingViewDidLayoutPages:)]) {
        [_delegate pagingViewDidLayoutPages:self];
    }
}

-(void)setCurrentPageIndex:(NSUInteger)pageIndex animated:(BOOL)animated
{
    if (_currentPageIndex == pageIndex) return;
    
    NSUInteger lastPageIndex = _currentPageIndex;
    
    _currentPageIndex = pageIndex;
    
    if (_loopEnabled) {
        [self setNeedsLayout];
    }
    
    if (nil != _delegate && [_delegate respondsToSelector:@selector(pagingViewDidSetPageIndex:lastPageIndex:animated:)]) {
        [_delegate pagingViewDidSetPageIndex:self lastPageIndex:lastPageIndex animated:animated];
    }
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

- (void)scrollToPage:(NSUInteger)pageIndex animated:(BOOL)animated
{
    if (animated) {
        CGRect rect = ({
            CGRect rect = [self pageViewFrameAtIndex:pageIndex ofContent:NO];
            CGSize currentSize = _innerScrollView.frame.size;
            rect.origin.x += (rect.size.width-currentSize.width)/2;
            rect.origin.y += (rect.size.height-currentSize.height)/2;
            rect.size = currentSize;
            rect;
        });
        
        if (!CGPointEqualToPoint(_innerScrollView.contentOffset, rect.origin)) {
            [_innerScrollView scrollRectToVisible:rect animated:YES];
            return;
            //expect to animate and call -scrollViewDidEndScrollingAnimation:
        }
    }
    
    //doesn't scroll.
    [self setCurrentPageIndex:pageIndex animated:NO];
}

- (void)enumeratePageViewsUsingBlock:(void (^)(UIView *pageView, NSUInteger pageIndex, NSUInteger currentPageIndex, BOOL *stop))block
{
    [_pageViews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        block(obj, idx, _currentPageIndex, stop);
    }];
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
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self scrollToPage:[self pageIndexShownCurrently] animated:YES];
    });
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView
{
    //invalidate decelerating
    [scrollView setContentOffset:scrollView.contentOffset animated:NO];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    [self setCurrentPageIndex:[self pageIndexShownCurrently] animated:YES];
}


#pragma mark - value affected by horizontal/vertical direction
- (CGRect)scrollViewFrameAtIndex:(NSUInteger)pageIndex
{
    CGFloat currentPageWidth = [self pageSizeAtIndex:pageIndex].width;
    CGSize selfSize = self.frame.size;
    return CGRectMake((selfSize.width-currentPageWidth)/2, 0, currentPageWidth, selfSize.height);
}

- (CGSize)scrollViewContentSize
{
    CGSize size = CGSizeMake(0, self.frame.size.height);
    for (NSValue *val in _pageSizes) {
        size.width += [val CGSizeValue].width;
    }
    return size;
}

- (CGPoint)pageOriginAtIndex:(NSUInteger)pageIndex
{
    CGPoint result = CGPointZero;
    
    NSInteger i = pageIndex;
    while ([self viewOrderWithPageIndex:i] > 0) {
        i = [self shiftedPageIndex:i offset:-1];
        result.x += [self pageSizeAtIndex:i].width;
    }
    
    return result;
}


@end


@implementation VerticalInfinitePagingView
- (CGRect)scrollViewFrameAtIndex:(NSUInteger)pageIndex
{
    CGFloat currentPageHeight = [self pageSizeAtIndex:pageIndex].height;
    CGSize selfSize = self.frame.size;
    return CGRectMake(0, (selfSize.height-currentPageHeight)/2, selfSize.width, currentPageHeight);
}

- (CGSize)scrollViewContentSize
{
    CGSize size = CGSizeMake(self.frame.size.width, 0);
    for (NSValue *val in self.pageSizes) {
        size.height += [val CGSizeValue].height;
    }
    return size;
}

- (CGPoint)pageOriginAtIndex:(NSUInteger)pageIndex
{
    CGPoint result = CGPointZero;
    
    NSInteger i = pageIndex;
    while ([self viewOrderWithPageIndex:i] > 0) {
        result.y += [self pageSizeAtIndex:i].height;
        i = [self shiftedPageIndex:i offset:-1];
    }
    
    return result;
}

@end
