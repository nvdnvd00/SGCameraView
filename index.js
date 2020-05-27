import React from "react";
import PropTypes from "prop-types";
import { requireNativeComponent } from "react-native";

class CameraView extends React.Component {
  onRecordingEnd = (e) => {
    const { data } = e.nativeEvent;
    this.props.onRecordingEnd(data);
  };
  render() {
    return (
      <SgCameraView {...this.props} onRecordingEnd={this.onRecordingEnd} />
    );
  }
}

CameraView.propTypes = {
  beat: PropTypes.string.isRequired,
  lyric: PropTypes.array,
  onRecordingEnd: PropTypes.func.isRequired,
};

var SgCameraView = requireNativeComponent("SgCameraView", CameraView);

module.exports = SgCameraView;
