#import "SnapshotHelper.js"

var target = UIATarget.localTarget();
var app = target.frontMostApp();
var window = app.mainWindow();


target.delay(2)
window.scrollViews()[0].buttons()["Get Started by selecting a fractal!"].tap();
target.delay(2)
captureLocalizedScreenshot("0-LandingScreen")

window.collectionViews()[0].cells()[13].tap();
//target.frontMostApp().mainWindow().buttons()["OpenCloseEditor"].tap();
//target.frontMostApp().mainWindow().buttons()["ToggleHUDViews"].tap();
//target.frontMostApp().navigationBar().buttons()["toolBarPlay"].tap();
//target.frontMostApp().navigationBar().buttons()["Stop"].tap();
//target.frontMostApp().navigationBar().buttons()["toolBarPlay"].tap();
//target.frontMostApp().mainWindow().sliders()["PlayBackSlider"].dragToValue(0.48);
//target.frontMostApp().mainWindow().sliders()["PlayBackSlider"].dragToValue(0.67);
//target.frontMostApp().mainWindow().sliders()["PlayBackSlider"].dragToValue(0.73);
//target.frontMostApp().mainWindow().sliders()["PlayBackSlider"].dragToValue(0.77);
//target.frontMostApp().mainWindow().sliders()["PlayBackSlider"].dragToValue(0.45);
//target.frontMostApp().navigationBar().buttons()["Stop"].tap();
//target.frontMostApp().navigationBar().leftButton().tap();
//target.frontMostApp().navigationBar().rightButton().tap();
//target.frontMostApp().navigationBar().rightButton().tap();
//target.frontMostApp().statusBar().tapWithOptions({tapOffset:{x:0.72, y:0.90}});
//target.frontMostApp().mainWindow().popover().dismiss();
//target.frontMostApp().navigationBar().leftButton().tap();
//target.frontMostApp().tabBar().buttons()["Browse Cloud"].tap();
// Alert detected. Expressions for handling alerts should be moved into the UIATarget.onAlert function definition.
//target.frontMostApp().alert().buttons()["OK"].tap();

target.delay(1)
app.navigationBar().leftButton().tap();

target.delay(6)
captureLocalizedScreenshot("1-DragonView")

target.delay(1)
window.buttons()["OpenCloseEditor"].tap();
target.delay(2)
captureLocalizedScreenshot("2-DragonEditDescription")

window.popover().tabBar().buttons()["Colors"].tap();
target.delay(2)
captureLocalizedScreenshot("3-DragonEditColors")

window.popover().tabBar().buttons()["Effects"].tap();
target.delay(2)
captureLocalizedScreenshot("4-DragonEditEffects")

window.popover().tabBar().buttons()["Rules"].tap();
target.delay(2)
captureLocalizedScreenshot("5-DragonEditRules")

//target.frontMostApp().mainWindow().buttons()["OpenCloseEditor"].tap();
window.elements()["OpenCloseEditor"].tapWithOptions({tapOffset:{x:0.82, y:0.51}});
target.delay(1)
//target.frontMostApp().mainWindow().buttons()["ToggleHUDViews"].tap();
//window.buttons()["toolBarHUDScreenIcon"].tap();
target.delay(1)

captureLocalizedScreenshot("6-DragonFullScreen")

app.navigationBar().buttons()["toolBarPlay"].tap();
target.delay(2)
target.frontMostApp().mainWindow().sliders()["PlayBackSlider"].dragToValue(0.77);
//window.sliders()[0].dragToValue(0.69);

captureLocalizedScreenshot("7-DragonPlay")

app.navigationBar().buttons()["Stop"].tap();
target.delay(1)

app.navigationBar().rightButton().tap();

target.delay(1)
captureLocalizedScreenshot("8-DragonShareOptions")

target.frontMostApp().mainWindow().popover().dismiss();

app.navigationBar().leftButton().tap();
