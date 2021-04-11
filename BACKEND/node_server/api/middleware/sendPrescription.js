const nodemailer = require("nodemailer");
const PDFDocument = require('pdfkit');
const AWS = require('aws-sdk');
var unirest = require("unirest");
const fs = require('fs');
const req = unirest("POST", "https://www.fast2sms.com/dev/bulk");
const logger = require('../../config/logger')(module);

const ID = 'AKIA4BGGYS5LJXQVN53J';
const SECRET = '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';
const BUCKET_NAME = 'scribe-plus-prescriptions';
const s3 = new AWS.S3({
    accessKeyId: ID,
    secretAccessKey: SECRET,
    signatureVersion: 'v4'
});

module.exports.sendPrescription = async(toEmail, name, age, gender, address, date, out /**2D Array */, patPhone) => {
  try{
    logger.log('info',`Entered PDF SENDING SECTION `);
    const doc = new PDFDocument({userPassword:"password"});
    var transporter = nodemailer.createTransport({
        service: 'gmail',
        auth: {
          user: 'scribeplus.contact@gmail.com',
          pass: 'deeplearners'
        }
    });
    let buffers = [];
    doc.on('data', buffers.push.bind(buffers));
   
    // Pipe its output somewhere, like to a file or HTTP response
    // See below for browser usage
     
    // Embed a font, set the font size, and render some text
      doc.fontSize(35)
      .text('CEC Hospital', 185, 30).fillColor("#000");
  
    
      doc.fontSize(15)
      .text('Dr.Rahul M.B.B.S', 30, 100).fillColor("#000");
    
      doc.fontSize(15)
      .text('Dr.Lane,Chennai-88', 30, 120).fillColor("#000");
    
      doc.fontSize(15)
      .text('PH: 1234567890', 350, 100).fillColor("#000");
    
      doc.fontSize(15)
      .text('FAX: rahul@gmail.com', 350, 120).fillColor("#000");
    
    doc.rect(30,150,doc.page.width*0.85,2).fill("#62438A");
    doc.fillColor("#000");
    
    doc.fontSize(15)
       .text('Name :', 30, 200).fillColor("#000");
    
       doc.fontSize(15)
       .text(`${name}`, 100, 190).fillColor("#000");
    doc.rect(100,210,doc.page.width*0.20,1).fill("#0A1A89");
    doc.fillColor("#000");
    
    doc.fontSize(15)
       .text('Age :', 250, 200).fillColor("#000");
    
       doc.fontSize(15)
       .text(age, 350, 193).fillColor("#000");
    doc.rect(310,210,doc.page.width*0.10,1).fill("#0A1A89");
    doc.fillColor("#000");
    
    doc.fontSize(15)
    .text('Gender :', 400, 200).fillColor("#000");
    
    doc.fontSize(15)
       .text(gender, 480, 190).fillColor("#000");
    doc.rect(480,210,doc.page.width*0.10,1).fill("#0A1A89");
    doc.fillColor("#000");
    
    doc.fontSize(15)
    .text('Address :', 30, 250).fillColor("#000");
  
    doc.fontSize(15)
       .text(address, 120, 240).fillColor("#000");
    doc.rect(110,260,doc.page.width*0.45,1).fill("#0A1A89");
    doc.fillColor("#000");
    
    doc.fontSize(15)
    .text('Date :', 400, 250).fillColor("#000");
    
    doc.fontSize(15)
       .text(date, 460, 240).fillColor("#000");
    doc.rect(450,260,doc.page.width*0.15,1).fill("#0A1A89");
    doc.fillColor("#000");
    let count = -1
    out.forEach((i) => {
        count += 1
      doc.fontSize(15)
      .text(`${i[0]}`, 100, 350+(count*40)).fillColor("#000");
      doc.fontSize(15)
      .text(`${i[1]} ${i[2]}`, 350, 350+(count*40)).fillColor("#000");    
  
      if(i[5] === "tablets") {
        doc.fontSize(15)
      .text('[TAB]', 5, 350+(count*40)).fillColor("#000");    
      } else {
        doc.fontSize(15)
      .text(`[${i[5]}]`, 8, 350+(count*40)).fillColor("#000");    
      }

      if(i[3].includes("ml") || i[3].includes("mg")){
        doc.fontSize(15)
      .text(`${i[3]}`, 450, 350+(count*40)).fillColor("#000");
      } else {
        doc.fontSize(15)
      .text(`x${i[3]}`, 450, 350+(count*40)).fillColor("#000");
      }

      doc.fontSize(10)
    .text(`${i[4]}`,450, 370+(count*40)).fillColor("#000")
    })
    
    doc.fontSize(15)
    .text('Review as needed. Complete rest adviced till July.',120,620).fillColor("#000")
  
    doc.fontSize(10)
    .text(`${new Date()}`,140,650).fillColor("#000");
    
    doc.rect(30,680,doc.page.width*0.80,2).fill("#62438A");
    doc.fillColor("#000");
    
    doc.fontSize(15)
    .text('Doctor Signature', 30, 700).fillColor("#000");
    
    doc.fontSize(15)
    .text('Powered By', 430, 700).fillColor("#000");
    
    // Add an image, constrain it to a given size, and center it vertically and horizontally
     
    // Finalize PDF file
    doc.end();
    
    doc.on('end', async () => {

        let pdfData = Buffer.concat(buffers);

        let mailOptions = {
            from: 'scribeplus.contact@gmail.com',
            to: toEmail,
            subject: 'Prescription',
            text: 'Prescription for the Doctor Visit ',
            attachments: [{
                filename: 'prescription.pdf',
                content: pdfData
            }]
        };
        const params = {
            Bucket: BUCKET_NAME,
            Key: 'prescription.pdf', // File name you want to save as in S3
            Body: pdfData
        };
        
        await s3.upload(params, async function(err, data) {
            if (err) {
                throw err;
            }
            console.log(`File uploaded successfully. ${data.Location}`);
            const url = await s3.getSignedUrl('getObject', {
                Bucket: BUCKET_NAME,
                Key: 'prescription.pdf', // File name you want to save as in S3
                Expires: 60 * 5
            });
            console.log("object Signed Url : ",url);
            var messageString = "Your Prescription is available in the following link for the next 5mins so download and keep it safe " + url;
            console.log(messageString);
            req.headers({
                "authorization": "aefkJGosAbt4CzKpjhYvM1rmUgyqWZHwl5ud9XF3T6OSDnBRLP3TnLhQiEDNBIvRVAsUFok8MJe0qCO5"
            });

            req.form({
                "sender_id": "FSTSMS",
                "message": messageString,
                "language": "english",
                "route": "p",
                "numbers": patPhone,
            });

            req.end(async function (res) {
                if (res.error) {
                    // logger.log('error',`An error occured at sending message ${res.error}`);
                    throw new Error(res.error);
                }        
            });
            logger.log('info',`PDF SENT `);
            return await transporter.sendMail(mailOptions);
        }); 
    })
  }
  catch(e){
    logger.log('error',`PDF NOT SENT ${e} `);
  }
};