---
title: "How does FractalScapes work"
---

FractalScapes is an L-System fractal generator. L-Systems is basically a graphics language with very simple rules. In most L-Systems, drawing rules are represented by letters of the alphabet such as "F" meaning draw a line. FractalScapes has replaced the letters with icons so in FractalScapes,

draw a line is represented by the icon: ![](/assets/images/kBIconRuleDrawLine.png)

Turn left is ![](/assets/images/kBIconRuleRotateCC.png)

Turn right is ![](/assets/images/kBIconRuleRotateC.png)

By putting the rules in sequence, you tell the application what to draw. so the sequence:

![](/assets/images/kBIconRuleDrawLine.png) ![](/assets/images/kBIconRuleRotateCC.png) ![](/assets/images/kBIconRuleDrawLine.png) ![](/assets/images/kBIconRuleRotateC.png) ![](/assets/images/kBIconRuleDrawLine.png)

Draws a horizontal line connected to a upward vertical line connected to a rightward horizontal line.

Every l-system fractal starts with an initial sequence of rules which can be like the one above and the starting rules are labeled "Start" in the app editor. You can draw all sorts of shapes with curves, fills and lines but that is not the cool part. The cool part happens next. With "Replacement Rules" see the "Replacement Rules" in the FAQ.
