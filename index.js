import React from "react";
import PropTypes from "prop-types";
import { requireNativeComponent } from "react-native";

class CameraView extends React.Component {
  onRecordingEnd = (e) => {
    const { data } = e.nativeEvent;
    console.log({ data });
    this.props.onRecordingEnd(data);
  };
  render() {
    return (
      <View style={{ width, height }}>
        <SgCameraView {...this.props} onRecordingEnd={this.onRecordingEnd} />
      </View>
    );
  }
}

CameraView.propTypes = {
  width: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
  height: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
  beat: PropTypes.string.isRequired,
  lyric: PropTypes.array,
  onRecordingEnd: PropTypes.func.isRequired,
};

var SgCameraView = requireNativeComponent("SgCameraView", CameraView);

module.exports = SgCameraView;
