# Timed Guided Session Audio Files

This directory should contain the following audio files for the timed guided session feature:

## Required Files

- `Luma_OneMinute.mp3` - A one-minute guided breathing session with Luma's voice
- `Luma_TwoMinute.mp3` - A two-minute guided breathing session with Luma's voice
- `Luma_FiveMinute.mp3` - A five-minute guided breathing session with Luma's voice

## Audio File Requirements

1. Files should be in MP3 format
2. Audio should be clear, professional quality with Luma's voice
3. Each file should match its stated duration (1, 2, or 5 minutes)
4. Audio should have proper fades to avoid clicking/popping
5. Volume levels should be consistent across all files

## Session Characteristics

Each file should contain a complete guided breathing session with Luma's voice. The session should:

- Guide the user through a proper breathing practice
- Include appropriate pacing with inhale, hold, and exhale instructions
- Include gentle encouragement and mindfulness cues
- End with a closing statement

## Implementation Details

These audio files are used by the `AudioCueManager` class to provide one-time guided sessions. Unlike regular breathing cues that loop continuously, these sessions play once and then automatically turn off voice guidance when complete.

The audio files are preloaded when the app starts to ensure smooth playback.

## Missing Files

If these files are missing, the app will still function, but the timed session options will not play anything. Error messages will be logged to the console indicating which files could not be found. 