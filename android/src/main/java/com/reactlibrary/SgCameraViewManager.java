package com.reactlibrary;

import android.graphics.Color;
import android.util.Log;
import android.view.View;
import android.view.ViewGroup;

import java.lang.String;

import androidx.appcompat.widget.AppCompatCheckBox;

import com.facebook.drawee.backends.pipeline.Fresco;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.uimanager.annotations.ReactProp;

import com.facebook.react.uimanager.SimpleViewManager;
import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.views.image.ReactImageManager;
import com.facebook.react.views.image.ReactImageView;

public class SgCameraViewManager extends SimpleViewManager<ReactImageView> {

    public static final String REACT_CLASS = "SgCameraView";
    ReactApplicationContext mCallerContext;

    public SgCameraViewManager(ReactApplicationContext reactContext) {
        mCallerContext = reactContext;
    }

    @Override
    public String getName() {
        return REACT_CLASS;
    }

    @Override
    public ReactImageView createViewInstance(ThemedReactContext context) {
//        AppCompatCheckBox cb = new AppCompatCheckBox(context);
//        cb.setChecked(true);
//        return cb;
        return new ReactImageView(context, Fresco.newDraweeControllerBuilder(), null, mCallerContext);
    }

    //    @ReactProp(name = "beat")
//    public void setBeat(View view,String prop){
////        view.setBackgroundColor(Color.BLUE);
//    }
    @ReactProp(name = "beatDetail")
    public void setBeatDetail(ReactImageView view, ReadableArray beatDetail) {
        Log.d("beatDetail", String.valueOf(beatDetail));
    }
}
