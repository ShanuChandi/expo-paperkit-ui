# expo-paperkit-ui

An Expo module that wraps Apple's **PaperKit** framework (iOS 26+) for React Native. Provides a full-featured drawing/markup canvas with native Apple Pencil support, shape insertion, text boxes, images, background patterns, and more.

> **Warning: iOS 26+ only.** PaperKit is a new Apple framework introduced at WWDC 2025. This module requires iOS 26.0 or later and an Expo development build. It does **not** work in Expo Go.

---

## Installation

```bash
npm install expo-paperkit-ui
# or
bun add expo-paperkit-ui
```

Then rebuild your native app:

```bash
npx expo prebuild --clean
# or
eas build --profile development --platform ios
```

---

## Quick Start

```tsx
import { PaperKitView, PaperKitViewRef } from "expo-paperkit-ui";
import React, { useRef } from "react";
import { Button, View } from "react-native";

export default function App() {
  const ref = useRef<PaperKitViewRef>(null);

  return (
    <View style={{ flex: 1 }}>
      <PaperKitView
        ref={ref}
        style={{ flex: 1 }}
        isEditable={true}
        isRulerActive={false}
        showsScrollIndicators={false}
      />
      <Button
        title="Toggle Tools"
        onPress={() => ref.current?.toggleToolPicker()}
      />
    </View>
  );
}
```

---

## Props

| Prop                     | Type        | Default | Description                          |
| ------------------------ | ----------- | ------- | ------------------------------------ |
| `style`                  | `ViewStyle` | -       | Standard React Native view style     |
| `isEditable`             | `boolean`   | `true`  | Whether the canvas can be edited     |
| `isRulerActive`          | `boolean`   | `false` | Show the native ruler tool           |
| `showsScrollIndicators`  | `boolean`   | `true`  | Show scroll indicators on the canvas |

---

## Events

| Event              | Payload                | Description                  |
| ------------------ | ---------------------- | ---------------------------- |
| `onDrawStart`      | `{ data: string }`     | User began drawing           |
| `onDrawEnd`        | `{ data: string }`     | User finished drawing        |
| `onDrawChange`     | `{ data: string }`     | Drawing content changed      |
| `onCanUndoChanged` | `{ canUndo: boolean }` | Undo availability changed    |
| `onCanRedoChanged` | `{ canRedo: boolean }` | Redo availability changed    |
| `onMarkupChanged`  | `{}`                   | Markup content changed       |

---

## Ref Methods

All methods are async and accessed via a ref:

```tsx
const ref = useRef<PaperKitViewRef>(null);
```

### Tool Picker

| Method              | Return | Description                         |
| ------------------- | ------ | ----------------------------------- |
| `setupToolPicker()`  | `void` | Show the native floating tool picker |
| `toggleToolPicker()` | `void` | Toggle tool picker visibility        |
| `hideToolPicker()`   | `void` | Hide the tool picker                 |

### Undo / Redo / Clear

| Method           | Return    | Description                  |
| ---------------- | --------- | ---------------------------- |
| `undo()`         | `void`    | Undo last action             |
| `redo()`         | `void`    | Redo last undone action      |
| `clearDrawing()` | `void`    | Clear all canvas content     |
| `clearMarkup()`  | `void`    | Alias for `clearDrawing()`   |
| `canUndo()`      | `boolean` | Check if undo is available   |
| `canRedo()`      | `boolean` | Check if redo is available   |

### Data Persistence

| Method                          | Return    | Description                                   |
| ------------------------------- | --------- | --------------------------------------------- |
| `captureDrawing()`              | `string`  | Capture canvas as base64 PNG image            |
| `getCanvasDataAsBase64()`       | `string`  | Get raw drawing data as base64 (save/restore) |
| `setCanvasDataFromBase64(data)` | `boolean` | Load drawing from base64 data                 |

**Save and restore example:**

```tsx
// Save
const data = await ref.current?.getCanvasDataAsBase64();
await AsyncStorage.setItem("drawing", data);

// Restore
const saved = await AsyncStorage.getItem("drawing");
if (saved) await ref.current?.setCanvasDataFromBase64(saved);
```

### Background Color

| Method                           | Return   | Description                                |
| -------------------------------- | -------- | ------------------------------------------ |
| `setCanvasBackgroundColor(hex)`  | `void`   | Set the paper surface color                |
| `getCanvasBackgroundColor()`     | `string` | Get current paper color as hex             |
| `setViewBackgroundColor(hex)`    | `void`   | Set the area behind the canvas             |
| `getViewBackgroundColor()`       | `string` | Get current view background as hex         |
| `showColorPicker()`              | `void`   | Open native iOS color picker for paper     |

```tsx
// Blue paper on dark background
ref.current?.setCanvasBackgroundColor("#E8F4FD");
ref.current?.setViewBackgroundColor("#1a1a2e");
```

### Background Patterns

| Method                          | Return | Description                                                 |
| ------------------------------- | ------ | ----------------------------------------------------------- |
| `setBackgroundPattern(pattern)` | `void` | Set pattern: `"none"`, `"lines"`, `"grid"`, or `"dots"`    |
| `setBackgroundLineColor(hex)`   | `void` | Color of pattern lines/dots                                 |
| `setBackgroundSpacing(points)`  | `void` | Spacing between lines/dots (default: 32)                    |

```tsx
// Notebook-style ruled lines
ref.current?.setBackgroundPattern("lines");
ref.current?.setBackgroundLineColor("#B0BEC5");
ref.current?.setBackgroundSpacing(28);

// Dotted (Moleskine-style)
ref.current?.setBackgroundPattern("dots");

// Graph paper
ref.current?.setBackgroundPattern("grid");

// Remove pattern
ref.current?.setBackgroundPattern("none");
```

### Canvas Aspect Ratio

| Method                       | Return | Description                    |
| ---------------------------- | ------ | ------------------------------ |
| `setCanvasAspectRatio(ratio)` | `void` | Set canvas width/height ratio |

```tsx
ref.current?.setCanvasAspectRatio(0.707);  // A4 portrait
ref.current?.setCanvasAspectRatio(16 / 9); // Widescreen
ref.current?.setCanvasAspectRatio(1);      // Square
```

### Quick Add Elements

Elements are added programmatically and the canvas auto-switches to **selection mode** so you can immediately move, resize, and rotate them.

#### Shapes

```tsx
ref.current?.insertShape({
  type: "rectangle",
  // Also: roundedRectangle, ellipse, star,
  //       chatBubble, regularPolygon, arrowShape
  x: 100,
  y: 100,
  width: 200,
  height: 200,
  strokeColor: "333333",
  fillColor: "FFD700",  // optional
  lineWidth: 2,
  rotation: 0,          // optional, radians
});
```

#### Text Boxes

```tsx
ref.current?.insertTextbox({
  text: "Hello World",
  x: 100,
  y: 100,
  width: 200,
  height: 50,
  rotation: 0,
});
```

#### Lines

```tsx
ref.current?.insertLine({
  fromX: 50,
  fromY: 200,
  toX: 300,
  toY: 200,
  strokeColor: "333333",
  lineWidth: 2,
  startMarker: false,
  endMarker: true,  // arrowhead
});
```

#### Images

```tsx
// From base64
ref.current?.insertImage({
  base64: "iVBORw0KGgo...",
  x: 50,
  y: 50,
  width: 300,
  height: 200,
});

// From file URI
ref.current?.insertImage({
  uri: "file:///path/to/photo.jpg",
  x: 50,
  y: 50,
  width: 300,
  height: 200,
});
```

### Add Menu and Tools

| Method                  | Return | Description                                            |
| ----------------------- | ------ | ------------------------------------------------------ |
| `showAddMenu()`         | `void` | Open native PaperKit add menu (shapes, text, stickers) |
| `setTouchMode(mode)`    | `void` | Switch between `"drawing"` and `"selection"`           |
| `setZoomRange(min, max)` | `void` | Set zoom limits (e.g. `0.5, 5`)                       |

---

## Types

```typescript
import type {
  PaperKitViewProps,
  PaperKitViewRef,
  ShapeType,
  TouchMode,
  BackgroundPattern,
  InsertShapeParams,
  InsertTextboxParams,
  InsertLineParams,
  InsertImageParams,
} from "expo-paperkit-ui";
```

| Type                | Values                                                                                                               |
| ------------------- | -------------------------------------------------------------------------------------------------------------------- |
| `ShapeType`         | `"rectangle"` `"roundedRectangle"` `"ellipse"` `"line"` `"arrowShape"` `"chatBubble"` `"regularPolygon"` `"star"` |
| `TouchMode`         | `"drawing"` or `"selection"`                                                                                         |
| `BackgroundPattern` | `"none"` `"lines"` `"grid"` `"dots"`                                                                               |

---

## Known Issues

This package is in active development. The following features need improvement:

- **Background patterns (grid, lines, dots) do not work reliably.** The overlay pattern may not display correctly or may disappear after interactions. This is due to PaperKit internally rebuilding its view hierarchy, which conflicts with the transparent overlay approach.
- **Canvas background color change does not work properly.** Setting the canvas background color may not apply to all internal PaperKit views consistently, or may be overridden by PaperKit's own rendering.

These are known limitations of working with PaperKit's internal (private) view hierarchy. Contributions to solve these issues are very welcome.

---

## Contributing

This is an open-source project and contributions are welcome! PaperKit is a brand-new framework from Apple (iOS 26+), so there is very little community knowledge available yet. If you have experience with PaperKit, PencilKit, or Expo native modules, your help would be greatly appreciated.

**Areas where help is needed:**

- Fixing the background pattern overlay (grid, lines, dots)
- Making canvas background color changes reliable
- Adding new PaperKit features as Apple expands the framework
- Testing on different iPad models and Apple Pencil generations
- Documentation improvements

**How to contribute:**

1. Fork the repository: [github.com/ShanuChandi/expo-paperkit-ui](https://github.com/ShanuChandi/expo-paperkit-ui)
2. Create a feature branch: `git checkout -b feature/my-fix`
3. Make your changes and test on a real device (PaperKit requires iOS 26+)
4. Submit a pull request

Feel free to open an issue to discuss ideas or report bugs.

---

## Requirements

| Requirement  | Version |
| ------------ | ------- |
| iOS          | 26.0+   |
| Expo         | SDK 53+ |
| React Native | 0.79+   |
| Xcode        | 26+     |

---

## License

MIT