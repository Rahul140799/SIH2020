const express = require('express');
const router = express();
const blockchain = require('./Blockchain/blockchain.js');
const doctor = require('../routes/Doctor/router.js');
const admin  = require('../routes/Admin/router.js');
const patient = require('../routes/Patient/router.js');

router.use('/api/blockchain',blockchain);
router.use('/api/doctor',doctor);
router.use('/api/admin',admin);
router.use('/api/patient',patient);


/**
 * @swagger
 * /:
 *   get:
 *      tags:
 *          - base
 *      description: Returns the base  url
 *      responses:
 *          200:
 *             description: A json containing a message
 *             schema:
 *                  type: object
 *                  properties:
 *                          message:
 *                              type: string
 */

router.get('/',async (req,res,next)=>{
    console.log("API CALLED");
    res.status(200).json({message:"BASE URL"});
});

module.exports = router;