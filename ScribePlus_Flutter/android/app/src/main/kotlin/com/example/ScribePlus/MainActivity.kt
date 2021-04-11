package com.example.ScribePlus

//import io.flutter.embedding.android.FlutterActivity
// Basic Kotlin - Flutter Setup
import androidx.annotation.NonNull;
import android.os.Bundle
import io.flutter.plugin.common.MethodChannel
import android.widget.Toast
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

// Audio Recorder Import
import java.time.LocalDateTime
import java.io.IOException
import android.media.MediaRecorder
import android.os.Environment
import android.media.AudioFormat

class MainActivity: FlutterActivity() {
    private val CHANNEL = "scribeplus.sendstring"

    private var output: String = Environment.getExternalStorageDirectory().absolutePath + "/recordingxxx.mp3"
    private var mediaRecorder: MediaRecorder? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Setting up access to Media Channel

        mediaRecorder = MediaRecorder()
    
        MethodChannel( flutterEngine.getDartExecutor(), CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "callSendStringFun") {
                // output = Environment.getExternalStorageDirectory().absolutePath + "/recordingxxx.mp3"
                println("mediiiaaaaaaaaaaaaaxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx ${mediaRecorder}")
                println("outxxx ${output}")
                
                showHelloFromFlutter(call.argument("arg"))
                val temp = sendString()
                result.success(temp)
            } else if(call.method == "stopRecord") {
                stopRecord()
                println("recording stoped")
                result.success(true)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun sendString(): String {
        return output
    }

    // Stop Record Function
    private fun stopRecord() {
        try {
            Toast.makeText(this,"Stopped!", Toast.LENGTH_SHORT).show()
            mediaRecorder?.stop()
            mediaRecorder?.release()
        } catch (e: IOException) {
            e.printStackTrace()
        }
    }


        private fun showHelloFromFlutter(argFromFlutter : String?){

            try {
                mediaRecorder?.setAudioSource(MediaRecorder.AudioSource.MIC)
                mediaRecorder?.setOutputFormat(AudioFormat.ENCODING_PCM_16BIT)
                mediaRecorder?.setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
                mediaRecorder?.setAudioChannels(1)
                mediaRecorder?.setAudioEncodingBitRate(128000)
                mediaRecorder?.setAudioSamplingRate(48000)
                mediaRecorder?.setOutputFile(output)
                println("mediiiaaaaaaaaaaaaa ${mediaRecorder}")

                mediaRecorder?.prepare()
                mediaRecorder?.start()
                println("path^ ${output}")
                Toast.makeText(this, "Recording started!", Toast.LENGTH_SHORT).show()
            } catch (e: IllegalStateException) {
                e.printStackTrace()
            } catch (e: IOException) {
                e.printStackTrace()
            }

            Toast.makeText(this, argFromFlutter, Toast.LENGTH_SHORT).show()
        }
}
