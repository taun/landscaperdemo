---
permalink: /blog/fractalscapes-without-scrollview
title:  "Basic Non-Scrolling UITableView and UICollectionViews"
date:   2014-12-19 23:49:00 -0500
tags: fractalscapes UICollectionView UITableView
categories: fractalscapes
summary: How to create a basic view which can layout subviews in a way similar to a UITableView or UICollectionView without the embedded scrolling and other baggage of the standard views. 
excerpt: How to create a basic view which can layout subviews in a way similar to a UITableView or UICollectionView without the embedded scrolling and other baggage of the standard views. 
toc: true
---

This is from a talk I gave at the [Philly CocoaHeads meeting](http://phillycocoa.org/2014/12/17/phillycocoa-meeting-notes-december-2014/). The [slideshow](http://www.moedae.com/blog/cocoaheads-talk-materials/CocoaHeads%20IB_Designable%20and%20MVC.pdf) for the talk is [here](http://www.moedae.com/blog/cocoaheads-talk-materials/CocoaHeads%20IB_Designable%20and%20MVC.pdf). The talk had 3 parts, implementing a basic replacement for UITableView and UICollectionView, using Smalltalk style MVC for views and using IBDesignable for MVC style view re-use. This is just part 1 of 3.

# Why not UICollectionView?

![Basic Collection Embedded in Table](/assets/images/blog/fractal-editor-bush-mini.png)

For the rest of this discussion, I am just going to use UICollectionView but all the points relate to UITableView as well. 

UICollectionView is great for presenting infinite lists of objects in a very efficient manner but to do this, it has many moving parts. There is the dataSource which makes it easy to cache and batch fetch objects before feeding them to the collection. There is the delegate which allows changing the view appearance and business logic on a per cell basis. Each collectionViewCell design has a reuseIdentifier so the cell views can be instantiated once and reused on an as needed basis during scrolling. And to top it all off, the UICollectionView is a subclass of UIScrollView so there is no separating the scroll functionality from the collection presentation.

What if all you want is to present a few homogeneous object views in either a flow or table layout. What if you don't need or want the scrolling or caching? What if you want a flow layout of objects embedded in something like a table layout? In all of these cases, the implementation of the standard UICollectionView gets in the way. Trying to disable scrolling behavior you didn't want is just a waste of valuable time. I had all of these issues in a few of my projects but always avoided starting from scratch because it seemed that would be more work than using the existing tools. Once I gave up on UICollectionView and started from scratch, it turned out to be much easier than expected with less code and much better suited to my needs. 

## Rolling Your Own Basic CollectionView

At its most basic, a tableView or collectionView is just a way of laying out object views. Organizing views vertically is a table. Laying out views horizontally then have them wrap when they reach a maximum width is similar to the standard collectionView flow layout. Achieving this layout behavior with auto layout is trivial. Note, I am not including other behaviors of TableViews such as the add, delete, and reorder accessory views.

### TableView Layout 

![Vertical Table View Layout](/assets/images/blog/VerticalCollectionTableLayoutSample2.png)

Why do we use static tableviews? This is not just a rhetorical question. If you need a static table view with 4 cells, why not just use a ViewController and layout 4 views? You have to create 4 tableViewCells anyhow and you don't need all of the tableView mechanisms. On the other hand, if you want to layout a variable but small number of object views in a vertical row layout and embed the whole thing in a scrollView, all you need is something like the following code.

TABLEVIEW LAYOUT CODE
```objectivec
@implementation NSLayoutConstraint (MDBAddons)

+(NSArray*) constraintsForFlowing:(NSArray *)views inContainingView:(UIView *)container forOrientation:(UILayoutConstraintAxis)axis withSpacing:(CGFloat)spacing {

    NSMutableArray* constraints = [NSMutableArray new];

    if (views.count > 0) {
        
        NSInteger viewIndex;

        UIView* firstView = [views firstObject];
        UIView* lastView = [views lastObject];
        
        NSLayoutAttribute firstEdgeAttribute;
        NSLayoutAttribute lastEdgeAttribute;

        if (axis == UILayoutConstraintAxisVertical) {
            firstEdgeAttribute = NSLayoutAttributeTop;
            lastEdgeAttribute = NSLayoutAttributeBottom;
        } else {
            firstEdgeAttribute = NSLayoutAttributeLeft;
            lastEdgeAttribute = NSLayoutAttributeRight;
        }
        
        [constraints addObject: [NSLayoutConstraint constraintWithItem: container
                                                             attribute: firstEdgeAttribute
                                                             relatedBy: NSLayoutRelationEqual
                                                                toItem: firstView
                                                             attribute: firstEdgeAttribute
                                                            multiplier: 1.0
                                                              constant: 0.0]];
                
        for (viewIndex = 1; viewIndex < views.count ; viewIndex++) {
            //
            UIView* prevView = views[viewIndex-1];
            UIView* view = views[viewIndex];
            
            [constraints addObject: [NSLayoutConstraint constraintWithItem: view
                                                                 attribute: firstEdgeAttribute
                                                                 relatedBy: NSLayoutRelationEqual
                                                                    toItem: prevView
                                                                 attribute: lastEdgeAttribute
                                                                multiplier: 1.0
                                                                  constant: spacing]];
            
        }
        
        [constraints addObject: [NSLayoutConstraint constraintWithItem: lastView
                                                             attribute: lastEdgeAttribute
                                                             relatedBy: NSLayoutRelationEqual
                                                                toItem: container
                                                             attribute: lastEdgeAttribute
                                                            multiplier: 1.0
                                                              constant: 0.0]];
        
    }
    
    return constraints;
}

@end
```

The above code takes an array of subviews and creates NSLayoutConstraints which will result in a table like layout. The assumption is the object container view passes the array of it's subviews to the above method during the updateContraints call of the object container. That's all there is to a basic table layout of views.

## UICollectionView Flow Layout

![CollectionView Layout](/assets/images/blog/FlowLayoutSample1.png)

Implementing a basic UICollectionView style flow layout is a little more complicated but not much. With a flow layout, we assume object views are going to be laid out left to right and top to bottom. We also decided to have a fixed width which is dictated by the basicCollectionView container. If we know the fixed width, then we simply need to find out how many object views will fit in a row, then calculate the constraints for each object view and the total height of the basicCollectionView. There are two ways to define the NSLayoutConstraints for the object views. They can be defined relative to each other or in absolute terms with respect to the container boundaries. Absolute constraints end up having a number of benefits. First and foremost, when a view is added or removed from the collection, it is easy to just update the absolute constraint constants rather than redoing the constraints. If you just change auto layout constraint constants, you get the views animating into place for free. 

The following code excerpt calculates the auto layout constraint constants for a view of a given collection index.

COLLECTIONVIEW CONSTANT CALC
```objectivec
-(void) calcHConstraint: (NSLayoutConstraint*)hConstraint vConstraint: (NSLayoutConstraint*) vConstraint forIndex: (NSUInteger) index {
    
    NSUInteger itemsPerLine = self.itemsPerLine;
    
    NSUInteger widthMargin = _justify ? (self.bounds.size.width - 2.0*self.outlineMargin - (itemsPerLine * _tileWidth)) / (itemsPerLine-1) : _tileMargin;

    NSUInteger lineNumber = floorf((float)index/(float)itemsPerLine);
    
    NSInteger hOffset = self.outlineMargin + (_tileWidth + widthMargin) * (index - lineNumber*itemsPerLine);
    
    NSInteger vOffset = (lineNumber==0 && _showOutline) ? self.outlineMargin : lineNumber*(_tileWidth+_tileMargin);

#pragma message "TODO: fix constraint limits to ? hardware?"
    if (vOffset < 0) {
        NSAssert(YES, @"Constraint out of range");
    }
    hOffset = hOffset < 0 ? 0 : hOffset;
    vOffset = vOffset < 0 ? 0 : vOffset;
    hOffset = hOffset > 1024 ? 1024 : hOffset;
    vOffset = vOffset > 1024 ? 1024 : vOffset;
    
    hConstraint.constant = hOffset;
    vConstraint.constant = vOffset;
}
```

During the collection container's layoutSubviews, all of the object views are laid out and given default absolute layout constraints. The same for whenever a view is added. Then during updateConstraints, the object views are iterated and the above method is called to update the constraint constants. If an object view is added, moved or removed, setNeedsConstraintsUpdate is called to flag the need to revise the constraint constants.

The above sample code was used to implement a basic collection view embedded in a table style view with drag and drag re-ordering, deleting and adding. The full implementation requires protocols for the object views, and drag and drop. Both of which I will outline at the end of this series since they use the Smalltalk style MVC and IBDesignable.

Below is an image of the current FractalScape implementation and [here is a video](https://vimeo.com/115025604) showing how it works.

![Basic Collection Embedded in Table](/assets/images/blog/fractal-editor-bush.png)
