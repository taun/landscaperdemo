---
permalink: /fractalscapes-science-1
title:  "Magic vs Science & UICollectionViews"
date:   2016-12-20 17:49:00 -0500
tags: fractalscapes uicollectionview
categories: fractalscapes
tag: fractalscapes
summary: "Or how I overcame magical thinking to finally solve my UICollectionView resizing layout on rotation problems."
excerpt: "Or how I overcame magical thinking to finally solve my UICollectionView resizing layout on rotation problems."
toc: true
---

This post is about how by changing my approach to a problem from trial and error to a more scientific method, I was able to do in 30 minutes what I hadn't been able to do in 3 days.

# Goal:
Figure out exactly how UICollectionViewFlowLayout works and use that knowledge to resize cells on rotation.

## Background
I had been working on minor updates to FractalScapes and Daisy both of which use the same style of UICollectionView for presenting the fractal plants & real plants to the user. Since both FractalScapes and Daisy deal with plants, the collectionViewCell was designed to look like a typical plant information stick a plant buyer finds stuck in the pot of a new plant. These sticks usually have the name, a description and technical information for the plant. Something like the image of plant markers ...

![Plant Markers](/assets/images/blog/garden_vegetable_cards.jpg)

A new feature was to have the UICollectionViewCells arranged so they would be centered for all screen sizes & orientations. In addition, it would be nice if the cells auto-resized themselves within a certain range to maximize the use of the screen space. The existing version just changed the collectionViewLayout insets rather than resizing the cells. This left lots of intra-cell space on a 7 Plus. Implementing resizing cells on rotation didn't seem like a lot to ask of the amazing collectionView with its all singing all dancing UICollectionViewLayout class. I figured it might take an hour to implement by invalidating the layout in the UIViewController call to viewWillTransitionToSize:withTransitionCoordinator: and implementing the size delegate. Similar to what I had already done for the edge insets.

Boy was I wrong.

TLDR;

## First Attempt
After reading UICollectionViewLayout documentation numerous times, the internal workings of the framework were still as clear as mud. So the first attempt was to use a brute force call to [UICollectionViewLayout invalidateLayout] within the call to [UIViewController viewWillTransitionToSize:withTransitionCoordinator:]. It seemed to work perfectly and took as little time as expected. But then during testing, it would randomly crash on rotation! Sometimes taking 10 or more rotation cycles before crashing. Every time, the crash had none of my code in the debugger stack, only a UICollectionView call to an  NSDictionary where it seemed it was looking up cached visible cells.

Ok let's spend the next 3 days proving my ignorance of the inner workings of UICollectionViewFlowLayouts by randomly changing stuff like a room full of monkeys writing the next great app? Let's make offerings of Hawaiian coffee to the coding gods. Maybe the app doesn't need this feature? Maybe no one will notice the little lonely cells in the big room? Let's just give up! 

## Scientific Method
Somehow after 3 days of trying magical thinking, I came to my senses and decided to try the scientific method. 

 

- **Hypothesis** - UICollectionViewFlowLayout is not invalidating as I expect.
- **Experiment** 
Create a subclass of UICollectionViewFlowLayout in order to be able to intercept and explore the input/output to the layout methods.
Add breakpoints and NSLog statements to the subclass' shouldInvalidateLayoutForBoundsChange: and invalidationContextForBoundsChange:
Whenever the device is rotated, the view bounds changes and the execution would break at shouldInvalidateLayoutForBoundsChange:. While at this breakpoint, I could now call super with various bounds and view the result allowing me to characterize the internal logic of the class.
- **Results Analysis**...
 

Behavior of FlowLayout shouldInvalidateLayoutForBoundsChange
It turns out, shouldInvalidateLayoutForBoundsChange: only returns YES if the dimension of the bounds change is orthogonal to the collections scrolling direction. If scrolling is vertical, then the shouldInvalidateLayoutForBoundsChange: returns YES for any change in the bounds X dimensions whether origin of width. Changes in the vertical dimension returns NO for shouldInvalidateLayoutForBoundsChange:.

Yay, so in a matter of a few minutes, we now know when the UICollectionViewFlowLayout expects to invalidate a layout on bounds change. Next is to find out what kind of invalidation context it triggers?

Behavior of invalidationContextForBoundsChange:
We continue past the shouldInvalidateLayoutForBoundsChange:  and the next break is invalidationContextForBoundsChange:. Here we can again call super with various bounds and then check which of the UICollectionViewFlowLayoutInvalidationContext invalidateABC properties are set to YES. Here is the NSLog result of a rotation changing the bounds width for a vertical scrolling collectionView:

```objectivec
[MDKUICollectionViewFlowLayoutDebug invalidationContextForBoundsChange:] bounds: \{\{0, -64\}, \{1366, 1024\}\},
 <UICollectionViewFlowLayoutInvalidationContext: 0x6180000e5700> 
invalidateEverything: NO,
invalidatedItemIndexPaths: NO, 
invalidateFlowLayoutAttributes: YES, 
invalidateFlowLayoutDelegateMetrics: NO
```

That's interesting! The flow layout does NOT set invalidateFlowLayoutDelegateMetrics. And upon further research, we know that the one method for setting item size, [UICollectionViewFlowLayoutDelegate collectionView:layout:sizeForItemAtIndexPath:] does not get called unless invalidateFlowLayoutDelegateMetrics is set. So that is our problem. UICollectionViewFlowLayout pretty much never asks for new sizes from the delegate. Even if the bounds changes and shouldInvalidateLayoutForBoundsChange: returns YES. Using our custom flow to override invalidationContextForBoundsChange: and set invalidateFlowLayoutDelegateMetrics = YES, results in our delegate being called for a new size and the desired resizing or rotation working beautifully.

## UICollection View Flow Layout Behavior Summary
- shouldInvalidateLayoutForBoundsChange: returns YES for any change in bounds orthogonal to the scrolling direction.
- [UICollectionViewFlowLayoutDelegate collectionView:layout:sizeForItemAtIndexPath:] will only be called if invalidateFlowLayoutDelegateMetrics = YES. AND the best time for this to be set is in a subclass implementation of [MDKUICollectionViewFlowLayoutDebug invalidationContextForBoundsChange:].

## Resizing UICollection Reusable View Implementation
```objectivec
@interface MDKUICollectionViewResizingFlowLayout : UICollectionViewFlowLayout
@end

@implementation MDKUICollectionViewFlowLayoutDebug

-(UICollectionViewLayoutInvalidationContext *)invalidationContextForBoundsChange:(CGRect)newBounds 
{
    UICollectionViewFlowLayoutInvalidationContext* validationContext = (UICollectionViewFlowLayoutInvalidationContext*)[super invalidationContextForBoundsChange:newBounds];
    validationContext.invalidateFlowLayoutDelegateMetrics = YES;

    return validationContext;
}

@end 
```
Then in your UIViewControllerFlowLayoutDelegate protocol implementor, return your new sizes. In my case, I implemented a class for the resizing and other related reusable functionality. 

```objectivec
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [MDBResizingWidthFlowLayoutDelegate collectionView: collectionView layout: collectionViewLayout sizeForItemAtIndexPath: indexPath];
} 
```

Lastly, if you wanted to just invalidate the sizes for the layout manually, you could do something like:


```objectivec
UICollectionViewFlowLayoutInvalidationContext* validationContext = [UICollectionViewFlowLayoutInvalidationContext new];
validationContext.invalidateFlowLayoutAttributes = YES;

UICollectionViewFlowLayout* layout = (UICollectionViewFlowLayout*)collectionView.collectionViewLayout;
[layout invalidateLayoutWithContext: validationContext];
```

iPhone 7 Plus result of resizing after each bounds change. The resizing algorithm adds a little height as well as width when there is more room.

| Before         | After     | 
|--------------|-----------|
| ![Portrait](/assets/images/blog/collection-view-portrait-before.png) | ![Portrait](/assets/images/blog/collection-view-portrait-after.png)      | 
| ![Landscape](/assets/images/blog/collection-view-landscape-before.png)      | ![Landscape](/assets/images/blog/collection-view-landscape-after.png)  | 