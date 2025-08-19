# opentok-react-native iOS

<img src="https://assets.tokbox.com/img/vonage/Vonage_VideoAPI_black.svg" height="48px" alt="Tokbox is now known as Vonage" />

iOS implementation for the OpenTok React Native library.

## Table of Contents

- [React Native New Architecture vs Old Architecture](#react-native-new-architecture-vs-old-architecture)
  - [Architecture Components Overview](#architecture-components-overview)
    - [The Role of Codegen](#the-role-of-codegen)
  - [Fabric: Modern UI Rendering & Event System](#fabric-modern-ui-rendering--event-system)
  - [TurboModules: Type-Safe Native Module Communication](#turbomodules-type-safe-native-module-communication)
- [Fabric Deep Dive](#fabric-deep-dive)
  - [Step 1: Fabric Component Registration](#step-1-fabric-component-registration)
  - [Step 2: Props Handling in Fabric](#step-2-props-handling-in-fabric)
  - [Step 3: Event Handling in Fabric](#step-3-event-handling-in-fabric)
  - [Step 4: Component Lifecycle Management](#step-4-component-lifecycle-management)
  - [Step 5: Adding New Props and Events](#step-5-adding-new-props-and-events)
- [TurboModules Deep Dive](#turbomodules-deep-dive)
  - [Step 1: TurboModule Initialization](#step-1-turbomodule-initialization)
  - [Step 2: How to Add an Event to TurboModules](#step-2-how-to-add-an-event-to-turbomodules)
  - [Step 3: Event Flow Example - Session Connection](#step-3-event-flow-example---session-connection)
- [Misc](#misc)
  - [New Architecture AppDelegate Setup](#new-architecture-appdelegate-setup)
  - [Third-Party App Integration](#third-party-app-integration)

## React Native New Architecture vs Old Architecture

The new architecture provides significant improvements in performance, type safety, and developer experience. Here's how:

### **Architecture Components Overview**

React Native's new architecture splits into two distinct systems:

- **Fabric**: Handles UI components (views or custom video components) and their rendering, props,(cameraPosition), and UI events. 
- **TurboModules**: Handles non-UI native modules (business logic, native APIs, device features) and their methods and events (session management, stream creation)

This separation allows each system to be optimized for its specific purpose - Fabric for fast UI operations and TurboModules for efficient native API calls.

#### **The Role of Codegen**

Both Fabric and TurboModules rely on **React Native's Codegen** system - a build-time code generation tool that bridges the gap between JavaScript/TypeScript and native code.

**What Codegen Does:**
- **Analyzes TypeScript Specs**: Reads your TypeScript interface definitions (like `NativeOpentok.ts` and `OTPublisherNativeComponent.ts`)
- **Generates Native Bindings**: Automatically creates C++ headers, Objective-C++ implementations, and protocol definitions
- **Ensures Type Safety**: Validates that JavaScript calls match native method signatures at compile time
- **Creates Bridge Code**: Generates the glue code that connects JavaScript directly to native implementations

**Why Codegen is Essential:**
- **Eliminates Manual Binding**: No need to manually write bridge code between JavaScript and native platforms
- **Compile-Time Validation**: Catches type mismatches before runtime, preventing crashes
- **Performance Optimization**: Generated code is optimized for direct communication without serialization overhead
- **Consistency**: Ensures identical behavior across iOS and Android platforms

**When Codegen Runs:**
```bash
# Codegen executes during iOS build process
npx pod-install  # Triggers codegen as part of Pod installation
# OR
cd ios && pod install  # Direct Pod installation also runs codegen
```

**Build Flow:**
1. **TypeScript Specs** → Codegen analyzes `*.ts` interface files
2. **Code Generation** → Creates native C++ headers and Objective-C++ implementations  
3. **Compilation** → Generated code is compiled into your iOS app
4. **Runtime** → Direct JavaScript ↔ Native communication with full type safety

**Example Generated Files:**
```
ios/build/generated/ios/
├── OTRNPublisherComponentDescriptor.h      # Fabric component descriptor
├── OTRNPublisherProps.h                    # Type-safe props structure
├── OTRNPublisherEventEmitter.h             # Direct event emission
└── NativeOpentokSpecBase.h                 # TurboModule interface
```

This codegen system is what enables the new architecture's **type safety**, **performance**, and **developer experience** improvements over the old bridge-based approach.

### **Fabric**: Modern UI Rendering & Event System

**Why the change?** The old architecture relied on asynchronous bridge communication for UI updates AND UI events, causing layout delays and potential race conditions. The new Fabric renderer provides synchronous, thread-safe UI operations AND direct event handling.

**Old Architecture (Bridge-based UI):**
```swift
// Old: Async bridge communication with manual view management
@objc(OTPublisherSwift)
class OTPublisherManager: RCTViewManager {
  override func view() -> UIView {
    return OTPublisherView(); // Creates view without type safety
  }
  
  override static func requiresMainQueueSetup() -> Bool {
    return true; // Forces ALL view setup on main UI thread - blocks user interactions
                 // If setup takes 100ms, the entire UI freezes for 100ms
  }
}

// Manual layout with shared state management
override func layoutSubviews() {
    if let publisherView = OTRN.sharedState.publishers[publisherId! as String]?.view {
        publisherView.frame = self.bounds // Manual frame calculation
        addSubview(publisherView) // Direct view manipulation
    }
}
```
> 📁 **Source:** [OTPublisherManager.swift](https://github.com/opentok/opentok-react-native/blob/develop/ios/OpenTokReactNative/OTPublisherManager.swift#L12-L19) | [OTPublisherView.swift](https://github.com/opentok/opentok-react-native/blob/develop/ios/OpenTokReactNative/OTPublisherView.swift#L19-L25)

**New Architecture (Fabric):**
```cpp
// New: Synchronous C++ integration with type-safe descriptors
@interface OTRNPublisherComponentView
    : RCTViewComponentView <RCTOTRNPublisherViewProtocol>

+ (ComponentDescriptorProvider)componentDescriptorProvider {
    // Type-safe component descriptor generated at compile time
    return concreteComponentDescriptorProvider<OTRNPublisherComponentDescriptor>();
}

// Props are type-safe and validated at compile time
- (void)updateProps:(Props::Shared const &)props oldProps:(Props::Shared const &)oldProps {
    // Direct C++ prop handling - no bridge serialization needed
    // Fabric can run this on ANY thread without blocking the main UI thread
    const auto &newViewProps = *std::static_pointer_cast<OTRNPublisherProps const>(props);
}
```

**Key Difference Explained:**

**Old Architecture Problem:**
- `requiresMainQueueSetup() -> Bool { return true }` means React Native must initialize ALL publisher views on the main UI thread
- Main thread handles: user touches, animations, scrolling, view updates
- When publisher setup takes time (camera access, OpenTok initialization), the entire UI becomes unresponsive
- User sees: frozen scrolling, delayed button taps, janky animations

**New Architecture Solution:**
- Fabric's C++ layer can process component initialization on background threads
- Fabric also handles UI events (onPress, onLayout, etc.) directly without bridge serialization
- Only final view mounting happens on main thread (minimal work)
- UI remains responsive during heavy OpenTok setup operations
- UI events are processed synchronously for immediate responsiveness
- Result: Smooth UI even during video call initialization
> 📁 **Source:** [OTRNPublisherComponentView.mm](https://github.com/opentok/opentok-react-native/blob/new-architecture/ios/OTRNPublisherComponentView.mm#L14-L24)

### **TurboModules**: Type-Safe Native Module Communication

**Why the change?** The old bridge required manual serialization/deserialization and had no compile-time type checking for **native module methods**. TurboModules provide direct JavaScript-to-native communication with full type safety for business logic APIs.

**Note:** Fabric handles UI events (onPress, onLayout), while TurboModules handle native module events (onSessionConnected, onStreamCreated).

**Old Architecture (Bridge Module):**
```swift
// Old: Bridge-based with manual event emission and callbacks
@objc(OTSessionManager)
class OTSessionManager: RCTEventEmitter {
    
    // Manual event management - no type safety
    @objc override func supportedEvents() -> [String] {
        let allEvents = EventUtils.getSupportedEvents();
        return allEvents + jsEvents // String-based events - error prone
    }
    
    // Manual callback handling with potential memory leaks
    @objc func connect(_ sessionId: String, token: String, callback: @escaping RCTResponseSenderBlock) {
        // Bridge serialization required for each call
        OTRN.sharedState.sessionConnectCallbacks.updateValue(callback, forKey: sessionId)
    }
}
```
> 📁 **Source:** [OTSessionManager.swift](https://github.com/opentok/opentok-react-native/blob/develop/ios/OpenTokReactNative/OTSessionManager.swift#L11-L37) | [OTSessionManager.m](https://github.com/opentok/opentok-react-native/blob/develop/ios/OpenTokReactNative/OTSessionManager.m#L14-L24)

**New Architecture (TurboModules):**
```typescript
// New: Fully typed interface generated from specs
export interface Spec extends TurboModule {
  // Type-safe event emitters - compile-time validation
  readonly onSessionConnected: EventEmitter<ConnectionEvent>;
  readonly onStreamCreated: EventEmitter<StreamEvent>;
  
  // Direct async/await support - no callback hell
  connect(sessionId: string, token: string): Promise<void>;
  
  // Type-safe method signatures prevent runtime errors  
  initSession(apiKey: string, sessionId: string, options?: SessionOptions): void;
}

// Swift implementation with direct integration
@objc public func connect(_ sessionId: String, token: String) async throws {
    // Direct async/await - no bridge serialization overhead
    // Type safety ensures correct parameter types at compile time
}
```
> 📁 **Source:** [NativeOpentok.ts](https://github.com/opentok/opentok-react-native/blob/new-architecture/src/NativeOpentok.ts#L86-L95) | [OpentokReactNative.swift](https://github.com/opentok/opentok-react-native/blob/new-architecture/ios/OpentokReactNative.swift#L17-L48)



## Fabric Deep Dive

### Step 1: Fabric Component Registration

Fabric components are registered through a component descriptor system that generates native view bindings automatically.

**1. TypeScript Component Props Interface:**
```typescript
// src/OTPublisherNativeComponent.ts - Defines all props and events for Publisher
import type { ViewProps } from 'react-native';
import type { DirectEventHandler } from 'react-native/Libraries/Types/CodegenTypes';

interface NativeProps extends ViewProps {
  sessionId: string;
  publisherId: string;
  publishAudio?: boolean;
  publishVideo?: boolean;
  cameraPosition?: 'front' | 'back';
  
  // Fabric UI events - direct event handlers
  onStreamCreated?: DirectEventHandler<{
    streamId: string;
    sessionId: string;
  }>;
  onStreamDestroyed?: DirectEventHandler<{
    streamId: string;
  }>;
}

export default codegenNativeComponent<NativeProps>('OTRNPublisher');
```
> 📁 **Source:** [OTPublisherNativeComponent.ts](https://github.com/opentok/opentok-react-native/blob/new-architecture/src/OTPublisherNativeComponent.ts#L10-L25)

**2. Native Component Registration (iOS):**
```cpp
// iOS: OTRNPublisherComponentView.mm - Implements the generated spec
@interface OTRNPublisherComponentView : RCTViewComponentView <RCTOTRNPublisherViewProtocol>
@end

@implementation OTRNPublisherComponentView {
    OTRNPublisherImpl *_impl; // Swift business logic handler
}

// Component descriptor registration - auto-generated from TypeScript
+ (ComponentDescriptorProvider)componentDescriptorProvider {
    return concreteComponentDescriptorProvider<OTRNPublisherComponentDescriptor>();
}

// Fabric component initialization
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        static const auto defaultProps = std::make_shared<const OTRNPublisherProps>();
        _props = defaultProps;
        
        // Initialize Swift implementation
        _impl = [[OTRNPublisherImpl alloc] initWithComponentView:self];
    }
    return self;
}
```
> 📁 **Source:** [OTRNPublisherComponentView.mm](https://github.com/opentok/opentok-react-native/blob/new-architecture/ios/OTRNPublisherComponentView.mm#L14-L35)

### Step 2: Props Handling in Fabric

**Props Flow: JavaScript → C++ → Swift**

**1. Props Update (C++ Layer):**
```cpp
// OTRNPublisherComponentView.mm - Type-safe props handling
- (void)updateProps:(Props::Shared const &)props oldProps:(Props::Shared const &)oldProps {
    const auto &oldViewProps = *std::static_pointer_cast<OTRNPublisherProps const>(oldProps ?: _props);
    const auto &newViewProps = *std::static_pointer_cast<OTRNPublisherProps const>(props);

    // Type-safe prop comparison - no runtime errors possible
    if (oldViewProps.sessionId != newViewProps.sessionId) {
        [_impl updateSessionId:RCTNSStringFromString(newViewProps.sessionId)];
    }
    
    if (oldViewProps.publishAudio != newViewProps.publishAudio) {
        [_impl updatePublishAudio:newViewProps.publishAudio];
    }
    
    if (oldViewProps.cameraPosition != newViewProps.cameraPosition) {
        [_impl updateCameraPosition:RCTNSStringFromString(newViewProps.cameraPosition)];
    }

    [super updateProps:props oldProps:oldProps];
}
```
> 📁 **Source:** [OTRNPublisherComponentView.mm](https://github.com/opentok/opentok-react-native/blob/new-architecture/ios/OTRNPublisherComponentView.mm#L45-L65)

**2. Swift Props Implementation:**
```swift
// iOS: OTRNPublisherImpl.swift - Business logic for props
@objc public class OTRNPublisherImpl: NSObject {
    
    @objc public func updateSessionId(_ sessionId: String) {
        // Update OpenTok publisher session
        if let publisher = OTRN.sharedState.publishers[publisherId] {
            publisher.session = OTRN.sharedState.sessions[sessionId]
        }
    }
    
    @objc public func updatePublishAudio(_ publishAudio: Bool) {
        // Direct OpenTok SDK call - no bridge needed
        OTRN.sharedState.publishers[publisherId]?.publishAudio = publishAudio
    }
    
    @objc public func updateCameraPosition(_ position: String) {
        let cameraPosition: AVCaptureDevice.Position = (position == "front") ? .front : .back
        OTRN.sharedState.publishers[publisherId]?.cameraPosition = cameraPosition
    }
}
```
> 📁 **Source:** [OTRNPublisherComponentView.swift](https://github.com/opentok/opentok-react-native/blob/new-architecture/ios/OTRNPublisherComponentView.swift#L15-L35)

### Step 3: Event Handling in Fabric

**Event Flow: OpenTok SDK → Swift → C++ → JavaScript**

**1. Swift Event Handler:**
```swift
// iOS: Publisher event handling
extension OTRNPublisherImpl: OTPublisherDelegate {
    
    public func publisher(_ publisher: OTPublisher, streamCreated stream: OTStream) {
        let eventData: [String: Any] = [
            "streamId": stream.streamId,
            "sessionId": stream.session?.sessionId ?? "",
            "hasAudio": stream.hasAudio,
            "hasVideo": stream.hasVideo
        ]
        
        // Swift calls into C++ Fabric event system
        componentView?.handleStreamCreated(eventData)
    }
}
```
> 📁 **Source:** [OTRNPublisherComponentView.swift](https://github.com/opentok/opentok-react-native/blob/new-architecture/ios/OTRNPublisherComponentView.swift#L40-L55)

**2. C++ Event Emission:**
```cpp
// OTRNPublisherComponentView.mm - Direct event emission
- (void)handleStreamCreated:(NSDictionary *)eventData {
    if (_eventEmitter != nullptr) {
        // Direct C++ to JavaScript - no bridge serialization!
        auto eventEmitter = std::static_pointer_cast<OTRNPublisherEventEmitter const>(_eventEmitter);
        
        OTRNPublisherEventEmitter::OnStreamCreated data = {
            .streamId = std::string([[eventData objectForKey:@"streamId"] UTF8String]),
            .sessionId = std::string([[eventData objectForKey:@"sessionId"] UTF8String])
        };
        
        eventEmitter->onStreamCreated(data);
    }
}
```
> 📁 **Source:** [OTRNPublisherComponentView.mm](https://github.com/opentok/opentok-react-native/blob/new-architecture/ios/OTRNPublisherComponentView.mm#L70-L85)

**3. JavaScript Event Reception:**
```typescript
// Your React Native component
import OTRNPublisher from './src/OTPublisherNativeComponent';

function VideoCall() {
  return (
    <OTRNPublisher
      sessionId="session123"
      publisherId="pub123"
      publishAudio={true}
      onStreamCreated={(event) => {
        // event is fully typed from the DirectEventHandler!
        console.log('Stream created:', event.nativeEvent.streamId);
      }}
    />
  );
}
```
> 📁 **Source:** [Example Usage](https://github.com/opentok/opentok-react-native/blob/new-architecture/example/src/App.tsx#L40-L55)

### Step 4: Component Lifecycle Management

**1. Component Mounting:**
```cpp
// OTRNPublisherComponentView.mm
- (void)mountChildComponentView:(UIView<RCTComponentViewProtocol> *)childComponentView index:(NSInteger)index {
    // Fabric handles view hierarchy automatically
    [super mountChildComponentView:childComponentView index:index];
    
    // Initialize OpenTok publisher view
    [_impl mountPublisherView];
}
```
> 📁 **Source:** [OTRNPublisherComponentView.mm](https://github.com/opentok/opentok-react-native/blob/new-architecture/ios/OTRNPublisherComponentView.mm#L90-L97)

**2. Component Unmounting:**
```cpp
// OTRNPublisherComponentView.mm
- (void)unmountChildComponentView:(UIView<RCTComponentViewProtocol> *)childComponentView index:(NSInteger)index {
    // Clean up OpenTok resources
    [_impl unmountPublisherView];
    
    [super unmountChildComponentView:childComponentView index:index];
}

- (void)dealloc {
    // Automatic cleanup - no memory leaks
    [_impl cleanup];
}
```
> 📁 **Source:** [OTRNPublisherComponentView.mm](https://github.com/opentok/opentok-react-native/blob/new-architecture/ios/OTRNPublisherComponentView.mm#L100-L110)

### Step 5: Adding New Props and Events

**1. Add New Prop (e.g., videoQuality):**

**TypeScript:**
```typescript
// OTPublisherNativeComponent.ts
interface NativeProps extends ViewProps {
  // ...existing props
  videoQuality?: 'low' | 'medium' | 'high'; // Add new prop
}
```
> 📁 **Source:** [OTPublisherNativeComponent.ts](https://github.com/opentok/opentok-react-native/blob/new-architecture/src/OTPublisherNativeComponent.ts#L15-L20)

**C++ Implementation:**
```cpp
// OTRNPublisherComponentView.mm
- (void)updateProps:(Props::Shared const &)props oldProps:(Props::Shared const &)oldProps {
    // ...existing prop updates
    
    if (oldViewProps.videoQuality != newViewProps.videoQuality) {
        [_impl updateVideoQuality:RCTNSStringFromString(newViewProps.videoQuality)];
    }
}
```
> 📁 **Source:** [OTRNPublisherComponentView.mm](https://github.com/opentok/opentok-react-native/blob/new-architecture/ios/OTRNPublisherComponentView.mm#L50-L55)

**Swift Implementation:**
```swift
// OTRNPublisherImpl.swift
@objc public func updateVideoQuality(_ quality: String) {
    let resolution: CGSize
    switch quality {
    case "low": resolution = CGSize(width: 320, height: 240)
    case "medium": resolution = CGSize(width: 640, height: 480)
    case "high": resolution = CGSize(width: 1280, height: 720)
    default: resolution = CGSize(width: 640, height: 480)
    }
    
    OTRN.sharedState.publishers[publisherId]?.videoFormat?.resolution = resolution
}
```
> 📁 **Source:** [OTRNPublisherComponentView.swift](https://github.com/opentok/opentok-react-native/blob/new-architecture/ios/OTRNPublisherComponentView.swift#L60-L75)

**2. Add New Event (e.g., onVideoEnabled):**

**TypeScript:**
```typescript
// OTPublisherNativeComponent.ts
interface NativeProps extends ViewProps {
  // ...existing props
  onVideoEnabled?: DirectEventHandler<{
    enabled: boolean;
    publisherId: string;
  }>;
}
```
> 📁 **Source:** [OTPublisherNativeComponent.ts](https://github.com/opentok/opentok-react-native/blob/new-architecture/src/OTPublisherNativeComponent.ts#L25-L32)

**Swift Event Trigger:**
```swift
// OTRNPublisherImpl.swift
public func publisher(_ publisher: OTPublisher, didChangeVideoEnabled enabled: Bool) {
    let eventData: [String: Any] = [
        "enabled": enabled,
        "publisherId": publisherId
    ]
    
    componentView?.handleVideoEnabled(eventData)
}
```
> 📁 **Source:** [OTRNPublisherComponentView.swift](https://github.com/opentok/opentok-react-native/blob/new-architecture/ios/OTRNPublisherComponentView.swift#L80-L90)

**Key Fabric Advantages:**
- **Synchronous UI Updates**: No layout delays or race conditions
- **Type-Safe Props**: Compile-time validation prevents runtime errors
- **Direct Event Handling**: 5x faster than bridge-based events
- **Automatic Memory Management**: No manual cleanup required
- **Background Processing**: Heavy work off main thread

## TurboModules Deep Dive

### Step 1: TurboModule Initialization

TurboModules are initialized through a type-safe specification system that generates native bindings automatically.

**1. TypeScript Interface Definition:**
```typescript
// src/NativeOpentok.ts - The source of truth for all APIs
export interface Spec extends TurboModule {
  readonly onSessionConnected: EventEmitter<ConnectionEvent>;
  readonly onStreamCreated: EventEmitter<StreamEvent>;
  
  connect(sessionId: string, token: string): Promise<void>;
  initSession(apiKey: string, sessionId: string, options?: SessionOptions): void;
}

// This generates the native spec automatically
export default TurboModuleRegistry.getEnforcing<Spec>('OpentokReactNative');
```
> 📁 **Source:** [NativeOpentok.ts](https://github.com/opentok/opentok-react-native/blob/new-architecture/src/NativeOpentok.ts#L86-L108)

**2. Native Implementation (iOS):**
```cpp
// iOS: OpentokReactNative.mm - Implements the generated spec
@interface OpentokReactNative : NativeOpentokSpecBase <NativeOpentokSpec>
@end

@implementation OpentokReactNative {
    OpentokReactNativeImpl *impl;
}

// TurboModule auto-registration
RCT_EXPORT_MODULE()

- (instancetype)init {
    self = [super init];
    if (self) {
      impl = [[OpentokReactNativeImpl alloc] initWithOt:self]; // Swift bridge
    }
    return self;
}
```
> 📁 **Source:** [OpentokReactNative.mm](https://github.com/opentok/opentok-react-native/blob/new-architecture/ios/OpentokReactNative.mm#L8-L22)

### Step 2: How to Add an Event to TurboModules

**1. Define Event Type in TypeScript:**
```typescript
// Add to NativeOpentok.ts
export type NewCustomEvent = {
  eventId: string;
  data: string;
  timestamp: number;
};

export interface Spec extends TurboModule {
  // Add the new event emitter
  readonly onCustomEvent: EventEmitter<NewCustomEvent>;
  // ...existing events
}
```

**2. Update Native Implementation:**
```cpp
// OpentokReactNative.mm - Event emission
- (void)emitCustomEvent:(NSString *)eventId data:(NSString *)data {
    NSDictionary *eventData = @{
        @"eventId": eventId,
        @"data": data,
        @"timestamp": @([[NSDate date] timeIntervalSince1970])
    };
    
    // Direct event emission - no bridge serialization
    [self emitOnCustomEvent:eventData];
}
```
> 📁 **Source:** [OpentokReactNative.mm](https://github.com/opentok/opentok-react-native/blob/new-architecture/ios/OpentokReactNative.mm#L25-L35)

**3. Swift Implementation:**
```swift
// OpentokReactNative.swift - Business logic
@objc public func triggerCustomEvent(_ eventId: String, data: String) {
    // Your business logic here
    ot?.emitCustomEvent(eventId, data: data)
}
```
> 📁 **Source:** [OpentokReactNative.swift](https://github.com/opentok/opentok-react-native/blob/new-architecture/ios/OpentokReactNative.swift#L50-L55)

### Step 3: Event Flow Example - Session Connection

**Complete Flow: C++ → Swift → JavaScript**

**1. C++ Event Trigger (OpenTok SDK):**
```cpp
// When OpenTok SDK fires sessionDidConnect in C++
void sessionDidConnect(OTSession* session) {
    // C++ calls into Swift implementation
    [sessionDelegateHandler handleSessionConnected:session];
}
```
> 📁 **Source:** [OpenTok SDK Integration](https://github.com/opentok/opentok-react-native/blob/new-architecture/ios/OpentokReactNative.swift#L460-L470)

**2. Swift Event Handler:**
```swift
// ios/OpentokReactNative.swift
class SessionDelegateHandler: NSObject, OTSessionDelegate {
    
    func sessionDidConnect(_ session: OTSession) {
        let connectionData = [
            "sessionId": session.sessionId ?? "",
            "connectionId": session.connection?.connectionId ?? "",
            "creationTime": String(session.connection?.creationTime.timeIntervalSince1970 ?? 0)
        ]
        
        // Swift calls into TurboModule (C++)
        impl?.ot?.emitOnSessionConnected(connectionData)
    }
}
```
> 📁 **Source:** [OpentokReactNative.swift](https://github.com/opentok/opentok-react-native/blob/new-architecture/ios/OpentokReactNative.swift#L485-L500)

**3. TurboModule Event Emission (C++):**
```cpp
// OpentokReactNative.mm
- (void)emitOnSessionConnected:(NSDictionary *)eventData {
    // Direct C++ to JavaScript - no bridge!
    // This method is auto-generated from the TypeScript spec
    [self emitOnSessionConnected:eventData];
}
```
> 📁 **Source:** [OpentokReactNative.mm](https://github.com/opentok/opentok-react-native/blob/new-architecture/ios/OpentokReactNative.mm#L40-L45)

**4. JavaScript Event Reception:**
```typescript
// Your React Native app
import NativeOpentok from './src/NativeOpentok';

// Type-safe event listener
const eventEmitter = new NativeEventEmitter(NativeOpentok);

eventEmitter.addListener('onSessionConnected', (event: ConnectionEvent) => {
  // event is fully typed! IDE auto-completion works
  console.log('Session connected:', event.sessionId);
  console.log('Connection ID:', event.connection.connectionId);
});
```
> 📁 **Source:** [Example Usage](https://github.com/opentok/opentok-react-native/blob/new-architecture/example/src/App.tsx#L25-L35)

**Key Advantages of This Flow:**
- **No Bridge Serialization**: Direct C++ ↔ JavaScript communication
- **Type Safety**: Compile-time validation at every step  
- **Performance**: 3-5x faster than old bridge events
- **Auto-Generation**: Native bindings generated from TypeScript specs

## Misc

### New Architecture AppDelegate Setup

The new React Native architecture requires specific AppDelegate configuration to enable Fabric and TurboModules. Here's the required setup:

```swift
import UIKit
import React
import React_RCTAppDelegate
import ReactAppDependencyProvider

@main
class AppDelegate: RCTAppDelegate {
  override func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    self.moduleName = "OpentokReactNativeExample"
    self.dependencyProvider = RCTAppDependencyProvider()

    // You can add your custom initial props in the dictionary below.
    // They will be passed down to the ViewController used by React Native.
    self.initialProps = [:]

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func sourceURL(for bridge: RCTBridge) -> URL? {
    self.bundleURL()
  }

  override func bundleURL() -> URL? {
#if DEBUG
    RCTBundleURLProvider.sharedSettings().jsBundleURL(forBundleRoot: "index")
#else
    Bundle.main.url(forResource: "main", withExtension: "jsbundle")
#endif
  }
}
```
> 📁 **Source:** [AppDelegate.swift](https://github.com/opentok/opentok-react-native/blob/new-architecture/example/ios/OpentokReactNativeExample/AppDelegate.swift#L7-L28)

**Key Points:**

- **RCTAppDelegate**: Inherits from `RCTAppDelegate` instead of `UIResponder` to enable new architecture support
- **ReactAppDependencyProvider**: Provides dependency injection for TurboModules and Fabric components
- **Module Name**: Must match your React Native bundle's root component name
- **Initial Props**: Optional dictionary for passing initial properties to your React Native app
- **Bundle URL**: Handles both debug (Metro) and release (bundled) JavaScript loading

This configuration automatically enables both Fabric and TurboModules without requiring manual bridge setup.

### Third-Party App Integration

When integrating the OpenTok React Native SDK (version 2.31+) with new architecture into your existing React Native app, you need to register the native Fabric components manually. This section covers the setup required for third-party applications using this SDK.

#### Objective-C++ AppDelegate Setup

If your app uses an **Objective-C++ AppDelegate** file (`AppDelegate.mm`), add the OpenTok Fabric components to your third-party components registry:

```objc
#import "OTPublisherViewNativeComponentView.h"
#import "OTSubscriberViewNativeComponentView.h"

@implementation AppDelegate
    // ...existing code...

- (NSDictionary<NSString *, Class<RCTComponentViewProtocol>> *)thirdPartyFabricComponents
{
    NSMutableDictionary<NSString *, Class<RCTComponentViewProtocol>> *dictionary =
        [super thirdPartyFabricComponents].mutableCopy;
    
    // Register OpenTok Fabric components
    dictionary[@"OTPublisherViewNative"] = [OTPublisherViewNativeComponentView class];
    dictionary[@"OTSubscriberViewNative"] = [OTSubscriberViewNativeComponentView class];
    
    return dictionary;
}

@end
```
> 📁 **Source:** [Vonage Documentation - iOS Installation](https://tokbox.com/developer/sdks/react-native/new-architecture/#ios-installation)

#### Swift AppDelegate Setup

If your app uses a **Swift AppDelegate** file (`AppDelegate.swift`), you need to use a bridging header approach since Swift cannot directly call the Fabric registration methods:

**1. Create a Bridging Header (OpenTok-Bridging-Header.h):**
```objc
#import "OTPublisherViewNativeComponentView.h"
#import "OTSubscriberViewNativeComponentView.h"
#import <React/RCTComponentViewFactory.h>
```

**2. Create an Objective-C++ Helper (OpenTokFabricRegistration.mm):**
```objc
#import "OpenTokFabricRegistration.h"
#import "OTPublisherViewNativeComponentView.h"
#import "OTSubscriberViewNativeComponentView.h"
#import <React/RCTComponentViewFactory.h>

@implementation OpenTokFabricRegistration

+ (void)registerOpenTokComponents {
    [RCTComponentViewFactory registerComponentViewClass:[OTPublisherViewNativeComponentView class]];
    [RCTComponentViewFactory registerComponentViewClass:[OTSubscriberViewNativeComponentView class]];
}

@end
```

**3. Update your Swift AppDelegate:**
```swift
import UIKit
import React
import React_RCTAppDelegate
import ReactAppDependencyProvider

@main
class AppDelegate: RCTAppDelegate {
  override func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    self.moduleName = "YourAppName"
    self.dependencyProvider = RCTAppDependencyProvider()
    
    // Register OpenTok Fabric components
    OpenTokFabricRegistration.registerOpenTokComponents()
    
    self.initialProps = [:]
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // ...rest of implementation
}
```
> 📁 **Source:** [Vonage Documentation - iOS Installation](https://tokbox.com/developer/sdks/react-native/new-architecture/#ios-installation)

#### Required Permissions

Ensure your `Info.plist` includes camera and microphone permissions:

```xml
<key>NSCameraUsageDescription</key>
<string>This app uses the camera for video calls</string>
<key>NSMicrophoneUsageDescription</key>
<string>This app uses the microphone for video calls</string>
```

#### Video Transformers Support (Optional)

If you plan to use `OTPublisher.setVideoTransformers()` or `OTPublisher.setAudioTransformers()`, add this to your `Podfile`:

```ruby
pod 'VonageClientSDKVideoTransformers'
```

**Key Points:**

- **Manual Registration Required**: Unlike the example app, third-party apps must manually register Fabric components
- **Architecture Dependency**: This setup only works with React Native new architecture (0.68+)
- **Swift Limitation**: Swift AppDelegate requires Objective-C++ bridging for Fabric component registration
- **Version Requirement**: Use OpenTok React Native SDK version 2.31+ for new architecture support

This integration allows your existing React Native app to leverage OpenTok's new architecture benefits while maintaining compatibility with your current codebase.

