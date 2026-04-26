const { getDefaultConfig } = require('@expo/metro-config');
const path = require('path');
const fs = require('fs');

// Use the real path as projectRoot to avoid junction/symlink path doubling on Windows
const realRoot = fs.realpathSync(__dirname);

module.exports = getDefaultConfig(realRoot);
