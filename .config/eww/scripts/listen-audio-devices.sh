get_audio_devices() {
  pw-dump | jq -c '[
    . as $root
    | .[] 
    | select(.info.props."media.class" == "Audio/Source" or .info.props."media.class" == "Audio/Sink")
    | .info.props."device.id" as $device_id
    | {
      id: .id,
      name: .info.props."node.description",
      type: (if .info.props."media.class" == "Audio/Source" then "input" else "output" end),
      device: (
        $root 
          | .[] 
          | select(.id == $device_id)
          | {
            selected_profile: .info.params.Profile[0] | {id: .index, name: .description},
            profiles: .info.params.EnumProfile | map({
              id: .index,
              name: .description
            })
          }
      ),
    }
  ]'
}

get_audio_devices