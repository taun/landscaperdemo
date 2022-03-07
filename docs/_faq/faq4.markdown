---
title: "What's the difference between Easy & Advanced Rules"
---

The Advanced rules give more control over what to draw and when using the rule "!" which means "draw!". Nothing is drawn on the screen without the "draw!" command. In "Easy" mode, the app adds the "draw!" command for you in the background. This way, something will always draw on the screen but you have less control over the drawing.

**Background details**: FractalScapes uses the "path" drawing feature of iOS. Every sequence of lines and turns define a path. A path can only have one color and thickness. To change the color or thickness of a path, one must "draw!" the path and start a new path. Drawing the path uses only the last designated color and thickness. This is like drawing on paper with felt markers. For example, to change the color of the path from red to blue, you start by drawing on the paper with a red marker, then put down the red and pick up the blue marker to start drawing in blue. The thickness of the line also depends on the tip of the marker so changing thickness also requires changing the marker. The "draw!" command tell the app to pick up a marker and draw all of the commands given since the last marker was used.

**Easy mode**: The app automatically sends a "draw!" command whenever the rules call for a change in color, thickness, stroke or fill.

**Advanced mode**: The app does not send any "draw!" command. Rules are only drawn if there is a draw rule added. This means you can "turn off" a series of replacement rules by just not including a draw! rule. You can watch a series of rules develop by moving the draw! rule step by step from the first position to the last. You have finer control over when a fill or stroke change is applied by the placement of the draw! rule which can be independent of the fill-on fill-off rules.
