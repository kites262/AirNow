package com.example.airnow

import com.example.airnow.BuildConfig
import android.Manifest
import android.annotation.SuppressLint
import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Bundle
import android.webkit.GeolocationPermissions
import android.webkit.WebChromeClient
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.FrameLayout
import androidx.activity.OnBackPressedCallback
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat

class MainActivity : AppCompatActivity() {

  companion object {
    private val WEB_URL = BuildConfig.WEB_URL
    private val WEB_URI: Uri = Uri.parse(WEB_URL)

    private val LOCATION_PERMISSIONS = arrayOf(
      Manifest.permission.ACCESS_COARSE_LOCATION,
      Manifest.permission.ACCESS_FINE_LOCATION,
    )
  }

  private lateinit var webView: WebView
  private var pendingGeolocationCallback: GeolocationPermissions.Callback? = null
  private var pendingGeolocationOrigin: String? = null
  private val locationPermissionLauncher =
    registerForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) {
      val granted = LOCATION_PERMISSIONS.all { permission ->
        it[permission] == true || ContextCompat.checkSelfPermission(
          this,
          permission,
        ) == PackageManager.PERMISSION_GRANTED
      }

      pendingGeolocationCallback?.let { callback ->
        callback.invoke(pendingGeolocationOrigin, granted, false)
        pendingGeolocationCallback = null
        pendingGeolocationOrigin = null
      }
    }

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)

    setupWebView()
    registerBackHandler()
    setContentView(webView)

    if (savedInstanceState == null) {
      loadUrl()
    } else {
      webView.restoreState(savedInstanceState)
    }
  }

  @SuppressLint("SetJavaScriptEnabled")
  private fun setupWebView() {
    webView = WebView(this).apply {
      layoutParams = FrameLayout.LayoutParams(
        FrameLayout.LayoutParams.MATCH_PARENT,
        FrameLayout.LayoutParams.MATCH_PARENT,
      )

      settings.apply {
        javaScriptEnabled = true
        domStorageEnabled = true
        setSupportZoom(false)
        displayZoomControls = false
        useWideViewPort = true
        loadWithOverviewMode = true
        cacheMode = android.webkit.WebSettings.LOAD_DEFAULT
      }

      webViewClient = AirNowWebViewClient()
      webChromeClient = AirNowWebChromeClient()
    }
  }

  private fun registerBackHandler() {
    onBackPressedDispatcher.addCallback(
      this,
      object : OnBackPressedCallback(true) {
        override fun handleOnBackPressed() {
          if (webView.canGoBack()) {
            webView.goBack()
          } else {
            isEnabled = false
            onBackPressedDispatcher.onBackPressed()
          }
        }
      },
    )
  }

  private fun loadUrl() {
    webView.loadUrl(WEB_URL)
  }

  //region Permissions

  private fun hasLocationPermissions(): Boolean {
    return LOCATION_PERMISSIONS.all { permission ->
      ContextCompat.checkSelfPermission(this, permission) == PackageManager.PERMISSION_GRANTED
    }
  }

  private fun requestLocationPermissions() {
    locationPermissionLauncher.launch(LOCATION_PERMISSIONS)
  }

  //endregion

  //region WebViewClient

  private inner class AirNowWebViewClient : WebViewClient() {
    override fun shouldOverrideUrlLoading(view: WebView, request: WebResourceRequest): Boolean {
      val uri = request.url
      return if (isAppUrl(uri)) {
        false
      } else {
        openExternalUrl(uri)
      }
    }
  }

  //endregion

  //region WebChromeClient

  private inner class AirNowWebChromeClient : WebChromeClient() {
    override fun onGeolocationPermissionsShowPrompt(
      origin: String,
      callback: GeolocationPermissions.Callback,
    ) {
      if (hasLocationPermissions()) {
        callback.invoke(origin, true, false)
      } else {
        pendingGeolocationCallback = callback
        pendingGeolocationOrigin = origin
        requestLocationPermissions()
      }
    }
  }

  //endregion

  //region Lifecycle

  override fun onSaveInstanceState(outState: Bundle) {
    webView.saveState(outState)
    super.onSaveInstanceState(outState)
  }

  override fun onPause() {
    super.onPause()
    webView.onPause()
  }

  override fun onResume() {
    super.onResume()
    webView.onResume()
  }

  override fun onDestroy() {
    webView.apply {
      stopLoading()
      settings.javaScriptEnabled = false
      loadUrl("about:blank")
      clearHistory()
      removeAllViews()
      destroy()
    }
    super.onDestroy()
  }

  //endregion

  private fun isAppUrl(uri: Uri): Boolean {
    return uri.scheme == WEB_URI.scheme && uri.host == WEB_URI.host
  }

  private fun openExternalUrl(uri: Uri): Boolean {
    val intent = Intent(Intent.ACTION_VIEW, uri)
    return try {
      startActivity(intent)
      true
    } catch (_: ActivityNotFoundException) {
      false
    }
  }
}
