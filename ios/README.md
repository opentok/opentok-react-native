# opentok-react-native iOS

<img src="https://assets.tokbox.com/img/vonage/Vonage_VideoAPI_black.svg" height="48px" alt="Tokbox is now known as Vonage" />

iOS implementation for the OpenTok React Native library.

## Table of Contents

- [React Native New Architecture vs Old Architecture](#react-native-new-architecture-vs-old-architecture)
  - [Architecture Components Overview](#architecture-components-overview)
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

## React Native New Architecture vs Old Architecture

The new architecture provides significant improvements in performance, type safety, and developer experience. Here's how:

### **Architecture Components Overview**

React Native's new architecture splits into two distinct systems:

- **Fabric**: Handles UI components (views, buttons, custom video components) and their rendering, props, and UI events (onPress, onLayout, onStreamCreated)
- **TurboModules**: Handles non-UI native modules (business logic, native APIs, device features) and their methods and events (session management, camera access, network calls)

This separation allows each system to be optimized for its specific purpose - Fabric for fast UI operations and TurboModules for efficient native API calls.

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

