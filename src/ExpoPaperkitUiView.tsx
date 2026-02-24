import {
    requireNativeModule,
    requireNativeViewManager,
} from "expo-modules-core";
import React, { useImperativeHandle, useRef } from "react";
import { Platform, findNodeHandle } from "react-native";
import type { PaperKitViewProps, PaperKitViewRef } from "./ExpoPaperkitUi.types";

let NativeModule: any = null;
let NativeViewManager: any = null;

if (Platform.OS === "ios") {
  try {
    NativeModule = requireNativeModule("ExpoPaperkitUi");
  } catch (e) {
    console.warn("ExpoPaperkitUi native module not found. Did you rebuild the native app?", e);
  }
  try {
    NativeViewManager = requireNativeViewManager("ExpoPaperkitUi");
  } catch (e) {
    console.warn("ExpoPaperkitUi native view not found. Did you rebuild the native app?", e);
  }
}

export const PaperKitView = React.forwardRef<PaperKitViewRef, PaperKitViewProps>(
  (props, ref) => {
    const viewRef = useRef<any>(null);

    const callNative = async (method: string, ...args: any[]) => {
      if (Platform.OS !== "ios" || !NativeModule || !viewRef.current) return;
      const viewTag = findNodeHandle(viewRef.current);
      if (!viewTag) return;
      return await NativeModule[method](viewTag, ...args);
    };

    useImperativeHandle(ref, () => ({
      // Tool Picker
      setupToolPicker: () => callNative("setupToolPicker"),
      toggleToolPicker: () => callNative("toggleToolPicker"),
      hideToolPicker: () => callNative("hideToolPicker"),

      // Undo / Redo / Clear
      undo: () => callNative("undo"),
      redo: () => callNative("redo"),
      clearDrawing: () => callNative("clearDrawing"),
      clearMarkup: () => callNative("clearMarkup"),
      canUndo: async () => (await callNative("canUndo")) ?? false,
      canRedo: async () => (await callNative("canRedo")) ?? false,

      // Data Persistence
      captureDrawing: async () => (await callNative("captureDrawing")) ?? "",
      getCanvasDataAsBase64: async () => (await callNative("getCanvasDataAsBase64")) ?? "",
      setCanvasDataFromBase64: async (data: string) =>
        (await callNative("setCanvasDataFromBase64", data)) ?? false,

      // Background Color
      setCanvasBackgroundColor: (color: string) =>
        callNative("setCanvasBackgroundColor", color),
      getCanvasBackgroundColor: async () =>
        (await callNative("getCanvasBackgroundColor")) ?? "FFFFFF",
      showColorPicker: () => callNative("showColorPicker"),

      // View Background Color (area behind canvas)
      setViewBackgroundColor: (color: string) =>
        callNative("setViewBackgroundColor", color),
      getViewBackgroundColor: async () =>
        (await callNative("getViewBackgroundColor")) ?? "FFFFFF",

      // Canvas
      setCanvasAspectRatio: (ratio: number) =>
        callNative("setCanvasAspectRatio", ratio),

      // Background Pattern
      setBackgroundPattern: (p) => callNative("setBackgroundPattern", p),
      setBackgroundLineColor: (c) => callNative("setBackgroundLineColor", c),
      setBackgroundSpacing: (s) => callNative("setBackgroundSpacing", s),

      // Add Menu
      showAddMenu: () => callNative("showAddMenu"),

      // Quick Add
      insertShape: (p) => callNative("insertShape", p),
      insertTextbox: (p) => callNative("insertTextbox", p),
      insertLine: (p) => callNative("insertLine", p),
      insertImage: (p) => callNative("insertImage", p),

      // Touch Mode & Zoom
      setTouchMode: (m) => callNative("setTouchMode", m),
      setZoomRange: (min, max) => callNative("setZoomRange", min, max),
    }), []);

    if (Platform.OS !== "ios" || !NativeViewManager) return null;

    return React.createElement(NativeViewManager, {
      ...props,
      ref: viewRef,
    });
  }
);
