package com.adups.my.flutter.flutter_home_widget;

import android.annotation.SuppressLint;
import android.annotation.TargetApi;
import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.ColorSpace;
import android.graphics.PixelFormat;
import android.hardware.HardwareBuffer;
import android.media.Image;
import android.media.Image.Plane;
import android.media.ImageReader;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.util.LinkedList;
import java.util.Queue;

import io.flutter.embedding.engine.renderer.FlutterRenderer;
import io.flutter.embedding.engine.renderer.RenderSurface;

// Based on io.flutter.embedding.android.FlutterImageView
public class FlutterBackgroundRenderer
        implements RenderSurface {
    @NonNull
    private ImageReader imageReader;
    @Nullable
    private final Queue<Image> imageQueue;
    @Nullable
    private Bitmap currentBitmap;
    @Nullable
    private FlutterRenderer flutterRenderer;

    /**
     * Whether the view is attached to the Flutter render.
     */
    private boolean isAttachedToFlutterRenderer = false;

    public FlutterBackgroundRenderer(@NonNull Context context, int width,
            int height) {
        this.imageReader = createImageReader(width, height);
        this.imageQueue = new LinkedList<>();
    }

    @SuppressLint("WrongConstant")
    @TargetApi(19)
    @NonNull
    private static ImageReader createImageReader(int width, int height) {
        if (android.os.Build.VERSION.SDK_INT >= 29) {
            return ImageReader.newInstance(
                    width,
                    height,
                    PixelFormat.RGBA_8888,
                    3,
                    HardwareBuffer.USAGE_GPU_SAMPLED_IMAGE | HardwareBuffer.USAGE_GPU_COLOR_OUTPUT);
        } else {
            return ImageReader.newInstance(width, height, PixelFormat.RGBA_8888, 3);
        }
    }

    @Nullable
    @Override
    public FlutterRenderer getAttachedRenderer() {
        return flutterRenderer;
    }

    /**
     * Invoked by the owner of this {@code FlutterImageView} when it wants to begin rendering a
     * Flutter UI to this {@code FlutterImageView}.
     */
    @Override
    public void attachToRenderer(@NonNull FlutterRenderer flutterRenderer) {
        if (this.flutterRenderer != null) {
            this.flutterRenderer.stopRenderingToSurface();
        }
        flutterRenderer.swapSurface(imageReader.getSurface());
        this.flutterRenderer = flutterRenderer;
        isAttachedToFlutterRenderer = true;
        connectSurfaceToRenderer();
    }

    /**
     * Invoked by the owner of this {@code FlutterImageView} when it no longer wants to render a
     * Flutter UI to this {@code FlutterImageView}.
     */
    @Override
    public void detachFromRenderer() {
        if (!isAttachedToFlutterRenderer) {
            return;
        }
        disconnectSurfaceFromRenderer();

        // Drop the lastest image as it shouldn't render this image if this view is
        // attached to the renderer again.
        acquireLatestImage();
        // Clear drawings.
        currentBitmap = null;

        // Close the images in the queue and clear the queue.
        for (final Image image : imageQueue) {
            image.close();
        }
        imageQueue.clear();
        flutterRenderer = null;
        isAttachedToFlutterRenderer = false;
    }

    @Override
    public void pause() {
        // Not supported.
    }

    /**
     * Acquires the next image to be drawn. Returns true if
     * there's an image available in the queue.
     */
    @TargetApi(19)
    private void acquireLatestImage() {
        if (!isAttachedToFlutterRenderer) {
            return;
        }
        // To avoid exceptions, check if a new image can be acquired.
        if (imageQueue.size() < imageReader.getMaxImages()) {
            final Image image = imageReader.acquireLatestImage();
            if (image != null) {
                imageQueue.add(image);
            }
        }
    }

    /**
     * Acquires next Bitmap from the queue.
     * The bitmap should not be released.
     */
    @Nullable
    @TargetApi(29)
    public Bitmap getBitmap() {
        if (!isAttachedToFlutterRenderer) {
            return null;
        }
        acquireLatestImage();
        if (imageQueue.isEmpty()) {
            return null;
        }
        Image image = imageQueue.poll();
        if (android.os.Build.VERSION.SDK_INT >= 29) {
            final HardwareBuffer buffer = image.getHardwareBuffer();
            currentBitmap = Bitmap.wrapHardwareBuffer(buffer,
                    ColorSpace.get(ColorSpace.Named.SRGB));
            buffer.close();
        } else {
            final Plane[] imagePlanes = image.getPlanes();
            if (imagePlanes.length != 1) {
                return null;
            }

            final Plane imagePlane = imagePlanes[0];
            final int desiredWidth = imagePlane.getRowStride() / imagePlane.getPixelStride();
            final int desiredHeight = image.getHeight();

            if (currentBitmap == null
                || currentBitmap.getWidth() != desiredWidth
                || currentBitmap.getHeight() != desiredHeight) {
                currentBitmap =
                        Bitmap.createBitmap(
                                desiredWidth, desiredHeight,
                                Bitmap.Config.ARGB_8888);
            }
            currentBitmap.copyPixelsFromBuffer(imagePlane.getBuffer());
        }
        image.close();
        return currentBitmap;
    }

    public void resize(int width, int height) {
        if (!isAttachedToFlutterRenderer) {
            return;
        }
        if (width == imageReader.getWidth() && height == imageReader.getHeight()) {
            return;
        }
        changeSurfaceSize(width, height);
        // Bind native window to the new surface, and create a new onscreen surface
        // with the new size in the native side.
        flutterRenderer.swapSurface(imageReader.getSurface());
    }

    private void connectSurfaceToRenderer() {
        if (flutterRenderer == null) {
            throw new IllegalStateException(
                    "connectSurfaceToRenderer() should only be called when flutterRenderer are non-null.");
        }

        flutterRenderer.startRenderingToSurface(imageReader.getSurface());
    }

    // FlutterRenderer must be non-null.
    private void changeSurfaceSize(int width, int height) {
        if (flutterRenderer == null) {
            throw new IllegalStateException(
                    "changeSurfaceSize() should only be called when flutterRenderer is non-null.");
        }
        imageQueue.clear();
        // Close all the resources associated with the image reader,
        // including the images.
        imageReader.close();// Image readers cannot be resized once created.
        imageReader = createImageReader(width, height);

        flutterRenderer.surfaceChanged(width, height);
    }

    // FlutterRenderer must be non-null.
    private void disconnectSurfaceFromRenderer() {
        if (flutterRenderer == null) {
            throw new IllegalStateException(
                    "disconnectSurfaceFromRenderer() should only be called when flutterRenderer is non-null.");
        }

        flutterRenderer.stopRenderingToSurface();
    }
}
