---
permalink: /funw-with-autolayout
title:  "Fun with auto layout"
date:   2012-12-08 19:49:00 -0500
tags: AutoLayout cocoa fix
summary: Fun in the sense of `great difficulties and mysteries.`
excerpt: Fun in the sense of `great difficulties and mysteries.`
---

In order to improve Aligyro on the iPhone 5, I switched the layout of the interface from "springs and struts" to "autolayout." Springs and struts has been around on the Mac forever and is to tell the operating system how to layout your interface elements. You tell it to either anchor an element feature (strut) or let the feature expand as needed (spring). The new to Apple autolayout is much more flexible. The programmer can specify features which should be equal such as height or width of buttons. One can specify alignments. You can even use math to say one element should be half the width of another. All very wonderful when it works.

![The Training Circle](/assets/images/blog/the-training-circle.png)

The learn mode training circle in Aligyro is just a flat png dotted circle laid on top of the 3D scene. The circle is centered on scene and rotated on it's center. To have a better preview of how the circle will look and to get the size correct, the circle is added in Interface Builder (IB) rather than in code. This means the layout needs to be done in IB. Initially this layout was done using struts and springs.


The struts are the |--| bars outside the box locking the margin between the element and the edge of the view. The springs <--> tell the view it can expand to allow the margins to be constant as the containing view expands and contracts. This worked perfectly for the learn mode dotted circle. The circle stayed centered on the 3D scene and scaled with the scene.

Changing the layout for all of the various Aligyro pages from springs and struts to autolayout was easy for everything but the learn mode. The goal with the learn mode autolayout was exactly the same as with springs and struts. The have the dotted circle centered on the 3D scene and to have it scale with the scene. This seemed trivial. Two of the available autolayout constraints are "align center x" and "align center y." Exactly what we want, a centered view. Since centering isn't sufficient to fully define the learn mode view, I needed to add either a defined margin or width and height. I tried both.

The problem was, no matter how I defined the autolayout constraints, the circle would not stay centered. It would start out centered but whenever the user clicked on the info button to bring up the preferences, the circle center would move. When they pressed play to go back to the 3D scene, the circle center would move again. Apparently, everytime the 3D view appeared or disappeared, the autolayout was being performed. Whenever the dotted circle view was rotated when the autolayout was performed, autolayout would move the view away from center.

Given that the center of the view does not change for any rotation about the center, this was bizarre behavior. The view was being rotated with the following code:

```objectivec
float zRotation = -DegreesToRadians(self.gyro3DView.rotation.z)+M_PI_2;

[self.trainingView.layer setValue:[NSNumber numberWithFloat: zRotation] forKeyPath:@"transform.rotation"];
```

The layer anchor point was set to the center and the dotted circle always rotated about it's center. The problem was it's center moved every time the autolayout was rerun. Somehow it seems, "align center" does not really mean align center for rotated layers.

I am sure there are many possible fixes. The one I chose was a 2 line workaround. Since the circle is only moved off center when the layout is run and when the circle layer rotation is non-zero and this only happens when leaving or entering the 3D view. I set the circle layer rotation to zero whenever the layout is happening. The next time the 3D scene is updated, the circle is rotated back to where it should be. The following code was added to my UIViewController for the 3D scene and dotted circle training view.

```objectivec
-(void)viewWillLayoutSubviews {

[self.trainingView.layer setValue: @0.0 forKeyPath: @"transform.rotation"];

}
```

The above overrides the standard UIViewController "viewWillLayoutSubviews" and sets the circle layer rotation to zero. Not pretty but it solved the problem.

Someone had a similar problem reported at [stackoverflow.com](http://stackoverflow.com/questions/13044289/autolayout-rotating-wheel)

And another version of the [problem here](http://openradar.appspot.com/12258628).