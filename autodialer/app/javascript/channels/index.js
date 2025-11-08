// Load all the channels within this directory and all subdirectories.
// Channel files must be named *_channel.js.

const channelFiles = require.context('.', true, /_channel\.js$/)
channelFiles.keys().forEach(channelFiles)
