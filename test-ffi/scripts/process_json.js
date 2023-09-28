import * as fs from 'fs';
import { ethers } from 'ethers';


const args = process.argv;

// Optionally specify a path to a file to read from. This is necessary because
// running this from the command line requires `../../test-ffi/tmp/temp.json` &
// running this from the test suite requires `./test-ffi/tmp/temp.json`. In ffi,
// the script is executed from the top-level directory.
const path = args[2] || './test-ffi/tmp/temp.json';

// Optionally specify a response type. This can be either '--top-level' or
// '--attribute'. If '--top-level' is specified, the script will extract the
// name, description, and image from the JSON and return them. If '--attribute'
// is specified, the script will extract the attribute from the JSON and return
// the trait_type, value, and display_type.
const responseType = args[3] || '--top-level';

// Optionally specify an attribute index. This is only used if the response type
// is '--attribute'.
const attributeIndex = args[4] || 0;

// Example command, run in the terminal from the top level directory:
// node ./test-ffi/scripts/process_json.js ./test-ffi/tmp/temp.json --attribute 1

// Read the file at the specified path.
const rawData = fs.readFileSync(path, "utf8");

let formattedJson;

try {
    // Parse the raw data as JSON.
    formattedJson = JSON.parse(rawData);
} catch (e) {
    // JSON.parse failed. Likely the path to the file is wrong, the json is not populated, or the JSON is malformed.
    process.stdout.write('0x000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000004a534f4e2e7061727365206661696c65642e204c696b656c7920746865207061746820746f207468652066696c652069732077726f6e672c20746865206a736f6e206973206e6f7420706f70756c617465642c206f7220746865204a534f4e206973206d616c666f726d65642e00000000000000000000000000000000000000');
}

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

    try {

    const traitType = attributes[attributeIndex].trait_type;
    const traitValue = attributes[attributeIndex].value;
    const traitDisplayType = attributes[attributeIndex].display_type || "noDisplayType";

    // Encode the typeArray and valueArray.
    const abiEncoded = ethers.utils.defaultAbiCoder.encode(
        ['string', 'string', 'string'], [traitType, traitValue, traitDisplayType]
    );

    // Write the abiEncoded data to stdout.
    process.stdout.write(abiEncoded);
    } catch (e) {
        // Likely the attributeIndex is out of bounds.
        process.stdout.write('0x0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000002b4c696b656c792074686520617474726962757465496e646578206973206f7574206f6620626f756e64732e000000000000000000000000000000000000000000');
    }
}
