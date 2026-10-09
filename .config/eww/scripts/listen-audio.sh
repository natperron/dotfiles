#!/bin/bash

# App streams to hide from the Apps view (regex on the app name)
HIDDEN_APPS="fluidsynth"

get_audio() {
  pw-dump | jq -c --arg hidden "$HIDDEN_APPS" '
    # wpctl shows volumes on a cubic scale, pw-dump stores them linearly
    def volume:
      ((.info.params.Props // []) | map(select(.channelVolumes)) | first // {}) as $props
      | {
        volume: (($props.channelVolumes // [0]) | add / length | pow(.; 1 / 3) * 100 | round),
        muted: ($props.mute // false)
      };

    def icon:
      if .muted or .volume == 0 then "audio-volume-muted"
      elif .volume < 34 then "audio-volume-low"
      elif .volume < 67 then "audio-volume-medium"
      else "audio-volume-high" end;

    def class($class):
      map(select(.type == "PipeWire:Interface:Node" and .info.props."media.class" == $class));

    (map(select(.type == "PipeWire:Interface:Metadata" and .props."metadata.name" == "default"))
      | first.metadata // []) as $metadata
    | def default_name($key): $metadata | map(select(.key == $key)) | first.value.name;

    def nodes($class; $default):
      class($class)
      # WirePlumber placeholder that switches a headset to HSP/HFP when the mic is used
      | map(select(.info.props."bluez5.loopback" != true))
      | map({
        id,
        serial: .info.props."object.serial",
        name: .info.props."node.description",
        default: (.info.props."node.name" == $default)
      } + volume)
      | sort_by(.name);

    def current: (map(select(.default)) | first) // {id: "", volume: 0, muted: true};

    map(select(.type == "PipeWire:Interface:Link") | .info) as $links
    | nodes("Audio/Sink"; default_name("default.audio.sink")) as $sinks
    | nodes("Audio/Source"; default_name("default.audio.source")) as $sources

    # App streams; the device they use comes from their links, $self/$other
    # being the link ends of the stream and the device respectively
    | def apps($class; $devices; $self; $other):
      class($class)
      | map(
        .id as $id
        | ([$links[] | select(.[$self] == $id) | .[$other]] | first) as $device_id
        | {
          id,
          name: (.info.props."application.name" // .info.props."application.process.binary" // .info.props."node.name"),
          icon: (.info.props."application.icon-name" // .info.props."application.process.binary" // "audio-x-generic" | ascii_downcase),
          media: (.info.props."media.name" // ""),
          device_id: ($device_id // ""),
          device_name: (($devices | map(select(.id == $device_id)) | first.name) // ""),
          follow_default: ($metadata | any(.subject == $id and .key == "target.object") | not)
        } + volume)
      | map(select(.name | test($hidden; "i") | not))
      | sort_by(.name | ascii_downcase);

    {
      sink: ($sinks | current | . + {icon: icon}),
      source: ($sources | current),
      sinks: $sinks,
      sources: $sources,
      playback: apps("Stream/Output/Audio"; $sinks; "output-node-id"; "input-node-id"),
      recording: apps("Stream/Input/Audio"; $sources; "input-node-id"; "output-node-id"),
      cards: (
        map(select(.type == "PipeWire:Interface:Device" and .info.props."media.class" == "Audio/Device"))
        | map({
          id,
          name: (.info.props."device.description" // .info.props."device.name"),
          selected_profile: ((.info.params.Profile // [])[0] // {} | {id: .index, name: .description}),
          profiles: [(.info.params.EnumProfile // [])[]
            | select(.available != "no")
            | {id: .index, name: .description}]
        })
        | sort_by(.name)
      )
    }'
}

# Only react to changes of devices, app streams, routing, defaults or removed objects
watch_changes() {
  pw-dump --monitor 2> /dev/null | jq -r --unbuffered '
    select(type == "array")
    | select(any(.[];
      .info == null
      or .type == "PipeWire:Interface:Device"
      or .type == "PipeWire:Interface:Metadata"
      or .type == "PipeWire:Interface:Link"
      or (.info.props."media.class" // "" | test("^(Audio/(Sink|Source)|Stream/(Output|Input)/Audio)$"))))
    | "changed"'
}

last=$(get_audio)
echo "$last"

watch_changes |
while read -r _; do
  # Throttle bursts, then only print when something visible changed
  sleep 0.2
  while read -r -t 0.05 _; do :; done
  current=$(get_audio)
  if [[ "$current" != "$last" ]]; then
    last=$current
    echo "$current"
  fi
done
