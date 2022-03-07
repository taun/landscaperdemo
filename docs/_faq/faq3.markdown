---
title: "What is a Replacement Rule"
---

Every fractal in FractalScapes has an initial starting sequence of rules.
This starting sequence may be drawing a triangle, a branch or just be a placeholder.
The real fun begins with the "Replacement Rules".
Any of the rules in the "Start" rules can be replaced with a new set of rules.
This replacement is what makes an l-system fractal. For example, if the starting rule
is just a straight line: ![](/assets/images/kBIconRuleDrawLine.png),

You can add a replacement rule for the straight line rule:

![](/assets/images/kBIconRuleDrawLine.png) => (gets replaced by)![](/assets/images/kBIconRuleDrawLine.png)
![](/assets/images/kBIconRuleRotateCC.png)![](/assets/images/kBIconRuleDrawLine.png)
![](/assets/images/kBIconRuleRotateCkBIconRuleDrawLine.png)

If we use the standard l-system alphabet rules,
then the above is the same as a starting rule = "F"
and a replacement rule of "F=>F+F-F". Applying the
replacement rule once means replace the one "F" in
the start with "F+F-F". Applying the replacement rule
again (level #2) would mean replace every F in the result "F+F-F"
with "F+F-F" which results in level #2= "F+F-F+F+F-F-F+F-F".
The result of replacing the starting rule with the replacement
rule for the first time is shown in the #1 preview window on the left of the app display.
The result of applying the replacements rules twice is in the #2 preview window.
The "Level" lets you change how many times the replacement rules are substituted
for the starting rule. Each new "Level" adds new detail to the fractal in the main window.

Level 2 resulting image: ![](/assets/images/SampleFAQLevel2.png)

You can use up to 6 placeholders ![](/assets/images/kBIconRulePlace0.png)![](/assets/images/kBIconRulePlace1.png)![](/assets/images/kbIconRulePlace2.png)
which don't draw anything but can then be replaced by any rule sequence you like.
You can have a replacement rule which replaces left turns, or any rule you like.
There are two separate drawing rules so you can have some lines replaced and some
lines not replaced or replaced with something different.

With replacement rules, even the sky isn't a limit.
