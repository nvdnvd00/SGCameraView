import { requireNativeComponent, NativeModules } from "react-native";

const SgCameraView = requireNativeComponent("SgCameraView", null);
const SgCameraManager = NativeModules.SgCameraManager;

export { SgCameraManager };
export default SgCameraView;
