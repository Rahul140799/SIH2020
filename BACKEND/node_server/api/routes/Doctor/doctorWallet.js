const express = require('express');
const router = express();
const mongoose = require('mongoose');
const { appointmentSchema, addQuestionSchema, getAnswerSchema }  = require('./doctor_schema');
const { auth } = require('../../middleware/auth');
const logger = require('../../../config/logger')(module);
const { getBalance } = require('../Blockchain/connection/handlers');



/**
 * @swagger
 * /api/doctor/wallet/balance:
 *   post:
 *      tags:
 *          - doctor
 *      description: to get balance of an account
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
 *             type: object
 *             required: 
 *                  - doctorAddress
 *             properties:
 *                  doctorAddress:
 *                      type: string
 *      responses:
 *          200:
 *             description: All the Follow up realted to this doctor and patient are displayed
 *             schema:
 *                  type: object
 *                  properties:
 *                      balance: 
 *                          type: string
 * 
 *           
 */
router.post('/balance',(req,res,next) => {
    try{
        if(req.body.doctorAddress){
            getBalance(req.body.doctorAddress).then((balance) => {
                console.log("BALANCE : : ",balance);
                logger.log('info',`Doctor Wallet Balance API called ${JSON.stringify(req.body)} ${balance}`);
                return res.status(200).json({balance:balance});
            });
        }
        else{
            logger.log('error',`WALLET API CALLED error ${JSON.stringify(req.body)} error: doctorAddress not specified`);
            return res.status(400).json({error:"Doctor Address Missing"});
        }
    }
    catch(e){
        logger.log('error',`WALLET API CALLED error ${JSON.stringify(req.body)} error: ${e}`);
            return res.status(500).json({error:e});
    }
});



module.exports = router;