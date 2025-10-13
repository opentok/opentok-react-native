/**
 * Type declarations for React Native CodegenTypes
 * This is needed because React Native 0.81 doesn't properly export these types
 */
declare module "react-native/Libraries/Types/CodegenTypes" {
  export type Int32 = number;
  export type Double = number;
  export type Float = number;

  export interface EventEmitter<T = any> {
    addListener(eventName: string, callback: (event: T) => void): void;
    removeListeners(count: number): void;
  }

  export type BubblingEventHandler<T = any> = (event: T) => void;
}
