package com.reactlibrary;

import android.graphics.Color;
import android.view.View;

import androidx.appcompat.widget.AppCompatCheckBox;

import com.facebook.react.uimanager.annotations.ReactProp;

import com.facebook.react.uimanager.SimpleViewManager;
import com.facebook.react.uimanager.ThemedReactContext;

public class SgCameraViewManager extends SimpleViewManager<View> {

    public static final String REACT_CLASS = "SgCameraView";
    private ThemedReactContext mContext;
    private View view;

    @Override
    public String getName() {
        return REACT_CLASS;
    }

    @Override
    public View createViewInstance(ThemedReactContext c) {
        // TODO: Implement some actually useful functionality
//        AppCompatCheckBox cb = new AppCompatCheckBox(c);
//        cb.setChecked(true);
//        return cb;
        mContext = c;
        view = new View(c);
        return new View(c);
    }

    @ReactProp(name = "beat")
    public void setBeat(View view,String prop){
//        view.setBackgroundColor(Color.BLUE);
    }
}
