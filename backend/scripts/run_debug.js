const { exec } = require('child_process');
const fs = require('fs');
const path = require('path');

const cmd = 'node scripts/rebootstrap.js';
const cwd = 'c:\\Users\\allou\\OneDrive\\Bureau\\Projts_Academique\\App_mobile_Epicier\\Application-Mobile-Commande-Epicier\\backend';

exec(cmd, { cwd }, (error, stdout, stderr) => {
    const output = `--- STDOUT ---\n${stdout}\n\n--- STDERR ---\n${stderr}\n\n--- ERROR ---\n${JSON.stringify(error, null, 2)}`;
    fs.writeFileSync('c:\\Users\\allou\\OneDrive\\Bureau\\Projts_Academique\\App_mobile_Epicier\\Application-Mobile-Commande-Epicier\\rebootstrap_debug.txt', output, 'utf8');
    console.log('Output written to rebootstrap_debug.txt');
});
