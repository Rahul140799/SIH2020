const express = require('express');
const router = express();
const jwt = require('jsonwebtoken');
const { getDocCount } = require('./connection/handlers.js');
const { auth } = require('../../middleware/auth.js');


/**
 * @swagger
 *
 * /api/blockchain/{username}:
 *   get:
 *     tags:
 *       - api
 *     description: user api to display the user in response
 *     produces:
 *       - application/json
 *     parameters:
 *       - name: username
 *         description: Username to use for login.
 *         in: path
 *         required: true
 *         type: string
 *     responses:
 *       200:
 *         description: login
 *         schema:
 *              type: object
 *              properties:
 *                  message:
 *                      type: string
 *                  user:
 *                      type: string
 *     deprecated: true
 *              
 */

router.get('/:username',(req,res,next)=>{
    const token = jwt.sign({_name : req.params.username},"jayvishaalj");
    res.header('auth-token',token).status(200).json({message:"API BASE URL",user:req.params.username});
});




module.exports = router;