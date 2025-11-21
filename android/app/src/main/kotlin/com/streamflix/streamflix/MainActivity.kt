package com.streamflix.streamflix

import android.content.Intent
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    private val TAG = "StreamflixOAuth"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "MainActivity onCreate")
        logIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        Log.d(TAG, "MainActivity onNewIntent")
        logIntent(intent)
    }

    private fun logIntent(intent: Intent?) {
        if (intent == null) {
            Log.d(TAG, "Intent is null")
            return
        }

        Log.d(TAG, "===== INTENT DEBUG =====")
        Log.d(TAG, "Action: ${intent.action}")
        Log.d(TAG, "Data: ${intent.data}")
        Log.d(TAG, "Data String: ${intent.dataString}")
        Log.d(TAG, "Scheme: ${intent.data?.scheme}")
        Log.d(TAG, "Host: ${intent.data?.host}")
        Log.d(TAG, "Path: ${intent.data?.path}")
        Log.d(TAG, "Query: ${intent.data?.query}")
        Log.d(TAG, "Fragment: ${intent.data?.fragment}")

        // Log all query parameters
        intent.data?.queryParameterNames?.forEach { paramName ->
            Log.d(TAG, "Query param '$paramName': ${intent.data?.getQueryParameter(paramName)}")
        }

        Log.d(TAG, "===== END INTENT DEBUG =====")
    }
}
