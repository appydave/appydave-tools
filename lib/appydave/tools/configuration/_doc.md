# Configuration Component

[ChatGPT conversation](https://chatgpt.com/g/g-4dMsIRK3E-ruby-script-assistant/c/d8ea5960-071b-48aa-9fd9-554ca302c7dd)
[ChatGPT conversation for Schema](https://chatgpt.com/c/bb93e7ac-f139-44f9-8b9c-4e74ac2fa461)

  attr_accessor :code,
                :narration


## Schema

### Channels Schema

- **code**: Short identifier for the channel (e.g., `"ad"`, `"ac"`, `"fv"`).
- **name**: Full name of the channel (e.g., `"AppyDave"`, `"AppyDave Coding"`, `"FliVideo"`).
- **youtube_handle**: YouTube handle for the channel (e.g., `"@appydave"`, `"@appydavecoding"`, `"@flivideo"`).

#### Example

```json
{
  "channels": {
    "appydave": {
      "code": "ad",
      "name": "AppyDave",
      "youtube_handle": "@appydave"
    },
    "appydave_coding": {
      "code": "ac",
      "name": "AppyDave Coding",
      "youtube_handle": "@appydavecoding"
    },
    "fli_video": {
      "code": "fv",
      "name": "FliVideo",
      "youtube_handle": "@flivideo"
    }
  }
}
```

### Channel Projects Schema

- **content_projects**: Path to the shared folder for content creation (e.g., `"/user/Library/CloudStorage/Dropbox/team-appydave"`).
- **video_projects**: Path to the local storage folder for active video projects (e.g., `"/user/tube-channels/appy-dave/active"`).
- **published_projects**: Path to the archive folder for published projects (e.g., `"/Volumes/Expansion/published/appydave"`).
- **abandoned_projects**: Path to the archive folder for incomplete or failed projects (e.g., `"/Volumes/Expansion/failed/appydave"`).

## Example
```json
{
  "projects": {
    "appydave": {
      "content_projects": "/user/Library/CloudStorage/Dropbox/team-appydave",
      "video_projects": "/user/tube-channels/appy-dave/active",
      "published_projects": "/Volumes/Expansion/published/appydave",
      "abandoned_projects": "/Volumes/Expansion/failed/appydave"
    },
    "appydave_coding": {
      "content_projects": "/user/Library/CloudStorage/Dropbox/team-appydavecoding",
      "video_projects": "/user/tube-channels/a-cast/cast-active",
      "published_projects": "/Volumes/Expansion/published/appydave-coding",
      "abandoned_projects": "/Volumes/Expansion/failed/appydave-coding"
    },
    "fli_video": {
      "content_projects": "/user/Library/CloudStorage/Dropbox/team-flivideo",
      "video_projects": "/user/tube-channels/fli-video/active",
      "published_projects": "/Volumes/Expansion/published/fli-video",
      "abandoned_projects": "/Volumes/Expansion/failed/fli-video"
    }
  }
}
```