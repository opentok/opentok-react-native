const fs = require('fs');
const path = require('path');
const each = require('underscore').each;

(function postInstall() {
  console.log('running post install linking');  
  const appName = require('../package.json').name;    
  const checkIOSBridingHeader = () => {
   const iOSFiles = fs.readdirSync(`${__dirname}/../ios/`);
   each(iOSFiles, file => {
     if (file.includes('Bridging-Header.h')) {
       return true;
     }
   });
   return false;
  };
  const linkIOS = () => {
    console.log('linking iOS files');
    const isBridge = checkIOSBridingHeader();
    const dirPath = path.join(__dirname, '../', 'ios');
    fs.readdir(dirPath, (err, files) => {
      files.forEach(file => {
        const fileContents = fs.readFileSync(`/${dirPath}/${file}`);
        if (file === 'Bridging-Header.h' && isBridge === false) {
          const bridgeName = `${appName}-${file}`;
          fs.writeFileSync(`${__dirname}/../ios/${bridgeName}`, fileContents);
        } else {
          fs.writeFileSync(`${__dirname}/../ios/${file}`, fileContents);
        }
      });
    });
  };
  linkIOS();
}());
