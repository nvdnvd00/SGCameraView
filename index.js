import PropTypes from "prop-types";
import React, { Component } from "react";
import { NativeModules, requireNativeComponent, View } from "react-native";

const SgCameraManager = NativeModules.SgCameraManager;

class SgCameraComponent extends Component {
  constructor(props) {
    super(props);
  }

  onRecordingEnd(event) {
    if (!this.props.onRecordingEnd) {
      return;
    }
    // this.props.onRecordingEnd(event.nativeEvent);
    this.props.onRecordingEnd(event);
  }

  render() {
    return (
      <SgCameraView {...this.props} onRecordingEnd={this.onRecordingEnd} />
    );
  }
}

SgCameraComponent.propTypes = {
  beat: PropTypes.string,
  onRecordingEnd: PropTypes.func,
  ...View.propTypes,
};

const SgCameraView = requireNativeComponent("SgCameraView", SgCameraComponent, {
  nativeOnly: {
    onRecordingEnd: true,
  },
});

export { SgCameraManager };
export default SgCameraComponent;
