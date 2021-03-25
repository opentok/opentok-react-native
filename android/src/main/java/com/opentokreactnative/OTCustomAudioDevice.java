package com.opentokreactnative;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothHeadset;
import android.bluetooth.BluetoothProfile;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.media.AudioFormat;
import android.media.AudioManager;
import android.media.AudioRecord;
import android.media.AudioTrack;
import android.media.MediaRecorder.AudioSource;
import android.media.audiofx.AcousticEchoCanceler;
import android.media.audiofx.NoiseSuppressor;
import android.os.Build;
import android.os.Handler;
import android.telephony.PhoneStateListener;
import android.telephony.TelephonyManager;

import java.nio.ByteBuffer;
import java.util.List;
import java.util.Locale;
import java.util.concurrent.locks.Condition;
import java.util.concurrent.locks.ReentrantLock;

class OTCustomAudioDevice extends BaseAudioDevice {
    private final OtLog.LogToken log = new OtLog.LogToken(this);

    private static final int NUM_CHANNELS_CAPTURING = 1;
    private static final int NUM_CHANNELS_RENDERING = 2;
    private static final int STEREO_CHANNELS = 2;
    private static final int DEFAULT_SAMPLE_RATE = 44100;
    private static final int SAMPLE_SIZE_IN_BYTES = 2;
    private static final int DEFAULT_SAMPLES_PER_BUFFER = (DEFAULT_SAMPLE_RATE / 1000) * 10; // 10ms
    private static final int DEFAULT_BUFFER_SIZE = SAMPLE_SIZE_IN_BYTES * DEFAULT_SAMPLES_PER_BUFFER * STEREO_CHANNELS;
    // Max 10 ms @ 48 kHz - Stereo
    private static final int DEFAULT_START_RENDERER_AND_CAPTURER_DELAY = 5 * 1000;
    private static final int DEFAULT_BLUETOOTH_SCO_START_DELAY = 2000;
    private Context context;

    private AudioTrack audioTrack;
    private AudioRecord audioRecord;

    // Capture & render buffers
    private ByteBuffer playBuffer;
    private ByteBuffer recBuffer;
    private byte[] tempBufPlay;
    private byte[] tempBufRec;

    private final ReentrantLock rendererLock = new ReentrantLock(true);
    private final Condition renderEvent = rendererLock.newCondition();
    private volatile boolean isRendering = false;
    private volatile boolean shutdownRenderThread = false;

    private final ReentrantLock captureLock = new ReentrantLock(true);
    private final Condition captureEvent = captureLock.newCondition();
    private volatile boolean isCapturing = false;
    private volatile boolean shutdownCaptureThread = false;

    private AudioSettings captureSettings;
    private AudioSettings rendererSettings;
    private NoiseSuppressor noiseSuppressor;
    private AcousticEchoCanceler echoCanceler;

    // Capturing delay estimation
    private int estimatedCaptureDelay = 0;

    // Rendering delay estimation
    private int bufferedPlaySamples = 0;
    private int playPosition = 0;
    private int estimatedRenderDelay = 0;

    private AudioManager audioManager;
    private AudioManagerMode audioManagerMode = new AudioManagerMode();

    private int outputSamplingRate = DEFAULT_SAMPLE_RATE;
    private int captureSamplingRate = DEFAULT_SAMPLE_RATE;
    private int samplesPerBuffer = DEFAULT_SAMPLES_PER_BUFFER;

    // For headset receiver.
    private static final String HEADSET_PLUG_STATE_KEY = "state";

    private BluetoothState bluetoothState;
    private BluetoothAdapter bluetoothAdapter;
    private BluetoothProfile bluetoothProfile;
    private final Object bluetoothLock = new Object();
    private TelephonyManager telephonyManager;

    private boolean isPaused;

    private enum OutputType {
        SPEAKER_PHONE,
        EAR_PIECE,
        HEAD_PHONES,
        BLUETOOTH
    }

    private OutputType audioOutputType = OutputType.SPEAKER_PHONE;

    private OutputType getOutputType() {
        return audioOutputType;
    }

    private void setOutputType(OutputType type) {
        audioOutputType = type;
    }

    private static class AudioManagerMode {
        private int oldMode;
        private int naquire;
        private final OtLog.LogToken log = new OtLog.LogToken(this);

        AudioManagerMode() {
            oldMode = 0;
            naquire = 0;
        }

        void acquireMode(AudioManager audioManager) {
            log.d("AudioManagerMode.acquireMode() called");
            if (0 == naquire++) {
                oldMode = audioManager.getMode();
                audioManager.setMode(AudioManager.MODE_IN_COMMUNICATION);
            }
        }

        void releaseMode(AudioManager audioManager) {
            log.d("AudioManagerMode.releaseMode() called");
            if (0 == --naquire) {
                audioManager.setMode(oldMode);
            }
        }
    }

    private static class AudioState {
        private int lastStreamVolume = 0;
        private int lastKnownFocusState = 0;
        private OutputType lastOutputType = OutputType.SPEAKER_PHONE;

        private final OtLog.LogToken log = new OtLog.LogToken(this);

        int getLastStreamVolume() {
            return lastStreamVolume;
        }

        void setLastStreamVolume(int lastStreamVolume) {
            this.lastStreamVolume = lastStreamVolume;
        }

        int getLastKnownFocusState() {
            return lastKnownFocusState;
        }

        void setLastKnownFocusState(int lastKnownFocusState) {
            this.lastKnownFocusState = lastKnownFocusState;
        }

        OutputType getLastOutputType() {
            return this.lastOutputType;
        }

        void setLastOutputType(OutputType lastOutputType) {
            log.d("AudioState.setLastOutputType(" + lastOutputType + ") called");
            this.lastOutputType = lastOutputType;
        }
    }

    private AudioState audioState = new AudioState();

    private BroadcastReceiver headsetBroadcastReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            log.d("headsetBroadcastReceiver.onReceive()");
            if (intent.getAction().equals(Intent.ACTION_HEADSET_PLUG)) {
                if (intent.getIntExtra(HEADSET_PLUG_STATE_KEY, 0) == 1) {
                    log.d("headsetBroadcastReceiver.onReceive():  Headphones connected");
                    audioState.setLastOutputType(getOutputType());
                    setOutputType(OutputType.HEAD_PHONES);
                    audioManager.setSpeakerphoneOn(false);
                    audioManager.setBluetoothScoOn(false);
                } else {
                    log.d("headsetBroadcastReceiver.onReceive():  Headphones disconnected");
                    if (getOutputType() == OutputType.HEAD_PHONES) {
                        if (audioState.getLastOutputType() == OutputType.BLUETOOTH &&
                                BluetoothState.Connected == bluetoothState) {
                            audioManager.setBluetoothScoOn(true);
                            startBluetoothSco();
                            setOutputType(OutputType.BLUETOOTH);
                        } else {
                            if (audioState.getLastOutputType() == OutputType.SPEAKER_PHONE) {
                                setOutputType(OutputType.SPEAKER_PHONE);
                                audioManager.setSpeakerphoneOn(true);
                            }
                            if (audioState.getLastOutputType() == OutputType.EAR_PIECE) {
                                setOutputType(OutputType.EAR_PIECE);
                                audioManager.setSpeakerphoneOn(false);
                            }
                        }
                    }
                }
            }
        }
    };

    // Intent broadcast receiver which handles changes in Bluetooth device availability.
    // Detects headset changes and Bluetooth SCO state changes.
    private final BroadcastReceiver bluetoothHeadsetReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            final String action = intent.getAction();
            if (action.equals(BluetoothHeadset.ACTION_AUDIO_STATE_CHANGED)) {
                final int state = intent.getIntExtra(
                        BluetoothHeadset.EXTRA_STATE, -1);
                switch (state) {
                    case BluetoothHeadset.STATE_AUDIO_DISCONNECTED:
                        log.d("bluetoothHeadsetReceiver.onReceive(): STATE_AUDIO_DISCONNECTED");
                        break;

                    case BluetoothHeadset.STATE_AUDIO_CONNECTING:
                        log.d("bluetoothHeadsetReceiver.onReceive(): STATE_AUDIO_CONNECTING");
                        break;

                    case BluetoothHeadset.STATE_AUDIO_CONNECTED:
                        log.d("bluetoothHeadsetReceiver.onReceive(): STATE_AUDIO_CONNECTED");
                        break;

                    default:
                        break;
                }
            }
        }
    };

    private void restoreAudioAfterBluetoothDisconnect() {
        if (audioManager.isWiredHeadsetOn()) {
            setOutputType(OutputType.HEAD_PHONES);
            audioManager.setSpeakerphoneOn(false);
        } else {
            if (audioState.getLastOutputType() == OutputType.SPEAKER_PHONE) {
                setOutputType(OutputType.SPEAKER_PHONE);
                super.setOutputMode(OutputMode.SpeakerPhone);
                audioManager.setSpeakerphoneOn(true);
            } else if (audioState.getLastOutputType() == OutputType.EAR_PIECE) {
                setOutputType(OutputType.EAR_PIECE);
                super.setOutputMode(OutputMode.Handset);
                audioManager.setSpeakerphoneOn(false);
            }
        }
    }

    private final BroadcastReceiver bluetoothBroadcastReceiver = new BroadcastReceiver() {
        public void onReceive(Context context, Intent intent) {
            final String action = intent.getAction();
            if (null != action && action.equals(BluetoothHeadset.ACTION_CONNECTION_STATE_CHANGED)) {
                int state = intent.getIntExtra(BluetoothHeadset.EXTRA_STATE, -1);
                switch (state) {
                    case BluetoothHeadset.STATE_CONNECTED:
                        log.d("bluetoothBroadcastReceiver.onReceive(): BluetoothHeadset.STATE_CONNECTED");
                        new Handler().postDelayed(() -> connectBluetooth(), DEFAULT_BLUETOOTH_SCO_START_DELAY);
                        break;
                    case BluetoothHeadset.STATE_DISCONNECTING:
                        log.d("bluetoothBroadcastReceiver.onReceive(): BluetoothHeadset.STATE_DISCONNECTING");
                        break;
                    case BluetoothHeadset.STATE_DISCONNECTED:
                        log.d("bluetoothBroadcastReceiver.onReceive(): BluetoothHeadset.STATE_DISCONNECTED");
                        stopBluetoothSco();
                        audioManager.setBluetoothScoOn(false);
                        break;
                    default:
                        break;
                }
            } else if (null != action && action.equals(AudioManager.ACTION_SCO_AUDIO_STATE_UPDATED)) {
                int state = intent.getIntExtra(AudioManager.EXTRA_SCO_AUDIO_STATE, -1);
                switch (state) {
                    case AudioManager.SCO_AUDIO_STATE_CONNECTED:
                        log.d("bluetoothBroadcastReceiver.onReceive(): AudioManager.SCO_AUDIO_STATE_CONNECTED");
                        bluetoothState = BluetoothState.Connected;
                        setOutputType(OutputType.BLUETOOTH);
                        OTCustomAudioDevice.super.setOutputMode(OutputMode.Handset); // When BT is connected it replaces the handset
                        break;
                    case AudioManager.SCO_AUDIO_STATE_ERROR:
                        log.d("bluetoothBroadcastReceiver.onReceive(): AudioManager.SCO_AUDIO_STATE_ERROR");
                        break;
                    case AudioManager.SCO_AUDIO_STATE_DISCONNECTED:
                        log.d("bluetoothBroadcastReceiver.onReceive(): AudioManager.SCO_AUDIO_STATE_DISCONNECTED");
                        restoreAudioAfterBluetoothDisconnect();
                        bluetoothState = BluetoothState.Disconnected;
                        break;
                    case AudioManager.SCO_AUDIO_STATE_CONNECTING:
                        log.d("bluetoothBroadcastReceiver.onReceive(): AudioManager.SCO_AUDIO_STATE_CONNECTING");
                        break;
                    default:
                        break;
                }
            }
        }
    };

    private PhoneStateListener phoneStateListener = new PhoneStateListener(){
        @Override
        public void onCallStateChanged(int state, String incomingNumber) {
            log.d("PhoneStateListener.onCallStateChanged()");
            super.onCallStateChanged(state, incomingNumber);
            switch (state) {

                case TelephonyManager.CALL_STATE_IDLE:
                    //Initial state
                    log.d("PhoneStateListener.onCallStateChanged(): TelephonyManager.CALL_STATE_IDLE");
                    // We delay a bit here the action of start capturing and rendering again because Android has to
                    // finish routing audio to the earpiece. It is an Android behaviour we have to deal with.
                    new Handler().postDelayed(() -> startRendererAndCapturer(), DEFAULT_START_RENDERER_AND_CAPTURER_DELAY);
                    break;

                case TelephonyManager.CALL_STATE_RINGING:
                    // Incoming call Ringing
                    log.d("PhoneStateListener.onCallStateChanged(): TelephonyManager.CALL_STATE_RINGING");
                    stopRendererAndCapturer();
                    break;

                case TelephonyManager.CALL_STATE_OFFHOOK:
                    // Outgoing Call | Accepted incoming call
                    log.d("PhoneStateListener.onCallStateChanged(): TelephonyManager.CALL_STATE_OFFHOOK");
                    stopRendererAndCapturer();
                    break;

                default:
                    log.d("PhoneStateListener.onCallStateChanged() default");
                    break;
            }
        }
    };

    private boolean wasRendering;
    private boolean wasCapturing;

    private void startRendererAndCapturer() {
        log.d("startRendererAndCapturer()");
        if (wasRendering) {
            startRenderer();
        }

        if (wasCapturing) {
            startCapturer();
        }
    }

    private void stopRendererAndCapturer() {
        log.d("stopRendererAndCapturer()");
        if (isRendering) {
            stopRenderer();
            wasRendering = true;
        }

        if (isCapturing) {
            stopCapturer();
            wasCapturing = true;
        }
    }

    private AudioManager.OnAudioFocusChangeListener audioFocusChangeListener = new AudioManager.OnAudioFocusChangeListener() {
        @Override
        public void onAudioFocusChange(int focusChange) {
            log.d("AudioManager.OnAudioFocusChangeListener.onAudioFocusChange(" + focusChange + ")");
            switch (focusChange) {
                case AudioManager.AUDIOFOCUS_GAIN:
                    log.d("AudioManager.OnAudioFocusChangeListener.onAudioFocusChange(" + focusChange + "): ");
                    //Check if coming back from a complete loss or a transient loss
                    switch (audioState.getLastKnownFocusState()) {
                        case AudioManager.AUDIOFOCUS_LOSS:
                            break;
                        case AudioManager.AUDIOFOCUS_LOSS_TRANSIENT:
                            break;
                        case AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK:
                            audioManager.setStreamVolume(AudioManager.STREAM_VOICE_CALL,
                                audioState.getLastStreamVolume(), 0);
                            break;
                        default:
                            log.d("focusChange = " + focusChange);
                            break;
                    }
                    setOutputType(audioState.getLastOutputType());
                    connectBluetooth();
                    forceInvokeConnectBluetooth();
                    break;

                case AudioManager.AUDIOFOCUS_LOSS:
                    // -1 Loss for indefinite time
                    log.d("AudioManager.OnAudioFocusChangeListener.onAudioFocusChange(" + focusChange + "): AudioManager.AUDIOFOCUS_LOSS");
                    break;
                case AudioManager.AUDIOFOCUS_LOSS_TRANSIENT:
                    // -2 Loss for short duration
                    log.d("AudioManager.OnAudioFocusChangeListener.onAudioFocusChange(" + focusChange + "): AudioManager.AUDIOFOCUS_LOSS_TRANSIENT");
                    break;
                case AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK:
                    // -3 stay quite in background
                    log.d("AudioManager.OnAudioFocusChangeListener.onAudioFocusChange(" + focusChange + "): AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK");
                    audioState.setLastStreamVolume(audioManager.getStreamVolume(AudioManager.STREAM_VOICE_CALL));
                    audioManager.setStreamVolume(AudioManager.STREAM_VOICE_CALL, 0, 0);
                    break;
                case AudioManager.AUDIOFOCUS_NONE:
                    log.d("AudioManager.OnAudioFocusChangeListener.onAudioFocusChange(" + focusChange + "): AudioManager.AUDIOFOCUS_NONE");
                    break;
                default:
                    log.d("AudioManager.OnAudioFocusChangeListener.onAudioFocusChange(" + focusChange + "): default");
                    break;
            }
            audioState.setLastOutputType(getOutputType());
            audioState.setLastKnownFocusState(focusChange);
        }
    };

    private void connectBluetooth() {
        log.d("connectBluetooth() called");
        audioManager.setBluetoothScoOn(true);
        startBluetoothSco();
    }

    public OTCustomAudioDevice(Context context) { // todo add here
        log.d("OTCustomAudioDevice() enter " + this);
        this.context = context;

        try {
            recBuffer = ByteBuffer.allocateDirect(DEFAULT_BUFFER_SIZE);
        } catch (Exception e) {
            log.e(e.getMessage());
        }
        tempBufRec = new byte[DEFAULT_BUFFER_SIZE];

        audioManager = (AudioManager)context.getSystemService(Context.AUDIO_SERVICE);
        bluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
        bluetoothProfile = null;

        int outputBufferSize = DEFAULT_BUFFER_SIZE;

        if (Build.VERSION.SDK_INT > Build.VERSION_CODES.JELLY_BEAN) {
            try {
                outputSamplingRate = Integer.parseInt(
                        audioManager.getProperty(AudioManager.PROPERTY_OUTPUT_SAMPLE_RATE));
            } catch(NumberFormatException numberFormatException) {
                log.e("OTCustomAudioDevice(): " + numberFormatException.getMessage());
            } finally {
                if (outputSamplingRate == 0) {
                    outputSamplingRate = DEFAULT_SAMPLE_RATE;
                }
            }
            try {
                samplesPerBuffer = Integer.parseInt(
                        audioManager.getProperty(AudioManager.PROPERTY_OUTPUT_FRAMES_PER_BUFFER));
                outputBufferSize = SAMPLE_SIZE_IN_BYTES
                    * samplesPerBuffer
                    * NUM_CHANNELS_RENDERING;
            } catch(NumberFormatException numberFormatException) {
                log.e("OTCustomAudioDevice(): " + numberFormatException.getMessage());
            } finally {
                if (outputBufferSize == 0) {
                    outputBufferSize = DEFAULT_BUFFER_SIZE;
                    samplesPerBuffer = DEFAULT_SAMPLES_PER_BUFFER;
                }
            }
        }

        try {
            playBuffer = ByteBuffer.allocateDirect(outputBufferSize);
        } catch (Exception e) {
            log.e(e.getMessage());
        }

        tempBufPlay = new byte[outputBufferSize];

        captureSettings = new AudioSettings(captureSamplingRate,
            NUM_CHANNELS_CAPTURING);
        rendererSettings = new AudioSettings(outputSamplingRate,
            NUM_CHANNELS_RENDERING);
        try {
            telephonyManager = (TelephonyManager) context.getSystemService(Context
                    .TELEPHONY_SERVICE);
        } catch (SecurityException e) {
            e.printStackTrace();
        }
        isPhoneStateListenerRegistered = false;
        wasCapturing = false;
        wasRendering = false;
        isPaused = false;
        log.d("OTCustomAudioDevice() exit  " + this);

    }

    @Override
    public boolean initCapturer() {
        log.d("initCapturer() called");

        // get the minimum buffer size that can be used
        int minRecBufSize = AudioRecord.getMinBufferSize(
            captureSettings.getSampleRate(),
            NUM_CHANNELS_CAPTURING == 1 ? AudioFormat.CHANNEL_IN_MONO : AudioFormat.CHANNEL_IN_STEREO,
            AudioFormat.ENCODING_PCM_16BIT
        );

        // double size to be more safe
        int recBufSize = minRecBufSize * 2;

        // release the object
        if (noiseSuppressor != null) {
            noiseSuppressor.release();
            noiseSuppressor = null;
        }
        if (echoCanceler != null) {
            echoCanceler.release();
            echoCanceler = null;
        }
        if (audioRecord != null) {
            audioRecord.release();
            audioRecord = null;
        }

        try {
            audioRecord = new AudioRecord(AudioSource.VOICE_COMMUNICATION,
                captureSettings.getSampleRate(),
                NUM_CHANNELS_CAPTURING == 1 ? AudioFormat.CHANNEL_IN_MONO
                    : AudioFormat.CHANNEL_IN_STEREO,
                AudioFormat.ENCODING_PCM_16BIT, recBufSize);
            if (NoiseSuppressor.isAvailable()) {
                noiseSuppressor = NoiseSuppressor.create(audioRecord.getAudioSessionId());
            }
            if (AcousticEchoCanceler.isAvailable()) {
                echoCanceler = AcousticEchoCanceler.create(audioRecord.getAudioSessionId());
            }

        } catch (Exception e) {
            throw new RuntimeException(e.getMessage());
        }

        // Check that the audioRecord is ready to be used.
        if (audioRecord.getState() != AudioRecord.STATE_INITIALIZED) {
            String errorDescription = String.format(Locale.getDefault(), "Audio capture could not be initialized.\n" +
                            "Requested parameters\n" +
                            "  Sampling Rate: %d\n" +
                            "  Number of channels: %d\n" +
                            "  Buffer size: %d\n",
                    captureSettings.getSampleRate(),
                    captureSettings.getNumChannels(),
                    minRecBufSize);
            log.e(errorDescription);
            throw new RuntimeException(errorDescription);
        }

        registerPhoneStateListener();

        shutdownCaptureThread = false;
        new Thread(captureThread).start();
        return true;
    }

    @Override
    public boolean destroyCapturer() {
        log.d("destroyCapturer() called");

        captureLock.lock();
        // release the object
        if (null != echoCanceler) {
            echoCanceler.release();
            echoCanceler = null;
        }
        if (null != noiseSuppressor) {
            noiseSuppressor.release();
            noiseSuppressor = null;
        }
        audioRecord.release();
        audioRecord = null;
        shutdownCaptureThread = true;
        captureEvent.signal();

        captureLock.unlock();

        unRegisterPhoneStateListener();
        wasCapturing = false;
        return true;
    }

    public int getEstimatedCaptureDelay() {
        return estimatedCaptureDelay;
    }

    @Override
    public boolean startCapturer() {
        log.d("startCapturer() called");

        if (audioRecord == null) {
            throw new IllegalStateException("startCapturer(): startRecording() called on an "
                    + "uninitialized AudioRecord.");
        }
        try {
            audioRecord.startRecording();

        } catch (IllegalStateException e) {
            throw new RuntimeException(e.getMessage());
        }

        captureLock.lock();
        isCapturing = true;
        captureEvent.signal();
        captureLock.unlock();
        audioManagerMode.acquireMode(audioManager);
        return true;
    }

    @Override
    public boolean stopCapturer() {
        log.d("stopCapturer() called");

        if (audioRecord == null) {
            throw new IllegalStateException("stopCapturer(): stop() called on an uninitialized AudioRecord.");
        }
        captureLock.lock();
        try {
            // Only stop if we are recording.
            if (audioRecord.getRecordingState() == AudioRecord.RECORDSTATE_RECORDING) {
                audioRecord.stop();
            }
        } catch (Exception e) {
            throw new RuntimeException(e.getMessage());
        } finally {
            // Ensure we always unlock
            isCapturing = false;
            captureLock.unlock();
        }
        audioManagerMode.releaseMode(audioManager);

        return true;
    }

    private Runnable captureThread = () -> {
        int samplesToRec = captureSamplingRate / 100;
        int samplesRead;

        try {
            android.os.Process.setThreadPriority(android.os.Process.THREAD_PRIORITY_URGENT_AUDIO);
        } catch (Exception e) {
            log.e("android.os.Process.setThreadPriority(): " + e.getMessage());
        }

        while (!shutdownCaptureThread) {
            captureLock.lock();
            try {
                if (!OTCustomAudioDevice.this.isCapturing) {
                    captureEvent.await();
                    continue;
                } else {
                    if (audioRecord == null) {
                        continue;
                    }
                    int lengthInBytes = (samplesToRec << 1) * NUM_CHANNELS_CAPTURING;
                    int readBytes = audioRecord.read(tempBufRec, 0, lengthInBytes);
                    if (readBytes >= 0) {
                        recBuffer.rewind();
                        recBuffer.put(tempBufRec);
                        samplesRead = (readBytes >> 1) / NUM_CHANNELS_CAPTURING;
                    } else {
                        switch (readBytes) {
                            case AudioRecord.ERROR_BAD_VALUE:
                                throw new RuntimeException("captureThread(): AudioRecord.ERROR_BAD_VALUE");
                            case AudioRecord.ERROR_INVALID_OPERATION:
                                throw new RuntimeException("captureThread(): AudioRecord.ERROR_INVALID_OPERATION");
                            case AudioRecord.ERROR:
                            default:
                                throw new RuntimeException("captureThread(): AudioRecord.ERROR or default");
                        }
                    }
                }
            } catch (Exception e) {
                BaseAudioDevice.publisherError(e);
                return;
            } finally {
                // Ensure we always unlock
                captureLock.unlock();
            }
            getAudioBus().writeCaptureData(recBuffer, samplesRead);
            estimatedCaptureDelay = samplesRead * 1000 / captureSamplingRate;
        }
    };

    @Override
    public boolean initRenderer() {
        log.d("initRenderer() called");

        // Request audio focus for playback
        int result = audioManager.requestAudioFocus(audioFocusChangeListener,
            // Use the music stream.
            AudioManager.STREAM_VOICE_CALL,
            // Request permanent focus.
            AudioManager.AUDIOFOCUS_GAIN);

        if (result == AudioManager.AUDIOFOCUS_REQUEST_GRANTED) {
            log.d("initRenderer(): AudioManager.AUDIOFOCUS_REQUEST_GRANTED");
        } else {
            log.d("initRenderer(): !AudioManager.AUDIOFOCUS_REQUEST_GRANTED");
            return false;
        }

        // initalize default values
        bluetoothState = BluetoothState.Disconnected;
        /* register for bluetooth sco callbacks and attempt to enable it */
        enableBluetoothEvents();
        // get the minimum buffer size that can be used
        int minPlayBufSize = AudioTrack.getMinBufferSize(
            rendererSettings.getSampleRate(),
            NUM_CHANNELS_RENDERING == 1 ? AudioFormat.CHANNEL_OUT_MONO : AudioFormat.CHANNEL_OUT_STEREO,
            AudioFormat.ENCODING_PCM_16BIT
        );

        // release the object
        if (audioTrack != null) {
            audioTrack.release();
            audioTrack = null;
        }

        try {
            audioTrack = new AudioTrack(
                AudioManager.STREAM_VOICE_CALL,
                rendererSettings.getSampleRate(),
                (NUM_CHANNELS_RENDERING == 1)
                    ? AudioFormat.CHANNEL_OUT_MONO
                    : AudioFormat.CHANNEL_OUT_STEREO,
                AudioFormat.ENCODING_PCM_16BIT,
                minPlayBufSize >= 6000 ? minPlayBufSize : minPlayBufSize * 2,
                AudioTrack.MODE_STREAM
            );
        } catch (Exception e) {
            throw new RuntimeException(e.getMessage());
        }
        // Check that the audioRecord is ready to be used.
        if (audioTrack.getState() != AudioTrack.STATE_INITIALIZED) {
            throw new RuntimeException("Audio renderer not initialized " + rendererSettings.getSampleRate());
        }

        bufferedPlaySamples = 0;

        registerPhoneStateListener();

        shutdownRenderThread = false;
        new Thread(renderThread).start();
        return true;
    }

    private void destroyAudioTrack() {
        rendererLock.lock();
        audioTrack.release();
        audioTrack = null;
        shutdownRenderThread = true;
        renderEvent.signal();
        rendererLock.unlock();
    }

    @Override
    public boolean destroyRenderer() {
        log.d("destroyRenderer() called");

        destroyAudioTrack();
        disableBluetoothEvents();
        unregisterHeadsetReceiver();
        audioManager.setSpeakerphoneOn(false);
        audioManager.abandonAudioFocus(audioFocusChangeListener);

        unRegisterPhoneStateListener();
        wasRendering = false;
        return true;
    }

    public int getEstimatedRenderDelay() {
        return estimatedRenderDelay;
    }

    @Override
    public boolean startRenderer() {
        log.d("startRenderer() called");

        // Enable speakerphone unless headset is connected.
        synchronized (bluetoothLock) {
            if (BluetoothState.Connected != bluetoothState) {
                if (audioManager.isWiredHeadsetOn()) {
                    log.d("startRenderer(): Turn off Speaker phone");
                    audioManager.setSpeakerphoneOn(false);
                } else {
                    log.d("startRenderer(): Turn on Speaker phone");
                    if (getOutputType() == OutputType.SPEAKER_PHONE) {
                        audioManager.setSpeakerphoneOn(true);
                    }
                }
            }
        }
        // Start playout.
        if (audioTrack == null) {
            throw new IllegalStateException("startRenderer(): play() called on uninitialized AudioTrack.");
        }
        try {
            audioTrack.play();
        } catch (IllegalStateException e) {
            throw new RuntimeException(e.getMessage());
        }
        rendererLock.lock();
        isRendering = true;
        renderEvent.signal();
        rendererLock.unlock();
        audioManagerMode.acquireMode(audioManager);
        registerBtReceiver();
        registerHeadsetReceiver();
        return true;
    }

    @Override
    public boolean stopRenderer() {
        log.d("stopRenderer() called");

        if (audioTrack == null) {
            throw new IllegalStateException("stopRenderer(): stop() called on uninitialized AudioTrack.");
        }
        rendererLock.lock();
        try {
            // Only stop if we are playing.
            if (audioTrack.getPlayState() == AudioTrack.PLAYSTATE_PLAYING) {
                audioTrack.stop();

            }
            audioTrack.flush();
        } catch (Exception e) {
            throw new RuntimeException(e.getMessage());
        } finally {
            isRendering = false;
            rendererLock.unlock();
        }
        audioManagerMode.releaseMode(audioManager);

        unregisterHeadsetReceiver();
        unregisterBtReceiver();
        return true;
    }

    private Runnable renderThread = () -> {
        int samplesToPlay = samplesPerBuffer;
        try {
            android.os.Process.setThreadPriority(android.os.Process.THREAD_PRIORITY_URGENT_AUDIO);
        } catch (Exception e) {
            log.e("android.os.Process.setThreadPriority(): " + e.getMessage());
        }

        while (!shutdownRenderThread) {
            rendererLock.lock();
            try {
                if (!OTCustomAudioDevice.this.isRendering) {
                    renderEvent.await();
                    continue;

                } else {
                    rendererLock.unlock();

                    // Don't lock on audioBus calls
                    playBuffer.clear();
                    int samplesRead = getAudioBus().readRenderData(playBuffer, samplesToPlay);

                    rendererLock.lock();

                    // After acquiring the lock again we must check if we are still playing
                    if (audioTrack == null || !OTCustomAudioDevice.this.isRendering) {
                        continue;
                    }

                    int bytesRead = (samplesRead << 1) * NUM_CHANNELS_RENDERING;
                    playBuffer.get(tempBufPlay, 0, bytesRead);

                    int bytesWritten = audioTrack.write(tempBufPlay, 0, bytesRead);
                    if (bytesWritten > 0) {
                        // increase by number of written samples
                        bufferedPlaySamples += (bytesWritten >> 1) / NUM_CHANNELS_RENDERING;

                        // decrease by number of played samples
                        int pos = audioTrack.getPlaybackHeadPosition();
                        if (pos < playPosition) {
                            // wrap or reset by driver
                            playPosition = 0;
                        }
                        bufferedPlaySamples -= (pos - playPosition);
                        playPosition = pos;

                        // we calculate the estimated delay based on the buffered samples
                        estimatedRenderDelay = bufferedPlaySamples * 1000 / outputSamplingRate;
                    } else {
                        switch (bytesWritten) {
                            case AudioTrack.ERROR_BAD_VALUE:
                                throw new RuntimeException(
                                        "renderThread(): AudioTrack.ERROR_BAD_VALUE");
                            case AudioTrack.ERROR_INVALID_OPERATION:
                                throw new RuntimeException(
                                        "renderThread(): AudioTrack.ERROR_INVALID_OPERATION");
                            case AudioTrack.ERROR:
                            default:
                                throw new RuntimeException(
                                        "renderThread(): AudioTrack.ERROR or default");
                        }
                    }
                }
            } catch (Exception e) {
                BaseAudioDevice.publisherError(e);
                return;
            } finally {
                rendererLock.unlock();
            }
        }
    };

    @Override
    public AudioSettings getCaptureSettings() {
        return this.captureSettings;
    }

    @Override
    public AudioSettings getRenderSettings() {
        return this.rendererSettings;
    }

    /**
     * Communication modes handling.
     */
    public boolean setOutputMode(OutputMode mode) {
        //This is public API and also called during initialization
        log.d("Audio Output mode set to --> " + mode);
        super.setOutputMode(mode);
        if(OutputMode.SpeakerPhone == mode) {
            audioState.setLastOutputType(getOutputType());
            setOutputType(OutputType.SPEAKER_PHONE);
            audioManager.setSpeakerphoneOn(true);
            stopBluetoothSco();
            audioManager.setBluetoothScoOn(false);
        } else {
            if (audioState.getLastOutputType() == OutputType.BLUETOOTH || bluetoothState == BluetoothState.Connected) {
                connectBluetooth();
            } else {
                audioState.setLastOutputType(getOutputType());
                audioManager.setSpeakerphoneOn(false);
                setOutputType(OutputType.EAR_PIECE);
                stopBluetoothSco();
                audioManager.setBluetoothScoOn(false);
            }
        }
        return true;
    }

    private boolean isHeadsetReceiverRegistered;

    private void registerHeadsetReceiver() {
        log.d("registerHeadsetReceiver() called ... isHeadsetReceiverRegistered = " + isHeadsetReceiverRegistered);

        if (isHeadsetReceiverRegistered) {
            return;
        }
        context.registerReceiver(headsetBroadcastReceiver, new IntentFilter(Intent.ACTION_HEADSET_PLUG));
        isHeadsetReceiverRegistered = true;
    }

    private void unregisterHeadsetReceiver() {
        log.d("unregisterHeadsetReceiver() called .. isHeadsetReceiverRegistered = " + isHeadsetReceiverRegistered);

        if (!isHeadsetReceiverRegistered) {
            return;
        }
        context.unregisterReceiver(headsetBroadcastReceiver);
        isHeadsetReceiverRegistered = false;
    }

    private boolean isBluetoothHeadSetReceiverRegistered;

    private void registerBtReceiver() {
        log.d("registerBtReceiver() called .. isBluetoothHeadSetReceiverRegistered = " + isBluetoothHeadSetReceiverRegistered);

        if (isBluetoothHeadSetReceiverRegistered) {
            return;
        }
        IntentFilter btFilter =  new IntentFilter(BluetoothHeadset.ACTION_CONNECTION_STATE_CHANGED);
        btFilter.addAction(AudioManager.ACTION_SCO_AUDIO_STATE_UPDATED);
        context.registerReceiver(bluetoothBroadcastReceiver, btFilter);

        // Register receiver for change in audio connection state of the Headset profile.
        context.registerReceiver(bluetoothHeadsetReceiver, new IntentFilter(BluetoothHeadset.ACTION_AUDIO_STATE_CHANGED));

        isBluetoothHeadSetReceiverRegistered = true;
    }


    private void unregisterBtReceiver() {
        log.d("unregisterBtReceiver() called .. bluetoothHeadSetReceiverRegistered = " + isBluetoothHeadSetReceiverRegistered);

        if (!isBluetoothHeadSetReceiverRegistered) {
            return;
        }
        context.unregisterReceiver(bluetoothBroadcastReceiver);
        context.unregisterReceiver(bluetoothHeadsetReceiver);
        isBluetoothHeadSetReceiverRegistered = false;
    }

    private boolean isPhoneStateListenerRegistered;

    private void registerPhoneStateListener() {
        log.d("registerPhoneStateListener() called");

        if (isPhoneStateListenerRegistered) {
            return;
        }
        if (telephonyManager != null) {
            telephonyManager.listen(phoneStateListener, PhoneStateListener.LISTEN_CALL_STATE);
            isPhoneStateListenerRegistered = true;
        }
    }

    private void unRegisterPhoneStateListener() {
        log.d("unRegisterPhoneStateListener() called");

        if (!isPhoneStateListenerRegistered) {
            return;
        }
        if (telephonyManager != null) {
            telephonyManager.listen(phoneStateListener, PhoneStateListener.LISTEN_NONE);
            isPhoneStateListenerRegistered = false;
        }
    }

    @Override
    public synchronized void onPause() {
        log.d("onPause() called");

        audioState.setLastOutputType(getOutputType());
        unregisterBtReceiver();
        unregisterHeadsetReceiver();
        isPaused = true;
    }

    @Override
    public synchronized void onResume() {
        log.d("onResume() called");
        if (!isPaused) {
            return;
        }

        if (bluetoothState == BluetoothState.Disconnected) {
            if (isRendering && (audioState.getLastOutputType() == OutputType.SPEAKER_PHONE)) {
                if (!audioManager.isWiredHeadsetOn()) {
                    log.d("onResume() - Set Speaker Phone ON True");
                    audioManager.setSpeakerphoneOn(true);
                }
            }
        }

        /* register handler for phonejack notifications */
        registerBtReceiver();
        registerHeadsetReceiver();
        connectBluetooth();
        forceInvokeConnectBluetooth();

        isPaused = false;
    }

    @Override
    public BluetoothState getBluetoothState() {
        return bluetoothState;
    }

    private void enableBluetoothEvents() {
        log.d("enableBluetoothEvents() called");
        if (audioManager.isBluetoothScoAvailableOffCall()) {
            registerBtReceiver();
            connectBluetooth();
        }

    }

    private void disableBluetoothEvents() {
        log.d("disableBluetoothEvents() called");

        if (null != bluetoothProfile && bluetoothAdapter != null) {
            bluetoothAdapter.closeProfileProxy(BluetoothProfile.HEADSET, bluetoothProfile);
        }

        unregisterBtReceiver();

        // Force a shutdown of bluetooth: when a call comes in, the handler is not invoked by system.
        Intent intent = new Intent(BluetoothHeadset.ACTION_CONNECTION_STATE_CHANGED);
        intent.putExtra(BluetoothHeadset.EXTRA_STATE, BluetoothHeadset.STATE_DISCONNECTED);
        bluetoothBroadcastReceiver.onReceive(context, intent);
    }

    private void startBluetoothSco() {
        log.d("startBluetoothSco() called");

        try {
            audioManager.startBluetoothSco();
        } catch (NullPointerException e) {
            log.e("startBluetoothSco(): " + e.getMessage());
        }
    }

    private void stopBluetoothSco() {
        log.d("stopBluetoothSco() called");

        try {
            audioManager.stopBluetoothSco();
        } catch (NullPointerException e) {
            log.e("stopBluetoothSco(): " + e.getMessage());
        }
    }

    private final BluetoothProfile.ServiceListener bluetoothProfileServiceListener = new BluetoothProfile.ServiceListener() {
        @Override
        public void onServiceConnected(int type, BluetoothProfile profile) {
            log.d("BluetoothProfile.ServiceListener.onServiceConnected()");
            if (BluetoothProfile.HEADSET == type) {
                bluetoothProfile = profile;
                List<BluetoothDevice> devices = profile.getConnectedDevices();
                log.d("Service Proxy Connected");
                if (!devices.isEmpty() &&
                        BluetoothHeadset.STATE_CONNECTED == profile.getConnectionState(devices.get(0))) {
                    // Force a init of bluetooth: the handler will not send a connected event if a
                    // device is already connected at the time of proxy connection request.
                    Intent intent = new Intent(BluetoothHeadset.ACTION_CONNECTION_STATE_CHANGED);
                    intent.putExtra(BluetoothHeadset.EXTRA_STATE, BluetoothHeadset.STATE_CONNECTED);
                    bluetoothBroadcastReceiver.onReceive(context, intent);
                }
            }
        }

        @Override
        public void onServiceDisconnected(int type) {
            log.d("BluetoothProfile.ServiceListener.onServiceDisconnected()");
        }
    };

    private void forceInvokeConnectBluetooth() {
        log.d("forceConnectBluetooth() called");
        // Force reconnection of bluetooth in the event of a phone call.
        synchronized (bluetoothLock) {
            bluetoothState = BluetoothState.Disconnected;
            if (bluetoothAdapter != null) {
                bluetoothAdapter.getProfileProxy(
                        context,
                        bluetoothProfileServiceListener,
                        BluetoothProfile.HEADSET
                );
            }
        }
    }

}