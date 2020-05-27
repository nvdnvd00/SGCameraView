import React from "react";
import PropTypes from "prop-types";
import { requireNativeComponent } from "react-native";

class CameraView extends React.Component {
  render() {
    return <SgCameraView {...this.props} />;
  }
}

CameraView.propTypes = {
  beat: PropTypes.string.isRequired,
  lyric: PropTypes.array,
  onRecordingEnd: PropTypes.func.isRequired,
};

var SgCameraView = requireNativeComponent("SgCameraView", CameraView);

module.exports = SgCameraView;
