#!/bin/bash
set -e

# Render 88.5-second cinematic demo video with smooth Ken Burns zoompan effect + synced narration audio
ffmpeg -y \
  -loop 1 -t 88.56 -i /Users/mm/Desktop/floodwise/floodwise_capitol_cover_600x800.jpg \
  -i /Users/mm/Desktop/floodwise/voiceover.mp3 \
  -filter_complex "\
    [0:v]scale=1080:1440,zoompan=z='min(zoom+0.00025,1.06)':d=2215:x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':s=1080x1440,format=yuv420p[v]" \
  -map "[v]" -map 1:a -c:v libx264 -preset veryfast -crf 20 -c:a aac -b:a 192k -shortest \
  /Users/mm/Desktop/floodwise/FloodWise_Demo_Video_Daniel_Dano.mp4

echo "VIDEO_RENDER_COMPLETE"
