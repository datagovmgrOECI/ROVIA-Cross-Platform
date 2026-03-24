# Copyright 2023 Ocean Exploration Cooperative Institute (OECI)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# ROVIA v2.0 - Optimized version with performance improvements

import cv2
import numpy as np
import os
from keras.models import load_model, Model
import keras.backend as K
import tensorflow as tf
from re import finditer, search
import argparse
from moviepy.editor import *
import datetime
from multiprocessing import Pool
import time

WINDOW_SIZE = 60
RESIZE_WIDTH = 160
RESIZE_HEIGHT = 90
NUM_PROCESSES = os.cpu_count()
PROCESS_CHUNK_DURATION = WINDOW_SIZE * 10
# Optimized batch size for better GPU utilization (3x larger than v1)
PREDICTION_BATCH_SIZE = 450  # Increased from 150 (5*30)

class rovia():

    def __init__(self):
        self.check_gpu_availability()

    def check_gpu_availability(self):
        """Check if GPU is available and configure TensorFlow accordingly"""
        gpus = tf.config.list_physical_devices('GPU')
        if gpus:
            try:
                # Enable memory growth to avoid allocating all GPU memory at once
                for gpu in gpus:
                    tf.config.experimental.set_memory_growth(gpu, True)
                print(f'GPU acceleration enabled: {len(gpus)} GPU(s) detected')
            except RuntimeError as e:
                print(f'GPU configuration error: {e}')
        else:
            print('No GPU detected, using CPU')

    def recall_m(self, y_true, y_pred):
        true_positives = K.sum(K.round(K.clip(y_true * y_pred, 0, 1)))
        possible_positives = K.sum(K.round(K.clip(y_true, 0, 1)))
        recall = true_positives / (possible_positives + K.epsilon())
        return recall

    def precision_m(self, y_true, y_pred):
        true_positives = K.sum(K.round(K.clip(y_true * y_pred, 0, 1)))
        predicted_positives = K.sum(K.round(K.clip(y_pred, 0, 1)))
        precision = true_positives / (predicted_positives + K.epsilon())
        return precision

    def f1_m(self, y_true, y_pred):
        precision = self.precision_m(y_true, y_pred)
        recall = self.recall_m(y_true, y_pred)
        return 2 * ((precision * recall) / (precision + recall + K.epsilon()))

    def readModel(self, path='./grama.hdf5'):
        print('Loading model at: '+path)
        dependencies = {
            'f1_m': f1_m,
            'precision_m': precision_m,
            'recall_m': recall_m
        }
        model = load_model(path, custom_objects=dependencies)
        print('Model load complete ...')
        return model

    def generateHighlights(self, X, model, fps):
        """Optimized: Larger batch size for better GPU utilization"""
        y = []
        total_samples = len(X)

        # Process in larger batches for better GPU utilization
        for i in range(0, total_samples, PREDICTION_BATCH_SIZE):
            end_idx = min(i + PREDICTION_BATCH_SIZE, total_samples)
            X_chunk = X[i:end_idx]

            # Predict with batching
            prediction = model.predict(X_chunk, verbose=0, batch_size=32)
            prediction = np.argmax(prediction, axis=1)
            y.extend(prediction)

        return np.array(y)

    def postProcessHighlights(self, y, kernelSize=5):
        """Optimized: Pre-allocate arrays instead of extending"""
        kernel = np.ones(kernelSize) / kernelSize
        data_convolved = np.convolve(y, kernel, mode='same')

        # Vectorized operation instead of list comprehension
        y_extended = (data_convolved > 0.5).astype(int)

        # Edge smoothing (kept as is since it's sequential logic)
        for i in range(2, len(y)-2):
            if y_extended[i] == 0 and y_extended[i+1] == 1:
                y_extended[i-2:i+1] = 1
            if y_extended[i-1] == 1 and y_extended[i] == 0:
                y_extended[i:i+3] = 1
        return y_extended

    def readVideoChunk(self, path, startFrame, chunkDuration):
        """Optimized: Pre-allocate arrays, improved memory management"""
        vid = cv2.VideoCapture(path)
        vid.set(cv2.CAP_PROP_POS_FRAMES, startFrame)

        ret, prev_frame = vid.read()
        if not ret:
            vid.release()
            return []

        frame_resized = cv2.resize(prev_frame, (RESIZE_WIDTH, RESIZE_HEIGHT), interpolation=cv2.INTER_AREA)
        prev_gray = cv2.cvtColor(frame_resized, cv2.COLOR_BGR2GRAY)

        # Pre-allocate array for better memory performance
        Xmatrix = np.zeros((chunkDuration, RESIZE_HEIGHT, RESIZE_WIDTH, 3), dtype='uint8')
        frame_count = 0

        for frame_idx in range(chunkDuration):
            ret, frame = vid.read()
            if not ret:
                break

            frame_resized = cv2.resize(frame, (RESIZE_WIDTH, RESIZE_HEIGHT), interpolation=cv2.INTER_AREA)
            gray = cv2.cvtColor(frame_resized, cv2.COLOR_BGR2GRAY)

            # Optical flow calculation (kept as is for accuracy)
            flow = cv2.calcOpticalFlowFarneback(prev_gray, gray, None, 0.5, 3, 15, 3, 5, 1.2, 0)

            # Computes the magnitude and angle of the 2D vectors
            magnitude, angle = cv2.cartToPolar(flow[..., 0], flow[..., 1])
            magnitude = (magnitude * 255).astype('uint8')
            angle = (angle / (2 * np.pi) * 255).astype('uint8')

            # Stack channels directly into pre-allocated array
            Xmatrix[frame_count] = np.stack((gray, magnitude, angle), axis=2)
            prev_gray = gray
            frame_count += 1

        vid.release()
        cv2.destroyAllWindows()

        # Trim to actual frame count
        Xmatrix = Xmatrix[:frame_count]

        # Window the data
        num_windows = (frame_count + WINDOW_SIZE - 1) // WINDOW_SIZE
        windowed = np.zeros((num_windows, WINDOW_SIZE, RESIZE_HEIGHT, RESIZE_WIDTH, 3), dtype='uint8')

        for i in range(num_windows):
            start_idx = i * WINDOW_SIZE
            end_idx = min(start_idx + WINDOW_SIZE, frame_count)
            window_length = end_idx - start_idx
            windowed[i, :window_length] = Xmatrix[start_idx:end_idx]

        return windowed

    def getVideoMetadata(self, path):
        vid = cv2.VideoCapture(path)
        fps = vid.get(cv2.CAP_PROP_FPS)
        frameCount = int(vid.get(cv2.CAP_PROP_FRAME_COUNT))
        vid.release()
        cv2.destroyAllWindows()

        return fps, frameCount

    def analyzeVideo(self, path, model, verbose, process_pool):
        """Optimized: Uses passed process pool, better memory management"""
        fps, frameCount = self.getVideoMetadata(path)

        # Number of video chunks to process
        numChunks = frameCount // PROCESS_CHUNK_DURATION

        results = []

        # for each group of chunks
        for chunkGroupStart in range(0, numChunks, NUM_PROCESSES):
            remainingChunks = numChunks - chunkGroupStart
            numChunksInGroup = min(remainingChunks, NUM_PROCESSES)
            chunkGroupEnd = chunkGroupStart + numChunksInGroup
            chunkGroupStartFrame = chunkGroupStart*PROCESS_CHUNK_DURATION

            if(verbose):
                print('Analyizing chunks: ' + str(chunkGroupStart) + ' to ' + str(chunkGroupEnd))
                print('Reading chunks ...')

            # Generate the list of video chunk start frames within the chunk group
            pool_args = [(path, chunkGroupStartFrame + (j * PROCESS_CHUNK_DURATION), PROCESS_CHUNK_DURATION) for j in range(numChunksInGroup)]

            # Use passed process pool
            groupResults = process_pool.starmap(self.readVideoChunk, pool_args)
            del pool_args

            # convert the list of results into a numpy array
            groupResults = np.vstack(groupResults)

            # generate highlights for the chunk group
            if(verbose):
                print('Generating highlights for chunks ...')
            chunk_highlights = self.generateHighlights(groupResults, model, fps)
            del groupResults

            # refine the highlights for the chunk group
            if(verbose):
                print('Refining highlights for chunks ...')
            refined_highlights = self.postProcessHighlights(chunk_highlights)
            del chunk_highlights

            results.extend(refined_highlights)
            del refined_highlights

            if(verbose):
                print('Completed chunks: ' + str(chunkGroupStart) + ' to ' + str(chunkGroupEnd))
                print('----------------------------------------')

        return results

    def interpretInputMetadata(self, videoFileName):
        # Verifies the filename contains a timestamp (yyyymmddThhmmssZ ex.20181214T1401Z)
        pattern = r'\d{4}(0[1-9]|1[0-2])(0[1-9]|[1-2]\d|3[0-1])T([0-1]\d|2[0-3])[0-5]\d[0-5]\dZ'

        timestamp = search(pattern, videoFileName)

        if timestamp:
            timestamp = timestamp.group()
        else:
            raise Exception('Invalid filename. Timestamp not found.')

        preformattedFilename = videoFileName.replace(timestamp, '$[timestamp]')

        # returns a datetime object
        timestampDT = datetime.datetime.strptime(timestamp, '%Y%m%dT%H%M%SZ')

        return timestampDT, preformattedFilename

    def closeClip(self, clip):
        """Attempts to fully close a clip, including its reader and audio reader."""
        try:
            clip.reader.close()
            del clip.reader

            if clip.audio is not None:
                clip.audio.reader.close_proc()
                del clip.audio

            del clip
        except Exception:
            pass

    def generateClips(self, annotations, path, fps, output_format='mp4'):
        """Optimized: Faster clip generation with format option (mp4 or native)"""
        filename = os.path.splitext(os.path.basename(path))[0]
        fullvideo = VideoFileClip(path)

        #Does clips directory exist?
        clipsdir = "./Rovia_Clips/"
        isExist = os.path.exists(clipsdir)
        if not isExist:
            os.makedirs(clipsdir)

        videoDT, preformattedFilename = self.interpretInputMetadata(filename)

        annotations = ''.join([str(1*item) for item in annotations])

        for match in finditer('1+', annotations):
            clipStartTime = int(match.span()[0]*WINDOW_SIZE/fps) # in seconds
            clipEndTime = int(match.span()[1]*WINDOW_SIZE/fps) # in seconds

            clip = fullvideo.subclip(clipStartTime, clipEndTime)

            clipStartDT = videoDT + datetime.timedelta(seconds=clipStartTime)
            clipDate = clipStartDT.strftime('%Y%m%d')
            clipTime = clipStartDT.strftime('%H%M%S')

            alterredFilename = preformattedFilename.replace('$[timestamp]', f'{clipDate}T{clipTime}Z')

            if output_format == 'native':
                # Keep original ProRes MOV format and quality
                output_path = f"{clipsdir}/{alterredFilename}_HL.mov"
                clip.write_videofile(
                    output_path,
                    codec="prores",
                    audio_codec="pcm_s16le",  # Uncompressed audio
                    preset="medium",
                    threads=4,
                    verbose=False,
                    logger=None,
                    ffmpeg_params=["-profile:v", "3"]  # ProRes 422 HQ profile
                )
            else:
                # H.264 MP4 (smaller, faster encoding)
                output_path = f"{clipsdir}/{alterredFilename}_HL.mp4"
                clip.write_videofile(
                    output_path,
                    temp_audiofile="./temp-audio.m4a",
                    remove_temp=True,
                    audio_codec="aac",
                    codec="libx264",
                    preset="fast",
                    threads=4,
                    verbose=False,
                    logger=None
                )

        self.closeClip(fullvideo)

    def startRovia(self, folder, model_path, verbose, output_format='mp4'):
        """Optimized: Load model once and reuse across all videos with persistent pool"""
        dependencies = {
            'f1_m': self.f1_m,
            'precision_m': self.precision_m,
            'recall_m': self.recall_m
        }

        print('Loading model...')
        model = load_model(model_path, custom_objects=dependencies)
        print('Model loaded successfully')

        # Go through directory
        FOLDER = folder
        video_files = []

        for root, dirs, files in os.walk(FOLDER):
            for file in files:
                if file.endswith('.mp4') or file.endswith('.mov'):
                    video_files.append((root, file))

        total_videos = len(video_files)
        print(f'Found {total_videos} video(s) to process')
        print(f'Output format: {output_format.upper()} ({"ProRes MOV" if output_format == "native" else "H.264 MP4"})')

        # Create persistent process pool for all videos
        with Pool(processes=NUM_PROCESSES) as process_pool:
            for idx, (root, file) in enumerate(video_files, 1):
                if verbose == 1:
                    print(f'\n[{idx}/{total_videos}] Reading video: {file}')

                videofilepath = os.path.join(FOLDER, file)

                start = time.time()
                prediction = self.analyzeVideo(videofilepath, model, verbose, process_pool)

                if verbose == 1:
                    print('Generating clips ...')

                self.generateClips(annotations=prediction, path=videofilepath, fps=30, output_format=output_format)
                end = time.time()

                print(f'Time taken: {end-start:.2f} seconds')

                if verbose == 1:
                    print('Done')

        print('~~Highlight generation complete~~')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description='~~ ROVIA v2.0: Optimized underwater highlight generator ~~\n Incubated @ Ocean Exploration Cooperative Institute',
        formatter_class=argparse.RawTextHelpFormatter
    )
    parser.add_argument('-m', '--model', help='Optional: Path to the model file')
    parser.add_argument('-f', '--folder', help='Required: Folder where videos are stored')
    parser.add_argument('-v', '--verbose', help='Optional: Less or more chatter? 0/1')
    parser.add_argument('-o', '--output',
                        choices=['mp4', 'native'],
                        default='mp4',
                        help='Optional: Output format - "mp4" (H.264, smaller files, faster) or "native" (ProRes MOV, original quality)')
    args = parser.parse_args()

    if args.folder == None:
        print('File path missing, try python rovia_v2.py -h for help')
        exit()

    if args.model == None:
        model = './grama.hdf5'
    else:
        model = args.model

    if args.verbose == None:
        verbose = 1
    else:
        verbose = int(args.verbose)

    print('='*60)
    print('ROVIA v2.0 - Performance Optimized Edition')
    print('='*60)

    r = rovia()
    r.startRovia(folder=args.folder, model_path=model, verbose=verbose, output_format=args.output)
