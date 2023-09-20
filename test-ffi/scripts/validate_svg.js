import * as fs from 'fs';
import isSvg from 'is-svg';
import { ethers } from 'ethers';

const args = process.argv;

const path = args[2] || './test-ffi/tmp/temp.svg';

// Load the SVG data from temp.svg and clear the escape characters.
const testSvg = fs.readFileSync(path, 'utf8').replace(/\\"/g, '"');

// Check if the SVG is valid.
const isValidSvg = isSvg(testSvg);

// Encode the isValidSvg and testSvg data.
const abiEncoded = ethers.utils.defaultAbiCoder.encode(
    ['bool', 'string'], [isValidSvg, testSvg]
);

// Write the abiEncoded data to stdout.
process.stdout.write(abiEncoded);
