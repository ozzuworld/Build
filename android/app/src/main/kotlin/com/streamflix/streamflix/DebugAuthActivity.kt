package com.streamflix.streamflix

import android.os.Bundle
import android.util.Log
import androidx.appcompat.app.AppCompatActivity
import net.openid.appauth.AuthorizationManagementActivity

class DebugAuthActivity : AuthorizationManagementActivity() {
    private val TAG = "StreamflixOAuth"

    override fun onCreate(savedInstanceState: Bundle?) {
        Log.d(TAG, "===== AUTHORIZATION REQUEST DEBUG =====")

        // Log the intent data
        intent?.let { intent ->
            Log.d(TAG, "Authorization Activity Started")
            Log.d(TAG, "Action: ${intent.action}")
            Log.d(TAG, "Data URI: ${intent.data}")
            Log.d(TAG, "Data String: ${intent.dataString}")

            // Log extras
            intent.extras?.let { extras ->
                for (key in extras.keySet()) {
                    Log.d(TAG, "Extra '$key': ${extras.get(key)}")
                }
            }
        }

        Log.d(TAG, "===== END AUTHORIZATION REQUEST DEBUG =====")

        super.onCreate(savedInstanceState)
    }
}
