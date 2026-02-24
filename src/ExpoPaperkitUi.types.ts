import type { StyleProp, ViewStyle } from "react-native";

// ─── Shape Types (for reference/future use) ─────────────────────────────────
export type ShapeType =
  | "rectangle"
  | "roundedRectangle"
  | "ellipse"
  | "line"
  | "arrowShape"
  | "chatBubble"
  | "regularPolygon"
  | "star";

export type TouchMode = "drawing" | "selection";

export type BackgroundPattern = "none" | "lines" | "grid" | "dots";

// ─── Insertion Params ───────────────────────────────────────────────────────
export interface InsertShapeParams {
  type: ShapeType;
  x?: number;
  y?: number;
  width?: number;
  height?: number;
  rotation?: number;
  strokeColor?: string;
  fillColor?: string;
  lineWidth?: number;
}

export interface InsertTextboxParams {
  text: string;
  x?: number;
  y?: number;
  width?: number;
  height?: number;
  rotation?: number;
}

export interface InsertLineParams {
  fromX: number;
  fromY: number;
  toX: number;
  toY: number;
  strokeColor?: string;
  lineWidth?: number;
  startMarker?: boolean;
  endMarker?: boolean;
}

export interface InsertImageParams {
  /** Base64-encoded image data (PNG/JPEG) */
  base64?: string;
  /** Image URI (file:// or https://) — used if base64 is not provided */
  uri?: string;
  x?: number;
  y?: number;
  width?: number;
  height?: number;
  rotation?: number;
}

// ─── Events ─────────────────────────────────────────────────────────────────
export interface DrawStartEvent {
  data: string;
}

export interface DrawEndEvent {
  data: string;
}

export interface DrawChangeEvent {
  data: string;
}

export interface CanUndoChangedEvent {
  canUndo: boolean;
}

export interface CanRedoChangedEvent {
  canRedo: boolean;
}

export interface NativeEvent<T> {
  nativeEvent: T;
}

// ─── View Props ─────────────────────────────────────────────────────────────
export interface PaperKitViewProps {
  style?: StyleProp<ViewStyle>;
  isEditable?: boolean;
  isRulerActive?: boolean;
  showsScrollIndicators?: boolean;
  onDrawStart?: (event: NativeEvent<DrawStartEvent>) => void;
  onDrawEnd?: (event: NativeEvent<DrawEndEvent>) => void;
  onDrawChange?: (event: NativeEvent<DrawChangeEvent>) => void;
  onMarkupChanged?: (event: NativeEvent<{}>) => void;
  onCanUndoChanged?: (event: NativeEvent<CanUndoChangedEvent>) => void;
  onCanRedoChanged?: (event: NativeEvent<CanRedoChangedEvent>) => void;
}

// ─── Ref Methods ────────────────────────────────────────────────────────────
export interface PaperKitViewRef {
  // Tool Picker
  /** Show the native floating tool picker */
  setupToolPicker(): Promise<void>;
  /** Toggle tool picker visibility */
  toggleToolPicker(): Promise<void>;
  /** Hide the tool picker */
  hideToolPicker(): Promise<void>;

  // Undo / Redo / Clear
  undo(): Promise<void>;
  redo(): Promise<void>;
  /** Clear canvas (PencilKit-compatible name) */
  clearDrawing(): Promise<void>;
  /** Clear canvas (PaperKit alias) */
  clearMarkup(): Promise<void>;
  canUndo(): Promise<boolean>;
  canRedo(): Promise<boolean>;

  // Data Persistence (PencilKit-compatible names)
  /** Capture canvas as base64 PNG */
  captureDrawing(): Promise<string>;
  /** Get drawing data as base64 for save/restore */
  getCanvasDataAsBase64(): Promise<string>;
  /** Load drawing from base64 data */
  setCanvasDataFromBase64(data: string): Promise<boolean>;

  // Background Color
  /** Set background color (hex, e.g. "FF0000" or "#FF0000") */
  setCanvasBackgroundColor(color: string): Promise<void>;
  /** Get current background color as hex */
  getCanvasBackgroundColor(): Promise<string>;
  /** Open native iOS color picker to choose background color */
  showColorPicker(): Promise<void>;

  // View Background Color (area behind the canvas)
  /** Set the background color of the area behind the canvas */
  setViewBackgroundColor(color: string): Promise<void>;
  /** Get current view background color as hex */
  getViewBackgroundColor(): Promise<string>;

  // Canvas
  /** Set canvas aspect ratio (width/height), e.g. 0.707 for A4 portrait */
  setCanvasAspectRatio(ratio: number): Promise<void>;

  // Background Pattern (lines/grid/dots drawn on the paper surface)
  /** Set pattern type: 'none' | 'lines' | 'grid' | 'dots' */
  setBackgroundPattern(pattern: BackgroundPattern): Promise<void>;
  /** Set pattern line/dot color (hex) */
  setBackgroundLineColor(color: string): Promise<void>;
  /** Set spacing between lines/dots in points (default 32) */
  setBackgroundSpacing(spacing: number): Promise<void>;

  // PaperKit Add Menu
  /**
   * Open the native PaperKit add menu (shapes, text, stickers etc.)
   */
  showAddMenu(): Promise<void>;

  // Quick Add — shapes auto-switch to selection mode after insertion
  /** Add a shape and auto-switch to selection mode */
  insertShape(params: InsertShapeParams): Promise<void>;
  /** Add a textbox and auto-switch to selection mode */
  insertTextbox(params: InsertTextboxParams): Promise<void>;
  /** Add a line and auto-switch to selection mode */
  insertLine(params: InsertLineParams): Promise<void>;
  /** Add an image to the canvas and auto-switch to selection mode */
  insertImage(params: InsertImageParams): Promise<void>;

  // Touch Mode & Zoom
  /** Switch between 'drawing' and 'selection' modes */
  setTouchMode(mode: TouchMode): Promise<void>;
  /** Set zoom limits */
  setZoomRange(min: number, max: number): Promise<void>;
}
