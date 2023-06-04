Look for 
```
var binary ='<<$BASE64BLOB>>' 
```
in the index.html inside the phishing folder and replace with your own base64 payload/container. Change the theme to different popular software (or try bluebeam) and modify the download name:

    var payloadfilename = 'BluebeamRevu.zip';

File will be downloaded automatically for the user under that name.

Modify and Run ./Serve.ps1 from  the Pheeders folder, it will deploy the app contained in phishing to azure app service and your payload will be hosted on https://<<APP NAME>>.azurewebsites.net