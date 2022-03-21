![Shakuro Draggable Overlay](Resources/title_image.png)
<br><br>
# DraggableOverlay
![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![Platform](https://img.shields.io/badge/platform-iOS-lightgrey.svg)
![License MIT](https://img.shields.io/badge/license-MIT-green.svg)

- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [License](#license)

`DraggableOverlay` is a Swift library to show custom draggble viewcontroller. `DraggableOverlay` has various configuration options:

Draggable Overlay example:

![](Resources/draggable_overlay.gif)

## Requirements

- iOS 11.0+
- Xcode 11.0+
- Swift 5.0+

## Installation

### CocoaPods

To integrate Draggable Overlay into your Xcode project with CocoaPods, specify it in your `Podfile`:

```ruby
pod 'Shakuro.DraggableOverlay'
```

Then, run the following command:

```bash
$ pod install
```

### Manually

If you prefer not to use CocoaPods, you can integrate Shakuro.DraggableOverlay simply by copying it to your project.

## Usage
Just initilize DraggableDetailsOverlayViewController with your nested viewcontroller and delegate. Nested viewcontroller must adopt the DraggableDetailsOverlayViewControllerDelegate and DraggableDetailsOverlayNestedInterface protocols. The delegate allows to respond to scrolling events.
Have a look at the [DraggableOverlayExample](https://github.com/shakurocom/DraggableOverlay/tree/main/DraggableOverlayExample) (perform `pod install` before usage)

## License

Shakuro.DraggableOverlay is released under the MIT license. [See LICENSE](https://github.com/shakurocom/DraggableOverlay/blob/main/LICENSE.md) for details.

## Give it a try and reach us

Star this tool if you like it, it will help us grow and add new useful things. 
Feel free to reach out and hire our team to develop a mobile or web project for you.


