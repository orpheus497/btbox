-- WirePlumber Bluetooth configuration for btbox
-- Enables all Bluetooth audio profiles, codecs, and input device handling

bluez_monitor.properties = {
  -- Enable SBC-XQ, AAC, LDAC, AptX, AptX-HD codecs
  ["bluez5.enable-sbc-xq"] = true,
  ["bluez5.enable-msbc"] = true,
  ["bluez5.enable-hw-volume"] = true,

  -- Enable both A2DP (high quality audio) and HFP (headset/mic)
  ["bluez5.headset-roles"] = "[ hsp_hs hsp_ag hfp_hf hfp_ag ]",

  -- Automatically switch between A2DP and HFP profiles
  ["bluez5.autoswitch-profile"] = true,

  -- Audio codecs to enable (ordered by preference)
  ["bluez5.codecs"] = "[ ldac aac aptx aptx_hd sbc sbc_xq ]",

  -- Enable all Bluetooth roles including input devices
  ["bluez5.roles"] = "[ a2dp_sink a2dp_source bap_sink bap_source hsp_hs hsp_ag hfp_hf hfp_ag ]",
}

bluez_monitor.rules = {
  -- Auto-connect all Bluetooth audio devices
  {
    matches = {
      {
        { "device.name", "matches", "bluez_card.*" },
      },
    },
    apply_properties = {
      ["bluez5.auto-connect"] = "[ hfp_hf hsp_hs a2dp_sink a2dp_source ]",
      ["device.profile"] = "a2dp-sink",
    },
  },

  -- Handle Bluetooth input/HID devices (keyboards, mice, game controllers)
  {
    matches = {
      {
        { "device.name", "matches", "bluez_input.*" },
      },
    },
    apply_properties = {
      ["device.autoconnect"] = true,
    },
  },
}
