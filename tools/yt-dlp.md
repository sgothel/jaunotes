
# yt-dlp

- [Homepage](https://github.com/yt-dlp/yt-dlp)
  - [Installation](https://github.com/yt-dlp/yt-dlp#installation)
    - [Details](https://github.com/yt-dlp/yt-dlp/wiki/Installation)

## Installation via pip/python
Recommended

```
# Create Python3 virtual_env if not existing
# virtualenv  ~/python3

# Activate Python3 virtual_env
source ~/python3/bin/activate

# Install
pip install -U "yt-dlp[default]"
```

## External JS Scripts Setup Guide
See [External JS Scripts Setup Guide](https://github.com/yt-dlp/yt-dlp/wiki/EJS)

```
pip install -U yt-dlp-ejs
```

### Using Deno (recommended)
See [Deno Setup](https://github.com/yt-dlp/yt-dlp/wiki/EJS#deno)


Prepare node config `~/.npmrc`
```
prefix = "/home/sven/node_modules"
```

Install and config deno via node
```
npm config list
npm install -g deno
~/node_modules/bin/deno upgrade
~/node_modules/bin/deno install --frozen
# ~/node_modules/bin/deno task bundle
```

pip install -U yt-dlp-ejs
```

## Configuration

```
--js-runtimes deno:/home/sven/node\_modules/bin/deno

# know what you are doing!
# --cookies-from-browser firefox:/home/user/.librewolf/some\_profile.dir

#-f 'best[height>=720]/best'
#-f 'best[height>=1080]/best'
#-f 'best[ext=mp4]/best'
#-f 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best'

# Download the best video available but no better than 1080p, or just the best video
-f "bv*[height<=1080]+ba/b[height<=1080] / bv*+ba/b"

#--audio-format opus
--merge-output-format mkv
--embed-chapters
--embed-subs
#--all-subs
#--sub-lang en,de,zh-Hans,fr
#--sub-lang en,de,zh-Hans,ru
--sub-lang en
#--sub-lang all
--write-sub
--write-auto-sub
--convert-subs srt
--compat-options no-keep-subs
--download-archive yt-dlp.archive
--sleep-interval 1
--max-sleep-interval 4
#--impersonate chrome:windows-10
# --sleep-interval 10
# --max-sleep-interval 30
```

