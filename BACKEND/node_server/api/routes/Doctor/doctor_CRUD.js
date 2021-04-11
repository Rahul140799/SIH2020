const express = require('express');
const router = express();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { createDoctor, getDoctor, getDocCount } = require('../Blockchain/connection/handlers.js');
const { doctorSchema, doctorLoginSchema } = require('./doctor_schema');
const { auth } = require('../../middleware/auth.js');
const QRCode  = require('qrcode');
const { sendMail } = require('../../middleware/sendmail.js');
const logger = require('../../../config/logger.js')(module);


/**
 * @swagger
 * /api/doctor/create:
 *   post:
 *      tags:
 *          - doctor
 *      description: to create a new doctor 
 *      consumes:
 *       - application/json
 *      parameters:
 *       - name: auth-token
 *         description: auth token got from  login.
 *         in: header
 *         type: string
 *       - in: body
 *         name: doctor
 *         schema :
 *              type: object
 *              required:
 *                  - name
 *                  - phno
 *                  - email
 *                  - password
 *              properties:
 *                  name:
 *                      type: string
 *                  phno:
 *                      type: string
 *                  email:
 *                      type: string
 *                  password:
 *                      type: string
 *                      minLength: 8
 *      responses:
 *          200:
 *             description: A json containing a the details of the address of the doctor
 *             schema:
 *                  type: object
 *                  properties:
 *                          message:
 *                              type: string
 *                          result:
 *                              type: object
 *                              properties:
 *                                  account:
 *                                      type: string
 *                                  hash:
 *                                      type: string
 *          
 */
router.post('/create',auth, async (req, res, next) => {
    try {
        const { error } = doctorSchema.validate(req.body);
        if (error) {
            logger.log('error',`Doctor Create error ${JSON.stringify(req.body)} error : ${error}`);
            res.status(400).json({ error: error.details[0].message });
        }
        else {
            console.log("CREATE DOCTOR API CALLED", req.body);
            logger.log('info',`Create Doctor API CALLED ${JSON.stringify(req.body)}`);
            const password = await bcrypt.hash(req.body.password, 10);
            console.log("PASSWORD ", password);
            createDoctor(req.body.name, req.body.phno, req.body.email, password).then(account => {
                console.log("ACCOUNT : ", account);
                QRCode.toDataURL(account.account,{scale:10}, function (err, url) {
                    console.log(url)
                    sendMail("DOCTOR ","This is the QR Code for the you to Login intot the app!",req.body.email,url).then((info,err) =>{
                        if(err){
                            logger.log('error',`Create Doctor API Error ${err}`);
                            console.log("err",err," info ",info);
                            return res.status(400).json({ message: "Doctor added! But QrCode Not Mailed", result: account })
                           
                        }
                        else{
                            logger.log('info',`Created new Doctor  ${JSON.stringify(account)}`);
                            return res.status(200).json({ message: "Doctor added!", result: account });
                        }
                    });
                  });
            });
        }
    }
    catch (e) {
        logger.log('error',`Doctor create API error ${JSON.stringify(req.body)} , error: ${e}`);
        res.status(400).json({ message: "wrong details" });
    }


});

/**
 * @swagger
 * /api/doctor/details:
 *   post:
 *      tags:
 *          - doctor
 *      description: to get the details of a doctor
 *      consumes:
 *       - application/json
 *      parameters:
 *       - name: auth-token
 *         description: auth token got from  login.
 *         in: header
 *         type: string
 *       - in: body
 *         name: doctor
 *         schema :
 *              type: object
 *              required:
 *                  - address
 *              properties:
 *                  address:
 *                      type: string
 *      responses:
 *          200:
 *             description: A doctor exist and the details of the doctor are returned 
 *             schema:
 *                  type: object
 *                  properties:
 *                          doctor:
 *                              type: object
 *                              properties:
 *                                  name:
 *                                      type: string
 *                                  phno:
 *                                      type: string
 *                                  doctorId:
 *                                      type: string
 *                                  email:
 *                                      type: string          
 */
router.post('/details',auth, async (req, res, next) => {
    console.log("DOC DETAIL : ", req.body.address);
    try {
        const doctor = await getDoctor(req.body.address);
        logger.log('info',`Doctor Details API Called ${JSON.stringify(req.body)} , doctor: ${JSON.stringify(doctor)}`);
        res.status(200).json({ doctor: { "name": doctor["1"], "phno": doctor["2"], "doctorId": doctor["0"], "email": doctor["3"] } });
    }
    catch (e) {
        logger.log('error',`Doctor Details API error ${JSON.stringify(req.body)} , error: ${e}`);
        res.status(400).json({ message: "Wrong Address" });
    }

});


/**
 * @swagger
 * /api/doctor/login:
 *   post:
 *      tags:
 *          - doctor
 *      description: to get the details of a doctor
 *      consumes:
 *       - application/json
 *      parameters:
 *       - in: body
 *         name: doctor
 *         schema :
 *              type: object
 *              required:
 *                  - address
 *                  - password
 *              properties:
 *                  address:
 *                      type: string
 *                  password:
 *                      type: string
 *      responses:
 *          200:
 *             description: A doctor exist and the details of the doctor are returned 
 *             schema:
 *                  type: object
 *                  properties:
 *                          message:
 *                              type: string
 * 
 *          401:
 *             description: wrong Creds check the address and password
 *             schema:
 *                  type: object
 *                  properties:
 *                          message:
 *                              type: string
 */
router.post('/login', async (req, res, next) => {
    try {
        const { error } = doctorLoginSchema.validate(req.body);
        if (error) {
            logger.log('error',`Doctor Login API error ${JSON.stringify(req.body)} , error: ${error}`);
            res.status(400).json({ error: error.details[0].message });
        }
        else {
            console.log("LOGIN DOC : ", req.body);
            const doctor = await getDoctor(req.body.address);
            const validPass = await bcrypt.compare(req.body.password, doctor["4"]);
            if (validPass) {
                const token = jwt.sign({ _name: req.body.address, _user: "doctor" }, "jayvishaalj");
                logger.log('info',`Doctor Login API  ${JSON.stringify(req.body)} , token: ${token}`);
                return res.header('auth-token', token).status(200).json({ message: "Logged In!" });
            }
            else {
                return res.status(401).json({ message: "Unotherized! wrong password" });
            }
        }
    }
    catch (e) {
        logger.log('error',`Doctor Login API error ${JSON.stringify(req.body)} , error: ${e}`);
        res.status(400).json({ message: "Wrong Creds" });
    }


});

/**
 * @swagger
 * /api/doctor/count:
 *   get:
 *      tags:
 *          - doctor
 *      description: Returns the count of doctors registered in the blockchain
 *      parameters:
 *       - name: auth-token
 *         description: auth token got from  login.
 *         in: header
 *         type: string
 *      responses:
 *          200:
 *             description: A json containing a message
 *             schema:
 *                  type: object
 *                  properties:
 *                          message:
 *                              type: string
 *          401:
 *              description: Access Denied
 */
router.get('/count', async (req, res, next) => {
    const message = await getDocCount();
    res.status(200).json({ message: message });
});

module.exports = router;