# react-native-sg-camera-view

## Getting started

`$ npm install react-native-sg-camera-view@git+https://git@github.com/nvdnvd00/SGCameraView.git`
or
`$ yarn add https://git@github.com/nvdnvd00/SGCameraView.git`

## Link

`$ pod install`

## Usage

```javascript
import SgCameraView from 'react-native-sg-camera-view';


const beat = <local_path>;
const lyric = <array_of_obj>;

const Screen = () => {
  const onRecordingEnd = (uri) => {
    // ...
  }
  return (
    <SgCameraView
      beat={beat}
      lyric={lyric}
      onRecordingEnd={onRecordingEnd}
   />;
  )
}
```
