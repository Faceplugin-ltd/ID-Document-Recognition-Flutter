package com.faceplugin.document_reader_sdk

import android.os.Handler
import android.os.Looper
import android.graphics.Bitmap
import android.graphics.Matrix
import com.faceplugin.documentreadersdk.DocumentReaderSDK
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.concurrent.Executors

/** Flutter port of RN DocumentReaderSdkModule. */
class DocumentReaderSdkPlugin : FlutterPlugin, MethodCallHandler {
  private lateinit var channel: MethodChannel
  private var appContext: android.content.Context? = null
  private val executor = Executors.newSingleThreadExecutor()
  private val mainHandler = Handler(Looper.getMainLooper())

  private fun success(result: Result, value: Any?) {
    mainHandler.post { result.success(value) }
  }

  private fun error(result: Result, code: String, message: String?) {
    mainHandler.post { result.error(code, message, null) }
  }

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    appContext = binding.applicationContext
    channel = MethodChannel(binding.binaryMessenger, "DocumentReaderSdk")
    channel.setMethodCallHandler(this)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    appContext = null
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    val context = appContext
    if (context == null) {
      result.error("E_CONTEXT", "Plugin not attached", null)
      return
    }

    when (call.method) {
      "getMachineCode" -> executor.execute {
        try {
          success(result, DocumentReaderSDK.getMachineCode(context) ?: "")
        } catch (t: Throwable) {
          error(result, "E_MACHINE_CODE", t.message)
        }
      }
      "setActivation" -> {
        val license = call.arguments as? String ?: ""
        executor.execute {
          try {
            success(result, DocumentReaderSDK.setActivation(context, license))
          } catch (t: Throwable) {
            error(result, "E_ACTIVATION", t.message)
          }
        }
      }
      "init" -> executor.execute {
        try {
          success(result, DocumentReaderSDK.init(context))
        } catch (t: Throwable) {
          error(result, "E_INIT", t.message)
        }
      }
      "deinit" -> executor.execute {
        try {
          DocumentReaderSDK.deinit()
          success(result, null)
        } catch (t: Throwable) {
          error(result, "E_DEINIT", t.message)
        }
      }
      "startNewSession" -> {
        val optionsJson = call.arguments as? String
        executor.execute {
          try {
            val json = if (optionsJson.isNullOrBlank()) {
              DocumentReaderSDK.startNewSession()
            } else {
              DocumentReaderSDK.startNewSession(optionsJson)
            }
            success(result, json)
          } catch (t: Throwable) {
            error(result, "E_SESSION", t.message)
          }
        }
      }
      "locateDocument" -> {
        val imageUri = call.arguments as? String ?: ""
        executor.execute {
          try {
            val bitmap = loadBitmap(context, imageUri)
              ?: run {
                error(result, "E_IMAGE", "Could not decode image: $imageUri")
                return@execute
              }
            val upright = uprightPortrait(bitmap)
            val locateBmp = scaleMax(upright, LOCATE_MAX_EDGE)
            val json = DocumentReaderSDK.locateDocument(locateBmp)
            success(
              result,
              rescaleLocateJson(
                json,
                locateBmp.width,
                locateBmp.height,
                upright.width,
                upright.height
              )
            )
          } catch (t: Throwable) {
            error(result, "E_LOCATE", t.message)
          }
        }
      }
      "recognize" -> {
        val args = call.arguments as? Map<*, *>
        val frontUri = args?.get("front") as? String ?: ""
        val backUri = args?.get("back") as? String
        val authenticityMode = (args?.get("authenticityMode") as? String)
            ?: if ((args?.get("authenticity") as? Boolean) == false) "none" else "normal"
        executor.execute {
          try {
            val frontRaw = loadBitmap(context, frontUri)
              ?: run {
                error(result, "E_IMAGE", "Could not decode front image: $frontUri")
                return@execute
              }
            val front = uprightPortrait(frontRaw)
            val back: Bitmap? =
              if (backUri.isNullOrBlank()) {
                null
              } else {
                loadBitmap(context, backUri)?.let { uprightPortrait(it) }
              }
            DocumentReaderSDK.startNewSession("{\"scenario\":\"FullProcess\",\"series\":false}")
            val json = DocumentReaderSDK.recognize(front, back, authenticityMode)
            success(result, json)
          } catch (t: Throwable) {
            error(result, "E_RECOGNIZE", t.message)
          }
        }
      }
      "lastLicenseError" -> {
        try {
          result.success(DocumentReaderSDK.lastLicenseError() ?: "")
        } catch (t: Throwable) {
          error(result, "E_LICENSE_ERROR", t.message)
        }
      }
      "getLicenseStatus" -> {
        try {
          result.success(DocumentReaderSDK.getLicenseStatus() ?: "{}")
        } catch (t: Throwable) {
          error(result, "E_LICENSE_STATUS", t.message)
        }
      }
      "writeStatus" -> {
        val json = call.arguments as? String ?: "{}"
        try {
          val file = java.io.File(context.filesDir, "docreader_status.json")
          file.writeText(json)
          success(result, null)
        } catch (t: Throwable) {
          error(result, "E_STATUS", t.message)
        }
      }
      else -> result.notImplemented()
    }
  }

  private fun loadBitmap(context: android.content.Context, uriOrBase64: String): Bitmap? {
    return if (uriOrBase64.startsWith("data:") || looksLikeBase64(uriOrBase64)) {
      ImageUtils.bitmapFromBase64(uriOrBase64)
    } else {
      ImageUtils.bitmapFromUri(context, uriOrBase64)
    }
  }

  private fun looksLikeBase64(value: String): Boolean {
    return value.length > 256 &&
      !value.contains("://") &&
      !value.startsWith("/") &&
      !value.startsWith("file:")
  }

  private fun uprightPortrait(src: Bitmap): Bitmap {
    if (src.width <= src.height) return src
    val matrix = Matrix().apply { postRotate(90f) }
    return Bitmap.createBitmap(src, 0, 0, src.width, src.height, matrix, true)
  }

  private fun scaleMax(src: Bitmap, maxEdge: Int): Bitmap {
    val longest = maxOf(src.width, src.height)
    if (longest <= maxEdge) return src
    val scale = maxEdge.toFloat() / longest
    return Bitmap.createScaledBitmap(
      src,
      (src.width * scale).toInt().coerceAtLeast(1),
      (src.height * scale).toInt().coerceAtLeast(1),
      true
    )
  }

  private fun rescaleLocateJson(
    json: String,
    locateW: Int,
    locateH: Int,
    imageW: Int,
    imageH: Int
  ): String {
    if (json.isEmpty()) return json
    return try {
      val root = org.json.JSONObject(json)
      root.put("_locateImageWidth", imageW)
      root.put("_locateImageHeight", imageH)
      val pos = root.optJSONObject("position") ?: return root.toString()
      val sx = imageW.toFloat() / locateW.coerceAtLeast(1)
      val sy = imageH.toFloat() / locateH.coerceAtLeast(1)
      val corners = pos.optJSONArray("corners")
      if (corners != null && corners.length() >= 4) {
        for (i in 0 until corners.length()) {
          val p = corners.optJSONObject(i) ?: continue
          p.put("x", p.optDouble("x") * sx)
          p.put("y", p.optDouble("y") * sy)
        }
      } else {
        if (pos.has("left")) pos.put("left", pos.optDouble("left") * sx)
        if (pos.has("top")) pos.put("top", pos.optDouble("top") * sy)
        if (pos.has("right")) pos.put("right", pos.optDouble("right") * sx)
        if (pos.has("bottom")) pos.put("bottom", pos.optDouble("bottom") * sy)
      }
      root.toString()
    } catch (_: Throwable) {
      json
    }
  }

  companion object {
    private const val LOCATE_MAX_EDGE = 480
  }
}
