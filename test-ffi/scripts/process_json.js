import * as fs from 'fs';
import { ethers } from 'ethers';
import { type } from 'os';


// Optionally specify a path to a file to read from. This is necessary because
// running this from the command line requires `../../test-ffi/tmp/temp` and
// running this from the test suite requires `./test-ffi/tmp/temp`. In ffi, the
// script is executed from the top-level directory.
const args = process.argv;
const path = args[2] || './test-ffi/tmp/temp';
const responseType = args[3] || '--top-level';
const attributeIndex = args[4] || 0;

const rawData = fs.readFileSync(path, "utf8");

try {
    const formattedJson = JSON.parse(rawData);

    // Example JSON:
    // {
    //     "name": "Example NFT #0",
    //     "description": "This is an example NFT",
    //     "image": "data:image/svg+xml;<svg xmlns=\\\"http://www.w3.org/2000/svg\\\" width=\\\"500\\\" height=\\\"500\\\" ><rect width=\\\"500\\\" height=\\\"500\\\" fill=\\\"lightgray\\\" /><text x=\\\"50%\\\" y=\\\"50%\\\" dominant-baseline=\\\"middle\\\" text-anchor=\\\"middle\\\" font-size=\\\"48\\\" fill=\\\"black\\\" >0</text></svg>",
    //     "attributes": [
    //       {
    //         "trait_type": "Example Attribute",
    //         "value": "Example Value"
    //       },
    //       {
    //         "trait_type": "Number",
    //         "value": "0",
    //         "display_type": "number"
    //       },
    //       {
    //         "trait_type": "Parity",
    //         "value": "Even"
    //       }
    //     ]
    //   }
    
    if (responseType === '--top-level') {
        // Extract the name, description, and image from the JSON.
        const itemName = formattedJson.name;
        const description = formattedJson.description;
        const image = formattedJson.image;

        // Initialize the typeArray and valueArray with the name, description, and
        // image.
        let typeArray = ['string', 'string', 'string'];
        let valueArray = [itemName, description, image];

        const abiEncoded = ethers.utils.defaultAbiCoder.encode(typeArray, valueArray);

        // Write the abiEncoded data to stdout.
        process.stdout.write(abiEncoded);
    } else if (responseType === '--attribute') {
        // Extract the attributes from the JSON.
        const attributes = formattedJson.attributes;

        const traitType = attributes[attributeIndex].trait_type;
        const traitValue = attributes[attributeIndex].value;
        const traitDisplayType = attributes[attributeIndex].display_type || "noDisplayType";

        // Encode the typeArray and valueArray.
        const abiEncoded = ethers.utils.defaultAbiCoder.encode(
            ['string', 'string', 'string'], [traitType, traitValue, traitDisplayType]
        );

        // Write the abiEncoded data to stdout.
        process.stdout.write(abiEncoded);
    }
} catch (e) {
    // JSON.parse failed. Likely the path to the file is wrong, the json is not populated, or the JSON is malformed.
    process.stdout.write('0x000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000004a534f4e2e7061727365206661696c65642e204c696b656c7920746865207061746820746f207468652066696c652069732077726f6e672c20746865206a736f6e206973206e6f7420706f70756c617465642c206f7220746865204a534f4e206973206d616c666f726d65642e00000000000000000000000000000000000000');
}








////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

// Saved for reference:

// console.log('Decoding raw data');
// // Decode the base64 encoded data
// const decodedData = atob(rawData).replaceAll('\\\\\\', '');

// console.log('Decoded data: ');
// console.log(decodedData);

// console.log('Converting bytes to string');
// // Convert the bytes to a string
// const stringJson = ethers.utils.defaultAbiCoder.decode(["bytes"], decodedData);

// console.log('Parsing string as JSON');
// Parse the string as JSON
// const formattedJson = JSON.parse(stringJson);